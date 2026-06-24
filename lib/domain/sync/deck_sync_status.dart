// Deck-level sync status (MVP_023, DEC-032). A plain-language, derived view of
// where an imported deck stands relative to its cloud review-state — for the
// deck-detail chip + the apply flow. Pure; it never mutates review state.

enum DeckSyncState {
  /// Not an imported deck with stable identity (e.g. a demo deck).
  notImportedDeck,

  /// Signed out — review-state sync is unavailable.
  signedOut,

  /// No matching cloud progress for this deck yet.
  notMatched,

  /// Cloud and local agree — nothing to apply.
  matchedUpToDate,

  /// This device's progress is newer than the cloud's.
  localAhead,

  /// Cloud has newer progress that can be applied here.
  cloudAhead,

  /// Cloud is newer but would regress progress — kept local, surfaced.
  conflict,

  /// Couldn't reach the cloud; local study is unaffected.
  offline,
}

class DeckSyncStatus {
  const DeckSyncStatus({
    required this.deckId,
    required this.state,
    this.fingerprint,
    this.cloudCardsAvailable = 0,
    this.localCardsMatched = 0,
    this.cardsWithCloudProgress = 0,
    this.cloudAheadCount = 0,
    this.conflictCount = 0,
    this.localAheadCount = 0,
  });

  factory DeckSyncStatus.simple(String deckId, DeckSyncState state) =>
      DeckSyncStatus(deckId: deckId, state: state);

  final String deckId;
  final String? fingerprint;
  final DeckSyncState state;
  final int cloudCardsAvailable;
  final int localCardsMatched;
  final int cardsWithCloudProgress;

  /// Cards whose cloud state the merge policy would safely apply (== applicable).
  final int cloudAheadCount;
  final int conflictCount;
  final int localAheadCount;

  bool get canApply => state == DeckSyncState.cloudAhead && cloudAheadCount > 0;
}

/// Pure derivation of the deck's headline state from per-card tallies. Priority:
/// cloud-ahead (something to apply) → conflict → local-ahead → up-to-date.
DeckSyncState deriveDeckSyncState({
  required bool imported,
  required bool signedIn,
  required bool fingerprintable,
  bool error = false,
  int cloudCardsAvailable = 0,
  int cloudAhead = 0,
  int conflicts = 0,
  int localAhead = 0,
}) {
  if (!imported || !fingerprintable) return DeckSyncState.notImportedDeck;
  if (!signedIn) return DeckSyncState.signedOut;
  if (error) return DeckSyncState.offline;
  if (cloudCardsAvailable == 0) return DeckSyncState.notMatched;
  if (cloudAhead > 0) return DeckSyncState.cloudAhead;
  if (conflicts > 0) return DeckSyncState.conflict;
  if (localAhead > 0) return DeckSyncState.localAhead;
  return DeckSyncState.matchedUpToDate;
}
