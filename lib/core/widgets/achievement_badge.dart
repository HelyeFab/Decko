import 'package:flutter/material.dart';

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

  final IconData icon;
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
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: earned ? scheme.primary : scheme.surfaceContainerHighest,
              border: Border.all(color: ring, width: 2),
            ),
            child: Icon(icon, color: fg, size: 28),
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
