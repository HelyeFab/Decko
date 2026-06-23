import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/activity/activity_event.dart';
import '../../domain/sync/sync_repository.dart';

/// Firestore-backed activity store (MVP_020): `/users/{uid}/activityEvents/{id}`.
/// Upserts are keyed by the event's stable id, so re-uploading the same event
/// is a no-op — never duplicate progress.
class FirestoreActivitySyncRepository implements CloudActivityRepository {
  FirestoreActivitySyncRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('activityEvents');

  @override
  Future<void> upsertEvents(String uid, List<ActivityEvent> events) async {
    final CollectionReference<Map<String, dynamic>> col = _col(uid);
    // Firestore batches cap at 500 ops.
    for (int i = 0; i < events.length; i += 450) {
      final WriteBatch batch = _db.batch();
      for (final ActivityEvent e in events.sublist(
          i, (i + 450).clamp(0, events.length))) {
        batch.set(
          col.doc(e.id),
          <String, dynamic>{...e.toJson(), 'syncedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    }
  }

  @override
  Future<List<ActivityEvent>> fetchEvents(String uid) async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _col(uid).get();
    return snap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> d) =>
            ActivityEvent.fromJson(d.data()))
        .toList();
  }
}
