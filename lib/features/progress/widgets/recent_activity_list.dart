import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/constants/decko_spacing.dart';
import '../../../domain/activity/activity_event.dart';

/// A compact list of the most recent ledger events (MVP_019).
class RecentActivityList extends StatelessWidget {
  const RecentActivityList({
    super.key,
    required this.events,
    required this.now,
    this.limit = 6,
  });

  final List<ActivityEvent> events;
  final DateTime now;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final List<ActivityEvent> shown = events.take(limit).toList();
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: DeckoSpacing.lg, vertical: DeckoSpacing.sm),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(DeckoRadii.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < shown.length; i++) ...<Widget>[
            if (i > 0) Divider(height: 1, color: scheme.outlineVariant),
            _Row(event: shown[i], now: now),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.event, required this.now});

  final ActivityEvent event;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DeckoSpacing.md),
      child: Row(
        children: <Widget>[
          Container(
            height: 36,
            width: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(DeckoRadii.sm),
            ),
            child: FaIcon(_icon(event.modeId),
                size: 15, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(width: DeckoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(_label(event),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(_relative(event.occurredAt, now),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          if (event.xpAwarded > 0)
            Text('+${event.xpAwarded} XP',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                )),
        ],
      ),
    );
  }
}

FaIconData _icon(String modeId) => switch (modeId) {
      ActivityModeIds.standardReview => FontAwesomeIcons.layerGroup,
      ActivityModeIds.bunburuSentenceBuilder => FontAwesomeIcons.cubesStacked,
      ActivityModeIds.listeningChallenge => FontAwesomeIcons.headphones,
      _ => FontAwesomeIcons.solidStar,
    };

String _label(ActivityEvent e) {
  switch (e.modeId) {
    case ActivityModeIds.standardReview:
      final int n = (e.metadata['reviewedCards'] as int?) ?? 0;
      return 'Reviewed $n card${n == 1 ? '' : 's'}';
    case ActivityModeIds.bunburuSentenceBuilder:
      return 'Sentence builder';
    case ActivityModeIds.listeningChallenge:
      return 'Listening challenge';
    default:
      return 'Practice';
  }
}

String _relative(DateTime when, DateTime now) {
  final DateTime d0 = DateTime(now.year, now.month, now.day);
  final DateTime d1 = DateTime(when.year, when.month, when.day);
  final int days = d0.difference(d1).inDays;
  if (days == 0) {
    final int mins = now.difference(when).inMinutes;
    if (mins < 1) return 'Just now';
    if (mins < 60) return '${mins}m ago';
    return '${now.difference(when).inHours}h ago';
  }
  if (days == 1) return 'Yesterday';
  if (days < 7) return '$days days ago';
  return '${(days / 7).floor()}w ago';
}
