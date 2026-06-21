// A structured, user- and test-facing summary of what Decko found inside an
// Anki package during import (MVP_013 DEC-022; turned into trust-signal UX in
// MVP_014 DEC-023). Each finding has a category + severity so the UI can group
// it calmly and derive an overall import health, with raw detail kept behind
// progressive disclosure.

/// The detected Anki package / collection variant.
enum AnkiPackageFormat { legacy2, legacy21, modern21b, unknown }

extension AnkiPackageFormatLabel on AnkiPackageFormat {
  String get label => switch (this) {
        AnkiPackageFormat.legacy2 => 'Legacy (collection.anki2)',
        AnkiPackageFormat.legacy21 => 'Legacy (collection.anki21)',
        AnkiPackageFormat.modern21b => 'Modern, zstd (collection.anki21b)',
        AnkiPackageFormat.unknown => 'Unrecognised',
      };

  /// A friendly, non-technical description for the primary UI.
  String get friendly => switch (this) {
        AnkiPackageFormat.legacy2 => 'Anki deck (older format)',
        AnkiPackageFormat.legacy21 => 'Anki deck',
        AnkiPackageFormat.modern21b => 'Anki deck (newer, compressed)',
        AnkiPackageFormat.unknown => 'Unrecognised package',
      };

  String? get collectionFile => switch (this) {
        AnkiPackageFormat.legacy2 => 'collection.anki2',
        AnkiPackageFormat.legacy21 => 'collection.anki21',
        AnkiPackageFormat.modern21b => 'collection.anki21b',
        AnkiPackageFormat.unknown => null,
      };
}

/// Where a finding belongs, for grouping in the UI.
enum DiagnosticCategory {
  package,
  collection,
  notesFields,
  templates,
  media,
  progress,
  scheduling,
}

extension DiagnosticCategoryLabel on DiagnosticCategory {
  String get label => switch (this) {
        DiagnosticCategory.package => 'Package',
        DiagnosticCategory.collection => 'Collection',
        DiagnosticCategory.notesFields => 'Notes & fields',
        DiagnosticCategory.templates => 'Card templates',
        DiagnosticCategory.media => 'Media',
        DiagnosticCategory.progress => 'Review progress',
        DiagnosticCategory.scheduling => 'Scheduling',
      };
}

/// How serious a finding is.
enum DiagnosticSeverity { info, warning, error }

/// Overall import health, derived from the findings' severities.
enum ImportHealth { healthy, usableWithWarnings, blocked }

/// One categorised finding from an import.
class ImportDiagnostic {
  const ImportDiagnostic({
    required this.category,
    required this.severity,
    required this.message,
    this.technicalDetail,
  });

  final DiagnosticCategory category;
  final DiagnosticSeverity severity;

  /// A calm, human-readable explanation (no enum names / parser jargon).
  final String message;

  /// Optional raw detail, shown only behind progressive disclosure.
  final String? technicalDetail;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'category': category.name,
        'severity': severity.name,
        'message': message,
        if (technicalDetail != null) 'technicalDetail': technicalDetail,
      };

  static ImportDiagnostic fromMap(Map<String, dynamic> m) => ImportDiagnostic(
        category: _enumByName(
            DiagnosticCategory.values, m['category'], DiagnosticCategory.package),
        severity: _enumByName(
            DiagnosticSeverity.values, m['severity'], DiagnosticSeverity.info),
        message: m['message'] as String? ?? '',
        technicalDetail: m['technicalDetail'] as String?,
      );
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
    this.findings = const <ImportDiagnostic>[],
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

  /// Categorised findings (info / warning / error).
  final List<ImportDiagnostic> findings;

  /// Set when the package cannot be imported at all; null on success.
  final String? blockingError;

  String? get collectionFile => format.collectionFile;

  bool get isBlocked => blockingError != null;

  /// Findings the user should pay attention to (warning or worse).
  List<ImportDiagnostic> get attentionFindings => findings
      .where((ImportDiagnostic d) => d.severity != DiagnosticSeverity.info)
      .toList();

  bool get hasWarnings => attentionFindings.isNotEmpty;

  /// Plain warning messages — compatibility for callers that just want strings.
  List<String> get warnings =>
      attentionFindings.map((ImportDiagnostic d) => d.message).toList();

  ImportHealth get health {
    if (isBlocked) return ImportHealth.blocked;
    if (findings.any((ImportDiagnostic d) => d.severity == DiagnosticSeverity.error)) {
      return ImportHealth.blocked;
    }
    if (hasWarnings) return ImportHealth.usableWithWarnings;
    return ImportHealth.healthy;
  }

  /// Findings grouped by category, preserving order, only where present.
  Map<DiagnosticCategory, List<ImportDiagnostic>> get byCategory {
    final Map<DiagnosticCategory, List<ImportDiagnostic>> out =
        <DiagnosticCategory, List<ImportDiagnostic>>{};
    for (final ImportDiagnostic d in findings) {
      (out[d.category] ??= <ImportDiagnostic>[]).add(d);
    }
    return out;
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'format': format.name,
        'hasMediaManifest': hasMediaManifest,
        'decks': decks,
        'notes': notes,
        'cards': cards,
        'models': models,
        'templates': templates,
        'mediaEntries': mediaEntries,
        'findings':
            findings.map((ImportDiagnostic d) => d.toMap()).toList(),
        if (blockingError != null) 'blockingError': blockingError,
      };

  static ImportDiagnostics fromMap(Map<String, dynamic> m) => ImportDiagnostics(
        format:
            _enumByName(AnkiPackageFormat.values, m['format'], AnkiPackageFormat.unknown),
        hasMediaManifest: m['hasMediaManifest'] as bool? ?? false,
        decks: m['decks'] as int? ?? 0,
        notes: m['notes'] as int? ?? 0,
        cards: m['cards'] as int? ?? 0,
        models: m['models'] as int? ?? 0,
        templates: m['templates'] as int? ?? 0,
        mediaEntries: m['mediaEntries'] as int? ?? 0,
        findings: (m['findings'] as List<dynamic>?)
                ?.map((dynamic e) =>
                    ImportDiagnostic.fromMap((e as Map).cast<String, dynamic>()))
                .toList() ??
            const <ImportDiagnostic>[],
        blockingError: m['blockingError'] as String?,
      );
}

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final T v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}
