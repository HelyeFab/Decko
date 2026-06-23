import 'dart:math' as math;

import 'activity_day.dart';
import 'activity_event.dart';
import 'activity_progress.dart';

/// Derives [ActivityProgress] from a list of [ActivityEvent]s (MVP_019). Pure
/// and deterministic — time is passed in, never read from the clock here.
class ActivityProgressCalculator {
  const ActivityProgressCalculator();

  ActivityProgress calculate(
    List<ActivityEvent> events,
    DateTime now, {
    int heatmapDays = 84,
    int recentLimit = 20,
  }) {
    final DateTime today = _dateOnly(now);

    int totalXp = 0, reviewXp = 0, practiceXp = 0, totalReviews = 0;
    int xpToday = 0, cardsReviewedToday = 0, practiceRoundsToday = 0;
    int legacyLongest = 0;
    final Set<DateTime> activeDays = <DateTime>{};

    for (final ActivityEvent e in events) {
      totalXp += e.xpAwarded;
      final int reviewedCards = _reviewedCards(e);
      if (e.isReview) {
        reviewXp += e.xpAwarded;
        totalReviews += reviewedCards;
      } else {
        practiceXp += e.xpAwarded;
      }
      if (e.isLegacy) {
        legacyLongest = math.max(
            legacyLongest, (e.metadata['longestStreak'] as int?) ?? 0);
        // Reconstruct the migrated streak's days (ending at the legacy event's
        // day) so the current streak survives migration and can continue — the
        // learner genuinely studied those days. They don't feed the heatmap.
        final int legacyStreak = (e.metadata['currentStreak'] as int?) ?? 0;
        final DateTime lastDay = _dateOnly(e.occurredAt);
        for (int d = 0; d < legacyStreak; d++) {
          activeDays.add(lastDay.subtract(Duration(days: d)));
        }
        continue; // legacy baseline isn't a heatmap day
      }
      final DateTime day = _dateOnly(e.occurredAt);
      activeDays.add(day);
      if (day == today) {
        xpToday += e.xpAwarded;
        if (e.isReview) {
          cardsReviewedToday += reviewedCards;
        } else {
          practiceRoundsToday += 1;
        }
      }
    }

    final int currentStreak = _currentStreak(activeDays, today);
    final int longestStreak = math.max(
      math.max(_longestRun(activeDays), legacyLongest),
      currentStreak,
    );

    final List<ActivityEvent> recent = <ActivityEvent>[
      for (final ActivityEvent e in events)
        if (!e.isLegacy) e,
    ]..sort((ActivityEvent a, ActivityEvent b) =>
        b.occurredAt.compareTo(a.occurredAt));

    return ActivityProgress(
      totalXp: totalXp,
      reviewXp: reviewXp,
      practiceXp: practiceXp,
      xpToday: xpToday,
      cardsReviewedToday: cardsReviewedToday,
      practiceRoundsToday: practiceRoundsToday,
      currentStreakDays: currentStreak,
      longestStreakDays: longestStreak,
      totalReviews: totalReviews,
      heatmap: _heatmap(events, today, heatmapDays),
      recent: recent.take(recentLimit).toList(),
    );
  }

  int _reviewedCards(ActivityEvent e) =>
      (e.metadata['reviewedCards'] as int?) ?? 0;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Consecutive active days ending today (or yesterday, if today is empty).
  int _currentStreak(Set<DateTime> days, DateTime today) {
    DateTime cursor = today;
    if (!days.contains(cursor)) {
      cursor = today.subtract(const Duration(days: 1));
      if (!days.contains(cursor)) return 0;
    }
    int streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int _longestRun(Set<DateTime> days) {
    if (days.isEmpty) return 0;
    final List<DateTime> sorted = days.toList()..sort();
    int longest = 1, run = 1;
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i].difference(sorted[i - 1]).inDays == 1) {
        run++;
      } else {
        run = 1;
      }
      longest = math.max(longest, run);
    }
    return longest;
  }

  List<ActivityDay> _heatmap(
      List<ActivityEvent> events, DateTime today, int days) {
    final Map<DateTime, List<int>> agg = <DateTime, List<int>>{};
    for (final ActivityEvent e in events) {
      if (e.isLegacy) continue;
      final DateTime day = _dateOnly(e.occurredAt);
      final List<int> a = agg.putIfAbsent(day, () => <int>[0, 0, 0, 0]);
      a[0] += e.xpAwarded;
      if (e.isReview) {
        a[1] += 1;
      } else {
        a[2] += 1;
      }
      a[3] += 1;
    }
    return <ActivityDay>[
      for (int i = days - 1; i >= 0; i--)
        () {
          final DateTime day = today.subtract(Duration(days: i));
          final List<int>? a = agg[day];
          return ActivityDay(
            day: day,
            xp: a?[0] ?? 0,
            reviewCount: a?[1] ?? 0,
            practiceCount: a?[2] ?? 0,
            totalEvents: a?[3] ?? 0,
          );
        }(),
    ];
  }
}
