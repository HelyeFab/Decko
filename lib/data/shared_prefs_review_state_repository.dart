import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/repositories/review_state_repository.dart';
import '../domain/review_card_state.dart';

/// [ReviewStateRepository] backed by `shared_preferences`: one JSON blob per
/// deck under `decko.reviewState.<deckId>` (DEC-011).
///
/// Per-deck blobs keep reads/writes scoped to the deck in play. For very large
/// decks the whole blob is rewritten on save, so the review screen flushes once
/// on leaving a session rather than per grade (a real DB would remove that
/// trade-off later).
class SharedPrefsReviewStateRepository implements ReviewStateRepository {
  const SharedPrefsReviewStateRepository();

  static const String _prefix = 'decko.reviewState.';

  String _key(String deckId) => '$_prefix$deckId';

  @override
  Future<List<ReviewCardState>> getStatesForDeck(String deckId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key(deckId));
    if (raw == null) return const <ReviewCardState>[];
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((dynamic m) =>
              _fromMap(deckId, m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const <ReviewCardState>[];
    }
  }

  @override
  Future<ReviewCardState?> getState(String deckId, String itemId) async {
    final List<ReviewCardState> all = await getStatesForDeck(deckId);
    for (final ReviewCardState s in all) {
      if (s.itemId == itemId) return s;
    }
    return null;
  }

  @override
  Future<void> saveState(ReviewCardState state) =>
      saveStates(<ReviewCardState>[state]);

  @override
  Future<void> saveStates(List<ReviewCardState> states) async {
    if (states.isEmpty) return;
    final String deckId = states.first.deckId;
    final Map<String, ReviewCardState> merged = <String, ReviewCardState>{
      for (final ReviewCardState s in await getStatesForDeck(deckId))
        s.itemId: s,
      for (final ReviewCardState s in states) s.itemId: s,
    };
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(deckId),
      jsonEncode(merged.values.map(_toMap).toList(growable: false)),
    );
  }

  @override
  Future<void> resetDeckStates(String deckId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(deckId));
  }

  // --- serialisation ---------------------------------------------------------

  Map<String, dynamic> _toMap(ReviewCardState s) => <String, dynamic>{
        'itemId': s.itemId,
        'queueState': s.queueState.name,
        'dueAt': s.dueAt?.toIso8601String(),
        'reps': s.reps,
        'lapses': s.lapses,
        'intervalDays': s.intervalDays,
        'easeFactor': s.easeFactor,
        'lastReviewedAt': s.lastReviewedAt?.toIso8601String(),
        'sourceSystem': s.sourceSystem,
      };

  ReviewCardState _fromMap(String deckId, Map<String, dynamic> m) =>
      ReviewCardState(
        deckId: deckId,
        itemId: m['itemId'] as String,
        queueState: ReviewQueueState.values.byName(m['queueState'] as String),
        dueAt: _date(m['dueAt']),
        reps: (m['reps'] as int?) ?? 0,
        lapses: (m['lapses'] as int?) ?? 0,
        intervalDays: (m['intervalDays'] as int?) ?? 0,
        easeFactor: (m['easeFactor'] as num?)?.toDouble(),
        lastReviewedAt: _date(m['lastReviewedAt']),
        sourceSystem: (m['sourceSystem'] as String?) ?? 'decko',
      );

  DateTime? _date(dynamic v) => v == null ? null : DateTime.parse(v as String);
}
