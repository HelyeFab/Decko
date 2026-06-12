// Pure (no Flutter) unit tests for the simple review scheduler + session model.

import 'package:flutter_test/flutter_test.dart';

import 'package:decko/data/simple_review_scheduler.dart';
import 'package:decko/domain/deck.dart';
import 'package:decko/domain/learning_item.dart';
import 'package:decko/domain/progress_snapshot.dart';
import 'package:decko/domain/review_rating.dart';
import 'package:decko/domain/review_session.dart';
import 'package:decko/domain/review_session_result.dart';

ReviewSessionResult _result(int total, {int good = 0, int again = 0}) =>
    ReviewSessionResult(
      deckId: 'd',
      totalCards: total,
      againCount: again,
      hardCount: 0,
      goodCount: good,
      easyCount: 0,
    );

Deck _deck(int count) => Deck(
      id: 'd',
      name: 'Test deck',
      description: '',
      items: <LearningItem>[
        for (int i = 0; i < count; i++)
          LearningItem(id: 'i$i', front: 'f$i', back: 'b$i'),
      ],
    );

final DateTime _at = DateTime(2026, 6, 12, 10);

void main() {
  const SimpleReviewScheduler scheduler = SimpleReviewScheduler();

  test('createSession starts at the first card with no answers', () {
    final ReviewSession s = scheduler.createSession(deck: _deck(3));

    expect(s.total, 3);
    expect(s.currentIndex, 0);
    expect(s.cardNumber, 1);
    expect(s.isComplete, isFalse);
    expect(s.currentItem?.id, 'i0');
    expect(s.answers, isEmpty);
    expect(s.progress, 0);
  });

  test('answering advances the card and records the answer in order', () {
    ReviewSession s = scheduler.createSession(deck: _deck(2));

    s = scheduler.answerCurrentCard(
        session: s, rating: ReviewRating.good, answeredAt: _at);
    expect(s.currentIndex, 1);
    expect(s.cardNumber, 2);
    expect(s.currentItem?.id, 'i1');
    expect(s.answers.single.itemId, 'i0');
    expect(s.answers.single.rating, ReviewRating.good);
    expect(s.progress, 0.5);
    expect(s.isComplete, isFalse);

    s = scheduler.answerCurrentCard(
        session: s, rating: ReviewRating.again, answeredAt: _at);
    expect(s.isComplete, isTrue);
    expect(s.currentItem, isNull);
    expect(s.answers.map((a) => a.itemId), <String>['i0', 'i1']);
  });

  test('completeSession tallies counts per rating', () {
    ReviewSession s = scheduler.createSession(deck: _deck(4));
    for (final ReviewRating r in <ReviewRating>[
      ReviewRating.again,
      ReviewRating.good,
      ReviewRating.good,
      ReviewRating.easy,
    ]) {
      s = scheduler.answerCurrentCard(session: s, rating: r, answeredAt: _at);
    }

    final ReviewSessionResult result = scheduler.completeSession(s);
    expect(result.totalCards, 4);
    expect(result.againCount, 1);
    expect(result.hardCount, 0);
    expect(result.goodCount, 2);
    expect(result.easyCount, 1);
  });

  test('an empty deck yields an empty, already-complete session', () {
    final ReviewSession s = scheduler.createSession(deck: _deck(0));

    expect(s.isEmpty, isTrue);
    expect(s.isComplete, isTrue);
    expect(s.currentItem, isNull);

    // Answering a card that doesn't exist is a no-op.
    final ReviewSession after = scheduler.answerCurrentCard(
        session: s, rating: ReviewRating.good, answeredAt: _at);
    expect(after.answers, isEmpty);
    expect(after.currentIndex, 0);
  });

  group('ProgressSnapshot.recordingSession', () {
    final DateTime mon = DateTime(2026, 6, 8, 9);
    final DateTime monLater = DateTime(2026, 6, 8, 20);
    final DateTime tue = DateTime(2026, 6, 9, 9);
    final DateTime thu = DateTime(2026, 6, 11, 9);

    test('first session: +10 XP/card, streak 1, today = cards', () {
      final ProgressSnapshot s =
          ProgressSnapshot.empty.recordingSession(_result(3, good: 3), mon);

      expect(s.totalXp, 30);
      expect(s.currentLevel, 1);
      expect(s.currentStreakDays, 1);
      expect(s.cardsReviewedToday, 3);
      expect(s.lastReviewedAt, mon);
      expect(s.hasProgress, isTrue);
      expect(s.lastSessionResult?.totalCards, 3);
    });

    test('same day: XP and today accumulate, streak unchanged', () {
      ProgressSnapshot s =
          ProgressSnapshot.empty.recordingSession(_result(3, good: 3), mon);
      s = s.recordingSession(_result(2, good: 2), monLater);

      expect(s.totalXp, 50);
      expect(s.cardsReviewedToday, 5);
      expect(s.currentStreakDays, 1);
    });

    test('consecutive day: streak increments, today resets', () {
      ProgressSnapshot s =
          ProgressSnapshot.empty.recordingSession(_result(3, good: 3), mon);
      s = s.recordingSession(_result(4, good: 4), tue);

      expect(s.currentStreakDays, 2);
      expect(s.cardsReviewedToday, 4);
      expect(s.totalXp, 70);
    });

    test('gap of more than a day: streak resets to 1', () {
      ProgressSnapshot s =
          ProgressSnapshot.empty.recordingSession(_result(3, good: 3), mon);
      s = s.recordingSession(_result(1, good: 1), thu); // Mon -> Thu

      expect(s.currentStreakDays, 1);
      expect(s.cardsReviewedToday, 1);
    });

    test('level rolls over every 100 XP', () {
      ProgressSnapshot s = ProgressSnapshot.empty;
      // 11 cards * 10 = 110 XP in one session.
      s = s.recordingSession(_result(11, good: 11), mon);
      expect(s.totalXp, 110);
      expect(s.currentLevel, 2);
      expect(s.xpIntoLevel, 10);
    });
  });
}
