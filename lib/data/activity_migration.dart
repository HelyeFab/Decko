import '../domain/activity/activity_event.dart';
import '../domain/progress_snapshot.dart';
import '../domain/repositories/activity_ledger_repository.dart';
import '../domain/repositories/progress_repository.dart';

/// One-time, idempotent backfill of the legacy [ProgressSnapshot] into the
/// activity ledger (MVP_019, DEC-028). Preserves existing XP and streaks as a
/// baseline; it never erases progress or fabricates per-day detail beyond the
/// streak the learner already had.
class ActivityMigration {
  const ActivityMigration._();

  static Future<void> ensureBackfilled(
    ActivityLedgerRepository ledger,
    ProgressRepository progress,
  ) async {
    final List<ActivityEvent> events = await ledger.allEvents();
    if (events.any((ActivityEvent e) => e.isLegacy)) return; // already done

    final ProgressSnapshot s = await progress.getSnapshot();
    final bool hasReview = s.totalXp > 0 ||
        s.totalCardsReviewed > 0 ||
        s.currentStreakDays > 0 ||
        s.longestStreakDays > 0;
    if (!hasReview && s.practiceXp == 0) return; // nothing to migrate

    final DateTime when =
        s.lastReviewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

    if (hasReview) {
      await ledger.record(ActivityEvent(
        id: 'legacy-review-${when.microsecondsSinceEpoch}',
        occurredAt: when,
        source: ActivitySource.review,
        modeId: ActivityModeIds.standardReview,
        outcome: ActivityOutcome.completed,
        xpAwarded: s.totalXp,
        metadata: <String, Object?>{
          'legacy': true,
          'reviewedCards': s.totalCardsReviewed,
          'currentStreak': s.currentStreakDays,
          'longestStreak': s.longestStreakDays,
        },
      ));
    }
    if (s.practiceXp > 0) {
      await ledger.record(ActivityEvent(
        id: 'legacy-practice-${when.microsecondsSinceEpoch}',
        occurredAt: when,
        source: ActivitySource.manualPractice,
        modeId: 'legacy_practice',
        outcome: ActivityOutcome.completed,
        xpAwarded: s.practiceXp,
        metadata: <String, Object?>{'legacy': true},
      ));
    }
  }
}
