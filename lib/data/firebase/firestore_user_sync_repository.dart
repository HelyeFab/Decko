import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/auth/decko_user.dart';
import '../../domain/sync/sync_repository.dart';

/// Firestore-backed profile + settings store (MVP_020):
/// `/users/{uid}/profile/main` and `/users/{uid}/settings/app`.
class FirestoreUserSyncRepository implements CloudUserRepository {
  FirestoreUserSyncRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _profile(String uid) =>
      _db.collection('users').doc(uid).collection('profile').doc('main');

  DocumentReference<Map<String, dynamic>> _settings(String uid) =>
      _db.collection('users').doc(uid).collection('settings').doc('app');

  @override
  Future<void> putProfile(DeckoUser user) async {
    await _profile(user.uid).set(<String, dynamic>{
      ...user.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> putSettings(String uid, AppSettings settings) async {
    await _settings(uid).set(
      settings.toMap(DateTime.now()),
      SetOptions(merge: true),
    );
  }

  @override
  Future<AppSettings?> fetchSettings(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> doc = await _settings(uid).get();
    final Map<String, dynamic>? data = doc.data();
    return data == null ? null : AppSettings.fromMap(data);
  }
}
