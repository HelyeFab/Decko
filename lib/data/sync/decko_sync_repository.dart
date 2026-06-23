// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import '../../domain/activity/activity_event.dart';
import '../../domain/auth/auth_repository.dart';
import '../../domain/repositories/activity_ledger_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/sync/sync_repository.dart';
import '../../domain/sync/sync_result.dart';
import '../../domain/sync/sync_status.dart';

/// The default [SyncRepository] orchestrator (MVP_020). Pushes local activity +
/// settings + profile to the cloud and merges cloud activity back — additively
/// and idempotently. Review/FSRS/import state is never read or written here.
class DeckoSyncRepository implements SyncRepository {
  DeckoSyncRepository({
    required AuthRepository auth,
    required ActivityLedgerRepository ledger,
    required SettingsRepository settings,
    required CloudActivityRepository cloudActivity,
    required CloudUserRepository cloudUser,
  })  : _auth = auth,
        _ledger = ledger,
        _settings = settings,
        _cloudActivity = cloudActivity,
        _cloudUser = cloudUser;

  final AuthRepository _auth;
  final ActivityLedgerRepository _ledger;
  final SettingsRepository _settings;
  final CloudActivityRepository _cloudActivity;
  final CloudUserRepository _cloudUser;

  final StreamController<SyncState> _controller =
      StreamController<SyncState>.broadcast();
  SyncState _state = SyncState.idle;

  @override
  SyncState get current => _state;

  @override
  Stream<SyncState> syncStateChanges() async* {
    yield _state;
    yield* _controller.stream;
  }

  void _emit(SyncState s) {
    _state = s;
    _controller.add(s);
  }

  @override
  Future<SyncResult> syncNow() async {
    final user = _auth.currentUser;
    if (user == null) {
      // Local-only: nothing to sync, and never an error state.
      _emit(SyncState.idle);
      return const SyncResult.failure('Sign in to sync your progress.');
    }

    _emit(_state.copyWith(status: SyncStatus.syncing, message: null));
    try {
      // 1) Activity: push all local events (idempotent by id), then merge back
      //    any cloud events we don't have. Never delete local-only events.
      final List<ActivityEvent> local = await _ledger.allEvents();
      await _cloudActivity.upsertEvents(user.uid, local);

      final List<ActivityEvent> remote =
          await _cloudActivity.fetchEvents(user.uid);
      final Set<String> localIds =
          local.map((ActivityEvent e) => e.id).toSet();
      int downloaded = 0;
      for (final ActivityEvent e in remote) {
        if (!localIds.contains(e.id)) {
          await _ledger.record(e);
          downloaded++;
        }
      }

      // 2) Settings + profile: push only (safe backup). Review state untouched.
      await _cloudUser.putSettings(
        user.uid,
        AppSettings(
          themeId: await _settings.getSelectedAppThemeId(),
          furiganaEnabled: await _settings.getShowFurigana(),
          dailyGoal: await _settings.getDailyGoal(),
        ),
      );
      await _cloudUser.putProfile(user);

      final DateTime now = DateTime.now();
      _emit(SyncState(status: SyncStatus.synced, lastSyncedAt: now));
      return SyncResult(uploaded: local.length, downloaded: downloaded);
    } catch (e) {
      _emit(_state.copyWith(
          status: SyncStatus.failed,
          message: 'Sync failed — your progress is safe locally. We’ll retry.'));
      return const SyncResult.failure('Sync failed.');
    }
  }
}
