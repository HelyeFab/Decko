// ignore_for_file: prefer_initializing_formals
import 'dart:math';

import '../../domain/deck.dart';
import '../../domain/import/source/imported_anki_source.dart';
import '../../domain/learning_item.dart';
import '../../domain/repositories/sentence_token_cache.dart';
import '../../domain/sentence_builder/sentence_builder_mapper.dart';
import '../../domain/sentence_builder/sentence_builder_round.dart';
import '../../domain/sentence_builder/sentence_builder_source.dart';
import '../../domain/sentence_builder/sentence_builder_token.dart';
import '../../domain/sentence_builder/sentence_tokenizer.dart';

/// Builds sentence-builder rounds by combining the sync sentence picker
/// ([SentenceBuilderMapper]) with the tokenizer service and a per-deck cache
/// (MVP_016). Tokenization is async + network; results are cached so repeat
/// plays are instant and offline. Never touches review/FSRS state.
class SentenceRoundService {
  const SentenceRoundService({
    required SentenceTokenizer tokenizer,
    required SentenceTokenCache cache,
    SentenceBuilderMapper mapper = const SentenceBuilderMapper(),
  })  : _tokenizer = tokenizer,
        _cache = cache,
        _mapper = mapper;

  final SentenceTokenizer _tokenizer;
  final SentenceTokenCache _cache;
  final SentenceBuilderMapper _mapper;

  /// Up to [limit] playable rounds for [deck], a fresh **random** selection each
  /// time (so practice doesn't always start with the same sentence). Cache hits
  /// return instantly; misses are tokenized in a single batch and cached.
  Future<List<SentenceBuilderRound>> roundsForDeck(
    Deck deck, {
    ImportedAnkiSource? ankiSource,
    SentenceBuilderSource source = SentenceBuilderSource.deckPractice,
    int limit = 25,
    Random? random,
  }) async {
    // Gather a bounded pool of capable cards, then sample [limit] from it.
    const int candidatePool = 400;
    final List<SentenceSource> candidates = <SentenceSource>[];
    for (final LearningItem item in deck.items) {
      final SentenceSource? s =
          _mapper.sourceFor(item, note: _noteFor(item, ankiSource));
      if (s != null) candidates.add(s);
      if (candidates.length >= candidatePool) break;
    }
    if (candidates.isEmpty) return <SentenceBuilderRound>[];

    candidates.shuffle(random ?? Random());
    final List<SentenceSource> sources =
        candidates.take(limit).toList(growable: false);

    final Map<String, CachedTokenization> cache = await _cache.load(deck.id);
    final List<SentenceSource> misses = <SentenceSource>[
      for (final SentenceSource s in sources)
        if (cache[s.itemId]?.sentence != s.sentence) s,
    ];

    final Map<String, CachedTokenization> fresh =
        await _tokenizeAll(misses);
    if (fresh.isNotEmpty) await _cache.save(deck.id, fresh);
    cache.addAll(fresh);

    final List<SentenceBuilderRound> rounds = <SentenceBuilderRound>[];
    for (final SentenceSource s in sources) {
      final CachedTokenization? t = cache[s.itemId];
      final SentenceBuilderRound? round =
          _round(s, deck.id, source, t);
      if (round != null) rounds.add(round);
    }
    return rounds;
  }

  /// A single round for [item] (manual / review presentation), or null when it
  /// has no usable sentence or tokenizes to fewer than two tiles.
  Future<SentenceBuilderRound?> roundForItem(
    LearningItem item, {
    required String deckId,
    required SentenceBuilderSource source,
    ImportedAnkiNote? note,
  }) async {
    final SentenceSource? s = _mapper.sourceFor(item, note: note);
    if (s == null) return null;

    final Map<String, CachedTokenization> cache = await _cache.load(deckId);
    CachedTokenization? t = cache[s.itemId];
    if (t == null || t.sentence != s.sentence) {
      final Map<String, CachedTokenization> fresh =
          await _tokenizeAll(<SentenceSource>[s]);
      if (fresh.isNotEmpty) await _cache.save(deckId, fresh);
      t = fresh[s.itemId];
    }
    return _round(s, deckId, source, t);
  }

  /// Tokenizes the [sources] in one batch and returns cache entries by item id.
  Future<Map<String, CachedTokenization>> _tokenizeAll(
      List<SentenceSource> sources) async {
    if (sources.isEmpty) return <String, CachedTokenization>{};
    final TokenizeResult result =
        await _tokenizer.tokenize(<String>[for (final SentenceSource s in sources) s.sentence]);
    final Map<String, CachedTokenization> out = <String, CachedTokenization>{};
    for (int i = 0; i < sources.length && i < result.tokens.length; i++) {
      out[sources[i].itemId] = CachedTokenization(
        sentence: i < result.lines.length
            ? result.lines[i]
            : sources[i].sentence,
        tokens: result.tokens[i],
      );
    }
    return out;
  }

  SentenceBuilderRound? _round(
    SentenceSource s,
    String deckId,
    SentenceBuilderSource source,
    CachedTokenization? t,
  ) {
    if (t == null || t.tokens.length < 2) return null;
    return SentenceBuilderRound(
      deckId: deckId,
      source: source,
      sentence: t.sentence,
      itemId: s.itemId,
      noteId: s.noteId,
      translation: s.translation,
      audioRef: s.audioRef,
      reading: s.reading,
      tokens: <SentenceBuilderToken>[
        for (int i = 0; i < t.tokens.length; i++)
          SentenceBuilderToken(
            text: t.tokens[i].surface,
            position: i,
            furigana: t.tokens[i].furigana,
          ),
      ],
    );
  }

  ImportedAnkiNote? _noteFor(LearningItem item, ImportedAnkiSource? source) {
    final String? noteId = item.importedProgress?.sourceNoteId;
    if (noteId == null || source == null) return null;
    return source.noteById(noteId);
  }
}

/// Cheap synchronous check that [deck] likely has sentence-capable cards, using
/// the mapped item content only (no imported source, no tokenization). Used to
/// decide entry-point visibility; the true rounds are built by the service.
bool deckHasLikelySentences(
  Deck deck, {
  ImportedAnkiSource? ankiSource,
  int sample = 200,
}) {
  const SentenceBuilderMapper mapper = SentenceBuilderMapper();
  final int n = deck.items.length < sample ? deck.items.length : sample;
  for (int i = 0; i < n; i++) {
    final LearningItem item = deck.items[i];
    final String? noteId = item.importedProgress?.sourceNoteId;
    final ImportedAnkiNote? note =
        (noteId != null) ? ankiSource?.noteById(noteId) : null;
    if (mapper.looksCapable(item, note: note)) return true;
  }
  return false;
}
