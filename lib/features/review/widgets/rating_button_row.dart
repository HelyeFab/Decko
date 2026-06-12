import 'package:flutter/material.dart';

import '../../../core/constants/decko_spacing.dart';
import '../../../domain/review_rating.dart';

/// The Again / Hard / Good / Easy grading row.
///
/// Purely presentational: it reports the tapped [ReviewRating] upward. Actual
/// scheduling is the job of a `SchedulerService` in a later MVP (DEC-003), so
/// nothing is calculated here.
class RatingButtonRow extends StatelessWidget {
  const RatingButtonRow({
    super.key,
    required this.onRate,
    this.enabled = true,
  });

  final ValueChanged<ReviewRating> onRate;
  final bool enabled;

  static const Map<ReviewRating, Color> _accents = <ReviewRating, Color>{
    ReviewRating.again: Color(0xFFE5534B),
    ReviewRating.hard: Color(0xFFE0883A),
    ReviewRating.good: Color(0xFF3FA66A),
    ReviewRating.easy: Color(0xFF3F77E0),
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (final ReviewRating rating in ReviewRating.values) ...<Widget>[
          Expanded(child: _RatingButton(
            rating: rating,
            accent: _accents[rating]!,
            onRate: enabled ? onRate : null,
          )),
          if (rating != ReviewRating.values.last)
            const SizedBox(width: DeckoSpacing.sm),
        ],
      ],
    );
  }
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({
    required this.rating,
    required this.accent,
    required this.onRate,
  });

  final ReviewRating rating;
  final Color accent;
  final ValueChanged<ReviewRating>? onRate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: '${rating.label} — ${rating.hint}',
      child: FilledButton(
        onPressed: onRate == null ? null : () => onRate!(rating),
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: DeckoSpacing.md),
          minimumSize: const Size(0, 56),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              rating.label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
