import '../sentence_builder/cube_token.dart';

/// One cached tokenization: the server-cleaned [sentence] and its word [tokens].
class CachedTokenization {
  const CachedTokenization({required this.sentence, required this.tokens});

  final String sentence;
  final List<CubeToken> tokens;
}

/// Persists tokenizer results per deck so the sentence builder is instant and
/// works offline after the first tokenize, and so the service isn't re-hit
/// (MVP_016). Keyed by `LearningItem.id`.
abstract class SentenceTokenCache {
  /// All cached tokenizations for [deckId], keyed by item id.
  Future<Map<String, CachedTokenization>> load(String deckId);

  /// Merges/overwrites [entries] into the deck's cache.
  Future<void> save(String deckId, Map<String, CachedTokenization> entries);

  /// Drops the deck's cache (e.g. on deck deletion).
  Future<void> clear(String deckId);
}
