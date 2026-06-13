// Unit tests for the due-queue, scheduling policy, state mapping, and the
// review-state repository.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:decko/data/fsrs_scheduling_policy.dart';
import 'package:decko/data/shared_prefs_review_state_repository.dart';
import 'package:decko/domain/due_queue.dart';
import 'package:decko/domain/import/imported_card_progress.dart';
import 'package:decko/domain/import/imported_card_state.dart';
import 'package:decko/domain/learning_item.dart';
import 'package:decko/domain/review_card_state.dart';
import 'package:decko/domain/review_rating.dart';

final DateTime _now = DateTime(2026, 6, 12, 10);

LearningItem _item(String id) => LearningItem(id: id, front: id, back: id);

void main() {
  group('FsrsSchedulingPolicy', () {
    const FsrsSchedulingPolicy fsrs = FsrsSchedulingPolicy();
    final ReviewCardState fresh =
        ReviewCardState.newCard(deckId: 'd', itemId: 'a');

    test('new + Good schedules into the future as review, sets FSRS fields', () {
      final ReviewCardState s = fsrs.next(fresh, ReviewRating.good, _now);
      expect(s.queueState, ReviewQueueState.review);
      expect(s.reps, 1);
      expect(s.intervalDays, greaterThanOrEqualTo(1));
      expect(s.dueAt!.isAfter(_now), isTrue);
      expect(s.isDueForReview(_now), isFalse);
      expect(s.stability, isNotNull);
      expect(s.difficulty, inInclusiveRange(1.0, 10.0));
      expect(s.schedulerVersion, 'fsrs-5');
    });

    test('new + Again → relearning, lapses+1, still scheduled (>=1 day)', () {
      final ReviewCardState s = fsrs.next(fresh, ReviewRating.again, _now);
      expect(s.queueState, ReviewQueueState.relearning);
      expect(s.lapses, 1);
      expect(s.intervalDays, greaterThanOrEqualTo(1));
    });

    test('Easy schedules farther than Good, which is farther than Hard', () {
      final int hard = fsrs.next(fresh, ReviewRating.hard, _now).intervalDays;
      final int good = fsrs.next(fresh, ReviewRating.good, _now).intervalDays;
      final int easy = fsrs.next(fresh, ReviewRating.easy, _now).intervalDays;
      expect(hard, lessThanOrEqualTo(good));
      expect(good, lessThan(easy));
    });

    test('reviewing an established card again grows its interval', () {
      // A card reviewed a while ago; review it now with Good.
      final ReviewCardState established = ReviewCardState(
        deckId: 'd',
        itemId: 'a',
        queueState: ReviewQueueState.review,
        reps: 3,
        intervalDays: 10,
        stability: 10,
        difficulty: 5,
        lastReviewedAt: _now.subtract(const Duration(days: 10)),
      );
      final ReviewCardState s = fsrs.next(established, ReviewRating.good, _now);
      expect(s.intervalDays, greaterThan(10));
      expect(s.stability!, greaterThan(10));
    });

    test('imported reviewed card is seeded, not reset (progress preserved)', () {
      final ReviewCardState imported = ReviewCardState(
        deckId: 'd',
        itemId: 'a',
        queueState: ReviewQueueState.review,
        reps: 8,
        lapses: 1,
        intervalDays: 30,
        easeFactor: 2.5,
        lastReviewedAt: _now.subtract(const Duration(days: 30)),
        // no stability/difficulty yet
      );
      final ReviewCardState s = fsrs.next(imported, ReviewRating.good, _now);
      expect(s.reps, 9); // not reset to new
      expect(s.queueState, ReviewQueueState.review);
      expect(s.intervalDays, greaterThanOrEqualTo(1));
      expect(s.stability, isNotNull);
    });
  });

  group('DueQueue.build', () {
    test('orders due review, then due learning, then new; excludes suspended '
        'and future', () {
      final List<LearningItem> items = <LearningItem>[
        _item('new1'),
        _item('reviewDue'),
        _item('suspended'),
        _item('learningDue'),
        _item('reviewFuture'),
        _item('new2'),
      ];
      final Map<String, ReviewCardState> states = <String, ReviewCardState>{
        'reviewDue': ReviewCardState(
            deckId: 'd',
            itemId: 'reviewDue',
            queueState: ReviewQueueState.review,
            dueAt: _now.subtract(const Duration(days: 1))),
        'suspended': ReviewCardState(
            deckId: 'd',
            itemId: 'suspended',
            queueState: ReviewQueueState.suspended),
        'learningDue': ReviewCardState(
            deckId: 'd',
            itemId: 'learningDue',
            queueState: ReviewQueueState.learning,
            dueAt: _now.subtract(const Duration(hours: 1))),
        'reviewFuture': ReviewCardState(
            deckId: 'd',
            itemId: 'reviewFuture',
            queueState: ReviewQueueState.review,
            dueAt: _now.add(const Duration(days: 5))),
        // new1/new2 have no state → treated as new.
      };

      final List<String> ids =
          DueQueue.build(items, states, _now).map((i) => i.id).toList();

      expect(ids, <String>['reviewDue', 'learningDue', 'new1', 'new2']);
    });

    test('all-new deck queues every card', () {
      final List<LearningItem> items =
          <LearningItem>[_item('a'), _item('b'), _item('c')];
      expect(DueQueue.build(items, const <String, ReviewCardState>{}, _now),
          hasLength(3));
    });
  });

  group('ReviewCardState.fromLearningItem', () {
    test('keeps imported progress', () {
      final LearningItem item = LearningItem(
        id: 'x',
        front: 'x',
        back: 'x',
        importedProgress: ImportedCardProgress(
          state: ImportedCardState.review,
          reps: 4,
          lapses: 1,
          intervalDays: 12,
          easeFactor: 2.3,
          dueAt: _now,
        ),
      );
      final ReviewCardState s = ReviewCardState.fromLearningItem('d', item);
      expect(s.queueState, ReviewQueueState.review);
      expect(s.reps, 4);
      expect(s.intervalDays, 12);
      expect(s.sourceSystem, 'anki');
    });

    test('no imported progress → new', () {
      final ReviewCardState s =
          ReviewCardState.fromLearningItem('d', _item('y'));
      expect(s.queueState, ReviewQueueState.newCard);
      expect(s.reps, 0);
    });
  });

  group('SharedPrefsReviewStateRepository', () {
    test('save / load / getState / reset round-trip', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const SharedPrefsReviewStateRepository repo =
          SharedPrefsReviewStateRepository();

      await repo.saveStates(<ReviewCardState>[
        ReviewCardState(
            deckId: 'd',
            itemId: 'a',
            queueState: ReviewQueueState.review,
            reps: 2,
            dueAt: _now),
        ReviewCardState.newCard(deckId: 'd', itemId: 'b'),
      ]);

      final List<ReviewCardState> loaded = await repo.getStatesForDeck('d');
      expect(loaded, hasLength(2));

      final ReviewCardState? a = await repo.getState('d', 'a');
      expect(a!.reps, 2);
      expect(a.queueState, ReviewQueueState.review);
      expect(a.dueAt, _now);

      // Upsert merges rather than duplicating.
      await repo.saveState(a.copyWith(reps: 5));
      expect(await repo.getStatesForDeck('d'), hasLength(2));
      expect((await repo.getState('d', 'a'))!.reps, 5);

      await repo.resetDeckStates('d');
      expect(await repo.getStatesForDeck('d'), isEmpty);
    });
  });
}
