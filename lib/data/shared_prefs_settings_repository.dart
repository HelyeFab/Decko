import 'package:shared_preferences/shared_preferences.dart';

import '../domain/repositories/settings_repository.dart';

/// [SettingsRepository] backed by `shared_preferences`.
///
/// `getInstance()` returns a cached singleton, so calling it per method keeps
/// this class const-constructible and free of init plumbing.
class SharedPrefsSettingsRepository implements SettingsRepository {
  const SharedPrefsSettingsRepository();

  static const String _appThemeKey = 'decko.settings.appThemeId';
  static const String _furiganaKey = 'decko.settings.showFurigana';
  static const String _dailyGoalKey = 'decko.settings.dailyGoal';
  static const int _defaultDailyGoal = 20;

  @override
  Future<String?> getSelectedAppThemeId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_appThemeKey);
  }

  @override
  Future<void> saveSelectedAppThemeId(String themeId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appThemeKey, themeId);
  }

  @override
  Future<bool> getShowFurigana() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_furiganaKey) ?? true;
  }

  @override
  Future<void> saveShowFurigana(bool show) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_furiganaKey, show);
  }

  @override
  Future<int> getDailyGoal() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dailyGoalKey) ?? _defaultDailyGoal;
  }

  @override
  Future<void> saveDailyGoal(int goal) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyGoalKey, goal);
  }
}
