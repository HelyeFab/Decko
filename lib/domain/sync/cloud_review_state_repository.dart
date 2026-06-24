import 'deck_fingerprint.dart';
import 'syncable_review_state.dart';

/// Cloud store for per-card review state, keyed by a stable [DeckFingerprint]
/// (MVP_022, DEC-031): `/users/{uid}/deckStates/{fingerprint}/cards/{itemId}`.
/// Upserts are idempotent by item id; deck content is never stored here.
abstract class CloudReviewStateRepository {
  /// Upserts the given card states under the deck's fingerprint, and records
  /// the fingerprint metadata so synced decks can be discovered.
  Future<void> upsertStates(
    String uid,
    DeckFingerprint fingerprint,
    List<SyncableReviewState> states,
  );

  /// All cloud card states for the deck's fingerprint (empty if none).
  Future<List<SyncableReviewState>> fetchStates(
    String uid,
    DeckFingerprint fingerprint,
  );
}
