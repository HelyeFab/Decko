import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../core/content/anki_content.dart';
import '../../domain/deck.dart';
import '../../domain/import/deck_import_adapter.dart';
import '../../domain/import/deck_import_info.dart';
import '../../domain/import/deck_import_preview.dart';
import '../../domain/import/imported_card_progress.dart';
import '../../domain/import/imported_card_state.dart';
import '../../domain/import/note_type_aware_card_mapper.dart';
import '../../domain/import/source/imported_anki_source.dart';
import '../../domain/learning_item.dart';
import '../../domain/repositories/imported_source_store.dart';
import '../../domain/repositories/media_store.dart';
import '../../domain/review_card_mode.dart';

/// Imports a (legacy, uncompressed) Anki `.apkg` package.
///
/// A `.apkg` is a zip containing an SQLite collection (`collection.anki2` /
/// `collection.anki21`). This MVP targets that uncompressed format; the modern
/// zstd-compressed `collection.anki21b` is detected and rejected with a clear
/// message (DEC-010). All parsing lives here, never in widgets, and every
/// failure surfaces as a [DeckImportException] so the UI can stay friendly.
class AnkiApkgImportAdapter implements DeckImportAdapter {
  const AnkiApkgImportAdapter();

  static const NoteTypeAwareCardMapper _mapper = NoteTypeAwareCardMapper();

  @override
  Future<DeckImportPreview> preview(Uint8List bytes) async {
    final _Parsed parsed = _parse(bytes);
    return DeckImportPreview(
      deckName: parsed.deckName,
      totalCards: parsed.cards.length,
      newCards: parsed.cards.where((c) => c.isNew).length,
      reviewedCards: parsed.cards.where((c) => c.isReviewed).length,
      suspendedCards:
          parsed.cards.where((c) => c.state == ImportedCardState.suspended).length,
      hasProgressData: parsed.hasProgressData,
      approxDueToday: parsed.approxDueToday,
      notes: parsed.notes,
      mediaFiles: parsed.mediaMap.length,
      audioRefs: parsed.audioRefs,
      imageRefs: parsed.imageRefs,
    );
  }

  @override
  Future<Deck> importDeck(
    Uint8List bytes, {
    required bool keepProgress,
    required DateTime importedAt,
    MediaStore? mediaStore,
    ImportedSourceStore? sourceStore,
  }) async {
    final _Parsed parsed = _parse(bytes);
    final bool keep = keepProgress && parsed.hasProgressData;
    final ImportProgressMode mode = !parsed.hasProgressData
        ? ImportProgressMode.unavailable
        : keep
            ? ImportProgressMode.kept
            : ImportProgressMode.fresh;

    final String deckId = 'anki-${importedAt.millisecondsSinceEpoch}';

    // Build the lossless source, then derive each Decko card from it — note-type
    // aware where the template/fields allow, positional otherwise (DEC-019).
    final ImportedAnkiSource source = _sourceFor(parsed, deckId);
    final Map<String, ImportedAnkiCardSource> cardSourceById =
        <String, ImportedAnkiCardSource>{
      for (final ImportedAnkiCardSource cs in source.cardSources)
        cs.sourceCardId: cs,
    };

    final List<LearningItem> items = <LearningItem>[
      for (final _Card c in parsed.cards)
        _itemFor(c, source, cardSourceById['${c.cardId}'], keep),
    ];

    if (mediaStore != null && parsed.mediaMap.isNotEmpty) {
      await _extractMedia(parsed, deckId, mediaStore);
    }
    // Preserve the lossless Anki source alongside the deck (DEC-016).
    if (sourceStore != null) {
      await sourceStore.saveSource(source);
    }

    return Deck(
      id: deckId,
      name: parsed.deckName,
      description: 'Imported from Anki · ${items.length} cards',
      items: items,
      importInfo: DeckImportInfo(progressMode: mode, importedAt: importedAt),
    );
  }

