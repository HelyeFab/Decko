import 'review_card_state.dart';
import 'review_rating.dart';

/// A deliberately simple, **temporary** scheduling policy.
///
/// It is NOT FSRS — it just applies fixed intervals so that grading writes back
/// meaningful local state and the due queue moves. A real FSRS scheduler will
/// replace this class without touching the UI or [ReviewCardState] (DEC-003 /
/// DEC-011). Pure: the clock is passed in, so it is fully unit-testable.
///
///   Again → relearning, lapses+1, due now,        interval 0
///   Hard  → review,     due tomorrow,             interval 1
///   Good  → review,     due in 3 days,            interval 3
///   Easy  → review,     due in 7 days,            interval 7
abstract final class ReviewSchedulingPolicy {
  static ReviewCardState next(
    ReviewCardState state,
    ReviewRating rating,
    DateTime now,
  ) {
    final int reps = state.reps + 1;
    return switch (rating) {
      ReviewRating.again => state.copyWith(
          queueState: ReviewQueueState.relearning,
          lapses: state.lapses + 1,
          reps: reps,
          dueAt: now,
          intervalDays: 0,
          lastReviewedAt: now,
        ),
      ReviewRating.hard => state.copyWith(
          queueState: ReviewQueueState.review,
          reps: reps,
          dueAt: now.add(const Duration(days: 1)),
          intervalDays: 1,
          lastReviewedAt: now,
        ),
      ReviewRating.good => state.copyWith(
          queueState: ReviewQueueState.review,
          reps: reps,
          dueAt: now.add(const Duration(days: 3)),
          intervalDays: 3,
          lastReviewedAt: now,
        ),
      ReviewRating.easy => state.copyWith(
          queueState: ReviewQueueState.review,
          reps: reps,
          dueAt: now.add(const Duration(days: 7)),
          intervalDays: 7,
          lastReviewedAt: now,
        ),
    };
  }
}
