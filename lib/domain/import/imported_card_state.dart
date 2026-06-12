/// The practical state of a card imported from an external deck.
///
/// Decko's neutral representation of "new / learning / review / relearning /
/// suspended" — it does not mirror any one scheduler's internals (per
/// docs/import-progress.md). It does not power scheduling yet.
enum ImportedCardState {
  isNew,
  learning,
  review,
  relearning,
  suspended;

  String get label => switch (this) {
        ImportedCardState.isNew => 'New',
        ImportedCardState.learning => 'Learning',
        ImportedCardState.review => 'Review',
        ImportedCardState.relearning => 'Relearning',
        ImportedCardState.suspended => 'Suspended',
      };
}