  /// Builds the Decko [LearningItem] for one Anki card.
  ///
  /// Keeps the id stable (`anki-card-<cardId>`) and the imported progress from
  /// the card row, so review state / FSRS are never reset — only the content
  /// arrangement changes. Uses the note-type-aware mapper when it recognises the
  /// source; otherwise keeps the positional mapping (simple/demo decks).
  LearningItem _itemFor(
    _Card c,
    ImportedAnkiSource source,
    ImportedAnkiCardSource? cardSource,
    bool keep,
  ) {
    String front = c.front;
    String back = c.back;
    String? reading = c.reading;
    String? example = c.example;
    ReviewCardMode mode = ReviewCardMode.generic;

    if (cardSource != null) {
      final CardMapping m =
          _mapper.map(source: source, cardSource: cardSource);
      if (m.recognized) {
        front = m.front;
        back = m.back;
        reading = m.reading;
        example = m.example;
        mode = m.mode;
      }
    }

    return LearningItem(
      id: 'anki-card-${c.cardId}',
      front: front,
      back: back,
      reading: reading,
      example: example,
      mode: mode,
      importedProgress: keep
          ? ImportedCardProgress(
              state: c.state,
              sourceCardId: '${c.cardId}',
              sourceNoteId: '${c.noteId}',
              dueAt: c.dueAt,
              intervalDays: c.intervalDays,
              reps: c.reps,
              lapses: c.lapses,
              easeFactor: c.easeFactor,
            )
          : null,
    );
  }

  /// Copies each package media payload to the [MediaStore] under its original
  /// filename, one at a time so large decks don't balloon memory.
  Future<void> _extractMedia(
      _Parsed parsed, String deckId, MediaStore store) async {
    for (final MapEntry<String, String> e in parsed.mediaMap.entries) {
      final ArchiveFile? file = parsed.archive.findFile(e.key);
      if (file == null) continue;
      try {
        await store.saveMedia(
            deckId, e.value, Uint8List.fromList(file.content as List<int>));
      } catch (_) {/* skip a single bad media file rather than fail import */}
    }
  }

  // --- parsing ---------------------------------------------------------------

  _Parsed _parse(Uint8List bytes) {
    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const DeckImportException(
        'This file isn’t a valid .apkg package.',
      );
    }

    final ArchiveFile? db = _findCollection(archive);
    if (db == null) {
      if (archive.findFile('collection.anki21b') != null) {
        throw const UnsupportedPackageException(
          'This deck uses Anki’s newer format. In Anki, export it with '
          '“Support older Anki versions” enabled, then try again.',
        );
      }
      throw const DeckImportException(
        'Decko couldn’t find an Anki collection inside this package.',
      );
    }

