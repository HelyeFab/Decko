import 'package:flutter/material.dart';

import '../../core/constants/decko_spacing.dart';
import 'app_theme_config.dart';
import 'card_theme_config.dart';

/// The single source of truth for Decko's built-in themes.
///
/// Both app themes and card themes are registered here so the gallery, router
/// and controller all read from one place rather than scattering colours
/// through widgets (per CODING_STANDARDS "theme tokens, centralised").
abstract final class ThemeRegistry {
  /// App shell themes. Order is the order shown in the gallery.
  static final List<AppThemeConfig> appThemes = <AppThemeConfig>[
    _softStudy,
    _deckoLight,
    _deckoDark,
  ];

  /// Card presentation themes.
  static const List<CardThemeConfig> cardThemes = <CardThemeConfig>[
    CardThemeConfig(
      id: 'minimal',
      name: 'Minimal Card',
      description: 'Large prompt, minimal chrome, maximum focus.',
      style: CardThemeStyle.minimal,
    ),
    CardThemeConfig(
      id: 'detailed',
      name: 'Detailed Card',
      description: 'Reading, meaning, example and tags laid out clearly.',
      style: CardThemeStyle.detailed,
    ),
    CardThemeConfig(
      id: 'game',
      name: 'Game Card',
      description: 'Playful treatment for challenge rounds and XP feedback.',
      style: CardThemeStyle.game,
    ),
  ];

  /// Decko defaults to the warm "Soft Study" look (per the MVP brief).
  static AppThemeConfig get defaultAppTheme => _softStudy;
  static CardThemeConfig get defaultCardTheme => cardThemes.first;

  static AppThemeConfig appThemeById(String id) =>
      appThemes.firstWhere((AppThemeConfig t) => t.id == id,
          orElse: () => defaultAppTheme);

  // --- App theme definitions -------------------------------------------------

  static final AppThemeConfig _softStudy = AppThemeConfig(
    id: 'soft-study',
    name: 'Soft Study',
    description: 'Warm, friendly and calm — Decko’s signature look.',
    themeData: _build(
      brightness: Brightness.light,
      seed: const Color(0xFFE0785A), // warm terracotta
      scaffold: const Color(0xFFF7F2EA), // soft cream
      surface: const Color(0xFFFFFBF5),
    ),
  );

  static final AppThemeConfig _deckoLight = AppThemeConfig(
    id: 'decko-light',
    name: 'Decko Light',
    description: 'Clean, bright and crisp for daytime study.',
    themeData: _build(
      brightness: Brightness.light,
      seed: const Color(0xFF4F6BED), // indigo
      scaffold: const Color(0xFFF4F6FB),
      surface: Colors.white,
    ),
  );

  static final AppThemeConfig _deckoDark = AppThemeConfig(
    id: 'decko-dark',
    name: 'Decko Dark',
    description: 'Low-light, low-distraction focus mode.',
    themeData: _build(
      brightness: Brightness.dark,
      seed: const Color(0xFF8AA2FF),
      scaffold: const Color(0xFF14161C),
      surface: const Color(0xFF1E212B),
    ),
  );

  /// Builds a consistent [ThemeData] from a small palette so every app theme
  /// shares the same shape, spacing and typography rhythm.
  static ThemeData _build({
    required Brightness brightness,
    required Color seed,
    required Color scaffold,
    required Color surface,
  }) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    ).copyWith(surface: surface);

    final RoundedRectangleBorder cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(DeckoRadii.lg),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      brightness: brightness,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: cardShape,
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DeckoRadii.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DeckoRadii.md),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: scheme.surfaceContainerHighest,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DeckoRadii.pill),
        ),
      ),
    );
  }
}
