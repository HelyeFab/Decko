import 'package:flutter/material.dart';

/// Configuration for an **app** theme — the shell, navigation, surfaces and
/// buttons.
///
/// Decko deliberately separates app themes from card themes (DEC-004): this
/// type styles the chrome around a study session, while `CardThemeConfig`
/// styles the flashcard itself.
@immutable
class AppThemeConfig {
  const AppThemeConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.themeData,
  });

  final String id;
  final String name;
  final String description;
  final ThemeData themeData;

  ColorScheme get colors => themeData.colorScheme;
  Brightness get brightness => themeData.brightness;
}
