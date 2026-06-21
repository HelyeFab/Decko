import 'import_diagnostics.dart';

/// How imported progress was handled for an imported deck.
enum ImportProgressMode {
  /// The user kept the source deck's progress.
  kept,

  /// The user chose to start the cards fresh.
  fresh,

  /// The source had no usable scheduling/progress data.
  unavailable;

  /// Line shown on the deck detail provenance section.
  String get provenanceLine => switch (this) {
        ImportProgressMode.kept => 'Progress: kept from Anki',
        ImportProgressMode.fresh => 'Progress: started fresh',
        ImportProgressMode.unavailable => 'Progress: no scheduling data found',
      };
}

/// Provenance for a deck that was imported rather than bundled as a demo.
///
/// Present only on imported decks (demo decks leave `Deck.importInfo` null).
class DeckImportInfo {
  const DeckImportInfo({
    required this.progressMode,
    required this.importedAt,
    this.sourceName = 'Anki',
    this.diagnostics,
  });

  final ImportProgressMode progressMode;
  final DateTime importedAt;
  final String sourceName;

  /// The import report for this deck, kept so it can be revisited from deck
  /// detail (MVP_014). Null for decks imported before this was recorded.
  final ImportDiagnostics? diagnostics;

  String get sourceLine => 'Imported from $sourceName';
}
