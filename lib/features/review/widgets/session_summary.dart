import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/constants/decko_spacing.dart';
import '../../../domain/review_rating.dart';
import '../../../domain/review_session_result.dart';

/// The end-of-session completion view: a celebratory header, per-rating counts,
/// and the two follow-up actions.
class SessionSummary extends StatelessWidget {
  const SessionSummary({
    super.key,
    required this.result,
    required this.onBackToDeck,
    required this.onReviewAgain,
    this.xpGained,
    this.streakDays,
    this.dailyReviewed,
    this.dailyGoal,
  });

  final ReviewSessionResult result;
  final VoidCallback onBackToDeck;
  final VoidCallback onReviewAgain;

  /// Light-gamification rewards (MVP_015). Null until progress is recorded.
  final int? xpGained;
  final int? streakDays;
  final int? dailyReviewed;
  final int? dailyGoal;

  static const Map<ReviewRating, Color> _accents = <ReviewRating, Color>{
    ReviewRating.again: Color(0xFFE5534B),
    ReviewRating.hard: Color(0xFFE0883A),
    ReviewRating.good: Color(0xFF3FA66A),
    ReviewRating.easy: Color(0xFF3F77E0),
  };

  bool get _hasRewards => xpGained != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DeckoSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            FaIcon(
              FontAwesomeIcons.trophy,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: DeckoSpacing.lg),
            Text(
              'Session complete',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: DeckoSpacing.xs),
            Text(
              'Cards reviewed: ${result.totalCards}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (_hasRewards) ...<Widget>[
              const SizedBox(height: DeckoSpacing.lg),
              _RewardChips(
                xpGained: xpGained,
                streakDays: streakDays,
                dailyReviewed: dailyReviewed,
                dailyGoal: dailyGoal,
              ),
            ],
            const SizedBox(height: DeckoSpacing.xl),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DeckoSpacing.lg,
                  vertical: DeckoSpacing.sm,
                ),
                child: Column(
                  children: <Widget>[
                    for (final ReviewRating rating in ReviewRating.values)
                      _RatingCountRow(
                        rating: rating,
                        count: result.countFor(rating),
                        accent: _accents[rating]!,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DeckoSpacing.xl),
            FilledButton.icon(
              onPressed: onReviewAgain,
              icon: const FaIcon(FontAwesomeIcons.rotateRight),
              label: const Text('Review again'),
            ),
            const SizedBox(height: DeckoSpacing.md),
            OutlinedButton.icon(
              onPressed: onBackToDeck,
              icon: const FaIcon(FontAwesomeIcons.arrowLeft),
              label: const Text('Back to deck'),
            ),
          ],
        ),
      ),
    );
  }
}

/// The light-gamification rewards row: XP gained, daily-goal progress, streak.
class _RewardChips extends StatelessWidget {
  const _RewardChips({
    required this.xpGained,
    required this.streakDays,
    required this.dailyReviewed,
    required this.dailyGoal,
  });

  final int? xpGained;
  final int? streakDays;
  final int? dailyReviewed;
  final int? dailyGoal;

  @override
  Widget build(BuildContext context) {
    final int goal = dailyGoal ?? 0;
    final int reviewed = dailyReviewed ?? 0;
    final bool goalDone = goal > 0 && reviewed >= goal;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: DeckoSpacing.sm,
      runSpacing: DeckoSpacing.sm,
      children: <Widget>[
        if (xpGained != null && xpGained! > 0)
          _Chip(icon: FontAwesomeIcons.bolt, label: '+$xpGained XP'),
        if (goal > 0)
          _Chip(
            icon: goalDone
                ? FontAwesomeIcons.solidCircleCheck
                : FontAwesomeIcons.bullseye,
            label: goalDone ? 'Daily goal reached' : '$reviewed / $goal today',
            highlight: goalDone,
          ),
        if (streakDays != null && streakDays! > 0)
          _Chip(
            icon: FontAwesomeIcons.fire,
            label: '$streakDays day streak',
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, this.highlight = false});

  final FaIconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color bg = highlight ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final Color fg = highlight ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DeckoSpacing.md,
        vertical: DeckoSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DeckoRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FaIcon(icon, size: 13, color: fg),
          const SizedBox(width: DeckoSpacing.sm),
          Text(label,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: fg, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _RatingCountRow extends StatelessWidget {
  const _RatingCountRow({
    required this.rating,
    required this.count,
    required this.accent,
  });

  final ReviewRating rating;
  final int count;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DeckoSpacing.sm),
      child: Row(
        children: <Widget>[
          Container(
            height: 10,
            width: 10,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: DeckoSpacing.md),
          Expanded(
            child: Text(rating.label, style: theme.textTheme.titleMedium),
          ),
          Text(
            '$count',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
