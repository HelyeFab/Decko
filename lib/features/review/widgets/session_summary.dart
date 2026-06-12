import 'package:flutter/material.dart';

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
  });

  final ReviewSessionResult result;
  final VoidCallback onBackToDeck;
  final VoidCallback onReviewAgain;

  static const Map<ReviewRating, Color> _accents = <ReviewRating, Color>{
    ReviewRating.again: Color(0xFFE5534B),
    ReviewRating.hard: Color(0xFFE0883A),
    ReviewRating.good: Color(0xFF3FA66A),
    ReviewRating.easy: Color(0xFF3F77E0),
  };

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
            Icon(
              Icons.celebration_rounded,
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
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Review again'),
            ),
            const SizedBox(height: DeckoSpacing.md),
            OutlinedButton.icon(
              onPressed: onBackToDeck,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back to deck'),
            ),
          ],
        ),
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
