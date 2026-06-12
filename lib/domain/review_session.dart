import 'learning_item.dart';
import 'review_answer.dart';

/// The in-memory state of one local review session over a deck's items.
///
/// Immutable: progress is made by producing a new session via [copyWith]
/// (the [ReviewScheduler] owns those transitions). No scheduling, due dates or
/// persistence live here — this is purely session position + recorded answers.
class ReviewSession {
  const ReviewSession({
    required this.deckId,
    required this.items,
    this.currentIndex = 0,
    this.answers = const <ReviewAnswer>[],
  });

  final String deckId;
  final List<LearningItem> items;

  /// Index of the card currently being reviewed.
  final int currentIndex;

  /// Answers recorded so far, in order.
  final List<ReviewAnswer> answers;

  int get total => items.length;

  /// True when there are no cards to review.
  bool get isEmpty => items.isEmpty;

  /// True once every card has been answered.
  bool get isComplete => currentIndex >= total;

  /// The card currently being shown, or null if the session is complete/empty.
  LearningItem? get currentItem =>
      isComplete || isEmpty ? null : items[currentIndex];

  /// 1-based position of the current card (e.g. "Card 2 of 5").
  int get cardNumber => currentIndex + 1;

  /// Fraction of the deck answered so far, in [0, 1].
  double get progress => total == 0 ? 0 : answers.length / total;

  ReviewSession copyWith({
    int? currentIndex,
    List<ReviewAnswer>? answers,
  }) {
    return ReviewSession(
      deckId: deckId,
      items: items,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
    );
  }
}
