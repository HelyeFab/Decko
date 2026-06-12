import 'review_answer.dart';
import 'review_rating.dart';

/// A summary of a finished review session: how many cards were graded at each
/// level. Derived from the recorded answers; holds no scheduling outcome.
class ReviewSessionResult {
  const ReviewSessionResult({
    required this.deckId,
    required this.totalCards,
    required this.againCount,
    required this.hardCount,
    required this.goodCount,
    required this.easyCount,
  });

  /// Builds a result by tallying [answers] for the given deck.
  factory ReviewSessionResult.fromAnswers({
    required String deckId,
    required List<ReviewAnswer> answers,
  }) {
    int again = 0, hard = 0, good = 0, easy = 0;
    for (final ReviewAnswer answer in answers) {
      switch (answer.rating) {
        case ReviewRating.again:
          again++;
        case ReviewRating.hard:
          hard++;
        case ReviewRating.good:
          good++;
        case ReviewRating.easy:
          easy++;
      }
    }
    return ReviewSessionResult(
      deckId: deckId,
      totalCards: answers.length,
      againCount: again,
      hardCount: hard,
      goodCount: good,
      easyCount: easy,
    );
  }

  final String deckId;
  final int totalCards;
  final int againCount;
  final int hardCount;
  final int goodCount;
  final int easyCount;

  /// Count for a given rating — handy for rendering the summary uniformly.
  int countFor(ReviewRating rating) => switch (rating) {
        ReviewRating.again => againCount,
        ReviewRating.hard => hardCount,
        ReviewRating.good => goodCount,
        ReviewRating.easy => easyCount,
      };
}
