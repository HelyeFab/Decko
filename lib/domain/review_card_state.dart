import 'import/imported_card_state.dart';
import 'learning_item.dart';

/// The scheduling bucket a card currently sits in.
enum ReviewQueueState { newCard, learning, review, relearning, suspended }

/// Persistent, per-card local review state.
///
/// Framework-light. This is Decko's neutral scheduling state — populated from
/// imported Anki progress on import, then advanced by the (temporary)
/// [ReviewSchedulingPolicy] as the user grades cards. It is FSRS-ready: a real
/// scheduler can read/write the same fields without any UI change (DEC-011).
class ReviewCardState {
  const ReviewCardState({
    required this.deckId,
    required this.itemId,
    required this.queueState,
    this.dueAt,
    this.reps = 0,
    this.lapses = 0,
    this.intervalDays = 0,
    this.easeFactor,
    this.lastReviewedAt,
    this.sourceSystem = 'decko',
  });

  /// A fresh, never-studied card.
  factory ReviewCardState.newCard({
    required String deckId,
    required String itemId,
    String sourceSystem = 'decko',
  }) =>
      ReviewCardState(
        deckId: deckId,
        itemId: itemId,
        queueState: ReviewQueueState.newCard,
        sourceSystem: sourceSystem,
      );

  /// Initial state for an imported item: maps preserved Anki progress when the
  /// user kept it, otherwise starts the card new.
  factory ReviewCardState.fromLearningItem(String deckId, LearningItem item) {
    final p = item.importedProgress;
    if (p == null) {
      return ReviewCardState.newCard(
          deckId: deckId, itemId: item.id, sourceSystem: 'anki');
    }
    return ReviewCardState(
      deckId: deckId,
      itemId: item.id,
      queueState: _fromImported(p.state),
      dueAt: p.dueAt,
      reps: p.reps ?? 0,
      lapses: p.lapses ?? 0,
      intervalDays: p.intervalDays ?? 0,
      easeFactor: p.easeFactor,
      lastReviewedAt: p.lastReviewedAt,
      sourceSystem: 'anki',
    );
  }

  final String deckId;
  final String itemId;
  final ReviewQueueState queueState;
  final DateTime? dueAt;
  final int reps;
  final int lapses;
  final int intervalDays;
  final double? easeFactor;
  final DateTime? lastReviewedAt;
  final String sourceSystem;

  bool get isSuspended => queueState == ReviewQueueState.suspended;
  bool get isNew => queueState == ReviewQueueState.newCard;
  bool get hasBeenReviewed =>
      reps > 0 ||
      queueState == ReviewQueueState.review ||
      queueState == ReviewQueueState.relearning;

  /// A review/learning card that is due now (new cards are "available", not due).
  bool isDueForReview(DateTime now) {
    if (isSuspended || isNew) return false;
    return dueAt == null || !dueAt!.isAfter(now);
  }

  ReviewCardState copyWith({
    ReviewQueueState? queueState,
    DateTime? dueAt,
    int? reps,
    int? lapses,
    int? intervalDays,
    double? easeFactor,
    DateTime? lastReviewedAt,
  }) {
    return ReviewCardState(
      deckId: deckId,
      itemId: itemId,
      queueState: queueState ?? this.queueState,
      dueAt: dueAt ?? this.dueAt,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      intervalDays: intervalDays ?? this.intervalDays,
      easeFactor: easeFactor ?? this.easeFactor,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      sourceSystem: sourceSystem,
    );
  }

  static ReviewQueueState _fromImported(ImportedCardState s) => switch (s) {
        ImportedCardState.isNew => ReviewQueueState.newCard,
        ImportedCardState.learning => ReviewQueueState.learning,
        ImportedCardState.review => ReviewQueueState.review,
        ImportedCardState.relearning => ReviewQueueState.relearning,
        ImportedCardState.suspended => ReviewQueueState.suspended,
      };
}
