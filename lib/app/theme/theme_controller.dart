import 'package:flutter/foundation.dart';

import 'app_theme_config.dart';
import 'theme_registry.dart';

/// Holds the currently selected app theme and notifies listeners on change.
///
/// Intentionally lightweight (a [ValueNotifier]) for MVP_001 — there is no real
/// app state yet, so a full state-management library would be premature (the
/// MVP brief lists "complex state management" as a non-goal). When persistence
/// arrives the selection can be hydrated here without touching the UI.
class ThemeController extends ValueNotifier<AppThemeConfig> {
  ThemeController() : super(ThemeRegistry.defaultAppTheme);

  void select(AppThemeConfig theme) => value = theme;

  void selectById(String id) => value = ThemeRegistry.appThemeById(id);
}
