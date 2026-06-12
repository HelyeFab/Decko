import 'import/imported_card_progress.dart';

/// A single thing to learn — the format-independent unit Decko studies.
///
/// Imported decks (Anki/CSV/JSON) are translated *into* `LearningItem`s by
/// import adapters (see DEC-002); external formats never leak past this layer.
/// Kept deliberately framework-light: no Flutter imports.
class LearningItem {
  const LearningItem({
    required this.id,
    required this.front,
    required this.back,
    this.reading,
    this.example,
    this.tags = const <String>[],
    this.importedProgress,
  });

  final String id;

  /// The prompt shown first (e.g. a word or question).
  final String front;

  /// The answer revealed after grading begins.
  final String back;

  /// Optional pronunciation / reading aid (e.g. furigana).
  final String? reading;

  /// Optional example sentence or usage note.
  final String? example;

  final List<String> tags;

  /// Imported scheduling/progress carried over from the source deck, when the
  /// user chose to keep progress; null otherwise.
  final ImportedCardProgress? importedProgress;
}
