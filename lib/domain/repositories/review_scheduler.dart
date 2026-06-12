import '../deck.dart';
import '../review_rating.dart';
import '../review_session.dart';
import '../review_session_result.dart';

/// The seam through which Decko schedules review.
///
/// MVP_003 ships a trivial queue implementation, but this is the interface a
/// real FSRS scheduler will implement later (DEC-003) — the review UI depends
/// only on this contract, never on scheduling internals. Implementations should
/// be pure: each transition returns a new [ReviewSession] rather than mutating.
abstract class ReviewScheduler {
  /// Starts a session over [deck]'s items.
  ReviewSession createSession({required Deck deck});

  /// Records [rating] for the current card and advances to the next.
  ///
  /// [answeredAt] is supplied by the caller so behaviour stays deterministic.
  ReviewSession answerCurrentCard({
    required ReviewSession session,
    required ReviewRating rating,
    required DateTime answeredAt,
  });

  /// Produces the end-of-session summary.
  ReviewSessionResult completeSession(ReviewSession session);
}
