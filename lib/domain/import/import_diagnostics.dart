// A structured, user- and test-facing summary of what Decko found inside an
// Anki package during import (MVP_013, DEC-022). Surfaced in the import preview
// and asserted in tests, so import outcomes are explainable rather than opaque.

/// The detected Anki package / collection variant.
enum AnkiPackageFormat {
  /// `collection.anki2` — very old, uncompressed.
  legacy2,

  /// `collection.anki21` — legacy, uncompressed (the common "Support older
  /// Anki versions" export).
  legacy21,

  /// `collection.anki21b` — modern, zstd-compressed (Anki 2.1.50+).
  modern21b,

  /// No recognisable Anki collection inside the package.
  unknown,
}

extension AnkiPackageFormatLabel on AnkiPackageFormat {
  String get label => switch (this) {
        AnkiPackageFormat.legacy2 => 'Legacy (collection.anki2)',
        AnkiPackageFormat.legacy21 => 'Legacy (collection.anki21)',
        AnkiPackageFormat.modern21b => 'Modern, zstd (collection.anki21b)',
        AnkiPackageFormat.unknown => 'Unrecognised',
      };

  String? get collectionFile => switch (this) {
        AnkiPackageFormat.legacy2 => 'collection.anki2',
        AnkiPackageFormat.legacy21 => 'collection.anki21',
        AnkiPackageFormat.modern21b => 'collection.anki21b',
        AnkiPackageFormat.unknown => null,
      };
}

/// What Decko detected and extracted from an Anki package.
class ImportDiagnostics {
  const ImportDiagnostics({
    required this.format,
    this.hasMediaManifest = false,
    this.decks = 0,
    this.notes = 0,
    this.cards = 0,
    this.models = 0,
    this.templates = 0,
    this.mediaEntries = 0,
    this.warnings = const <String>[],
    this.blockingError,
  });

  final AnkiPackageFormat format;
  final bool hasMediaManifest;
  final int decks;
  final int notes;
  final int cards;
  final int models;
  final int templates;
  final int mediaEntries;

  /// Non-blocking issues — the deck still imports (e.g. missing media).
  final List<String> warnings;

  /// Set when the package cannot be imported at all; null on success.
  final String? blockingError;

  bool get hasWarnings => warnings.isNotEmpty;
  bool get isBlocked => blockingError != null;

  String? get collectionFile => format.collectionFile;

  ImportDiagnostics copyWith({
    int? decks,
    int? notes,
    int? cards,
    int? models,
    int? templates,
    int? mediaEntries,
    bool? hasMediaManifest,
    List<String>? warnings,
    String? blockingError,
  }) {
    return ImportDiagnostics(
      format: format,
      hasMediaManifest: hasMediaManifest ?? this.hasMediaManifest,
      decks: decks ?? this.decks,
      notes: notes ?? this.notes,
      cards: cards ?? this.cards,
      models: models ?? this.models,
      templates: templates ?? this.templates,
      mediaEntries: mediaEntries ?? this.mediaEntries,
      warnings: warnings ?? this.warnings,
      blockingError: blockingError ?? this.blockingError,
    );
  }
}
