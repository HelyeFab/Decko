// Pure tests for study options (MVP_011): defaults, override resolution,
// furigana preference, serialization, and due-queue session caps.

import 'package:flutter_test/flutter_test.dart';

import 'package:decko/domain/due_queue.dart';
import 'package:decko/domain/learning_item.dart';
import 'package:decko/domain/review_card_state.dart';
import 'package:decko/domain/study_options/study_options.dart';

void main() {
  group('effective option resolution', () {
    const StudyOptions global = StudyOptions(
      newCardsPerDay: 20,
      reviewCardsPerDay: 200,
      maxSessionCards: 100,
      audioAutoplayMode: AudioAutoplayMode.off,
      imageDisplayMode: ImageDisplayMode.withQuestion,
    );

    test('no deck override → effective equals global', () {
      final EffectiveStudyOptions e =
          EffectiveStudyOptions.resolve(global, null);
      expect(e.newCardsPerDay, 20);
      expect(e.reviewCardsPerDay, 200);
      expect(e.maxSessionCards, 100);
      expect(e.audioAutoplayMode, AudioAutoplayMode.off);
      expect(e.imageDisplayMode, ImageDisplayMode.withQuestion);
      expect(e.furiganaPreference, FuriganaPreference.useGlobal);
    });

    test('deck override wins where set; unset falls back to global', () {
      const DeckStudyOptions deck = DeckStudyOptions(
        newCardsPerDay: 5,
        audioAutoplayMode: AudioAutoplayMode.beforeQuestion,
        // reviewCardsPerDay / maxSessionCards / imageDisplayMode unset
      );
      final EffectiveStudyOptions e =
          EffectiveStudyOptions.resolve(global, deck);
      expect(e.newCardsPerDay, 5); // overridden
      expect(e.audioAutoplayMode, AudioAutoplayMode.beforeQuestion); // overridden
      expect(e.reviewCardsPerDay, 200); // global
      expect(e.maxSessionCards, 100); // global
      expect(e.imageDisplayMode, ImageDisplayMode.withQuestion); // global
    });
  });

  group('furigana preference', () {
    EffectiveStudyOptions withPref(FuriganaPreference p) =>
        EffectiveStudyOptions.resolve(
            StudyOptions.defaults, DeckStudyOptions(furiganaPreference: p));

    test('useGlobal follows the global toggle', () {
      final EffectiveStudyOptions e = withPref(FuriganaPreference.useGlobal);
      expect(e.resolveShowFurigana(true), isTrue);
      expect(e.resolveShowFurigana(false), isFalse);
    });

    test('alwaysShow / alwaysHide ignore the global toggle', () {
      expect(withPref(FuriganaPreference.alwaysShow).resolveShowFurigana(false),
          isTrue);
      expect(withPref(FuriganaPreference.alwaysHide).resolveShowFurigana(true),
          isFalse);
    });
  });

  group('serialization', () {
    test('global options round-trip', () {
      const StudyOptions o = StudyOptions(
        newCardsPerDay: 7,
        reviewCardsPerDay: 99,
        maxSessionCards: 42,
        audioAutoplayMode: AudioAutoplayMode.afterReveal,
        imageDisplayMode: ImageDisplayMode.afterReveal,
        burySiblingsUntilTomorrow: true,
      );
      final StudyOptions r = StudyOptions.fromMap(o.toMap());
      expect(r.newCardsPerDay, 7);
      expect(r.reviewCardsPerDay, 99);
      expect(r.maxSessionCards, 42);
      expect(r.audioAutoplayMode, AudioAutoplayMode.afterReveal);
      expect(r.imageDisplayMode, ImageDisplayMode.afterReveal);
      expect(r.burySiblingsUntilTomorrow, isTrue);
    });

    test('deck options round-trip preserves unset (null) fields', () {
      const DeckStudyOptions o = DeckStudyOptions(
        newCardsPerDay: 3,
        furiganaPreference: FuriganaPreference.alwaysShow,
      );
      final DeckStudyOptions r = DeckStudyOptions.fromMap(o.toMap());
      expect(r.newCardsPerDay, 3);
      expect(r.reviewCardsPerDay, isNull); // unset stays null
      expect(r.audioAutoplayMode, isNull);
      expect(r.furiganaPreference, FuriganaPreference.alwaysShow);
    });
  });

  group('due-queue session caps', () {
    // a–e are due review cards; f–j are new cards.
    final List<LearningItem> items = <LearningItem>[
      for (final String id in <String>['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'])
        LearningItem(id: id, front: id, back: id),
    ];
    final Map<String, ReviewCardState> states = <String, ReviewCardState>{
      for (final String id in <String>['a', 'b', 'c', 'd', 'e'])
        id: ReviewCardState(
          deckId: 'd',
          itemId: id,
          queueState: ReviewQueueState.review,
          reps: 1,
          dueAt: DateTime(2020),
        ),
    };
    final DateTime now = DateTime(2026, 6, 20);

    test('no caps → every due review + new card is queued', () {
      expect(DueQueue.build(items, states, now), hasLength(10));
    });

    test('maxReview caps due review cards', () {
      final List<LearningItem> q =
          DueQueue.build(items, states, now, maxReview: 2);
      // 2 review + 5 new = 7
      expect(q, hasLength(7));
      expect(q.take(2).map((i) => i.id), <String>['a', 'b']);
    });

    test('maxNew caps new cards', () {
      final List<LearningItem> q =
          DueQueue.build(items, states, now, maxNew: 3);
      expect(q, hasLength(8)); // 5 review + 3 new
    });

    test('maxSession caps the final total', () {
      final List<LearningItem> q =
          DueQueue.build(items, states, now, maxSession: 4);
      expect(q, hasLength(4));
    });

    test('all three caps combine', () {
      final List<LearningItem> q = DueQueue.build(items, states, now,
          maxReview: 2, maxNew: 3, maxSession: 4);
      // 2 review + 3 new = 5, then capped to 4
      expect(q, hasLength(4));
    });
  });
}
