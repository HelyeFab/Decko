/// Persists small app-level settings locally.
///
/// Async so the storage backend can be swapped later without touching callers.
abstract class SettingsRepository {
  /// The saved app-theme id, or null if the user hasn't chosen one.
  Future<String?> getSelectedAppThemeId();

  /// Persists the chosen app-theme id.
  Future<void> saveSelectedAppThemeId(String themeId);
}
