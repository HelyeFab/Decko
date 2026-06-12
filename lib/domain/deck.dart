import 'import/deck_import_info.dart';
import 'learning_item.dart';

/// A named collection of [LearningItem]s.
///
/// This is Decko's internal deck model. Imported decks become `Deck`s through
/// adapters; the rest of the app depends only on this type (DEC-002).
class Deck {
  const Deck({
    required this.id,
    required this.name,
    required this.description,
    required this.items,
    this.importInfo,
  });

  final String id;
  final String name;
  final String description;
  final List<LearningItem> items;

  /// Provenance when this deck was imported; null for bundled demo decks.
  final DeckImportInfo? importInfo;

  int get itemCount => items.length;

  bool get isEmpty => items.isEmpty;

  /// True for decks brought in via an import adapter.
  bool get isImported => importInfo != null;
}
