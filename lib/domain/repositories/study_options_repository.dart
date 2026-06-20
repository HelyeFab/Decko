import '../study_options/study_options.dart';

/// Persists global study defaults and per-deck overrides, and resolves the
/// effective options a review session should use (MVP_011, DEC-020).
abstract class StudyOptionsRepository {
  Future<StudyOptions> getGlobalOptions();
  Future<void> saveGlobalOptions(StudyOptions options);

  /// The deck's overrides, or null when the deck has none.
  Future<DeckStudyOptions?> getDeckOptions(String deckId);
  Future<void> saveDeckOptions(String deckId, DeckStudyOptions options);
  Future<void> deleteDeckOptions(String deckId);

  /// Global defaults with the deck's overrides applied.
  Future<EffectiveStudyOptions> getEffectiveOptions(String deckId);
}
