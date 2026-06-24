// MVP_022: deck fingerprinting, review-state DTO round-trip, and the
// conflict-safe merge policy. Pure domain — no Firebase.

import 'package:flutter_test/flutter_test.dart';

import 'package:decko/data/sync/review_state_sync_service.dart';
import 'package:decko/domain/auth/auth_repository.dart';
import 'package:decko/domain/auth/auth_state.dart';
import 'package:decko/domain/auth/decko_user.dart';
import 'package:decko/domain/deck.dart';
import 'package:decko/domain/import/deck_import_info.dart';
import 'package:decko/domain/import/imported_card_progress.dart';
import 'package:decko/domain/import/imported_card_state.dart';
import 'package:decko/domain/learning_item.dart';
import 'package:decko/domain/repositories/review_state_repository.dart';
import 'package:decko/domain/review_card_state.dart';
import 'package:decko/domain/sync/cloud_review_state_repository.dart';
import 'package:decko/domain/sync/deck_fingerprint.dart';
import 'package:decko/domain/sync/review_state_merge_policy.dart';
import 'package:decko/domain/sync/syncable_review_state.dart';

LearningItem _ankiItem(int cardId, {int? noteId}) => LearningItem(
      id: 'anki-card-$cardId',
      front: 'f',
      back: 'b',
      importedProgress: ImportedCardProgress(
        state: ImportedCardState.review,
        sourceNoteId: noteId == null ? null : 'note-$noteId',
      ),
    );

Deck _importedDeck(String name, List<LearningItem> items) => Deck(
      id: 'local-$name',
      name: name,
      description: '',
      items: items,
      importInfo: DeckImportInfo(
        progressMode: ImportProgressMode.fresh,
        importedAt: DateTime(2026),
      ),
    );

SyncableReviewState _state({
  String itemId = 'anki-card-1',
  DateTime? lastReviewed,
  int reps = 0,
  int lapses = 0,
  ReviewQueueState queue = ReviewQueueState.review,
}) =>
    SyncableReviewState(
      itemId: itemId,
      queueState: reps == 0 && lastReviewed == null
          ? ReviewQueueState.newCard
          : queue,
      reps: reps,
      lapses: lapses,
      intervalDays: reps,
      updatedAt: lastReviewed ?? DateTime(2026),
      lastReviewedAt: lastReviewed,
    );

class _MemReviewState implements ReviewStateRepository {
  final Map<String, Map<String, ReviewCardState>> byDeck =
      <String, Map<String, ReviewCardState>>{};
  @override
  Future<List<ReviewCardState>> getStatesForDeck(String deckId) async =>
      byDeck[deckId]?.values.toList() ?? <ReviewCardState>[];
  @override
  Future<ReviewCardState?> getState(String deckId, String itemId) async =>
      byDeck[deckId]?[itemId];
  @override
  Future<void> saveState(ReviewCardState s) async => byDeck
      .putIfAbsent(s.deckId, () => <String, ReviewCardState>{})[s.itemId] = s;
  @override
  Future<void> saveStates(List<ReviewCardState> states) async {
    for (final ReviewCardState s in states) {
      await saveState(s);
    }
  }

  @override
  Future<void> resetDeckStates(String deckId) async => byDeck.remove(deckId);
}

class _MemCloud implements CloudReviewStateRepository {
  final Map<String, Map<String, SyncableReviewState>> byKey =
      <String, Map<String, SyncableReviewState>>{};
  @override
  Future<void> upsertStates(String uid, DeckFingerprint fp,
      List<SyncableReviewState> states) async {
    final Map<String, SyncableReviewState> m = byKey.putIfAbsent(
        '$uid/${fp.key}', () => <String, SyncableReviewState>{});
    for (final SyncableReviewState s in states) {
      m[s.itemId] = s;
    }
  }

  @override
  Future<List<SyncableReviewState>> fetchStates(
          String uid, DeckFingerprint fp) async =>
      byKey['$uid/${fp.key}']?.values.toList() ?? <SyncableReviewState>[];
}

class _FakeAuth implements AuthRepository {
  _FakeAuth(this._user);
  final DeckoUser? _user;
  @override
  DeckoUser? get currentUser => _user;
  @override
  Stream<AuthState> authStateChanges() => Stream<AuthState>.value(AuthState(_user));
  @override
  Future<DeckoUser> signInAnonymously() => throw UnimplementedError();
  @override
  Future<DeckoUser> signInWithEmail(String e, String p) => throw UnimplementedError();
  @override
  Future<DeckoUser> createAccountWithEmail(String e, String p) => throw UnimplementedError();
  @override
  Future<DeckoUser> signInWithGoogle() => throw UnimplementedError();
  @override
  Future<void> signOut() async {}
}

