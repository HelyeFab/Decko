import 'review_card_state.dart';
import 'review_rating.dart';

/// Computes the next [ReviewCardState] for a graded card.
///
/// The seam between the review UI and the scheduling maths: the UI calls
/// [next] and persists the result; it never contains scheduling logic itself
/// (DEC-011 / DEC-013). [now] is injected so implementations stay deterministic
/// and unit-testable.
abstract class ReviewSchedulingPolicy {
  const ReviewSchedulingPolicy();

  ReviewCardState next(ReviewCardState state, ReviewRating rating, DateTime now);
}
