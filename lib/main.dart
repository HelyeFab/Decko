import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/decko_app.dart';
import 'data/firebase/firebase_auth_repository.dart';
import 'data/firebase/firestore_activity_sync_repository.dart';
import 'data/firebase/firestore_review_state_sync_repository.dart';
import 'data/firebase/firestore_user_sync_repository.dart';
import 'data/local_activity_ledger_repository.dart';
import 'data/local_only_auth_repository.dart';
import 'data/local_only_sync_repository.dart';
import 'data/shared_prefs_review_state_repository.dart';
import 'data/shared_prefs_settings_repository.dart';
import 'data/sync/decko_sync_repository.dart';
import 'data/sync/review_state_sync_service.dart';
import 'domain/auth/auth_repository.dart';
import 'domain/sync/sync_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Required before any plugin (shared_preferences) is touched during startup.
  WidgetsFlutterBinding.ensureInitialized();

  // Cloud is optional: if Firebase can't initialise, Decko runs local-only and
  // stays fully usable offline / signed out (MVP_020, DEC-029).
  // Load first-run onboarding state before routing so there's no flash (MVP_024).
  const SharedPrefsSettingsRepository settings = SharedPrefsSettingsRepository();
  final bool onboarded = await settings.getHasCompletedOnboarding();

  AuthRepository auth = const LocalOnlyAuthRepository();
  SyncRepository sync = const LocalOnlySyncRepository();
  ReviewStateSyncService? reviewStateSync;
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    final FirebaseAuthRepository firebaseAuth = FirebaseAuthRepository();
    auth = firebaseAuth;
    sync = DeckoSyncRepository(
      auth: firebaseAuth,
      ledger: const LocalActivityLedgerRepository(),
      settings: settings,
      cloudActivity: FirestoreActivitySyncRepository(),
      cloudUser: FirestoreUserSyncRepository(),
    );
    reviewStateSync = ReviewStateSyncService(
      auth: firebaseAuth,
      reviewState: const SharedPrefsReviewStateRepository(),
      cloud: FirestoreReviewStateSyncRepository(),
    );
  } catch (_) {
    // Stay local-only.
  }

  runApp(DeckoApp(
    settingsRepository: settings,
    authRepository: auth,
    syncRepository: sync,
    reviewStateSync: reviewStateSync,
    onboardingComplete: onboarded,
  ));
}
