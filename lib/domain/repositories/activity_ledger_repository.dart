import '../activity/activity_event.dart';

/// Stores and queries the local activity ledger (MVP_019, DEC-028). The ledger
/// is the source of truth for XP / streaks / heatmap / history; it never decides
/// card due state. Local-first, designed to be sync-ready later.
abstract class ActivityLedgerRepository {
  /// Appends an event to the ledger.
  Future<void> record(ActivityEvent event);

  /// Events with `occurredAt` in `[start, end)`.
  Future<List<ActivityEvent>> eventsBetween(DateTime start, DateTime end);

  /// The most recent events, newest first.
  Future<List<ActivityEvent>> recentEvents({int limit = 50});

  /// Every recorded event.
  Future<List<ActivityEvent>> allEvents();
}
