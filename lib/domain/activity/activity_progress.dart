import 'activity_day.dart';
import 'activity_event.dart';

/// Motivational progress derived from the activity ledger (MVP_019, DEC-028).
/// Replaces the snapshot as the source of truth for XP / streaks / heatmap,
/// while review/FSRS state stays separate. Framework-light.
class ActivityProgress {
  const ActivityProgress({
    this.totalXp = 0,
    this.reviewXp = 0,
    this.practiceXp = 0,
    this.xpToday = 0,
    this.cardsReviewedToday = 0,
    this.practiceRoundsToday = 0,
    this.currentStreakDays = 0,
    this.longestStreakDays = 0,
    this.totalReviews = 0,
    this.heatmap = const <ActivityDay>[],
    this.recent = const <ActivityEvent>[],
  });

  static const ActivityProgress empty = ActivityProgress();

  final int totalXp;
  final int reviewXp;
  final int practiceXp;
  final int xpToday;
  final int cardsReviewedToday;
  final int practiceRoundsToday;
  final int currentStreakDays;
  final int longestStreakDays;

  /// Total cards reviewed across all time (for the "100 reviews" achievement).
  final int totalReviews;
  final List<ActivityDay> heatmap;
  final List<ActivityEvent> recent;

  /// Whether anything has been recorded yet.
  bool get hasActivity => totalXp > 0 || recent.isNotEmpty || currentStreakDays > 0;

  /// Levels are 100 XP each, starting at level 1 (review + practice).
  int get currentLevel => totalXp ~/ 100 + 1;
  int get xpIntoLevel => totalXp % 100;

  /// Today's activity count toward the daily goal — reviews + practice rounds.
  int get activityToday => cardsReviewedToday + practiceRoundsToday;

  double dailyGoalProgress(int goal) =>
      goal <= 0 ? 1 : (activityToday / goal).clamp(0, 1).toDouble();

  bool dailyGoalMet(int goal) => goal > 0 && activityToday >= goal;

  bool get reviewedToday => cardsReviewedToday > 0;
}
