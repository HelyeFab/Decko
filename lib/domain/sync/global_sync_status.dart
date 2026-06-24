// Global account/sync status (MVP_023, DEC-032) — describes the account layer,
// not review scheduling. Pure + framework-light.

import 'sync_status.dart';

enum SyncConnectionState { signedOut, online, offline, syncing, error }

class GlobalSyncStatus {
  const GlobalSyncStatus({
    required this.connectionState,
    this.lastSuccessfulSyncAt,
    this.pendingApplies = 0,
    this.errorMessage,
  });

  static const GlobalSyncStatus signedOut =
      GlobalSyncStatus(connectionState: SyncConnectionState.signedOut);

  final SyncConnectionState connectionState;
  final DateTime? lastSuccessfulSyncAt;

  /// Decks with cloud review progress waiting for an explicit apply.
  final int pendingApplies;
  final String? errorMessage;

  bool get isSignedIn => connectionState != SyncConnectionState.signedOut;
  bool get isSyncing => connectionState == SyncConnectionState.syncing;
}

/// Pure derivation of the global status from auth + the activity [SyncState].
GlobalSyncStatus deriveGlobalSyncStatus({
  required bool signedIn,
  required SyncState syncState,
  int pendingApplies = 0,
}) {
  if (!signedIn) return GlobalSyncStatus.signedOut;
  final SyncConnectionState conn = switch (syncState.status) {
    SyncStatus.syncing => SyncConnectionState.syncing,
    SyncStatus.failed => SyncConnectionState.error,
    SyncStatus.offline => SyncConnectionState.offline,
    SyncStatus.idle || SyncStatus.synced => SyncConnectionState.online,
  };
  return GlobalSyncStatus(
    connectionState: conn,
    lastSuccessfulSyncAt: syncState.lastSyncedAt,
    pendingApplies: pendingApplies,
    errorMessage: syncState.message,
  );
}
