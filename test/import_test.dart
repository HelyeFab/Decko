// Parser + storage tests for Anki .apkg import.
//
// There is no real .apkg fixture committed; instead each test builds a minimal,
// valid Anki collection with sqlite3 and zips it with `archive`, so the parser
// is exercised end-to-end on the host (system libsqlite3 on macOS).

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:decko/domain/repositories/media_store.dart';

import 'package:decko/data/import/anki_apkg_import_adapter.dart';
import 'package:decko/data/imported_deck_storage.dart';
import 'package:decko/domain/deck.dart';
import 'package:decko/domain/import/deck_import_adapter.dart';
import 'package:decko/domain/import/deck_import_info.dart';
import 'package:decko/domain/import/deck_import_preview.dart';
import 'package:decko/domain/import/imported_card_state.dart';

final String _fs = String.fromCharCode(0x1f); // Anki field separator

class _FakeMediaStore implements MediaStore {
  final Map<String, Uint8List> saved = <String, Uint8List>{};
  @override
  Future<void> saveMedia(String deckId, String fileName, Uint8List bytes) async =>
      saved['$deckId/$fileName'] = bytes;
  @override
  Future<String?> resolveMedia(String deckId, String fileName) async =>
      saved.containsKey('$deckId/$fileName') ? '$deckId/$fileName' : null;
  @override
  Future<void> deleteMediaForDeck(String deckId) async =>
      saved.removeWhere((String k, _) => k.startsWith('$deckId/'));
}

