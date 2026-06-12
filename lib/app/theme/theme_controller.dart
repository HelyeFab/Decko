import 'package:flutter/foundation.dart';

import '../../domain/repositories/settings_repository.dart';
import 'app_theme_config.dart';
import 'theme_registry.dart';

/// Holds the currently selected app theme, persists changes, and notifies
/// listeners on change.
///
/// Lightweight by design (a [ValueNotifier]) — MVP_004 only persists the theme
/// id via [SettingsRepository]; a full state-management library would still be
/// premature (a non-goal). Persistence is fire-and-forget so the UI stays
/// instant; hydration happens once via [load].
class ThemeController extends ValueNotifier<AppThemeConfig> {
  ThemeController(this._settings) : super(ThemeRegistry.defaultAppTheme);

  final SettingsRepository _settings;

  /// Applies the previously saved theme, if any. Safe to call once at startup.
  Future<void> load() async {
    final String? savedId = await _settings.getSelectedAppThemeId();
    if (savedId != null) value = ThemeRegistry.appThemeById(savedId);
  }

  void select(AppThemeConfig theme) {
    value = theme;
    _settings.saveSelectedAppThemeId(theme.id);
  }

  void selectById(String id) => select(ThemeRegistry.appThemeById(id));
}