    final Directory tmp = Directory.systemTemp.createTempSync('decko_apkg');
    final File dbFile = File('${tmp.path}/collection.sqlite');
    Database? handle;
    try {
      dbFile.writeAsBytesSync(db.content as List<int>);
      handle = sqlite3.open(dbFile.path);
      return _readCollection(handle, archive);
    } on DeckImportException {
      rethrow;
    } catch (_) {
      throw const DeckImportException(
        'Decko couldn’t read this deck. It may be corrupted or use an '
        'unsupported Anki format.',
      );
    } finally {
      handle?.close();
      try {
        tmp.deleteSync(recursive: true);
      } catch (_) {/* best effort */}
    }
  }

  ArchiveFile? _findCollection(Archive archive) =>
      archive.findFile('collection.anki21') ??
      archive.findFile('collection.anki2');

  _Parsed _readCollection(Database db, Archive archive) {
    final ResultSet col = db.select('SELECT crt, decks, models FROM col LIMIT 1');
    final int crt = col.isEmpty ? 0 : (col.first['crt'] as int? ?? 0);
    final Map<String, String> deckNames = _deckNames(db, col);
    final Map<String, ImportedAnkiModel> models = _parseModels(col);

    // note id -> fields; also build the lossless source notes.
    final String fieldSeparator = String.fromCharCode(0x1f);
    final Map<int, List<String>> fields = <int, List<String>>{};
    final Map<int, String> noteModelId = <int, String>{};
    final List<ImportedAnkiNote> sourceNotes = <ImportedAnkiNote>[];
    int audioRefs = 0;
    int imageRefs = 0;
    for (final Row r in db.select('SELECT id, guid, mid, flds, tags FROM notes')) {
      final int id = r['id'] as int;
      final String flds = r['flds'] as String;
      final List<String> values = flds.split(fieldSeparator);
      fields[id] = values;
      final String mid = '${r['mid']}';
      noteModelId[id] = mid;
      audioRefs += countAudioRefs(flds);
      imageRefs += countImageRefs(flds);
      sourceNotes.add(
          _sourceNote(id, r['guid'] as String?, mid, r['tags'] as String?,
              values, models[mid]));
    }

    final List<_Card> cards = <_Card>[];
    final List<ImportedAnkiCardSource> cardSources = <ImportedAnkiCardSource>[];
    final Set<int> deckIds = <int>{};
    for (final Row r in db.select(
      'SELECT id, nid, did, ord, queue, type, due, ivl, reps, lapses, factor '
      'FROM cards',
    )) {
      final int nid = r['nid'] as int;
      final List<String> f = fields[nid] ?? const <String>[];
      deckIds.add(r['did'] as int);
      final _Card card = _Card.fromRow(r, f, crt);
      cards.add(card);

      final int ord = r['ord'] as int? ?? 0;
      final ImportedAnkiModel? model = models[noteModelId[nid]];
      cardSources.add(ImportedAnkiCardSource(
        sourceCardId: '${r['id']}',
        sourceNoteId: '$nid',
        sourceDeckId: '',
        templateOrdinal: ord,
        templateName: model?.templateByOrdinal(ord)?.name,
        queueState: card.state.name,
        due: r['due'] as int? ?? 0,
        reps: card.reps,
        lapses: card.lapses,
      ));
    }

    if (cards.isEmpty) {
      throw const DeckImportException(
        'This deck doesn’t contain any importable cards.',
      );
    }

    final String deckName = _primaryDeckName(cards, deckNames);
    final List<String> notes = <String>[];
    if (deckIds.length > 1) {
      notes.add('Multiple Anki decks were combined into one Decko deck.');
    }

    final bool hasProgress = cards.any((c) => c.isReviewed || c.reps > 0 ||
        c.state == ImportedCardState.suspended);
    final int? approxDue = hasProgress
        ? cards.where((c) => c.isDueToday).length
        : null;

    return _Parsed(
      deckName: deckName,
      cards: cards,
      hasProgressData: hasProgress,
      approxDueToday: approxDue,
      notes: notes,
      archive: archive,
      mediaMap: _readMediaMap(archive),
      audioRefs: audioRefs,
      imageRefs: imageRefs,
      models: models.values.toList(),
      sourceNotes: sourceNotes,
      cardSources: cardSources,
    );
  }

  /// Builds a lossless [ImportedAnkiNote] from a note's raw field values,
  /// naming each field via the model's ordinal-ordered field names.
  ImportedAnkiNote _sourceNote(int id, String? guid, String mid, String? tags,
      List<String> values, ImportedAnkiModel? model) {
    final List<String> names = model?.fieldNames ?? const <String>[];
    final List<ImportedAnkiField> srcFields = <ImportedAnkiField>[
      for (int i = 0; i < values.length; i++)
        ImportedAnkiField(
          name: i < names.length ? names[i] : 'Field ${i + 1}',
          ordinal: i,
          rawValue: values[i],
          plainTextValue: stripMedia(_cleanField(values[i])),
          mediaReferences: _mediaRefs(values[i]),
        ),
    ];
    return ImportedAnkiNote(
      sourceNoteId: '$id',
      sourceGuid: guid ?? '',
      sourceModelId: mid,
      modelName: model?.name ?? 'Unknown',
      deckId: '',
      fields: srcFields,
      tags: (tags ?? '').trim().split(RegExp(r'\s+'))
          .where((String t) => t.isNotEmpty)
          .toList(),
    );
  }

  /// Parses `col.models` (legacy schema) into models with fields + templates.
  Map<String, ImportedAnkiModel> _parseModels(ResultSet col) {
    final String json =
        col.isEmpty ? '{}' : (col.first['models'] as String? ?? '{}');
    final Map<String, ImportedAnkiModel> out = <String, ImportedAnkiModel>{};
    try {
      final Map<String, dynamic> decoded =
          jsonDecode(json) as Map<String, dynamic>;
      decoded.forEach((String id, dynamic v) {
        if (v is! Map) return;
        final List<dynamic> flds = (v['flds'] as List<dynamic>?) ?? <dynamic>[];
        final List<dynamic> tmpls =
            (v['tmpls'] as List<dynamic>?) ?? <dynamic>[];
        out[id] = ImportedAnkiModel(
          id: id,
          name: v['name'] as String? ?? 'Note type',
          fieldNames: flds
              .map((dynamic f) => (f as Map)['name'] as String? ?? '')
              .toList(),
          templates: <ImportedAnkiCardTemplate>[
            for (final dynamic t in tmpls)
              if (t is Map)
                ImportedAnkiCardTemplate(
                  sourceModelId: id,
                  ordinal: (t['ord'] as int?) ?? 0,
                  name: t['name'] as String? ?? 'Card',
                  questionTemplate: t['qfmt'] as String? ?? '',
                  answerTemplate: t['afmt'] as String? ?? '',
                ),
          ],
        );
      });
    } catch (_) {/* leave empty */}
    return out;
  }

  List<MediaReference> _mediaRefs(String raw) => <MediaReference>[
        for (final AnkiSegment seg in parseAnkiContent(raw))
          if (seg is AudioSegment)
            MediaReference(fileName: seg.fileName, kind: MediaKind.audio)
          else if (seg is ImageSegment)
            MediaReference(fileName: seg.fileName, kind: MediaKind.image),
      ];

  /// The lossless source for a freshly imported deck.
  ImportedAnkiSource _sourceFor(_Parsed parsed, String deckId) =>
      ImportedAnkiSource(
        deckId: deckId,
        models: parsed.models,
        notes: parsed.sourceNotes,
        cardSources: parsed.cardSources,
      );

  /// Reads the package's `media` mapping (numbered payload -> original name).
  Map<String, String> _readMediaMap(Archive archive) {
    final ArchiveFile? f = archive.findFile('media');
    if (f == null) return const <String, String>{};
    try {
      final Map<String, dynamic> decoded =
          jsonDecode(utf8.decode(f.content as List<int>))
              as Map<String, dynamic>;
      return decoded.map(
          (String k, dynamic v) => MapEntry<String, String>(k, v as String));
    } catch (_) {
      return const <String, String>{};
    }
  }

  Map<String, String> _deckNames(Database db, ResultSet col) {
    // Legacy schema stores decks as JSON in col.decks.
    final String json = col.isEmpty ? '{}' : (col.first['decks'] as String? ?? '{}');
    final Map<String, String> out = <String, String>{};
    try {
      final Map<String, dynamic> decoded =
          jsonDecode(json) as Map<String, dynamic>;
      decoded.forEach((String id, dynamic v) {
        if (v is Map && v['name'] is String) out[id] = v['name'] as String;
      });
    } catch (_) {/* fall through to table */}

    if (out.isEmpty) {
      // Newer schema keeps decks in their own table.
      try {
        for (final Row r in db.select('SELECT id, name FROM decks')) {
          out['${r['id']}'] = r['name'] as String;
        }
      } catch (_) {/* leave empty */}
    }
    return out;
  }

  String _primaryDeckName(List<_Card> cards, Map<String, String> names) {
    final Map<int, int> counts = <int, int>{};
    for (final _Card c in cards) {
      counts[c.deckId] = (counts[c.deckId] ?? 0) + 1;
    }
    int? best;
    int bestCount = -1;
    counts.forEach((int did, int n) {
      if (n > bestCount) {
        best = did;
        bestCount = n;
      }
    });
    final String? name = names['$best'];
    if (name == null || name.trim().isEmpty || name == 'Default') {
      return 'Imported deck';
    }
    // Anki nests subdecks with "::"; show the leaf name.
    return name.split('::').last;
  }
}

