import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../constants/decko_spacing.dart';

/// A simple achievement badge placeholder for the progress screen.
///
/// [earned] toggles between an active (coloured) and a locked (muted) look.
class AchievementBadge extends StatelessWidget {
  const AchievementBadge({
    super.key,
    required this.icon,
    required this.label,
    this.earned = false,
  });

  final FaIconData icon;
  final String label;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color ring = earned ? scheme.primary : scheme.surfaceContainerHighest;
    final Color fg = earned ? scheme.onPrimary : scheme.onSurfaceVariant;

    return Semantics(
      label: '$label badge, ${earned ? 'earned' : 'locked'}',
      child: Column(
        children: <Widget>[
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Container(
                height: 64,
                width: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      earned ? scheme.primary : scheme.surfaceContainerHighest,
                  border: Border.all(color: ring, width: 2),
                ),
                child: FaIcon(icon,
                    color: earned ? fg : fg.withValues(alpha: 0.5), size: 26),
              ),
              // A corner marker so earned vs not-yet-earned is unmistakable.
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  height: 22,
                  width: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: earned ? scheme.primary : scheme.surfaceContainerHigh,
                    border: Border.all(color: scheme.surface, width: 2),
                  ),
                  child: FaIcon(
                    earned ? FontAwesomeIcons.check : FontAwesomeIcons.lock,
                    size: 9,
                    color:
                        earned ? scheme.onPrimary : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DeckoSpacing.sm),
          SizedBox(
            width: 84,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: earned ? scheme.onSurface : scheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
