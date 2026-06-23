// MVP_019: file-backed activity ledger persistence + queries.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:decko/data/local_activity_ledger_repository.dart';
import 'package:decko/domain/activity/activity_event.dart';

ActivityEvent _event(String id, DateTime when, {int xp = 10}) => ActivityEvent(
      id: id,
      occurredAt: when,
      source: ActivitySource.review,
      modeId: ActivityModeIds.standardReview,
      outcome: ActivityOutcome.completed,
      xpAwarded: xp,
      metadata: <String, Object?>{'reviewedCards': xp ~/ 10},
    );

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('decko_ledger'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('records, persists, and reloads events', () async {
    final LocalActivityLedgerRepository repo =
        LocalActivityLedgerRepository(baseDir: tmp);
    await repo.record(_event('a', DateTime(2026, 6, 20)));
    await repo.record(_event('b', DateTime(2026, 6, 22)));

    // A fresh instance reads the same file.
    final List<ActivityEvent> all =
        await LocalActivityLedgerRepository(baseDir: tmp).allEvents();
    expect(all, hasLength(2));
    expect(all.map((ActivityEvent e) => e.id), containsAll(<String>['a', 'b']));
  });

  test('recentEvents returns newest first; eventsBetween filters', () async {
    final LocalActivityLedgerRepository repo =
        LocalActivityLedgerRepository(baseDir: tmp);
    await repo.record(_event('old', DateTime(2026, 6, 18)));
    await repo.record(_event('new', DateTime(2026, 6, 22)));

    final List<ActivityEvent> recent = await repo.recentEvents(limit: 1);
    expect(recent.single.id, 'new');

    final List<ActivityEvent> window = await repo.eventsBetween(
        DateTime(2026, 6, 21), DateTime(2026, 6, 23));
    expect(window.map((ActivityEvent e) => e.id), <String>['new']);
  });

  test('missing file yields an empty ledger', () async {
    final List<ActivityEvent> all =
        await LocalActivityLedgerRepository(baseDir: tmp).allEvents();
    expect(all, isEmpty);
  });
}
