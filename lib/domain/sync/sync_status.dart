/// Cloud sync status, surfaced to the user in friendly terms (MVP_020).
enum SyncStatus { idle, syncing, synced, failed, offline }

/// A snapshot of sync progress for the Account screen.
class SyncState {
  const SyncState({
    this.status = SyncStatus.idle,
    this.lastSyncedAt,
    this.message,
  });

  static const SyncState idle = SyncState();

  final SyncStatus status;
  final DateTime? lastSyncedAt;
  final String? message;

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncedAt,
    String? message,
  }) =>
      SyncState(
        status: status ?? this.status,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        message: message,
      );
}
