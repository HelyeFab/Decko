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
import 'package:decko/domain/import/import_diagnostics.dart';
import 'package:decko/domain/import/source/imported_anki_source.dart';
import 'package:decko/domain/import/zstd_decoder.dart';
import 'package:decko/domain/repositories/imported_source_store.dart';
import 'package:decko/domain/review_card_mode.dart';

/// A no-op zstd decoder for host tests — returns input unchanged, so modern
/// fixtures whose payloads are left raw "decompress" to themselves.
class _IdentityZstd implements ZstdDecoder {
  @override
  Future<Uint8List> decode(Uint8List input) async => input;
}

/// A zstd decoder that always fails — simulates an undecodable modern package.
class _FailingZstd implements ZstdDecoder {
  @override
  Future<Uint8List> decode(Uint8List input) async =>
      throw const ZstdDecodeException('cannot decode');
}

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

/// A default note type ("Basic") with three positional fields and one card
/// template — enough for the legacy positional tests. MVP_009 tests pass their
/// own [modelsJson] to exercise named fields and multiple card templates.
const String _defaultModelId = '1500000000';
String _defaultModelsJson() => jsonEncode(<String, dynamic>{
      _defaultModelId: <String, dynamic>{
        'name': 'Basic',
        'flds': <Map<String, Object>>[
          <String, Object>{'name': 'Front', 'ord': 0},
          <String, Object>{'name': 'Back', 'ord': 1},
          <String, Object>{'name': 'Field2', 'ord': 2},
        ],
        'tmpls': <Map<String, Object>>[
          <String, Object>{
            'name': 'Card 1',
            'ord': 0,
            'qfmt': '{{Front}}',
            'afmt': '{{Back}}',
          },
        ],
      },
    });

