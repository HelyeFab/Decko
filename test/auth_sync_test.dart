// MVP_020: auth fake, sync idempotency/merge, settings mapping, offline path,
// and the no-review-mutation boundary. All fakes — no Firebase.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:decko/data/local_only_sync_repository.dart';
import 'package:decko/data/sync/decko_sync_repository.dart';
import 'package:decko/domain/activity/activity_event.dart';
import 'package:decko/domain/auth/auth_repository.dart';
import 'package:decko/domain/auth/auth_state.dart';
import 'package:decko/domain/auth/decko_user.dart';
import 'package:decko/domain/repositories/activity_ledger_repository.dart';
import 'package:decko/domain/repositories/settings_repository.dart';
import 'package:decko/domain/sync/sync_repository.dart';
import 'package:decko/domain/sync/sync_result.dart';

class FakeAuth implements AuthRepository {
  FakeAuth([this._user]);
  DeckoUser? _user;
  final StreamController<AuthState> _ctrl =
      StreamController<AuthState>.broadcast();

  @override
  Stream<AuthState> authStateChanges() async* {
    yield AuthState(_user);
    yield* _ctrl.stream;
  }

  @override
  DeckoUser? get currentUser => _user;

  Future<DeckoUser> _set(DeckoUser u) async {
    _user = u;
    _ctrl.add(AuthState(u));
    return u;
  }

  @override
  Future<DeckoUser> signInAnonymously() =>
      _set(const DeckoUser(uid: 'anon', isAnonymous: true));
  @override
  Future<DeckoUser> signInWithEmail(String e, String p) =>
      _set(DeckoUser(uid: 'u1', email: e));
  @override
  Future<DeckoUser> createAccountWithEmail(String e, String p) =>
      _set(DeckoUser(uid: 'u1', email: e));
  @override
  Future<DeckoUser> signInWithGoogle() =>
      _set(const DeckoUser(uid: 'g1', email: 'g@example.com'));
  @override
  Future<void> signOut() async {
    _user = null;
    _ctrl.add(AuthState.localOnly);
  }
}

class MemLedger implements ActivityLedgerRepository {
  final List<ActivityEvent> events = <ActivityEvent>[];
  @override
  Future<void> record(ActivityEvent e) async => events.add(e);
  @override
  Future<List<ActivityEvent>> allEvents() async => List<ActivityEvent>.of(events);
  @override
  Future<List<ActivityEvent>> eventsBetween(DateTime s, DateTime e) async =>
      events.toList();
  @override
  Future<List<ActivityEvent>> recentEvents({int limit = 50}) async =>
      events.take(limit).toList();
}

class FakeCloudActivity implements CloudActivityRepository {
  final Map<String, Map<String, ActivityEvent>> store =
      <String, Map<String, ActivityEvent>>{};
  @override
  Future<void> upsertEvents(String uid, List<ActivityEvent> events) async {
    final Map<String, ActivityEvent> m =
        store.putIfAbsent(uid, () => <String, ActivityEvent>{});
    for (final ActivityEvent e in events) {
      m[e.id] = e; // keyed by id → idempotent
    }
  }

  @override
  Future<List<ActivityEvent>> fetchEvents(String uid) async =>
      store[uid]?.values.toList() ?? <ActivityEvent>[];
}

class FakeCloudUser implements CloudUserRepository {
  DeckoUser? profile;
  final Map<String, AppSettings> settings = <String, AppSettings>{};
  @override
  Future<void> putProfile(DeckoUser user) async => profile = user;
  @override
  Future<void> putSettings(String uid, AppSettings s) async =>
      settings[uid] = s;
  @override
  Future<AppSettings?> fetchSettings(String uid) async => settings[uid];
}

class FakeSettings implements SettingsRepository {
  String? theme;
  bool furigana = true;
  int goal = 20;
  @override
  Future<String?> getSelectedAppThemeId() async => theme;
  @override
  Future<void> saveSelectedAppThemeId(String t) async => theme = t;
  @override
  Future<bool> getShowFurigana() async => furigana;
  @override
  Future<void> saveShowFurigana(bool v) async => furigana = v;
  @override
  Future<int> getDailyGoal() async => goal;
  @override
  Future<void> saveDailyGoal(int g) async => goal = g;
  bool onboarded = true;
  @override
  Future<bool> getHasCompletedOnboarding() async => onboarded;
  @override
  Future<void> saveHasCompletedOnboarding(bool done) async => onboarded = done;
}

ActivityEvent _ev(String id) => ActivityEvent(
      id: id,
      occurredAt: DateTime(2026, 6, 23),
      source: ActivitySource.review,
      modeId: ActivityModeIds.standardReview,
      outcome: ActivityOutcome.completed,
      xpAwarded: 10,
      metadata: const <String, Object?>{'reviewedCards': 1},
    );

