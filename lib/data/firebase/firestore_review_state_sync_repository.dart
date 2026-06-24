import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/sync/cloud_review_state_repository.dart';
import '../../domain/sync/deck_fingerprint.dart';
import '../../domain/sync/syncable_review_state.dart';

/// Firestore-backed review-state store (MVP_022, DEC-031):
/// `/users/{uid}/deckStates/{fingerprint}/cards/{itemId}`. Stores ONLY review
/// scheduling state — never deck content or media.
class FirestoreReviewStateSyncRepository implements CloudReviewStateRepository {
  FirestoreReviewStateSyncRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _deckDoc(
          String uid, DeckFingerprint fp) =>
      _db.collection('users').doc(uid).collection('deckStates').doc(fp.key);

  @override
  Future<void> upsertStates(
    String uid,
    DeckFingerprint fp,
    List<SyncableReviewState> states,
  ) async {
    final DocumentReference<Map<String, dynamic>> deckDoc = _deckDoc(uid, fp);
    // Record the fingerprint metadata (so synced decks can be discovered).
    await deckDoc.set(<String, dynamic>{
      ...fp.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final CollectionReference<Map<String, dynamic>> cards =
        deckDoc.collection('cards');
    for (int i = 0; i < states.length; i += 450) {
      final WriteBatch batch = _db.batch();
      for (final SyncableReviewState s
          in states.sublist(i, (i + 450).clamp(0, states.length))) {
        batch.set(cards.doc(s.itemId), s.toJson(), SetOptions(merge: true));
      }
      await batch.commit();
    }
  }

  @override
  Future<List<SyncableReviewState>> fetchStates(
      String uid, DeckFingerprint fp) async {
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _deckDoc(uid, fp).collection('cards').get();
    return snap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> d) =>
            SyncableReviewState.fromJson(d.data()))
        .toList();
  }
}
