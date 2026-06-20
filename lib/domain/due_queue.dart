import 'learning_item.dart';
import 'review_card_state.dart';

/// Builds the ordered list of cards to study for a session.
///
/// Pure and deterministic. A card is included when it is not suspended and is
/// either due for review or still new. Ordering: due review/relearning cards
/// first, then due learning cards, then new cards — each preserving the deck's
/// original order (DEC-011).
///
/// Optional caps (MVP_011, DEC-020) limit a session without touching any card's
/// state: [maxReview] caps due review cards, [maxNew] caps new cards, and
/// [maxSession] caps the final total. Due learning cards are always kept (they
/// were already started). Nulls mean "no limit".
abstract final class DueQueue {
  static List<LearningItem> build(
    List<LearningItem> items,
    Map<String, ReviewCardState> statesById,
    DateTime now, {
    int? maxNew,
    int? maxReview,
    int? maxSession,
  }) {
    final List<LearningItem> dueReview = <LearningItem>[];
    final List<LearningItem> dueLearning = <LearningItem>[];
    final List<LearningItem> newCards = <LearningItem>[];

    for (final LearningItem item in items) {
      final ReviewCardState state = statesById[item.id] ??
          ReviewCardState.newCard(deckId: '', itemId: item.id);

      if (state.isSuspended) continue;

      if (state.isNew) {
        newCards.add(item);
      } else if (state.isDueForReview(now)) {
        if (state.queueState == ReviewQueueState.learning) {
          dueLearning.add(item);
        } else {
          dueReview.add(item);
        }
      }
      // Not new, not due → scheduled in the future → skip.
    }

    final List<LearningItem> queue = <LearningItem>[
      ..._cap(dueReview, maxReview),
      ...dueLearning,
      ..._cap(newCards, maxNew),
    ];
    return _cap(queue, maxSession);
  }

  static List<LearningItem> _cap(List<LearningItem> items, int? max) {
    if (max == null || max < 0 || items.length <= max) return items;
    return items.sublist(0, max);
  }
}
