// ignore_for_file: prefer_initializing_formals
import '../../domain/auth/auth_repository.dart';
import '../../domain/deck.dart';
import '../../domain/repositories/review_state_repository.dart';
import '../../domain/review_card_state.dart';
import '../../domain/sync/cloud_review_state_repository.dart';
import '../../domain/sync/deck_fingerprint.dart';
import '../../domain/sync/deck_sync_status.dart';
import '../../domain/sync/review_state_merge_policy.dart';
import '../../domain/sync/syncable_review_state.dart';

/// The result of applying cloud review-state to a local deck.
class ReviewApplyResult {
  const ReviewApplyResult({
    this.applied = 0,
    this.conflicts = 0,
    this.unmatched = 0,
  });
  final int applied;
  final int conflicts;
  final int unmatched;
}

/// Cross-device review-state sync (MVP_022, DEC-031). Pushes per-card review
/// state for fingerprinted decks, and — only on explicit request — applies
/// matching cloud state locally via the conflict-safe [ReviewStateMergePolicy].
/// It never syncs deck content and never resets existing local progress.
class ReviewStateSyncService {
  ReviewStateSyncService({
    required AuthRepository auth,
    required ReviewStateRepository reviewState,
    required CloudReviewStateRepository cloud,
    this.deviceId,
    DeckFingerprinter fingerprinter = const DeckFingerprinter(),
    ReviewStateMergePolicy policy = const ReviewStateMergePolicy(),
  })  : _auth = auth,
        _reviewState = reviewState,
        _cloud = cloud,
        _fingerprinter = fingerprinter,
        _policy = policy;

  final AuthRepository _auth;
  final ReviewStateRepository _reviewState;
  final CloudReviewStateRepository _cloud;
  final DeckFingerprinter _fingerprinter;
  final ReviewStateMergePolicy _policy;
  final String? deviceId;

  String? get _uid {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return null;
    return user.uid;
  }

  /// Pushes the given (already-saved) card states for [deck] — incremental,
  /// e.g. the cards just answered in a session. Only reviewed cards are sent.
  Future<void> pushStates(Deck deck, List<ReviewCardState> states) async {
    final String? uid = _uid;
    if (uid == null) return;
    final DeckFingerprint? fp = _fingerprinter.fingerprint(deck);
    if (fp == null) return;
    final List<SyncableReviewState> dtos = <SyncableReviewState>[
      for (final ReviewCardState s in states)
        if (s.hasBeenReviewed)
          SyncableReviewState.fromReviewCardState(s,
              updatedAt: s.lastReviewedAt ?? DateTime.now(), deviceId: deviceId),
    ];
    if (dtos.isEmpty) return;
    await _cloud.upsertStates(uid, fp, dtos);
  }

  /// Full push of a deck's reviewed cards (used on sync / sign-in).
  Future<void> pushDeck(Deck deck) async {
    if (_uid == null || _fingerprinter.fingerprint(deck) == null) return;
    await pushStates(deck, await _reviewState.getStatesForDeck(deck.id));
  }

  /// Best-effort push of every fingerprintable deck.
  Future<void> pushAll(List<Deck> decks) async {
    if (_uid == null) return;
    for (final Deck deck in decks) {
      try {
        await pushDeck(deck);
      } catch (_) {/* one deck failing must not stop the rest */}
    }
  }

