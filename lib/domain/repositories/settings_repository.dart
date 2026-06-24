/// Persists small app-level settings locally.
///
/// Async so the storage backend can be swapped later without touching callers.
abstract class SettingsRepository {
  /// The saved app-theme id, or null if the user hasn't chosen one.
  Future<String?> getSelectedAppThemeId();

  /// Persists the chosen app-theme id.
  Future<void> saveSelectedAppThemeId(String themeId);

  /// Whether furigana readings are shown on cards (defaults to true).
  Future<bool> getShowFurigana();

  /// Persists the furigana on/off preference.
  Future<void> saveShowFurigana(bool show);

  /// The motivational daily card goal (defaults to 20). A presentation target
  /// only — it never affects scheduling or the due queue (MVP_015).
  Future<int> getDailyGoal();

  /// Persists the daily card goal.
  Future<void> saveDailyGoal(int goal);

  /// Whether the user has finished (or skipped) first-run onboarding. Local-only
  /// and not tied to auth — signing out never resets it (MVP_024).
  Future<bool> getHasCompletedOnboarding();

  /// Persists onboarding completion.
  Future<void> saveHasCompletedOnboarding(bool done);
}
