import '../domain/deck.dart';
import '../domain/learning_item.dart';
import '../domain/repositories/review_scheduler.dart';
import '../domain/review_answer.dart';
import '../domain/review_rating.dart';
import '../domain/review_session.dart';
import '../domain/review_session_result.dart';

/// A deliberately minimal [ReviewScheduler].
///
/// It walks the deck's cards in order, one answer at a time, and tallies the
/// ratings at the end. No intervals, due dates, stability/difficulty or
/// persistence (all MVP_003 non-goals) — this is the placeholder that a real
/// FSRS scheduler replaces behind the same interface (DEC-003).
class SimpleReviewScheduler implements ReviewScheduler {
  const SimpleReviewScheduler();

  @override
  ReviewSession createSession({required Deck deck}) {
    return ReviewSession(
      deckId: deck.id,
      items: List<LearningItem>.unmodifiable(deck.items),
    );
  }

  @override
  ReviewSession answerCurrentCard({
    required ReviewSession session,
    required ReviewRating rating,
    required DateTime answeredAt,
  }) {
    final LearningItem? current = session.currentItem;
    if (current == null) return session; // nothing to answer

    return session.copyWith(
      currentIndex: session.currentIndex + 1,
      answers: <ReviewAnswer>[
        ...session.answers,
        ReviewAnswer(
          itemId: current.id,
          rating: rating,
          answeredAt: answeredAt,
        ),
      ],
    );
  }

  @override
  ReviewSessionResult completeSession(ReviewSession session) {
    return ReviewSessionResult.fromAnswers(
      deckId: session.deckId,
      answers: session.answers,
    );
  }
}
