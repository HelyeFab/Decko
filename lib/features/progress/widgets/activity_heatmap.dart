import 'package:flutter/material.dart';

import '../../../core/constants/decko_spacing.dart';
import '../../../domain/activity/activity_day.dart';

/// A GitHub-style XP heatmap (MVP_019): the recent [days] (oldest first) laid
/// out as week columns of seven cells, intensity by XP, today ringed.
class ActivityHeatmap extends StatelessWidget {
  const ActivityHeatmap({super.key, required this.days, required this.today});

  final List<ActivityDay> days;
  final DateTime today;

  static const double _gap = 4;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    // Split into columns of 7 (a "week" block), oldest → newest.
    final List<List<ActivityDay>> columns = <List<ActivityDay>>[];
    for (int i = 0; i < days.length; i += 7) {
      columns.add(days.sublist(i, (i + 7).clamp(0, days.length)));
    }
    final DateTime todayDate = DateTime(today.year, today.month, today.day);

    return Container(
      padding: const EdgeInsets.all(DeckoSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(DeckoRadii.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Activity',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: DeckoSpacing.md),
          // Size the cells to fill the card width edge-to-edge (no float).
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final int cols = columns.length;
              final double cell =
                  (constraints.maxWidth - (cols - 1) * _gap) / cols;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (int c = 0; c < cols; c++) ...<Widget>[
                    if (c > 0) const SizedBox(width: _gap),
                    Column(
                      children: <Widget>[
                        for (final ActivityDay d in columns[c]) ...<Widget>[
                          _Cell(
                            day: d,
                            size: cell,
                            isToday: d.day == todayDate,
                            scheme: scheme,
                          ),
                          const SizedBox(height: _gap),
                        ],
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: DeckoSpacing.sm),
          _Legend(scheme: scheme),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.day,
    required this.size,
    required this.isToday,
    required this.scheme,
  });

  final ActivityDay day;
  final double size;
  final bool isToday;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: _intensity(day.xp, scheme),
        borderRadius: BorderRadius.circular(4),
        border: isToday
            ? Border.all(color: scheme.onSurface, width: 1.4)
            : null,
      ),
    );
  }
}

Color _intensity(int xp, ColorScheme scheme) {
  if (xp <= 0) return scheme.surfaceContainerHighest;
  if (xp <= 10) return scheme.primary.withValues(alpha: 0.35);
  if (xp <= 30) return scheme.primary.withValues(alpha: 0.6);
  if (xp <= 60) return scheme.primary.withValues(alpha: 0.8);
  return scheme.primary;
}

class _Legend extends StatelessWidget {
  const _Legend({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    Widget swatch(int xp) => Container(
          height: 11,
          width: 11,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: _intensity(xp, scheme),
            borderRadius: BorderRadius.circular(3),
          ),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Text('Less',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(width: DeckoSpacing.xs),
        swatch(0),
        swatch(5),
        swatch(20),
        swatch(45),
        swatch(80),
        const SizedBox(width: DeckoSpacing.xs),
        Text('More',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: scheme.onSurfaceVariant)),
      ],
    );
  }
}
