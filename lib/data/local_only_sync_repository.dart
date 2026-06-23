import '../domain/sync/sync_repository.dart';
import '../domain/sync/sync_result.dart';
import '../domain/sync/sync_status.dart';

/// The default [SyncRepository] when Firebase isn't wired (MVP_020). Decko is
/// fully usable; there's just nothing to sync until the user signs in.
class LocalOnlySyncRepository implements SyncRepository {
  const LocalOnlySyncRepository();

  @override
  SyncState get current => SyncState.idle;

  @override
  Stream<SyncState> syncStateChanges() =>
      Stream<SyncState>.value(SyncState.idle);

  @override
  Future<SyncResult> syncNow() async =>
      const SyncResult.failure('Sign in to sync your progress.');
}
