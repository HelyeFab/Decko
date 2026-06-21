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
    this.lastReviewedAt,
    this.lastSessionResult,
  });

  /// The starting state before any review has happened.
  static const ProgressSnapshot empty = ProgressSnapshot();

  /// XP awarded per reviewed card.
  static const int xpPerCard = 10;

  final int totalXp;
  final int currentStreakDays;

  /// The best streak ever reached — monotonic, so streak achievements stay
  /// earned even after the current streak breaks (MVP_015).
  final int longestStreakDays;
  final int cardsReviewedToday;
  final DateTime? lastReviewedAt;
  final ReviewSessionResult? lastSessionResult;

  /// Total cards reviewed across all time (derived from XP).
  int get totalCardsReviewed => totalXp ~/ xpPerCard;

  /// Whether a review has already been recorded today.
  bool get reviewedToday => cardsReviewedToday > 0;

  /// Progress toward a motivational daily [goal] in [0, 1].
  double dailyGoalProgress(int goal) =>
      goal <= 0 ? 1 : (cardsReviewedToday / goal).clamp(0, 1).toDouble();

  /// Whether today's motivational [goal] has been met.
  bool dailyGoalMet(int goal) => goal > 0 && cardsReviewedToday >= goal;

  /// Levels are 100 XP each, starting at level 1.
  int get currentLevel => totalXp ~/ 100 + 1;

  /// XP accumulated within the current level, in [0, 100).
  int get xpIntoLevel => totalXp % 100;

  /// True when no session has been recorded yet.
  bool get hasProgress => lastReviewedAt != null;

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
