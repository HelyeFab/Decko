import 'package:flutter/material.dart';

/// The distinct visual treatments a flashcard can use.
enum CardThemeStyle { minimal, detailed, game }

/// Configuration for a **card** theme — how an individual flashcard is
/// presented (layout, reveal style, flourish).
///
/// Separate from `AppThemeConfig` by design (DEC-004) so a learner can pair any
/// app shell with any card look. The actual rendering lives in the reusable
/// `DeckoCard` widget, which reads [style].
@immutable
class CardThemeConfig {
  const CardThemeConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.style,
  });

  final String id;
  final String name;
  final String description;
  final CardThemeStyle style;
}
