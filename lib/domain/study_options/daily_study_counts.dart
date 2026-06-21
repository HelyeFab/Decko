// Per-deck record of what's been studied *today* (MVP_012, DEC-021): how many
// new / review cards were consumed, and which source notes were touched (for
// sibling burying). Drives true daily limits — reopening a session the same day
// keeps the remaining allowance; a new day resets it. Pure, framework-light.

/// Counts + studied-note set for one deck on one calendar day.
class DailyStudyCounts {
  const DailyStudyCounts({
    required this.day,
    this.newStudied = 0,
    this.reviewStudied = 0,
    this.studiedNoteIds = const <String>{},
  });

  /// The local calendar day these counts belong to (`yyyy-M-d`).
  final String day;
  final int newStudied;
  final int reviewStudied;

  /// Source note ids with at least one card studied today (for burying).
  final Set<String> studiedNoteIds;

  /// Deterministic local-day key, used as the rollover boundary.
  static String dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  static DailyStudyCounts empty(DateTime today) =>
      DailyStudyCounts(day: dayKey(today));

  /// These counts if still today, else a fresh zeroed record for [today].
  DailyStudyCounts forDay(DateTime today) =>
      day == dayKey(today) ? this : DailyStudyCounts.empty(today);

  /// Cards still allowed today given a daily [limit] (never negative).
  int remainingNew(int limit) => (limit - newStudied).clamp(0, limit);
  int remainingReview(int limit) => (limit - reviewStudied).clamp(0, limit);

  /// Records one studied card of the given kind, plus its note id (if known).
  DailyStudyCounts record({required bool isNew, String? noteId}) {
    return DailyStudyCounts(
      day: day,
      newStudied: newStudied + (isNew ? 1 : 0),
      reviewStudied: reviewStudied + (isNew ? 0 : 1),
      studiedNoteIds: noteId == null
          ? studiedNoteIds
          : <String>{...studiedNoteIds, noteId},
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'day': day,
        'newStudied': newStudied,
        'reviewStudied': reviewStudied,
        'studiedNoteIds': studiedNoteIds.toList(),
      };

  static DailyStudyCounts fromMap(Map<String, dynamic> m) => DailyStudyCounts(
        day: m['day'] as String? ?? '',
        newStudied: m['newStudied'] as int? ?? 0,
        reviewStudied: m['reviewStudied'] as int? ?? 0,
        studiedNoteIds:
            (m['studiedNoteIds'] as List<dynamic>?)?.cast<String>().toSet() ??
                const <String>{},
      );
}
