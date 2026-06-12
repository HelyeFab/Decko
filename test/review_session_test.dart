// Pure (no Flutter) unit tests for the simple review scheduler + session model.

import 'package:flutter_test/flutter_test.dart';

import 'package:decko/data/simple_review_scheduler.dart';
import 'package:decko/domain/deck.dart';
import 'package:decko/domain/learning_item.dart';
import 'package:decko/domain/review_rating.dart';
import 'package:decko/domain/review_session.dart';
import 'package:decko/domain/review_session_result.dart';

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
}
