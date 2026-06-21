import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/repositories/daily_study_counts_repository.dart';
import '../domain/study_options/daily_study_counts.dart';

/// [DailyStudyCountsRepository] backed by `shared_preferences`, one key per deck.
class SharedPrefsDailyStudyCountsRepository
    implements DailyStudyCountsRepository {
  const SharedPrefsDailyStudyCountsRepository();

  static String _key(String deckId) => 'decko.dailyCounts.$deckId';

  @override
  Future<DailyStudyCounts> getCounts(String deckId, DateTime today) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key(deckId));
    if (raw == null) return DailyStudyCounts.empty(today);
    try {
      return DailyStudyCounts.fromMap(jsonDecode(raw) as Map<String, dynamic>)
          .forDay(today); // resets when the stored day rolled over
    } catch (_) {
      return DailyStudyCounts.empty(today);
    }
  }

  @override
  Future<void> saveCounts(String deckId, DailyStudyCounts counts) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(deckId), jsonEncode(counts.toMap()));
  }
}