/// Builds a `.apkg` (zip with a `collection.anki21` SQLite DB) from card specs.
/// Each card spec: [type, queue, reps, ivl, factor], with fields front/back/ex.
Uint8List _buildApkg({
  required String deckName,
  required List<_CardSpec> cards,
  Map<String, List<int>> media = const <String, List<int>>{},
}) {
  final Directory tmp = Directory.systemTemp.createTempSync('decko_fixture');
  final String path = '${tmp.path}/collection.anki21';
  final Database db = sqlite3.open(path);
  try {
    db.execute('CREATE TABLE col (id INTEGER PRIMARY KEY, crt INTEGER, '
        'decks TEXT);');
    db.execute('CREATE TABLE notes (id INTEGER PRIMARY KEY, flds TEXT);');
    db.execute('CREATE TABLE cards (id INTEGER PRIMARY KEY, nid INTEGER, '
        'did INTEGER, queue INTEGER, type INTEGER, due INTEGER, ivl INTEGER, '
        'reps INTEGER, lapses INTEGER, factor INTEGER);');

    db.execute(
      'INSERT INTO col (id, crt, decks) VALUES (1, 1600000000, ?);',
      <Object?>['{"1":{"name":"$deckName"},"2":{"name":"Default"}}'],
    );

    for (int i = 0; i < cards.length; i++) {
      final _CardSpec c = cards[i];
      final int nid = 100 + i;
      db.execute('INSERT INTO notes (id, flds) VALUES (?, ?);',
          <Object?>[nid, '${c.front}$_fs${c.back}$_fs${c.field2}']);
      db.execute(
        'INSERT INTO cards (id, nid, did, queue, type, due, ivl, reps, '
        'lapses, factor) VALUES (?, ?, 1, ?, ?, 0, ?, ?, 0, ?);',
        <Object?>[200 + i, nid, c.queue, c.type, c.ivl, c.reps, c.factor],
      );
    }
  } finally {
    db.close();
  }

  final Uint8List dbBytes = File(path).readAsBytesSync();
  tmp.deleteSync(recursive: true);

  // Media: numbered payload files + the `media` JSON mapping (numbered->name).
  final Map<String, String> mediaMap = <String, String>{};
  final Archive archive = Archive()
    ..addFile(ArchiveFile('collection.anki21', dbBytes.length, dbBytes));
  int n = 0;
  media.forEach((String name, List<int> bytes) {
    archive.addFile(ArchiveFile('$n', bytes.length, bytes));
    mediaMap['$n'] = name;
    n++;
  });
  final List<int> mediaJson = jsonEncode(mediaMap).codeUnits;
  archive.addFile(ArchiveFile('media', mediaJson.length, mediaJson));
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

class _CardSpec {
  const _CardSpec({
    required this.type,
    required this.queue,
    this.reps = 0,
    this.ivl = 0,
    this.factor = 0,
    this.front = 'front',
    this.back = 'back',
    this.field2 = '今日は良い天気です。',
  });
  final int type;
  final int queue;
  final int reps;
  final int ivl;
  final int factor;
  final String front;
  final String back;
  final String field2;
}

void main() {
  const AnkiApkgImportAdapter adapter = AnkiApkgImportAdapter();

  // A deck with one new, one reviewed, one suspended card.
  Uint8List mixedDeck() => _buildApkg(
        deckName: 'Japanese Core',
        cards: const <_CardSpec>[
          _CardSpec(type: 0, queue: 0, front: '食べる', back: 'to eat'),
          _CardSpec(
              type: 2, queue: 2, reps: 5, ivl: 10, factor: 2500,
              front: '飲む', back: 'to drink'),
          _CardSpec(type: 0, queue: -1, front: '本', back: 'book'),
        ],
      );

  test('preview reports counts and detects progress', () async {
    final DeckImportPreview p = await adapter.preview(mixedDeck());

    expect(p.deckName, 'Japanese Core');
    expect(p.totalCards, 3);
    expect(p.newCards, 1);
    expect(p.reviewedCards, 1);
    expect(p.suspendedCards, 1);
    expect(p.hasProgressData, isTrue);
  });

  test('importDeck keepProgress preserves imported state and strips HTML',
      () async {
    final Deck deck = await adapter.importDeck(
      mixedDeck(),
      keepProgress: true,
      importedAt: DateTime(2026, 6, 12),
    );

    expect(deck.isImported, isTrue);
    expect(deck.importInfo!.progressMode, ImportProgressMode.kept);
    expect(deck.items, hasLength(3));
    expect(deck.items.first.front, '食べる');

    final reviewed = deck.items.firstWhere((i) => i.front == '飲む');
    expect(reviewed.importedProgress, isNotNull);
    expect(reviewed.importedProgress!.state, ImportedCardState.review);
    expect(reviewed.importedProgress!.reps, 5);
    expect(reviewed.importedProgress!.intervalDays, 10);
    expect(reviewed.importedProgress!.easeFactor, 2.5);
  });

  test('importDeck start-fresh drops imported progress', () async {
    final Deck deck = await adapter.importDeck(
      mixedDeck(),
      keepProgress: false,
      importedAt: DateTime(2026, 6, 12),
    );

    expect(deck.importInfo!.progressMode, ImportProgressMode.fresh);
    expect(deck.items.every((i) => i.importedProgress == null), isTrue);
  });

  test('a deck of only new cards reports no progress, mode unavailable',
      () async {
    final Uint8List bytes = _buildApkg(
      deckName: 'Fresh Deck',
      cards: const <_CardSpec>[
        _CardSpec(type: 0, queue: 0),
        _CardSpec(type: 0, queue: 0),
      ],
    );

    final DeckImportPreview p = await adapter.preview(bytes);
    expect(p.hasProgressData, isFalse);

    final Deck deck = await adapter.importDeck(bytes,
        keepProgress: true, importedAt: DateTime(2026, 6, 12));
    expect(deck.importInfo!.progressMode, ImportProgressMode.unavailable);
  });

  test('modern zstd .anki21b is rejected with a clear message', () async {
    final Archive archive = Archive()
      ..addFile(ArchiveFile('collection.anki21b', 3, <int>[1, 2, 3]));
    final Uint8List bytes =
        Uint8List.fromList(ZipEncoder().encode(archive));

    expect(
      () => adapter.preview(bytes),
      throwsA(isA<UnsupportedPackageException>()),
    );
  });

  test('garbage bytes fail gracefully as a DeckImportException', () async {
    expect(
      () => adapter.preview(Uint8List.fromList(<int>[0, 1, 2, 3, 4])),
      throwsA(isA<DeckImportException>()),
    );
  });

  test('field mapping: a kana field becomes the reading (deduped), a sentence '
      'becomes the example', () async {
    final Uint8List kanaCase = _buildApkg(
      deckName: 'Vocab',
      cards: const <_CardSpec>[
        // field0=三, field1=three, field2=duplicated kana reading.
        _CardSpec(type: 0, queue: 0, front: '三', back: 'three',
            field2: 'さん さん'),
      ],
    );
    final Deck kanaDeck = await adapter.importDeck(kanaCase,
        keepProgress: false, importedAt: DateTime(2026, 6, 12));
    final item = kanaDeck.items.single;
    expect(item.front, '三');
    expect(item.back, 'three');
    expect(item.reading, 'さん'); // deduped, not "さん さん"
    expect(item.example, isNull); // a reading is not an example

    final Uint8List sentenceCase = _buildApkg(
      deckName: 'Vocab',
      cards: const <_CardSpec>[
        _CardSpec(type: 0, queue: 0, front: '食べる', back: 'to eat',
            field2: '毎日ご飯を食べます。'),
      ],
    );
    final Deck sentenceDeck = await adapter.importDeck(sentenceCase,
        keepProgress: false, importedAt: DateTime(2026, 6, 12));
    expect(sentenceDeck.items.single.example, '毎日ご飯を食べます。');
  });

  test('real note shape: furigana → reading, back blob → meaning + example, '
      'junk dropped', () async {
    // Mirrors the Kuchiguse / Core note format seen in real .apkg files.
    final Uint8List bytes = _buildApkg(
      deckName: 'Kuchiguse',
      cards: <_CardSpec>[
        _CardSpec(
          type: 0,
          queue: 0,
          front: '[sound:word_101.wav]<br><ruby>会社<rt>かいしゃ</rt></ruby>',
          back: 'n - company; office<br>'
              '<ruby>会社<rt>かいしゃ</rt></ruby>どう？<br>'
              "How's work?<br>[sound:sentence_101.wav]<br>jp500_0101",
          field2: '',
        ),
      ],
    );

    final Deck deck = await adapter.importDeck(bytes,
        keepProgress: false, importedAt: DateTime(2026, 6, 12));
    final item = deck.items.single;

    expect(item.front, contains('会社[かいしゃ]')); // furigana preserved
    expect(item.front, contains('[sound:word_101.wav]')); // word audio kept
    expect(item.reading, isNull);
    expect(item.back, 'n - company; office'); // first back line only
    expect(item.example, contains('会社[かいしゃ]どう？'));
    expect(item.example, contains("How's work?"));
    expect(item.example, contains('[sound:sentence_101.wav]')); // sentence audio kept
    expect(item.example, isNot(contains('jp500'))); // id dropped
  });

  test('extracts media, counts refs, and keeps media markers on the card',
      () async {
    final Uint8List bytes = _buildApkg(
      deckName: 'Media Deck',
      cards: const <_CardSpec>[
        _CardSpec(
          type: 0,
          queue: 0,
          front: '食[た]べる [sound:taberu.mp3] <img src="taberu.jpg">',
          back: 'to eat',
          field2: '',
        ),
      ],
      media: <String, List<int>>{
        'taberu.mp3': <int>[1, 2, 3],
        'taberu.jpg': <int>[4, 5, 6],
      },
    );

    final DeckImportPreview p = await adapter.preview(bytes);
    expect(p.mediaFiles, 2);
    expect(p.audioRefs, 1);
    expect(p.imageRefs, 1);

    final _FakeMediaStore store = _FakeMediaStore();
    final Deck deck = await adapter.importDeck(bytes,
        keepProgress: false, importedAt: DateTime(2026, 6, 13), mediaStore: store);

    // Media saved under the deck id; markers preserved on the card.
    expect(store.saved.keys, containsAll(<String>[
      '${deck.id}/taberu.mp3',
      '${deck.id}/taberu.jpg',
    ]));
    expect(deck.items.first.front, contains('[sound:taberu.mp3]'));
    expect(deck.items.first.front, contains('<img src="taberu.jpg">'));
  });

  test('imported decks survive a storage round-trip', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const ImportedDeckStorage storage = ImportedDeckStorage();

    final Deck deck = await adapter.importDeck(
      mixedDeck(),
      keepProgress: true,
      importedAt: DateTime(2026, 6, 12),
    );
    await storage.save(<Deck>[deck]);

    final List<Deck> loaded = await storage.load();
    expect(loaded, hasLength(1));
    expect(loaded.first.name, 'Japanese Core');
    expect(loaded.first.isImported, isTrue);
    final restored = loaded.first.items.firstWhere((i) => i.front == '飲む');
    expect(restored.importedProgress!.state, ImportedCardState.review);
    expect(restored.importedProgress!.reps, 5);
  });
}
