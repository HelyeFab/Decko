import '../import/source/imported_anki_source.dart';

/// Persists the lossless [ImportedAnkiSource] for an imported deck (DEC-016).
///
/// Async + behind an interface so storage can evolve. The source can be large
/// (raw fields for thousands of notes), so implementations should not use
/// `shared_preferences`.
abstract class ImportedSourceStore {
  /// Persists the source for its deck.
  Future<void> saveSource(ImportedAnkiSource source);

  /// Loads the source for [deckId], or null if none was stored.
  Future<ImportedAnkiSource?> getSourceForDeck(String deckId);

  /// Removes stored source for [deckId] (used when a deck is deleted).
  Future<void> deleteSourceForDeck(String deckId);
}
