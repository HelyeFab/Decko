// MVP_017: practice-mode registry availability, the outcome→motivation seam,
// and the review-state boundary (practice never touches review fields).

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:decko/data/decko_practice_mode_registry.dart';
import 'package:decko/data/shared_prefs_progress_repository.dart';
import 'package:decko/domain/deck.dart';
import 'package:decko/domain/learning_item.dart';
import 'package:decko/domain/practice/practice_mode.dart';
import 'package:decko/domain/practice/practice_outcome.dart';
import 'package:decko/domain/progress_snapshot.dart';

LearningItem _item(String id, {String? example}) =>
    LearningItem(id: id, front: id, back: 'b', example: example);

Deck _deck(List<LearningItem> items) =>
    Deck(id: 'd', name: 'D', description: '', items: items);

PracticeOutcome _outcome({int correct = 2, int wrong = 0, int xp = 10}) =>
    PracticeOutcome(
      modeId: PracticeModeId.bunburuSentenceBuilder,
      deckId: 'd',
      itemId: 'i',
      startedAt: DateTime(2026, 1, 1, 0, 0),
      completedAt: DateTime(2026, 1, 1, 0, 1),
      correctCount: correct,
      incorrectCount: wrong,
      xpAwarded: xp,
    );

void main() {
  group('DeckoPracticeModeRegistry (MVP_017)', () {
    const DeckoPracticeModeRegistry registry = DeckoPracticeModeRegistry();

    test('Bunburu is available for a sentence-capable card', () {
      final List<PracticeMode> modes =
          registry.availableForCard(_item('a', example: 'one two three'));
      expect(modes, hasLength(1));
      expect(modes.first.id, PracticeModeId.bunburuSentenceBuilder);
    });

    test('no modes for a card without a sentence', () {
      expect(registry.availableForCard(_item('a')), isEmpty);
    });

    test('availableForDeck reflects whether any card is capable', () {
      expect(
          registry.availableForDeck(
              _deck(<LearningItem>[_item('a', example: 'one two')])),
          hasLength(1));
      expect(registry.availableForDeck(_deck(<LearningItem>[_item('a')])),
          isEmpty);
    });

    test('Bunburu is both a manual mode and a review presentation', () {
      final LearningItem item = _item('a', example: 'one two three');
      expect(registry.manualModesForCard(item), hasLength(1));
      expect(registry.reviewPresentationModesForCard(item), hasLength(1));
    });
  });

  group('practice outcome → motivation seam (MVP_017)', () {
    test('recordingPractice adds practice XP/count, never review fields', () {
      final ProgressSnapshot s = ProgressSnapshot(
        totalXp: 100,
        currentStreakDays: 3,
        longestStreakDays: 4,
        cardsReviewedToday: 5,
        lastReviewedAt: DateTime(2026, 6, 22),
      );
      final ProgressSnapshot p = s.recordingPractice(15);

      expect(p.practiceXp, 15);
      expect(p.practiceCount, 1);
      expect(p.combinedXp, 115); // counts toward level
      // Review-derived state is untouched.
      expect(p.totalXp, 100);
      expect(p.currentStreakDays, 3);
      expect(p.cardsReviewedToday, 5);
      expect(p.totalCardsReviewed, 10); // still 100/10, unaffected by practice
    });

    test('PracticeOutcome round-trips through JSON', () {
      final PracticeOutcome r =
          PracticeOutcome.fromJson(_outcome(correct: 3, wrong: 1).toJson());
      expect(r.modeId, PracticeModeId.bunburuSentenceBuilder);
      expect(r.xpAwarded, 10);
      expect(r.total, 4);
      expect(r.allCorrect, isFalse);
    });

    test('recordPracticeOutcome persists XP without touching review state',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPrefsProgressRepository repo = SharedPrefsProgressRepository(
        clock: () => DateTime(2026, 6, 22),
      );
      await repo.recordPracticeOutcome(_outcome(xp: 25));
      final ProgressSnapshot s = await repo.getSnapshot();
      expect(s.practiceXp, 25);
      expect(s.practiceCount, 1);
      expect(s.totalXp, 0); // no review happened
      expect(s.cardsReviewedToday, 0);
      expect(s.lastReviewedAt, isNull); // practice didn't record a review
      expect(s.combinedXp, 25); // but practice XP counts toward level
    });
  });
}
