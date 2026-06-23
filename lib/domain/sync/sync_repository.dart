import '../activity/activity_event.dart';
import '../auth/decko_user.dart';
import 'sync_result.dart';
import 'sync_status.dart';

/// Safe, syncable app settings (MVP_020). Deliberately small — no deck data,
/// no per-deck study options, nothing that can affect scheduling.
class AppSettings {
  const AppSettings({
    this.themeId,
    required this.furiganaEnabled,
    required this.dailyGoal,
  });

  final String? themeId;
  final bool furiganaEnabled;
  final int dailyGoal;

  Map<String, dynamic> toMap(DateTime updatedAt) => <String, dynamic>{
        if (themeId != null) 'selectedThemeId': themeId,
        'furiganaEnabled': furiganaEnabled,
        'dailyGoal': dailyGoal,
        'updatedAt': updatedAt.toIso8601String(),
      };

  static AppSettings fromMap(Map<String, dynamic> m) => AppSettings(
        themeId: m['selectedThemeId'] as String?,
        furiganaEnabled: m['furiganaEnabled'] as bool? ?? true,
        dailyGoal: m['dailyGoal'] as int? ?? 20,
      );
}

/// Orchestrates cloud sync of motivational state only (profile, settings,
/// activity ledger). Never touches review/FSRS/due/import state (DEC-029).
abstract class SyncRepository {
  Stream<SyncState> syncStateChanges();
  SyncState get current;

  /// Pushes local activity + settings to the cloud and merges cloud activity
  /// back into the local ledger (additive, idempotent). No-op while local-only.
  Future<SyncResult> syncNow();
}

/// Cloud store for activity events. Upserts are keyed by stable event id so the
/// same event can never create duplicate progress.
abstract class CloudActivityRepository {
  Future<void> upsertEvents(String uid, List<ActivityEvent> events);
  Future<List<ActivityEvent>> fetchEvents(String uid);
}

/// Cloud store for the user profile + safe settings.
abstract class CloudUserRepository {
  Future<void> putProfile(DeckoUser user);
  Future<void> putSettings(String uid, AppSettings settings);
  Future<AppSettings?> fetchSettings(String uid);
}
