// Unit tests for MVP_015: longest-streak monotonicity, daily-goal maths,
// achievement derivation, and progress serialization (incl. migration).

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:decko/data/shared_prefs_progress_repository.dart';
import 'package:decko/domain/achievement.dart';
import 'package:decko/domain/progress_snapshot.dart';
import 'package:decko/domain/review_session_result.dart';

ReviewSessionResult _result(int cards) => ReviewSessionResult(
      deckId: 'd',
      totalCards: cards,
      againCount: 0,
      hardCount: 0,
      goodCount: cards,
      easyCount: 0,
    );

Map<Achievement, bool> _earned(ProgressSnapshot s, int goal) =>
    <Achievement, bool>{
      for (final AchievementStatus a in achievementsFor(s, goal))
        a.achievement: a.earned,
    };

void main() {
  group('streak (MVP_015)', () {
    test('longestStreakDays is monotonic across a broken streak', () {
      ProgressSnapshot s = ProgressSnapshot.empty;
      s = s.recordingSession(_result(1), DateTime(2026, 6, 1));
      s = s.recordingSession(_result(1), DateTime(2026, 6, 2));
      s = s.recordingSession(_result(1), DateTime(2026, 6, 3));
      expect(s.currentStreakDays, 3);
      expect(s.longestStreakDays, 3);

      // A gap resets the current streak but not the longest.
      s = s.recordingSession(_result(1), DateTime(2026, 6, 10));
      expect(s.currentStreakDays, 1);
      expect(s.longestStreakDays, 3);
    });

    test('reviewedToday reflects whether today already counted', () {
      const ProgressSnapshot none = ProgressSnapshot(cardsReviewedToday: 0);
      const ProgressSnapshot some = ProgressSnapshot(cardsReviewedToday: 4);
      expect(none.reviewedToday, isFalse);
      expect(some.reviewedToday, isTrue);
    });
  });

  group('daily goal (MVP_015)', () {
    test('progress and met derive from cards reviewed today', () {
      const ProgressSnapshot s = ProgressSnapshot(cardsReviewedToday: 10);
      expect(s.dailyGoalProgress(20), 0.5);
      expect(s.dailyGoalMet(20), isFalse);
      expect(const ProgressSnapshot(cardsReviewedToday: 20).dailyGoalMet(20),
          isTrue);
      // Over-goal clamps to 1.0.
      expect(const ProgressSnapshot(cardsReviewedToday: 50).dailyGoalProgress(20),
          1.0);
    });
  });

  group('achievements (MVP_015)', () {
    test('empty progress unlocks nothing', () {
      final Map<Achievement, bool> m = _earned(ProgressSnapshot.empty, 20);
      expect(m.values.every((bool e) => !e), isTrue);
    });

    test('rules: first review, 100 cards, 3-day streak, daily goal', () {
      final ProgressSnapshot s = ProgressSnapshot(
        totalXp: 1000, // 100 cards × 10 XP
        currentStreakDays: 1,
        longestStreakDays: 3,
        cardsReviewedToday: 20,
        lastReviewedAt: DateTime(2026, 6, 20),
      );
      final Map<Achievement, bool> m = _earned(s, 20);
      expect(m[Achievement.firstReview], isTrue);
      expect(m[Achievement.hundredCards], isTrue);
      expect(m[Achievement.threeDayStreak], isTrue);
      expect(m[Achievement.dailyGoal], isTrue);
    });

    test('daily goal stays locked below the goal; 100 cards below threshold', () {
      final ProgressSnapshot s = ProgressSnapshot(
        totalXp: 50,
        longestStreakDays: 1,
        cardsReviewedToday: 3,
        lastReviewedAt: DateTime(2026, 6, 20),
      );
      final Map<Achievement, bool> m = _earned(s, 20);
      expect(m[Achievement.firstReview], isTrue);
      expect(m[Achievement.dailyGoal], isFalse);
      expect(m[Achievement.threeDayStreak], isFalse);
      expect(m[Achievement.hundredCards], isFalse);
    });
  });

  group('progress serialization (MVP_015)', () {
    test('persists and restores longestStreakDays', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPrefsProgressRepository repo = SharedPrefsProgressRepository(
        clock: () => DateTime(2026, 6, 20, 10),
      );
      await repo.recordSessionResult(_result(5));
      final ProgressSnapshot s = await repo.getSnapshot();
      expect(s.totalXp, 50);
      expect(s.currentStreakDays, 1);
      expect(s.longestStreakDays, 1);
    });

    test('back-fills longestStreakDays from currentStreakDays for old blobs',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'decko.progress.snapshot': jsonEncode(<String, dynamic>{
          'totalXp': 400,
          'currentStreakDays': 4,
          'cardsReviewedToday': 2,
          'lastReviewedAt': DateTime(2026, 6, 20).toIso8601String(),
        }),
      });
      final ProgressSnapshot s =
          await const SharedPrefsProgressRepository().getSnapshot();
      expect(s.currentStreakDays, 4);
      expect(s.longestStreakDays, 4); // migrated, not 0
    });
  });
}
