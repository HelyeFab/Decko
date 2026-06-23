/// The outcome of a single sync run (MVP_020).
class SyncResult {
  const SyncResult({
    this.uploaded = 0,
    this.downloaded = 0,
    this.ok = true,
    this.error,
  });

  const SyncResult.failure(this.error)
      : uploaded = 0,
        downloaded = 0,
        ok = false;

  /// Activity events pushed to the cloud (idempotent — re-pushing is a no-op).
  final int uploaded;

  /// New cloud events merged into the local ledger.
  final int downloaded;
  final bool ok;
  final String? error;
}
