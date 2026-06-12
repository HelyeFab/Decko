/// A read-only summary of what an import adapter found in a package, shown to
/// the user before they confirm the import.
///
/// Counts are best-effort; [approxDueToday] is intentionally nullable and
/// labelled "approximate" in the UI because due-date interpretation is uncertain
/// across source formats.
class DeckImportPreview {
  const DeckImportPreview({
    required this.deckName,
    required this.totalCards,
    required this.newCards,
    required this.reviewedCards,
    required this.suspendedCards,
    required this.hasProgressData,
    this.approxDueToday,
    this.notes = const <String>[],
  });

  final String deckName;
  final int totalCards;
  final int newCards;
  final int reviewedCards;
  final int suspendedCards;

  /// Whether any usable scheduling/progress data was detected.
  final bool hasProgressData;

  /// Approximate cards due today, or null if it couldn't be derived safely.
  final int? approxDueToday;

  /// Caveats worth surfacing (e.g. multiple decks collapsed into one).
  final List<String> notes;
}
