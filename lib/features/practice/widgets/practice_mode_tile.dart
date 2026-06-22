import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/constants/decko_spacing.dart';
import '../../../domain/practice/practice_mode.dart';

/// The display icon for a practice mode (UI-side mapping, keeps the domain
/// framework-light).
FaIconData practiceModeIcon(PracticeModeId id) => switch (id) {
      PracticeModeId.bunburuSentenceBuilder => FontAwesomeIcons.cubesStacked,
      PracticeModeId.listeningChallenge => FontAwesomeIcons.headphones,
    };

/// The action label for launching a mode from a single card (e.g. in review).
String practiceCardAction(PracticeModeId id) => switch (id) {
      PracticeModeId.bunburuSentenceBuilder => 'Build this sentence',
      PracticeModeId.listeningChallenge => 'Listen & choose',
    };

/// A tappable practice-mode row (MVP_017). Used by the Practice Hub and Deck
/// Detail so every surface renders modes the same way.
class PracticeModeTile extends StatelessWidget {
  const PracticeModeTile({
    super.key,
    required this.mode,
    required this.onTap,
    this.accent = false,
  });

  final PracticeMode mode;
  final VoidCallback onTap;

  /// When true, uses the filled accent style (for the Hub hero entries).
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color bg = accent ? scheme.primaryContainer : theme.cardColor;
    final Color fg = accent ? scheme.onPrimaryContainer : scheme.onSurface;
    final Color sub =
        accent ? scheme.onPrimaryContainer.withValues(alpha: 0.85) : scheme.onSurfaceVariant;
    final Color medallionBg =
        accent ? scheme.onPrimaryContainer.withValues(alpha: 0.12) : scheme.primaryContainer;
    final Color medallionFg = accent ? scheme.onPrimaryContainer : scheme.onPrimaryContainer;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(DeckoRadii.lg),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(DeckoSpacing.lg),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(DeckoRadii.lg),
            border: accent ? null : Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: <Widget>[
              Container(
                height: 44,
                width: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: medallionBg,
                  borderRadius: BorderRadius.circular(DeckoRadii.md),
                ),
                child: FaIcon(practiceModeIcon(mode.id),
                    size: 18, color: medallionFg),
              ),
              const SizedBox(width: DeckoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(mode.title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: fg, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(mode.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(color: sub)),
                  ],
                ),
              ),
              FaIcon(FontAwesomeIcons.play,
                  size: 14, color: accent ? fg : scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