class _Parsed {
  _Parsed({
    required this.deckName,
    required this.cards,
    required this.hasProgressData,
    required this.approxDueToday,
    required this.notes,
    required this.archive,
    required this.mediaMap,
    required this.audioRefs,
    required this.imageRefs,
    required this.models,
    required this.sourceNotes,
    required this.cardSources,
  });

  final String deckName;
  final List<_Card> cards;
  final bool hasProgressData;
  final int? approxDueToday;
  final List<String> notes;
  final Archive archive;
  final Map<String, String> mediaMap;
  final int audioRefs;
  final int imageRefs;
  final List<ImportedAnkiModel> models;
  final List<ImportedAnkiNote> sourceNotes;
  final List<ImportedAnkiCardSource> cardSources;
}

class _Card {
  _Card({
    required this.cardId,
    required this.noteId,
    required this.deckId,
    required this.state,
    required this.reps,
    required this.lapses,
    required this.front,
    required this.back,
    required this.reading,
    required this.example,
    required this.intervalDays,
    required this.easeFactor,
    required this.dueAt,
    required this.isDueToday,
  });

  factory _Card.fromRow(Row r, List<String> fields, int crt) {
    final int type = r['type'] as int? ?? 0;
    final int queue = r['queue'] as int? ?? 0;
    final int ivl = r['ivl'] as int? ?? 0;
    final int factor = r['factor'] as int? ?? 0;
    final int due = r['due'] as int? ?? 0;

    final ImportedCardState state = _stateFor(type: type, queue: queue);
    final _Fields mapped = _mapFields(fields);

    // Review cards: `due` is days since collection creation.
    DateTime? dueAt;
    bool dueToday = false;
    if (type >= 2 && crt > 0) {
      dueAt = DateTime.fromMillisecondsSinceEpoch(crt * 1000)
          .add(Duration(days: due));
      final DateTime now = DateTime.now();
      dueToday = !dueAt.isAfter(DateTime(now.year, now.month, now.day)
          .add(const Duration(days: 1)));
    }

    return _Card(
      cardId: r['id'] as int,
      noteId: r['nid'] as int,
      deckId: r['did'] as int,
      state: state,
      reps: r['reps'] as int? ?? 0,
      lapses: r['lapses'] as int? ?? 0,
      front: mapped.front,
      back: mapped.back,
      reading: mapped.reading,
      example: mapped.example,
      intervalDays: ivl > 0 ? ivl : null,
      easeFactor: factor > 0 ? factor / 1000 : null,
      dueAt: dueAt,
      isDueToday: dueToday,
    );
  }