/// Builds a `.apkg` (zip with a `collection.anki21` SQLite DB) from card specs.
/// Each card spec: [type, queue, reps, ivl, factor], with fields front/back/ex.
///
/// [modelsJson] is the raw `col.models` blob; when null a default Basic note
/// type is used. Each [_CardSpec] may override its model id, template ordinal,
/// tags, and supply named field values directly (MVP_009).
Uint8List _buildApkg({
  required String deckName,
  required List<_CardSpec> cards,
  Map<String, List<int>> media = const <String, List<int>>{},
  String? modelsJson,
}) {
  final Directory tmp = Directory.systemTemp.createTempSync('decko_fixture');
  final String path = '${tmp.path}/collection.anki21';
  final Database db = sqlite3.open(path);
  try {
    db.execute('CREATE TABLE col (id INTEGER PRIMARY KEY, crt INTEGER, '
        'decks TEXT, models TEXT);');
    db.execute('CREATE TABLE notes (id INTEGER PRIMARY KEY, guid TEXT, '
        'mid INTEGER, flds TEXT, tags TEXT);');
    db.execute('CREATE TABLE cards (id INTEGER PRIMARY KEY, nid INTEGER, '
        'did INTEGER, ord INTEGER, queue INTEGER, type INTEGER, due INTEGER, '
        'ivl INTEGER, reps INTEGER, lapses INTEGER, factor INTEGER);');

    db.execute(
      'INSERT INTO col (id, crt, decks, models) VALUES (1, 1600000000, ?, ?);',
      <Object?>[
        '{"1":{"name":"$deckName"},"2":{"name":"Default"}}',
        modelsJson ?? _defaultModelsJson(),
      ],
    );

    for (int i = 0; i < cards.length; i++) {
      final _CardSpec c = cards[i];
      final int nid = 100 + i;
      final String flds = '${c.front}$_fs${c.back}$_fs${c.field2}';
      db.execute(
        'INSERT INTO notes (id, guid, mid, flds, tags) VALUES (?, ?, ?, ?, ?);',
        <Object?>[nid, 'guid-$nid', _defaultModelId, flds, ''],
      );
      db.execute(
        'INSERT INTO cards (id, nid, did, ord, queue, type, due, ivl, reps, '
        'lapses, factor) VALUES (?, ?, 1, 0, ?, ?, 0, ?, ?, 0, ?);',
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

// --- Rich fixtures for lossless-source tests (MVP_009) ----------------------

/// A source note with explicit model id, named field values, and Anki tags.
class _SrcNote {
  const _SrcNote({
    required this.id,
    required this.mid,
    required this.flds,
    this.tags = '',
  });
  final int id;
  final String mid;
  final List<String> flds;
  final String tags;
}

/// A source card with its note id and card-template ordinal (new + due now).
class _SrcCard {
  const _SrcCard({required this.id, required this.nid, required this.ord});
  final int id;
  final int nid;
  final int ord;
}

/// Captures the [ImportedAnkiSource] handed to the import adapter, so source
/// preservation can be asserted without touching disk.
class _CapturingSourceStore implements ImportedSourceStore {
  ImportedAnkiSource? saved;
  @override
  Future<void> saveSource(ImportedAnkiSource source) async => saved = source;
  @override
  Future<ImportedAnkiSource?> getSourceForDeck(String deckId) async =>
      saved?.deckId == deckId ? saved : null;
  @override
  Future<void> deleteSourceForDeck(String deckId) async {
    if (saved?.deckId == deckId) saved = null;
  }
}

/// Builds a `col.models` blob with one model: [fields] in order + [templates]
/// in order (each with empty q/a format — text is irrelevant to these tests).
String _modelJson(
  String id,
  String name,
  List<String> fields,
  List<String> templates,
) {
  return jsonEncode(<String, dynamic>{
    id: <String, dynamic>{
      'name': name,
      'flds': <Map<String, Object>>[
        for (int i = 0; i < fields.length; i++)
          <String, Object>{'name': fields[i], 'ord': i},
      ],
      'tmpls': <Map<String, Object>>[
        for (int i = 0; i < templates.length; i++)
          <String, Object>{
            'name': templates[i],
            'ord': i,
            'qfmt': '',
            'afmt': '',
          },
      ],
    },
  });
}

/// Encodes a minimal Anki `MediaEntries` protobuf (just `name` per entry) so
/// modern-package fixtures can be built without a protobuf dependency.
Uint8List _encodeMediaEntries(List<String> names) {
  void writeVarint(BytesBuilder b, int v) {
    while (v >= 0x80) {
      b.addByte((v & 0x7f) | 0x80);
      v >>= 7;
    }
    b.addByte(v);
  }

  final BytesBuilder out = BytesBuilder();
  for (final String name in names) {
    final List<int> nameBytes = utf8.encode(name);
    final BytesBuilder entry = BytesBuilder()..addByte(0x0A); // field 1, len
    writeVarint(entry, nameBytes.length);
    entry.add(nameBytes);
    final Uint8List entryBytes = entry.toBytes();
    out.addByte(0x0A); // MediaEntries field 1 (entries), len
    writeVarint(out, entryBytes.length);
    out.add(entryBytes);
  }
  return out.toBytes();
}

/// Builds a `.apkg` with full control over the model, notes (named fields +
/// tags + model id), and cards (note id + template ordinal) — for source tests.
/// When [modern] is true, the collection is named `collection.anki21b` and the
/// media manifest is a `MediaEntries` protobuf (payloads left raw, so an
/// identity zstd decoder round-trips them).
Uint8List _buildSourceApkg({
  required String deckName,
  required String modelsJson,
  required List<_SrcNote> notes,
  required List<_SrcCard> cards,
  Map<String, List<int>> media = const <String, List<int>>{},
  bool modern = false,
  bool includeMediaManifest = true,
}) {
  final Directory tmp = Directory.systemTemp.createTempSync('decko_src_fixture');
  final String path = '${tmp.path}/collection.anki21';
  final Database db = sqlite3.open(path);
  try {
    db.execute('CREATE TABLE col (id INTEGER PRIMARY KEY, crt INTEGER, '
        'decks TEXT, models TEXT);');
    db.execute('CREATE TABLE notes (id INTEGER PRIMARY KEY, guid TEXT, '
        'mid INTEGER, flds TEXT, tags TEXT);');
    db.execute('CREATE TABLE cards (id INTEGER PRIMARY KEY, nid INTEGER, '
        'did INTEGER, ord INTEGER, queue INTEGER, type INTEGER, due INTEGER, '
        'ivl INTEGER, reps INTEGER, lapses INTEGER, factor INTEGER);');

    db.execute(
      'INSERT INTO col (id, crt, decks, models) VALUES (1, 1600000000, ?, ?);',
      <Object?>['{"1":{"name":"$deckName"}}', modelsJson],
    );
    for (final _SrcNote n in notes) {
      db.execute(
        'INSERT INTO notes (id, guid, mid, flds, tags) VALUES (?, ?, ?, ?, ?);',
        <Object?>[n.id, 'guid-${n.id}', n.mid, n.flds.join(_fs), n.tags],
      );
    }
    for (final _SrcCard c in cards) {
      db.execute(
        'INSERT INTO cards (id, nid, did, ord, queue, type, due, ivl, reps, '
        'lapses, factor) VALUES (?, ?, 1, ?, 0, 0, 0, 0, 0, 0, 0);',
        <Object?>[c.id, c.nid, c.ord],
      );
    }
  } finally {
    db.close();
  }

  final Uint8List dbBytes = File(path).readAsBytesSync();
  tmp.deleteSync(recursive: true);

  final String collectionName =
      modern ? 'collection.anki21b' : 'collection.anki21';
  final Map<String, String> mediaMap = <String, String>{};
  final List<String> orderedNames = <String>[];
  final Archive archive = Archive()
    ..addFile(ArchiveFile(collectionName, dbBytes.length, dbBytes));
  int n = 0;
  media.forEach((String name, List<int> bytes) {
    archive.addFile(ArchiveFile('$n', bytes.length, bytes));
    mediaMap['$n'] = name;
    orderedNames.add(name);
    n++;
  });
  if (includeMediaManifest) {
    final List<int> manifest = modern
        ? _encodeMediaEntries(orderedNames)
        : jsonEncode(mediaMap).codeUnits;
    archive.addFile(ArchiveFile('media', manifest.length, manifest));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
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

  group('lossless source preservation (MVP_009)', () {
    test('preserves named fields by name + ordinal, with raw values, tags, '
        'and per-field media refs', () async {
      final Uint8List bytes = _buildSourceApkg(
        deckName: 'Core 2k',
        modelsJson: _modelJson('m1', 'Japanese Vocab', <String>[
          'Reading', 'Audio', 'Sentence', 'Sentence-Kana',
          'Sentence-English', 'Sentence Audio', 'Image_URI', 'Tags',
        ], <String>['Card 1']),
        notes: const <_SrcNote>[
          _SrcNote(id: 100, mid: 'm1', tags: 'n5 vocab', flds: <String>[
            '会社[かいしゃ]',
            '[sound:word.mp3]',
            '会社はどこ？',
            'かいしゃはどこ？',
            'Where is the company?',
            '[sound:sent.mp3]',
            '<img src="office.jpg">',
            'business formal',
          ]),
        ],
        cards: const <_SrcCard>[_SrcCard(id: 200, nid: 100, ord: 0)],
      );

      final _CapturingSourceStore store = _CapturingSourceStore();
      await adapter.importDeck(bytes,
          keepProgress: false,
          importedAt: DateTime(2026, 6, 12),
          sourceStore: store);

      final ImportedAnkiSource src = store.saved!;
      final ImportedAnkiNote note = src.notes.single;

      // Every field preserved by name, in ordinal order — none dropped.
      expect(note.fields.map((ImportedAnkiField f) => f.name).toList(),
          <String>[
            'Reading', 'Audio', 'Sentence', 'Sentence-Kana',
            'Sentence-English', 'Sentence Audio', 'Image_URI', 'Tags',
          ]);
      expect(note.fields.map((ImportedAnkiField f) => f.ordinal).toList(),
          <int>[0, 1, 2, 3, 4, 5, 6, 7]);

      // Raw values kept verbatim (may carry markup Decko doesn't understand).
      expect(note.fieldByName('Reading')!.rawValue, '会社[かいしゃ]');
      expect(note.fieldByName('Image_URI')!.rawValue, '<img src="office.jpg">');
      // Plain-text value available where useful.
      expect(note.fieldByName('Sentence-Kana')!.plainTextValue,
          contains('かいしゃ'));

      // Note-level tags preserved.
      expect(note.tags, <String>['n5', 'vocab']);

      // Per-field media references detected for audio and image fields.
      final MediaReference wordAudio =
          note.fieldByName('Audio')!.mediaReferences.single;
      expect(wordAudio.kind, MediaKind.audio);
      expect(wordAudio.fileName, 'word.mp3');
      expect(note.fieldByName('Sentence Audio')!.mediaReferences.single.kind,
          MediaKind.audio);
      final MediaReference image =
          note.fieldByName('Image_URI')!.mediaReferences.single;
      expect(image.kind, MediaKind.image);
      expect(image.fileName, 'office.jpg');
    });

    test('preserves model identity + Listening/Reading/Production templates, '
        'and links each card to its template', () async {
      final Uint8List bytes = _buildSourceApkg(
        deckName: 'JP 3-card',
        modelsJson: _modelJson('m2', 'Japanese (3 cards)',
            <String>['Expression', 'Meaning'],
            <String>['Listening', 'Reading', 'Production']),
        notes: const <_SrcNote>[
          _SrcNote(id: 100, mid: 'm2', flds: <String>['食べる', 'to eat']),
        ],
        cards: const <_SrcCard>[
          _SrcCard(id: 200, nid: 100, ord: 0),
          _SrcCard(id: 201, nid: 100, ord: 1),
          _SrcCard(id: 202, nid: 100, ord: 2),
        ],
      );

      final _CapturingSourceStore store = _CapturingSourceStore();
      final Deck deck = await adapter.importDeck(bytes,
          keepProgress: false,
          importedAt: DateTime(2026, 6, 12),
          sourceStore: store);

      final ImportedAnkiSource src = store.saved!;
      final ImportedAnkiModel model = src.models.single;
      expect(model.name, 'Japanese (3 cards)');
      expect(model.fieldNames, <String>['Expression', 'Meaning']);
      expect(model.templates.map((ImportedAnkiCardTemplate t) => t.name).toList(),
          <String>['Listening', 'Reading', 'Production']);
      expect(model.templateByOrdinal(2)!.name, 'Production');

      // The three generated cards keep their template identity — not collapsed.
      expect(src.cardSources, hasLength(3));
      expect(
        src.cardSources
            .map((ImportedAnkiCardSource c) => c.templateName)
            .toSet(),
        <String>{'Listening', 'Reading', 'Production'},
      );
      // Review still opens: the deck produced usable Decko cards.
      expect(deck.items, isNotEmpty);
    });
  });

  group('note-type-aware card mapping (MVP_010)', () {
    test('a 3-template note produces 3 distinct, mode-tagged Decko cards',
        () async {
      final Uint8List bytes = _buildSourceApkg(
        deckName: 'JP 3-card',
        modelsJson: _modelJson('m', 'JP', <String>[
          'Expression', 'Meaning', 'Audio', 'Sentence', 'Sentence Audio',
          'Image',
        ], <String>['Listening', 'Reading', 'Production']),
        notes: const <_SrcNote>[
          _SrcNote(id: 100, mid: 'm', flds: <String>[
            '会社[かいしゃ]',
            'company',
            '[sound:word.mp3]',
            '会社へ行く',
            '[sound:sent.mp3]',
            '<img src="office.jpg">',
          ]),
        ],
        cards: const <_SrcCard>[
          _SrcCard(id: 200, nid: 100, ord: 0),
          _SrcCard(id: 201, nid: 100, ord: 1),
          _SrcCard(id: 202, nid: 100, ord: 2),
        ],
      );

      final Deck deck = await adapter.importDeck(bytes,
          keepProgress: false, importedAt: DateTime(2026, 6, 20));

      expect(deck.items, hasLength(3));
      // Stable ids = imported progress / FSRS safety.
      expect(deck.items.map((i) => i.id).toList(),
          <String>['anki-card-200', 'anki-card-201', 'anki-card-202']);
      // Three distinct study modes, not lookalikes.
      expect(
        deck.items.map((i) => i.mode).toSet(),
        <ReviewCardMode>{
          ReviewCardMode.listening,
          ReviewCardMode.reading,
          ReviewCardMode.production,
        },
      );
      final listening =
          deck.items.firstWhere((i) => i.mode == ReviewCardMode.listening);
      final production =
          deck.items.firstWhere((i) => i.mode == ReviewCardMode.production);
      expect(listening.front, contains('[sound:word.mp3]'));
      expect(listening.front, isNot(contains('会社'))); // audio-first
      expect(production.front, contains('company'));
      expect(production.front, isNot(contains('会社'))); // Japanese hidden
    });

    test('a simple positional deck stays generic (fallback unchanged)',
        () async {
      final Deck deck = await adapter.importDeck(mixedDeck(),
          keepProgress: false, importedAt: DateTime(2026, 6, 20));
      expect(deck.items.every((i) => i.mode == ReviewCardMode.generic), isTrue);
      expect(deck.items.first.front, '食べる'); // positional content preserved
    });
  });

  group('import compatibility hardening (MVP_013)', () {
    final DateTime when = DateTime(2026, 6, 21);

    Uint8List basicDeck({bool modern = false, bool manifest = true}) =>
        _buildSourceApkg(
          deckName: 'Basic Deck',
          modern: modern,
          includeMediaManifest: manifest,
          modelsJson:
              _modelJson('m', 'Basic', <String>['Front', 'Back'], <String>['Card 1']),
          notes: const <_SrcNote>[
            _SrcNote(id: 100, mid: 'm', flds: <String>['hello', 'world']),
          ],
          cards: const <_SrcCard>[_SrcCard(id: 200, nid: 100, ord: 0)],
        );

    test('legacy package reports legacy format + counts in diagnostics',
        () async {
      final DeckImportPreview p = await adapter.preview(mixedDeck());
      expect(p.diagnostics, isNotNull);
      expect(p.diagnostics!.format, AnkiPackageFormat.legacy21);
      expect(p.diagnostics!.collectionFile, 'collection.anki21');
      expect(p.diagnostics!.cards, 3);
      expect(p.diagnostics!.isBlocked, isFalse);
    });

    test('modern .anki21b collection imports and reports its format', () async {
      final Uint8List bytes = basicDeck(modern: true);
      final AnkiApkgImportAdapter modernAdapter =
          AnkiApkgImportAdapter(zstd: _IdentityZstd());

      final DeckImportPreview p = await modernAdapter.preview(bytes);
      expect(p.diagnostics!.format, AnkiPackageFormat.modern21b);
      expect(p.diagnostics!.collectionFile, 'collection.anki21b');
      expect(p.totalCards, 1);

      final Deck deck = await modernAdapter.importDeck(bytes,
          keepProgress: false, importedAt: when);
      expect(deck.items, hasLength(1));
      expect(deck.items.first.id, 'anki-card-200'); // stable identity
    });

    test('modern media manifest (protobuf) + payloads extract via the decoder',
        () async {
      final Uint8List bytes = _buildSourceApkg(
        deckName: 'Modern Media',
        modern: true,
        modelsJson:
            _modelJson('m', 'Basic', <String>['Front', 'Back'], <String>['Card 1']),
        notes: const <_SrcNote>[
          _SrcNote(id: 100, mid: 'm', flds: <String>['[sound:a.mp3]', 'b']),
        ],
        cards: const <_SrcCard>[_SrcCard(id: 200, nid: 100, ord: 0)],
        media: const <String, List<int>>{'a.mp3': <int>[1, 2, 3]},
      );
      final _FakeMediaStore store = _FakeMediaStore();
      final AnkiApkgImportAdapter modernAdapter =
          AnkiApkgImportAdapter(zstd: _IdentityZstd());

      final Deck deck = await modernAdapter.importDeck(bytes,
          keepProgress: false, importedAt: when, mediaStore: store);
      expect(store.saved.keys, contains('${deck.id}/a.mp3'));
    });

    test('a modern package that cannot be decompressed fails clearly, no crash',
        () async {
      final Uint8List bytes = basicDeck(modern: true);
      final AnkiApkgImportAdapter failing =
          AnkiApkgImportAdapter(zstd: _FailingZstd());
      await expectLater(
        failing.preview(bytes),
        throwsA(isA<UnsupportedPackageException>()),
      );
    });

    test('a package with no collection database fails with a clear message',
        () async {
      final Archive archive = Archive()
        ..addFile(ArchiveFile('media', 2, utf8.encode('{}')));
      final Uint8List bytes = Uint8List.fromList(ZipEncoder().encode(archive));
      await expectLater(
        adapter.preview(bytes),
        throwsA(predicate((Object? e) =>
            e is DeckImportException &&
            e.message.contains('No Anki collection'))),
      );
    });

    test('a collection missing Anki tables fails with a clear, non-SQLite message',
        () async {
      final Directory tmp = Directory.systemTemp.createTempSync('decko_bad');
      final String path = '${tmp.path}/c.sqlite';
      final Database db = sqlite3.open(path);
      db.execute('CREATE TABLE unrelated (id INTEGER);');
      db.close();
      final Uint8List dbBytes = File(path).readAsBytesSync();
      tmp.deleteSync(recursive: true);
      final Archive archive = Archive()
        ..addFile(ArchiveFile('collection.anki21', dbBytes.length, dbBytes));
      final Uint8List bytes = Uint8List.fromList(ZipEncoder().encode(archive));

      await expectLater(
        adapter.preview(bytes),
        throwsA(predicate((Object? e) =>
            e is DeckImportException &&
            e.message.contains('expected Anki tables') &&
            !e.message.toLowerCase().contains('sqlite'))),
      );
    });

    test('media referenced without a manifest still imports, with a warning',
        () async {
      final Uint8List bytes = _buildSourceApkg(
        deckName: 'No Manifest',
        includeMediaManifest: false,
        modelsJson:
            _modelJson('m', 'Basic', <String>['Front', 'Back'], <String>['Card 1']),
        notes: const <_SrcNote>[
          _SrcNote(id: 100, mid: 'm', flds: <String>['[sound:x.mp3]', 'b']),
        ],
        cards: const <_SrcCard>[_SrcCard(id: 200, nid: 100, ord: 0)],
      );
      final DeckImportPreview p = await adapter.preview(bytes);
      expect(p.diagnostics!.hasMediaManifest, isFalse);
      expect(
          p.diagnostics!.warnings.any((String w) => w.contains('media may not play or show')),
          isTrue);
      // Still studyable.
      final Deck deck = await adapter.importDeck(bytes,
          keepProgress: false, importedAt: when);
      expect(deck.items, hasLength(1));
    });

    test('a note type with unfamiliar field names still imports (generic)',
        () async {
      final Uint8List bytes = _buildSourceApkg(
        deckName: 'Weird',
        modelsJson: _modelJson('m', 'Weird',
            <String>['Blorp', 'Zxcv', 'Qwerty'], <String>['Card 1']),
        notes: const <_SrcNote>[
          _SrcNote(id: 100, mid: 'm', flds: <String>['a', 'b', 'c']),
        ],
        cards: const <_SrcCard>[_SrcCard(id: 200, nid: 100, ord: 0)],
      );
      final Deck deck = await adapter.importDeck(bytes,
          keepProgress: false, importedAt: when);
      expect(deck.items, hasLength(1));
    });

    test('garbage bytes still fail as a handled DeckImportException', () async {
      await expectLater(
        adapter.preview(Uint8List.fromList(<int>[9, 9, 9, 9, 9])),
        throwsA(isA<DeckImportException>()),
      );
    });
  });
}