  /// The plain-language sync status for [deck] (drives the deck-detail chip +
  /// the apply prompt). Pure status read — it never mutates review state.
  Future<DeckSyncStatus> deckStatus(Deck deck) async {
    final DeckFingerprint? fp = _fingerprinter.fingerprint(deck);
    final bool fingerprintable = fp != null;
    final bool signedIn = _uid != null;

    if (!deck.isImported || !fingerprintable) {
      return DeckSyncStatus(
        deckId: deck.id,
        fingerprint: fp?.key,
        state: deriveDeckSyncState(
            imported: deck.isImported,
            signedIn: signedIn,
            fingerprintable: fingerprintable),
      );
    }
    if (!signedIn) {
      return DeckSyncStatus(
          deckId: deck.id, fingerprint: fp.key, state: DeckSyncState.signedOut);
    }

    List<SyncableReviewState> cloud;
    try {
      cloud = await _cloud.fetchStates(_uid!, fp);
    } catch (_) {
      return DeckSyncStatus(
          deckId: deck.id, fingerprint: fp.key, state: DeckSyncState.offline);
    }
    final Map<String, ReviewCardState> local = await _localMap(deck.id);

    int matched = 0;
    int withProgress = 0;
    int cloudAhead = 0;
    int conflicts = 0;
    int localAhead = 0;
    for (final SyncableReviewState c in cloud) {
      if (c.hasProgress) withProgress++;
      final ReviewCardState? localState = local[c.itemId];
      if (localState == null) continue;
      matched++;
      final SyncableReviewState localDto = _dto(localState);
      switch (_policy.decide(localDto, c)) {
        case MergeDecision.useCloud:
          cloudAhead++;
        case MergeDecision.conflict:
          conflicts++;
        case MergeDecision.keepLocal:
          final DateTime? lr = localDto.lastReviewedAt;
          final DateTime? cr = c.lastReviewedAt;
          if (c.hasProgress &&
              localDto.hasProgress &&
              lr != null &&
              cr != null &&
              lr.isAfter(cr)) {
            localAhead++;
          }
      }
    }

    return DeckSyncStatus(
      deckId: deck.id,
      fingerprint: fp.key,
      state: deriveDeckSyncState(
        imported: true,
        signedIn: true,
        fingerprintable: true,
        cloudCardsAvailable: cloud.length,
        cloudAhead: cloudAhead,
        conflicts: conflicts,
        localAhead: localAhead,
      ),
      cloudCardsAvailable: cloud.length,
      localCardsMatched: matched,
      cardsWithCloudProgress: withProgress,
      cloudAheadCount: cloudAhead,
      conflictCount: conflicts,
      localAheadCount: localAhead,
    );
  }

  /// Applies matching cloud state to [deck] — explicit, user-initiated. Only
  /// safe winners are written; non-matching cards and conflicts are left alone.
  Future<ReviewApplyResult> applyToDeck(Deck deck) async {
    final String? uid = _uid;
    final DeckFingerprint? fp = _fingerprinter.fingerprint(deck);
    if (uid == null || fp == null) return const ReviewApplyResult();

    final List<SyncableReviewState> cloud = await _cloud.fetchStates(uid, fp);
    final Map<String, ReviewCardState> local = await _localMap(deck.id);

    final List<ReviewCardState> winners = <ReviewCardState>[];
    int conflicts = 0;
    int unmatched = 0;
    for (final SyncableReviewState c in cloud) {
      final ReviewCardState? localState = local[c.itemId];
      if (localState == null) {
        unmatched++;
        continue;
      }
      switch (_policy.decide(_dto(localState), c)) {
        case MergeDecision.useCloud:
          winners.add(c.toReviewCardState(deck.id));
        case MergeDecision.conflict:
          conflicts++;
        case MergeDecision.keepLocal:
          break;
      }
    }
    if (winners.isNotEmpty) await _reviewState.saveStates(winners);
    return ReviewApplyResult(
      applied: winners.length,
      conflicts: conflicts,
      unmatched: unmatched,
    );
  }

  Future<Map<String, ReviewCardState>> _localMap(String deckId) async {
    final List<ReviewCardState> states =
        await _reviewState.getStatesForDeck(deckId);
    return <String, ReviewCardState>{
      for (final ReviewCardState s in states) s.itemId: s,
    };
  }

  SyncableReviewState _dto(ReviewCardState s) =>
      SyncableReviewState.fromReviewCardState(s,
          updatedAt:
              s.lastReviewedAt ?? DateTime.fromMillisecondsSinceEpoch(0));
}
