import 'imported_card_state.dart';

/// Practical progress carried over from an imported card.
///
/// Framework-light. Stored as *imported Anki state*, deliberately not as native
/// FSRS state (DEC-005 / docs/import-progress.md). Fields are best-effort: only
/// what the source format exposes is populated. Does not drive the scheduler in
/// this MVP.
class ImportedCardProgress {
  const ImportedCardProgress({
    required this.state,
    this.sourceCardId,
    this.sourceNoteId,
    this.dueAt,
    this.intervalDays,
    this.reps,
    this.lapses,
    this.easeFactor,
    this.lastReviewedAt,
  });

  final ImportedCardState state;
  final String? sourceCardId;
  final String? sourceNoteId;
  final DateTime? dueAt;
  final int? intervalDays;
  final int? reps;
  final int? lapses;
  final double? easeFactor;
  final DateTime? lastReviewedAt;
}