ReviewCardState _reviewState(String deckId, String itemId,
        {int reps = 0, int lapses = 0, DateTime? lastReviewed}) =>
    ReviewCardState(
      deckId: deckId,
      itemId: itemId,
      queueState: reps > 0 ? ReviewQueueState.review : ReviewQueueState.newCard,
      reps: reps,
      lapses: lapses,
      intervalDays: reps,
      lastReviewedAt: lastReviewed,
    );

void main() {
  const DeckFingerprinter fp = DeckFingerprinter();

  group('deck fingerprint (MVP_022)', () {
    test('the same imported deck yields the same fingerprint, order-independent',
        () {
      final DeckFingerprint? a = fp.fingerprint(_importedDeck('Core', <LearningItem>[
        _ankiItem(1, noteId: 1),
        _ankiItem(2, noteId: 2),
        _ankiItem(3, noteId: 3),
      ]));
      // Same cards, different local deck id + item order (a "second device").
      final DeckFingerprint? b = fp.fingerprint(_importedDeck('Core', <LearningItem>[
        _ankiItem(3, noteId: 3),
        _ankiItem(1, noteId: 1),
        _ankiItem(2, noteId: 2),
      ]));
      expect(a, isNotNull);
      expect(a!.key, b!.key);
      expect(a.cardIdHash, b.cardIdHash);
      expect(a, equals(b));
    });

    test('different card sets produce different fingerprints', () {
      final DeckFingerprint a =
          fp.fingerprint(_importedDeck('Core', <LearningItem>[_ankiItem(1), _ankiItem(2)]))!;
      final DeckFingerprint b =
          fp.fingerprint(_importedDeck('Core', <LearningItem>[_ankiItem(1), _ankiItem(9)]))!;
      expect(a.key, isNot(b.key));
    });

    test('non-imported / non-anki decks are not fingerprintable', () {
      final Deck demo = Deck(
        id: 'demo',
        name: 'Demo',
        description: '',
        items: const <LearningItem>[LearningItem(id: 'demo-1', front: 'a', back: 'b')],
      );
      expect(fp.fingerprint(demo), isNull);
      // An imported deck whose ids aren't stable anki ids is also rejected.
      final Deck mixed = _importedDeck('Mixed', const <LearningItem>[
        LearningItem(id: 'not-anki', front: 'a', back: 'b'),
      ]);
      expect(fp.fingerprint(mixed), isNull);
    });
  });

  group('syncable review-state DTO (MVP_022)', () {
    test('round-trips through JSON and back to a ReviewCardState', () {
      final ReviewCardState original = ReviewCardState(
        deckId: 'd',
        itemId: 'anki-card-7',
        queueState: ReviewQueueState.review,
        dueAt: DateTime(2026, 7, 1),
        reps: 12,
        lapses: 2,
        intervalDays: 30,
        easeFactor: 2.5,
        lastReviewedAt: DateTime(2026, 6, 1),
        stability: 40.5,
        difficulty: 5.2,
        schedulerVersion: 'fsrs-5',
      );
      final SyncableReviewState dto = SyncableReviewState.fromReviewCardState(
          original, updatedAt: DateTime(2026, 6, 1), deviceId: 'dev-1');
      final SyncableReviewState back =
          SyncableReviewState.fromJson(dto.toJson());
      final ReviewCardState rebuilt = back.toReviewCardState('d');
      expect(rebuilt.itemId, 'anki-card-7');
      expect(rebuilt.reps, 12);
      expect(rebuilt.lapses, 2);
      expect(rebuilt.intervalDays, 30);
      expect(rebuilt.stability, 40.5);
      expect(rebuilt.difficulty, 5.2);
      expect(rebuilt.queueState, ReviewQueueState.review);
      expect(rebuilt.schedulerVersion, 'fsrs-5');
    });
  });

  group('merge policy (MVP_022)', () {
    const ReviewStateMergePolicy policy = ReviewStateMergePolicy();

    test('adopts cloud progress onto a fresh local card', () {
      final MergeDecision d = policy.decide(
        _state(), // local: new card, no progress
        _state(reps: 5, lastReviewed: DateTime(2026, 6, 10)),
      );
      expect(d, MergeDecision.useCloud);
    });

    test('keeps local when cloud has no progress', () {
      final MergeDecision d = policy.decide(
        _state(reps: 5, lastReviewed: DateTime(2026, 6, 10)),
        _state(), // cloud: blank
      );
      expect(d, MergeDecision.keepLocal);
    });

    test('newer, non-regressing cloud wins', () {
      final MergeDecision d = policy.decide(
        _state(reps: 5, lapses: 1, lastReviewed: DateTime(2026, 6, 1)),
        _state(reps: 8, lapses: 1, lastReviewed: DateTime(2026, 6, 10)),
      );
      expect(d, MergeDecision.useCloud);
    });

    test('older cloud never overwrites newer local', () {
      final MergeDecision d = policy.decide(
        _state(reps: 8, lastReviewed: DateTime(2026, 6, 10)),
        _state(reps: 5, lastReviewed: DateTime(2026, 6, 1)),
      );
      expect(d, MergeDecision.keepLocal);
    });

    test('newer cloud that REGRESSES reps is a conflict, not an overwrite', () {
      final MergeDecision d = policy.decide(
        _state(reps: 12, lapses: 3, lastReviewed: DateTime(2026, 6, 1)),
        // Newer timestamp but fewer reps → suspicious, never silently applied.
        _state(reps: 4, lapses: 3, lastReviewed: DateTime(2026, 6, 10)),
      );
      expect(d, MergeDecision.conflict);
    });
  });

  group('review-state sync service (MVP_022)', () {
    final Deck deck = _importedDeck('Core', <LearningItem>[
      _ankiItem(1, noteId: 1),
      _ankiItem(2, noteId: 2),
      _ankiItem(3, noteId: 3),
      _ankiItem(4, noteId: 4),
    ]);
    const DeckoUser user = DeckoUser(uid: 'u1', email: 'a@b.com');

    ReviewStateSyncService service(_MemReviewState local, _MemCloud cloud,
            {DeckoUser? as = user}) =>
        ReviewStateSyncService(
            auth: _FakeAuth(as), reviewState: local, cloud: cloud);

    test('pushStates uploads only reviewed cards', () async {
      final _MemReviewState local = _MemReviewState();
      final _MemCloud cloud = _MemCloud();
      await service(local, cloud).pushStates(deck, <ReviewCardState>[
        _reviewState(deck.id, 'anki-card-1',
            reps: 5, lastReviewed: DateTime(2026, 6, 10)),
        _reviewState(deck.id, 'anki-card-2'), // new, never reviewed
      ]);
      final List<SyncableReviewState> cloudStates =
          await cloud.fetchStates('u1', fp.fingerprint(deck)!);
      expect(cloudStates.map((SyncableReviewState s) => s.itemId),
          <String>['anki-card-1']);
    });

    test('applies cloud progress to fresh local cards only', () async {
      final _MemReviewState local = _MemReviewState()
        ..byDeck[deck.id] = <String, ReviewCardState>{
          'anki-card-1': _reviewState(deck.id, 'anki-card-1'), // fresh
        };
      final _MemCloud cloud = _MemCloud()
        ..byKey['u1/${fp.fingerprint(deck)!.key}'] =
            <String, SyncableReviewState>{
          'anki-card-1': _state(
              itemId: 'anki-card-1', reps: 7, lastReviewed: DateTime(2026, 6, 10)),
          'anki-card-99': _state(
              itemId: 'anki-card-99', reps: 3, lastReviewed: DateTime(2026, 6, 9)),
        };
      final ReviewApplyResult r = await service(local, cloud).applyToDeck(deck);
      expect(r.applied, 1); // card-1 adopted
      expect(r.unmatched, 1); // card-99 has no local card
      expect(local.byDeck[deck.id]!['anki-card-1']!.reps, 7);
    });

    test('never overwrites a more-advanced local card', () async {
      final _MemReviewState local = _MemReviewState()
        ..byDeck[deck.id] = <String, ReviewCardState>{
          'anki-card-1': _reviewState(deck.id, 'anki-card-1',
              reps: 20, lastReviewed: DateTime(2026, 6, 20)),
        };
      final _MemCloud cloud = _MemCloud()
        ..byKey['u1/${fp.fingerprint(deck)!.key}'] =
            <String, SyncableReviewState>{
          'anki-card-1': _state(reps: 5, lastReviewed: DateTime(2026, 6, 1)),
        };
      final ReviewApplyResult r = await service(local, cloud).applyToDeck(deck);
      expect(r.applied, 0);
      expect(local.byDeck[deck.id]!['anki-card-1']!.reps, 20); // untouched
    });

    test('signed-out is a no-op (no push, no apply)', () async {
      final _MemReviewState local = _MemReviewState();
      final _MemCloud cloud = _MemCloud()
        ..byKey['u1/${fp.fingerprint(deck)!.key}'] =
            <String, SyncableReviewState>{
          'anki-card-1': _state(reps: 7, lastReviewed: DateTime(2026, 6, 10)),
        };
      final ReviewStateSyncService svc = service(local, cloud, as: null);
      await svc.pushStates(deck, <ReviewCardState>[
        _reviewState(deck.id, 'anki-card-1', reps: 5, lastReviewed: DateTime(2026)),
      ]);
      final ReviewApplyResult r = await svc.applyToDeck(deck);
      expect(r.applied, 0);
    });
  });
}
