import 'dart:math';

import 'learning_item.dart';
import 'review_card_state.dart';
import 'study_options/study_options.dart';

/// Builds the ordered list of cards to study for a session.
///
/// Pure and deterministic (given a fixed [random]). A card is included when it
/// is not suspended and is either due for review or still new. Ordering: due
/// review/relearning cards first, then due learning cards, then new cards —
/// each preserving the deck's original order (DEC-011).
///
/// Optional caps (MVP_011, DEC-020) limit a session without touching any card's
/// state: [maxReview] caps due review cards, [maxNew] caps new cards, and
/// [maxSession] caps the final total. Nulls mean "no limit".
///
/// Sibling burying (MVP_012, DEC-021): when [buryByNote] is set, cards are keyed
/// to a source note via [noteIdByItemId]; any whose note is in
/// [studiedNotesToday] (already studied earlier today) is dropped, and within
/// this build only the first card per note is kept (so same-session siblings
/// collapse to one). Cards with no known note id are never buried. Burying never
/// changes card state — it only filters which cards enter the session.
/// [newCardOrder] controls new-card sequencing ([random] required for shuffle).
abstract final class DueQueue {
  static List<LearningItem> build(
    List<LearningItem> items,
    Map<String, ReviewCardState> statesById,
    DateTime now, {
    int? maxNew,
    int? maxReview,
    int? maxSession,
    NewCardOrder newCardOrder = NewCardOrder.deckOrder,
    Random? random,
    Map<String, String> noteIdByItemId = const <String, String>{},
    Set<String> studiedNotesToday = const <String>{},
    bool buryByNote = false,
  }) {
    final List<LearningItem> dueReview = <LearningItem>[];
    final List<LearningItem> dueLearning = <LearningItem>[];
    List<LearningItem> newCards = <LearningItem>[];

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

    // Sibling burying: one card per note, and none whose note was studied today.
    // Process review → learning → new so a due review beats a new sibling.
    List<LearningItem> review = dueReview;
    List<LearningItem> learning = dueLearning;
    if (buryByNote) {
      final Set<String> seen = <String>{...studiedNotesToday};
      List<LearningItem> bury(List<LearningItem> list) => list.where((i) {
            final String? nid = noteIdByItemId[i.id];
            if (nid == null) return true; // unknown note → can't bury
            if (seen.contains(nid)) return false;
            seen.add(nid);
            return true;
          }).toList();
      review = bury(dueReview);
      learning = bury(dueLearning);
      newCards = bury(newCards);
    }

    if (newCardOrder == NewCardOrder.random && random != null) {
      newCards = List<LearningItem>.of(newCards)..shuffle(random);
    }

    final List<LearningItem> queue = <LearningItem>[
      ..._cap(review, maxReview),
      ...learning,
      ..._cap(newCards, maxNew),
    ];
    return _cap(queue, maxSession);
  }

  static List<LearningItem> _cap(List<LearningItem> items, int? max) {
    if (max == null || max < 0 || items.length <= max) return items;
    return items.sublist(0, max);
  }
}
