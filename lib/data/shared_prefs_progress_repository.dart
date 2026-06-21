import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/progress_snapshot.dart';
import '../domain/repositories/progress_repository.dart';
import '../domain/review_session_result.dart';

/// [ProgressRepository] backed by `shared_preferences`, storing the snapshot as
/// a single JSON blob.
///
/// The clock is injectable so streak/"today" logic is deterministic in tests.
class SharedPrefsProgressRepository implements ProgressRepository {
  const SharedPrefsProgressRepository({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  static const String _key = 'decko.progress.snapshot';

  @override
  Future<ProgressSnapshot> getSnapshot() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key);
    if (raw == null) return ProgressSnapshot.empty;
    return _decode(raw);
  }

  @override
  Future<void> recordSessionResult(ReviewSessionResult result) async {
    final ProgressSnapshot current = await getSnapshot();
    final ProgressSnapshot next = current.recordingSession(result, _clock());
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _encode(next));
  }

  @override
  Future<void> resetProgress() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  // --- serialisation ---------------------------------------------------------

  String _encode(ProgressSnapshot s) {
    final ReviewSessionResult? last = s.lastSessionResult;
    return jsonEncode(<String, dynamic>{
      'totalXp': s.totalXp,
      'currentStreakDays': s.currentStreakDays,
      'cardsReviewedToday': s.cardsReviewedToday,
      'longestStreakDays': s.longestStreakDays,
      'lastReviewedAt': s.lastReviewedAt?.toIso8601String(),
      'lastSessionResult': last == null
          ? null
          : <String, dynamic>{
              'deckId': last.deckId,
              'totalCards': last.totalCards,
              'again': last.againCount,
              'hard': last.hardCount,
              'good': last.goodCount,
              'easy': last.easyCount,
            },
    });
  }

  ProgressSnapshot _decode(String raw) {
    final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
    final Map<String, dynamic>? last =
        map['lastSessionResult'] as Map<String, dynamic>?;
    final String? lastReviewedAt = map['lastReviewedAt'] as String?;

    return ProgressSnapshot(
      totalXp: (map['totalXp'] as int?) ?? 0,
      currentStreakDays: (map['currentStreakDays'] as int?) ?? 0,
      // Back-fill for snapshots saved before longestStreak existed.
      longestStreakDays: (map['longestStreakDays'] as int?) ??
          (map['currentStreakDays'] as int?) ??
          0,
      cardsReviewedToday: (map['cardsReviewedToday'] as int?) ?? 0,
      lastReviewedAt:
          lastReviewedAt == null ? null : DateTime.parse(lastReviewedAt),
      lastSessionResult: last == null
          ? null
          : ReviewSessionResult(
              deckId: last['deckId'] as String,
              totalCards: last['totalCards'] as int,
              againCount: last['again'] as int,
              hardCount: last['hard'] as int,
              goodCount: last['good'] as int,
              easyCount: last['easy'] as int,
            ),
    );
  }
}