DeckoSyncRepository _sync(
  FakeAuth auth,
  MemLedger ledger,
  FakeCloudActivity cloud,
  FakeCloudUser cloudUser,
  FakeSettings settings,
) =>
    DeckoSyncRepository(
      auth: auth,
      ledger: ledger,
      settings: settings,
      cloudActivity: cloud,
      cloudUser: cloudUser,
    );

void main() {
  group('auth fake', () {
    test('sign-in sets the user and emits state; sign-out clears it', () async {
      final FakeAuth auth = FakeAuth();
      expect(auth.currentUser, isNull);
      final DeckoUser u = await auth.signInWithEmail('a@b.com', 'pw');
      expect(u.email, 'a@b.com');
      expect(auth.currentUser, isNotNull);
      await auth.signOut();
      expect(auth.currentUser, isNull);
    });
  });

  group('AppSettings mapping', () {
    test('round-trips through the cloud map', () {
      const AppSettings s =
          AppSettings(themeId: 'soft', furiganaEnabled: false, dailyGoal: 35);
      final AppSettings back = AppSettings.fromMap(s.toMap(DateTime(2026)));
      expect(back.themeId, 'soft');
      expect(back.furiganaEnabled, isFalse);
      expect(back.dailyGoal, 35);
    });
  });

  group('sync orchestrator', () {
    test('uploads local events and is idempotent (no duplicates)', () async {
      final FakeAuth auth = FakeAuth(const DeckoUser(uid: 'u1'));
      final MemLedger ledger = MemLedger()..events.addAll(<ActivityEvent>[_ev('a'), _ev('b')]);
      final FakeCloudActivity cloud = FakeCloudActivity();
      final FakeCloudUser cloudUser = FakeCloudUser();
      final DeckoSyncRepository sync =
          _sync(auth, ledger, cloud, cloudUser, FakeSettings());

      final SyncResult r1 = await sync.syncNow();
      expect(r1.ok, isTrue);
      expect(r1.uploaded, 2);
      expect(cloud.store['u1']!.length, 2);

      final SyncResult r2 = await sync.syncNow();
      expect(cloud.store['u1']!.length, 2); // still 2 — idempotent by id
      expect(r2.downloaded, 0);
      expect(ledger.events.length, 2);
    });

    test('merges cloud-only events without deleting local-only events',
        () async {
      final FakeAuth auth = FakeAuth(const DeckoUser(uid: 'u1'));
      final MemLedger ledger = MemLedger()..events.add(_ev('local'));
      final FakeCloudActivity cloud = FakeCloudActivity()
        ..store['u1'] = <String, ActivityEvent>{'remote': _ev('remote')};
      final DeckoSyncRepository sync =
          _sync(auth, ledger, cloud, FakeCloudUser(), FakeSettings());

      final SyncResult r = await sync.syncNow();
      expect(r.downloaded, 1); // 'remote' pulled down
      final Set<String> ids =
          ledger.events.map((ActivityEvent e) => e.id).toSet();
      expect(ids, containsAll(<String>['local', 'remote'])); // local survives
      expect(cloud.store['u1']!.keys, containsAll(<String>['local', 'remote']));
    });

    test('pushes profile + safe settings only', () async {
      final FakeAuth auth = FakeAuth(const DeckoUser(uid: 'u1', email: 'a@b.com'));
      final FakeCloudUser cloudUser = FakeCloudUser();
      final FakeSettings settings = FakeSettings()
        ..theme = 'deckoDark'
        ..goal = 40;
      await _sync(auth, MemLedger(), FakeCloudActivity(), cloudUser, settings)
          .syncNow();
      expect(cloudUser.profile?.email, 'a@b.com');
      expect(cloudUser.settings['u1']?.themeId, 'deckoDark');
      expect(cloudUser.settings['u1']?.dailyGoal, 40);
    });

    test('signed-out sync is a no-op failure and never touches the ledger',
        () async {
      final MemLedger ledger = MemLedger()..events.add(_ev('local'));
      final DeckoSyncRepository sync = _sync(
          FakeAuth(), ledger, FakeCloudActivity(), FakeCloudUser(),
          FakeSettings());
      final SyncResult r = await sync.syncNow();
      expect(r.ok, isFalse);
      expect(ledger.events.length, 1); // untouched
    });

    test('LocalOnlySyncRepository never errors and asks the user to sign in',
        () async {
      const LocalOnlySyncRepository sync = LocalOnlySyncRepository();
      final SyncResult r = await sync.syncNow();
      expect(r.ok, isFalse);
      expect(r.error, contains('Sign in'));
    });
  });
}
