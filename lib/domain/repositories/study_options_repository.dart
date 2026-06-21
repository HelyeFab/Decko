import '../study_options/study_options.dart';

/// Persists global study defaults, reusable option profiles, and per-deck
/// overrides, and resolves the effective options a review session should use
/// (MVP_011 DEC-020; profiles added MVP_012 DEC-021).
abstract class StudyOptionsRepository {
  Future<StudyOptions> getGlobalOptions();
  Future<void> saveGlobalOptions(StudyOptions options);

  /// All profiles, beginning with the synthetic "Default" (mirrors global).
  Future<List<StudyOptionProfile>> listProfiles();

  /// A profile by id; the default id returns the global-backed default.
  Future<StudyOptionProfile?> getProfile(String id);

  /// Creates or updates a user profile (the default profile is read-only —
  /// edit it via [saveGlobalOptions]).
  Future<void> saveProfile(StudyOptionProfile profile);

  /// Deletes a user profile. Decks still pointing at it fall back to global.
  Future<void> deleteProfile(String id);

  /// The deck's overrides (incl. assigned profile), or null when none.
  Future<DeckStudyOptions?> getDeckOptions(String deckId);
  Future<void> saveDeckOptions(String deckId, DeckStudyOptions options);
  Future<void> deleteDeckOptions(String deckId);

  /// Resolves global/default → assigned profile → deck override.
  Future<EffectiveStudyOptions> getEffectiveOptions(String deckId);
}
