import 'activity/activity_progress.dart';
import 'progress_snapshot.dart';

/// The small starter set of achievements (MVP_015, DEC-024).
///
/// Light gamification is **derived** from progress — it never drives scheduling.
enum Achievement { firstReview, dailyGoal, threeDayStreak, hundredCards }

extension AchievementInfo on Achievement {
  String get title => switch (this) {
        Achievement.firstReview => 'First review',
        Achievement.dailyGoal => 'Daily goal',
        Achievement.threeDayStreak => '3-day streak',
        Achievement.hundredCards => '100 cards',
      };

  String get blurb => switch (this) {
        Achievement.firstReview => 'Finished your first study session',
        Achievement.dailyGoal => 'Hit your daily goal',
        Achievement.threeDayStreak => 'Studied 3 days in a row',
        Achievement.hundredCards => 'Reviewed 100 cards in total',
      };
}

/// Whether a given [Achievement] is currently earned.
class AchievementStatus {
  const AchievementStatus(this.achievement, this.earned);
  final Achievement achievement;
  final bool earned;
}

/// Pure: derives each achievement's earned state from the progress snapshot and
/// the motivational [dailyGoal]. Streak/total achievements use monotonic fields
/// so they stay earned; the daily goal reflects today.
List<AchievementStatus> achievementsFor(ProgressSnapshot s, int dailyGoal) {
  return <AchievementStatus>[
    AchievementStatus(Achievement.firstReview, s.hasProgress),
    AchievementStatus(Achievement.dailyGoal, s.dailyGoalMet(dailyGoal)),
    AchievementStatus(Achievement.threeDayStreak, s.longestStreakDays >= 3),
    AchievementStatus(Achievement.hundredCards, s.totalCardsReviewed >= 100),
  ];
}

/// The same starter set, derived from the activity ledger (MVP_019, DEC-028).
List<AchievementStatus> achievementsForActivity(
    ActivityProgress p, int dailyGoal) {
  return <AchievementStatus>[
    AchievementStatus(Achievement.firstReview, p.totalReviews > 0),
    AchievementStatus(Achievement.dailyGoal, p.dailyGoalMet(dailyGoal)),
    AchievementStatus(Achievement.threeDayStreak, p.longestStreakDays >= 3),
    AchievementStatus(Achievement.hundredCards, p.totalReviews >= 100),
  ];
}
