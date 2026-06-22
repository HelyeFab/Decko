import 'dart:math' as math;

import 'review_session_result.dart';

/// A small local snapshot of the learner's progress.
///
/// Framework-light and immutable. The XP / streak / today maths lives in the
/// pure [recordingSession] method so it can be unit-tested deterministically
/// (time is injected, never read from the clock here). Storage/serialisation is
/// the data layer's job, not this model's.
class ProgressSnapshot {
  const ProgressSnapshot({
    this.totalXp = 0,
    this.currentStreakDays = 0,
    this.longestStreakDays = 0,
    this.cardsReviewedToday = 0,
    this.practiceXp = 0,
    this.practiceCount = 0,
    this.lastReviewedAt,
    this.lastSessionResult,
  });

  /// The starting state before any review has happened.
  static const ProgressSnapshot empty = ProgressSnapshot();

  /// XP awarded per reviewed card.
  static const int xpPerCard = 10;

  /// Review XP (drives the review-derived "cards reviewed" metric).
  final int totalXp;
  final int currentStreakDays;

  /// The best streak ever reached — monotonic, so streak achievements stay
  /// earned even after the current streak breaks (MVP_015).
  final int longestStreakDays;
  final int cardsReviewedToday;

  /// Motivational XP earned from practice modes (MVP_017). Counts toward level
  /// but is kept separate from review XP so review metrics stay accurate.
  final int practiceXp;

  /// How many practice sessions have been completed (MVP_017).
  final int practiceCount;
  final DateTime? lastReviewedAt;
  final ReviewSessionResult? lastSessionResult;

  /// All XP that counts toward level — review + practice.
  int get combinedXp => totalXp + practiceXp;

  /// Total cards reviewed across all time (derived from review XP only).
  int get totalCardsReviewed => totalXp ~/ xpPerCard;

  /// Returns the snapshot after a practice session awarded [xp] (MVP_017).
  /// Touches only motivational fields — never review state, streak, or counts.
  ProgressSnapshot recordingPractice(int xp) => ProgressSnapshot(
        totalXp: totalXp,
        currentStreakDays: currentStreakDays,
        longestStreakDays: longestStreakDays,
        cardsReviewedToday: cardsReviewedToday,
        practiceXp: practiceXp + (xp < 0 ? 0 : xp),
        practiceCount: practiceCount + 1,
        lastReviewedAt: lastReviewedAt,
        lastSessionResult: lastSessionResult,
      );

  /// Whether a review has already been recorded today.
  bool get reviewedToday => cardsReviewedToday > 0;

  /// Progress toward a motivational daily [goal] in [0, 1].
  double dailyGoalProgress(int goal) =>
      goal <= 0 ? 1 : (cardsReviewedToday / goal).clamp(0, 1).toDouble();

  /// Whether today's motivational [goal] has been met.
  bool dailyGoalMet(int goal) => goal > 0 && cardsReviewedToday >= goal;

  /// Levels are 100 XP each, starting at level 1 (review + practice XP).
  int get currentLevel => combinedXp ~/ 100 + 1;

  /// XP accumulated within the current level, in [0, 100).
  int get xpIntoLevel => combinedXp % 100;

  /// True once there's any recorded activity — a review or a practice session.
  bool get hasProgress => lastReviewedAt != null || practiceCount > 0;

  /// Returns the snapshot that results from completing [result] at [now].
  ///
  /// - awards [xpPerCard] XP per reviewed card,
  /// - accumulates today's count when [now] is the same day as the last review,
  ///   otherwise starts today's count fresh,
  /// - bumps the streak when the last review was yesterday, keeps it when it was
  ///   today, and resets to 1 on a gap or first-ever session.
  ProgressSnapshot recordingSession(ReviewSessionResult result, DateTime now) {
    final int gainedXp = result.totalCards * xpPerCard;
    final DateTime? last = lastReviewedAt;

    final bool sameDay = last != null && _isSameDay(last, now);
    final bool consecutive = last != null && _isSameDay(_dayBefore(now), last);

    final int streak;
    if (sameDay) {
      streak = currentStreakDays == 0 ? 1 : currentStreakDays;
    } else if (consecutive) {
      streak = currentStreakDays + 1;
    } else {
      streak = 1;
    }

    return ProgressSnapshot(
      totalXp: totalXp + gainedXp,
      currentStreakDays: streak,
      longestStreakDays: math.max(longestStreakDays, streak),
      cardsReviewedToday:
          sameDay ? cardsReviewedToday + result.totalCards : result.totalCards,
      lastReviewedAt: now,
      lastSessionResult: result,
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime _dayBefore(DateTime d) =>
      DateTime(d.year, d.month, d.day).subtract(const Duration(days: 1));
}
