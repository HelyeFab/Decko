// MVP_012 tests: 3-layer option resolution (global → profile → deck), the
// profile repository, true daily limits, and sibling burying / new-card order
// in the due queue.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:decko/data/shared_prefs_study_options_repository.dart';
import 'package:decko/domain/due_queue.dart';
import 'package:decko/domain/learning_item.dart';
import 'package:decko/domain/review_card_state.dart';
import 'package:decko/domain/study_options/daily_study_counts.dart';
import 'package:decko/domain/study_options/study_options.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('3-layer resolution (global → profile → deck)', () {
    test('profile is the base; deck override wins per-field', () {
      const StudyOptions profile =
          StudyOptions(newCardsPerDay: 50, reviewCardsPerDay: 200);
      final EffectiveStudyOptions e = EffectiveStudyOptions.resolve(
          profile, const DeckStudyOptions(reviewCardsPerDay: 10));
      expect(e.newCardsPerDay, 50); // inherited from profile
      expect(e.reviewCardsPerDay, 10); // deck override
    });
  });

  group('profile repository', () {
    const SharedPrefsStudyOptionsRepository repo =
        SharedPrefsStudyOptionsRepository();

    test('listProfiles always starts with the global-backed default', () async {
      await repo.saveGlobalOptions(const StudyOptions(newCardsPerDay: 7));
      final List<StudyOptionProfile> list = await repo.listProfiles();
      expect(list.first.isDefault, isTrue);
      expect(list.first.options.newCardsPerDay, 7);
    });

    test('a deck assigned a profile resolves through it', () async {
      await repo.saveProfile(const StudyOptionProfile(
          id: 'intense',
          name: 'Intense',
          options: StudyOptions(newCardsPerDay: 99)));
      await repo.saveDeckOptions(
          'd', const DeckStudyOptions(profileId: 'intense'));
      final EffectiveStudyOptions e = await repo.getEffectiveOptions('d');
      expect(e.newCardsPerDay, 99);
    });

    test('deck override beats the assigned profile', () async {
      await repo.saveProfile(const StudyOptionProfile(
          id: 'p', name: 'P', options: StudyOptions(newCardsPerDay: 99)));
      await repo.saveDeckOptions('d',
          const DeckStudyOptions(profileId: 'p', newCardsPerDay: 3));
      final EffectiveStudyOptions e = await repo.getEffectiveOptions('d');
      expect(e.newCardsPerDay, 3);
    });

    test('deleting an assigned profile falls back to global', () async {
      await repo.saveGlobalOptions(const StudyOptions(newCardsPerDay: 20));
      await repo.saveProfile(const StudyOptionProfile(
          id: 'x', name: 'X', options: StudyOptions(newCardsPerDay: 99)));
      await repo.saveDeckOptions('d', const DeckStudyOptions(profileId: 'x'));
      await repo.deleteProfile('x');
      final EffectiveStudyOptions e = await repo.getEffectiveOptions('d');
      expect(e.newCardsPerDay, 20);
    });

    test('the default profile cannot be deleted', () async {
      await repo.deleteProfile(StudyOptionProfile.defaultId);
      final List<StudyOptionProfile> list = await repo.listProfiles();
      expect(list.any((StudyOptionProfile p) => p.isDefault), isTrue);
    });
  });

  group('true daily limits', () {
    final DateTime today = DateTime(2026, 6, 20);

    test('remaining drops as cards are studied; resets the next day', () {
      DailyStudyCounts c = DailyStudyCounts.empty(today)
          .record(isNew: true)
          .record(isNew: true)
          .record(isNew: false);
      expect(c.newStudied, 2);
      expect(c.reviewStudied, 1);
      expect(c.remainingNew(20), 18);
      expect(c.remainingReview(200), 199);
      // same day keeps the tally; a new day zeroes it
      expect(c.forDay(today).newStudied, 2);
      expect(c.forDay(DateTime(2026, 6, 21)).newStudied, 0);
    });

    test('a second same-day session offers only the remaining new cards', () {
      final List<LearningItem> items = <LearningItem>[
        for (final String id in <String>['a', 'b', 'c', 'd', 'e'])
          LearningItem(id: id, front: id, back: id),
      ];
      const Map<String, ReviewCardState> states = <String, ReviewCardState>{};
      // Limit 4/day; 3 already studied today → 1 remaining this session.
      DailyStudyCounts c = DailyStudyCounts.empty(today)
          .record(isNew: true)
          .record(isNew: true)
          .record(isNew: true);
      final List<LearningItem> session = DueQueue.build(items, states, today,
          maxNew: c.remainingNew(4));
      expect(session, hasLength(1));
      // Next day the allowance resets.
      final List<LearningItem> tomorrow = DueQueue.build(items, states, today,
          maxNew: c.forDay(DateTime(2026, 6, 21)).remainingNew(4));
      expect(tomorrow, hasLength(4));
    });
  });

  group('sibling burying in the queue', () {
    final List<LearningItem> items = <LearningItem>[
      for (final String id in <String>['a', 'b', 'c', 'd'])
        LearningItem(id: id, front: id, back: id),
    ];
    const Map<String, ReviewCardState> states = <String, ReviewCardState>{};
    // a & b share note n1; c is n2; d has no known note.
    const Map<String, String> noteMap = <String, String>{
      'a': 'n1',
      'b': 'n1',
      'c': 'n2',
    };
    final DateTime now = DateTime(2026, 6, 20);

    List<String> ids(List<LearningItem> q) =>
        q.map((LearningItem i) => i.id).toList();

    test('only one card per note enters a session; unknown notes are kept', () {
      final List<LearningItem> q = DueQueue.build(items, states, now,
          buryByNote: true, noteIdByItemId: noteMap);
      expect(ids(q), containsAll(<String>['a', 'c', 'd']));
      expect(ids(q), isNot(contains('b'))); // sibling of a, buried
    });

    test('cards whose note was studied earlier today are buried', () {
      final List<LearningItem> q = DueQueue.build(items, states, now,
          buryByNote: true,
          noteIdByItemId: noteMap,
          studiedNotesToday: <String>{'n2'});
      expect(ids(q), containsAll(<String>['a', 'd']));
      expect(ids(q), isNot(contains('b'))); // sibling
      expect(ids(q), isNot(contains('c'))); // note studied today
    });

    test('burying disabled keeps every card', () {
      final List<LearningItem> q = DueQueue.build(items, states, now,
          buryByNote: false, noteIdByItemId: noteMap);
      expect(q, hasLength(4));
    });
  });

  group('new-card order', () {
    final List<LearningItem> items = <LearningItem>[
      for (final String id in <String>['a', 'b', 'c', 'd', 'e'])
        LearningItem(id: id, front: id, back: id),
    ];
    const Map<String, ReviewCardState> states = <String, ReviewCardState>{};
    final DateTime now = DateTime(2026, 6, 20);

    test('deck order preserves the deck sequence', () {
      final List<LearningItem> q = DueQueue.build(items, states, now);
      expect(q.map((LearningItem i) => i.id),
          <String>['a', 'b', 'c', 'd', 'e']);
    });

    test('random keeps the same set of new cards', () {
      final List<LearningItem> q = DueQueue.build(items, states, now,
          newCardOrder: NewCardOrder.random, random: Random(42));
      expect(q.map((LearningItem i) => i.id).toSet(),
          <String>{'a', 'b', 'c', 'd', 'e'});
    });
  });
}