  final int cardId;
  final int noteId;
  final int deckId;
  final ImportedCardState state;
  final int reps;
  final int lapses;
  final String front;
  final String back;
  final String? reading;
  final String? example;
  final int? intervalDays;
  final double? easeFactor;
  final DateTime? dueAt;
  final bool isDueToday;

  bool get isNew => state == ImportedCardState.isNew;
  bool get isReviewed =>
      state == ImportedCardState.review ||
      state == ImportedCardState.relearning ||
      reps > 0;

  static ImportedCardState _stateFor({required int type, required int queue}) {
    if (queue == -1) return ImportedCardState.suspended;
    return switch (type) {
      1 => ImportedCardState.learning,
      2 => ImportedCardState.review,
      3 => ImportedCardState.relearning,
      _ => ImportedCardState.isNew,
    };
  }
}

/// The Decko-facing pieces extracted from a note's raw fields.
class _Fields {
  const _Fields({
    required this.front,
    required this.back,
    this.reading,
    this.example,
  });

  final String front;
  final String back;
  final String? reading;
  final String? example;
}

/// Maps an Anki note's raw fields to Decko fields.
///
/// Real Japanese note types carry furigana (`<ruby>漢字<rt>かな</rt></ruby>`) and
/// often pack the back as `meaning<br>sentence<br>translation<br>[sound:…]<br>id`.
/// So this:
///  - converts furigana to bracket notation `漢字[かな]` and keeps it, so the app
///    can render ruby (with a toggle) instead of mashing kanji + reading;
///  - splits the back into lines, dropping audio refs, id-like tokens, and a
///    line that just repeats the front; first line = answer, rest = example;
///  - falls back to content heuristics (kana field → reading, sentence field →
///    example) for note types that split those out.
/// Still an isolated, heuristic layer flagged for improvement (DEC-010).
_Fields _mapFields(List<String> raw) {
  final String front0 = _cleanField(raw.isNotEmpty ? raw[0] : '');
  final String rawBack = raw.length > 1 ? raw[1] : '';

  final List<String> backLines = _splitLines(rawBack)
      .map(_cleanField)
      .where((String s) => s.isNotEmpty && s != front0 && !_isIdLike(s))
      .toList();
  final String back = backLines.isNotEmpty ? backLines.first : '';
  String? example =
      backLines.length > 1 ? backLines.skip(1).join('\n') : null;

  // Fallbacks for note types that split reading/example into their own fields
  // (test the text only, ignoring any media markers).
  String? reading;
  if (!stripMedia(front0).contains('[')) {
    for (final String f in raw.skip(2)) {
      final String t = stripMedia(_cleanField(f));
      if (t.isNotEmpty && !t.contains('[') && _isKanaReading(t)) {
        reading = t;
        break;
      }
    }
  }
  if (example == null) {
    for (final String f in raw.skip(2)) {
      final String c = _cleanField(f);
      final String t = stripMedia(c);
      // A real example must contain Japanese — avoids picking id/tag fields
      // like "item:435851".
      if (t.isNotEmpty && t != back && t != front0 && _isSentence(t) &&
          _hasJapanese(t)) {
        example = c;
        break;
      }
    }
  }

  // Media in separate fields is placed where it belongs rather than dumped on
  // the front: the word's audio stays with the front (the prompt); a second
  // audio (in field order) is the sentence audio and goes with the example;
  // images move to the answer (back) so the front stays a clean prompt and the
  // back is substantial. Media already inline in front/back/example is kept.
  final String present = '$front0\n$back\n${example ?? ''}';
  final List<String> orphanAudio = <String>[];
  final List<String> orphanImages = <String>[];
  for (final String f in raw.skip(2)) {
    for (final String marker in mediaMarkers(_cleanField(f))) {
      if (present.contains(marker)) continue;
      final List<String> bucket =
          marker.startsWith('[sound:') ? orphanAudio : orphanImages;
      if (!bucket.contains(marker)) bucket.add(marker);
    }
  }

  final bool splitAudio =
      example != null && example.isNotEmpty && orphanAudio.length > 1;

  // Front (prompt) carries the word's audio and the image; a second audio is the
  // sentence's and rides with the example.
  final List<String> frontMedia = <String>[
    ...(splitAudio ? <String>[orphanAudio.first] : orphanAudio),
    ...orphanImages,
  ];
  final String front = frontMedia.isEmpty
      ? front0
      : <String>[front0, ...frontMedia].where((String s) => s.isNotEmpty).join(' ');

  if (splitAudio) {
    example = <String>[example, ...orphanAudio.skip(1)].join(' ');
  }

  return _Fields(front: front, back: back, reading: reading, example: example);
}

