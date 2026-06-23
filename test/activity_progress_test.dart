// MVP_019: activity event serialization, ledger-derived progress (XP, streaks,
// heatmap), and the legacy migration.

import 'package:flutter_test/flutter_test.dart';

import 'package:decko/data/activity_migration.dart';
import 'package:decko/domain/activity/activity_event.dart';
import 'package:decko/domain/activity/activity_progress.dart';
import 'package:decko/domain/activity/activity_progress_calculator.dart';
import 'package:decko/domain/practice/practice_outcome.dart';
import 'package:decko/domain/progress_snapshot.dart';
import 'package:decko/domain/repositories/activity_ledger_repository.dart';
import 'package:decko/domain/repositories/progress_repository.dart';
import 'package:decko/domain/review_session_result.dart';

class _MemLedger implements ActivityLedgerRepository {
  final List<ActivityEvent> events = <ActivityEvent>[];
  @override
  Future<void> record(ActivityEvent e) async => events.add(e);
  @override
  Future<List<ActivityEvent>> allEvents() async => List<ActivityEvent>.of(events);
  @override
  Future<List<ActivityEvent>> eventsBetween(DateTime s, DateTime e) async =>
      events.where((ActivityEvent x) =>
          !x.occurredAt.isBefore(s) && x.occurredAt.isBefore(e)).toList();
  @override
  Future<List<ActivityEvent>> recentEvents({int limit = 50}) async =>
      events.take(limit).toList();
}

class _FakeProgress implements ProgressRepository {
  _FakeProgress(this.snapshot);
  ProgressSnapshot snapshot;
  @override
  Future<ProgressSnapshot> getSnapshot() async => snapshot;
  @override
  Future<void> recordSessionResult(ReviewSessionResult r) async {}
  @override
  Future<void> recordPracticeOutcome(PracticeOutcome o) async {}
  @override
  Future<void> resetProgress() async {}
}

ActivityEvent _review(DateTime when, int cards) => ActivityEvent(
      id: 'r${when.microsecondsSinceEpoch}',
      occurredAt: when,
      source: ActivitySource.review,
      modeId: ActivityModeIds.standardReview,
      outcome: ActivityOutcome.completed,
      xpAwarded: cards * 10,
      metadata: <String, Object?>{'reviewedCards': cards},
    );

ActivityEvent _practice(DateTime when, int xp) => ActivityEvent(
      id: 'p${when.microsecondsSinceEpoch}',
      occurredAt: when,
      source: ActivitySource.deckPractice,
      modeId: ActivityModeIds.listeningChallenge,
      outcome: ActivityOutcome.completed,
      xpAwarded: xp,
    );

void main() {
  const ActivityProgressCalculator calc = ActivityProgressCalculator();
  final DateTime now = DateTime(2026, 6, 22, 10);
  final DateTime today = DateTime(2026, 6, 22);

  test('ActivityEvent round-trips through JSON', () {
    final ActivityEvent e = _review(now, 5);
    final ActivityEvent r = ActivityEvent.fromJson(e.toJson());
    expect(r.source, ActivitySource.review);
    expect(r.modeId, ActivityModeIds.standardReview);
    expect(r.xpAwarded, 50);
    expect(r.metadata['reviewedCards'], 5);
    expect(r.isReview, isTrue);
  });

  group('calculator', () {
    test('separates review and practice XP and totals', () {
      final ActivityProgress p = calc.calculate(<ActivityEvent>[
        _review(today, 3),
        _practice(today, 25),
      ], now);
      expect(p.reviewXp, 30);
      expect(p.practiceXp, 25);
      expect(p.totalXp, 55);
      expect(p.xpToday, 55);
      expect(p.cardsReviewedToday, 3);
      expect(p.practiceRoundsToday, 1);
      expect(p.activityToday, 4);
      expect(p.totalReviews, 3);
    });

    test('today excludes earlier days', () {
      final ActivityProgress p = calc.calculate(<ActivityEvent>[
        _review(today, 3),
        _review(today.subtract(const Duration(days: 1)), 9),
      ], now);
      expect(p.cardsReviewedToday, 3);
      expect(p.totalReviews, 12);
    });

    test('derives current and longest streak from active days', () {
      final ActivityProgress p = calc.calculate(<ActivityEvent>[
        _review(today, 1),
        _review(today.subtract(const Duration(days: 1)), 1),
        _review(today.subtract(const Duration(days: 2)), 1),
        // a gap, then an older 2-day run
        _review(today.subtract(const Duration(days: 6)), 1),
        _review(today.subtract(const Duration(days: 7)), 1),
      ], now);
      expect(p.currentStreakDays, 3);
      expect(p.longestStreakDays, 3);
    });

    test('heatmap groups by day, includes today, keeps empty days', () {
      final ActivityProgress p = calc.calculate(<ActivityEvent>[
        _review(today, 2),
        _review(today, 3), // same day aggregates
        _practice(today.subtract(const Duration(days: 1)), 5),
      ], now, heatmapDays: 7);
      expect(p.heatmap, hasLength(7));
      final last = p.heatmap.last; // today
      expect(last.day, today);
      expect(last.xp, 50); // (2+3) cards × 10
      expect(last.reviewCount, 2);
      // a day with no events is empty
      expect(p.heatmap.where((d) => d.isEmpty), isNotEmpty);
    });
  });

  group('legacy migration', () {
    test('backfills snapshot XP + streak, idempotently', () async {
      final _MemLedger ledger = _MemLedger();
      final _FakeProgress progress = _FakeProgress(ProgressSnapshot(
        totalXp: 500,
        practiceXp: 40,
        currentStreakDays: 4,
        longestStreakDays: 6,
        lastReviewedAt: today,
      ));

      await ActivityMigration.ensureBackfilled(ledger, progress);
      expect(ledger.events.where((e) => e.isLegacy), hasLength(2));

      // Idempotent.
      await ActivityMigration.ensureBackfilled(ledger, progress);
      expect(ledger.events.where((e) => e.isLegacy), hasLength(2));

      // Derived progress preserves XP and reconstructs the streak.
      final ActivityProgress p = calc.calculate(ledger.events, now);
      expect(p.totalXp, 540); // 500 review + 40 practice
      expect(p.currentStreakDays, 4); // reconstructed from the legacy streak
      expect(p.longestStreakDays, 6);
    });

    test('does nothing when there is no legacy progress', () async {
      final _MemLedger ledger = _MemLedger();
      await ActivityMigration.ensureBackfilled(
          ledger, _FakeProgress(ProgressSnapshot.empty));
      expect(ledger.events, isEmpty);
    });
  });
}
