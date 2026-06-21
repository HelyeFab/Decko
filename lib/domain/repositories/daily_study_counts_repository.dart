import '../study_options/daily_study_counts.dart';

/// Persists per-deck daily study counts so true daily limits survive across
/// sessions on the same day and reset at the day boundary (MVP_012, DEC-021).
abstract class DailyStudyCountsRepository {
  /// Today's counts for the deck — zeroed automatically when the day rolled
  /// over since they were last saved.
  Future<DailyStudyCounts> getCounts(String deckId, DateTime today);

  Future<void> saveCounts(String deckId, DailyStudyCounts counts);
}