final RegExp _rubyTag = RegExp(r'<ruby>(.*?)<rt>(.*?)</rt></ruby>', dotAll: true);
final RegExp _imgTag = RegExp(
  r'<img[^>]*\bsrc\s*=\s*["' "'" r']([^"' "'" r']+)["' "'" r'][^>]*>',
  caseSensitive: false,
);

/// Cleans one Anki field to plain text but **preserves furigana** (`漢字[かな]`)
/// and **media references** (`[sound:x]`, normalised `<img src="x">`).
String _cleanField(String raw) {
  // <ruby>漢字<rt>かな</rt></ruby> -> 漢字[かな]
  String s = raw.replaceAllMapped(_rubyTag, (Match m) {
    final String base = _stripTags(m.group(1) ?? '');
    final String read = _stripTags(m.group(2) ?? '');
    return read.isEmpty ? base : '$base[$read]';
  });
  // Normalise images, then strip every tag EXCEPT <img …>.
  s = s.replaceAllMapped(_imgTag, (Match m) => '<img src="${m.group(1)}">');
  s = s.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ');
  s = s
      .replaceAll(RegExp(r'<(?!img )[^>]*>', caseSensitive: false), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');
  s = s.replaceAll(RegExp(r'[ \t]+'), ' ').trim();
  return _collapseRepeat(s);
}

String _stripTags(String s) => s.replaceAll(RegExp(r'<[^>]+>'), '');

List<String> _splitLines(String s) =>
    s.split(RegExp(r'<br\s*/?>|\n', caseSensitive: false));

/// An id-like token such as `jp500_0101` — junk, not content.
bool _isIdLike(String s) => RegExp(r'^[A-Za-z]+\d+[A-Za-z0-9_]*$').hasMatch(s);

/// A short, kana-only string — i.e. a reading, not a sentence.
bool _isKanaReading(String s) {
  if (s.isEmpty || s.length > 16) return false;
  // Hiragana + katakana (incl. prolonged-sound mark) and spaces only.
  return RegExp(r'^[぀-ヿ\s]+$').hasMatch(s);
}

/// Looks like an example sentence: long enough, or with sentence punctuation.
bool _isSentence(String s) =>
    s.length >= 8 || s.contains('。') || s.contains('、') || s.contains('？');

/// Whether the text contains any Japanese (kana or CJK).
bool _hasJapanese(String s) => RegExp(r'[぀-ヿ㐀-鿿]').hasMatch(s);

/// Collapses a string of identical whitespace-separated tokens to one.
String _collapseRepeat(String s) {
  final List<String> parts = s.split(' ');
  if (parts.length > 1 && parts.every((String p) => p == parts.first)) {
    return parts.first;
  }
  return s;
}
