import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/constants/decko_spacing.dart';
import '../../../domain/import/import_diagnostics.dart';

/// A calm, Decko-styled "import health" panel (MVP_014, DEC-023).
///
/// Turns structured [ImportDiagnostics] into a trust signal: a status header,
/// a friendly metadata row, grouped findings by category, and a collapsed
/// "Technical details" disclosure — no enum names or parser noise up front.
/// Reused by the import preview and the deck's import report.
class ImportHealthSummary extends StatelessWidget {
  const ImportHealthSummary({super.key, required this.diagnostics});

  final ImportDiagnostics diagnostics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _StatusHeader(diagnostics: diagnostics),
        const SizedBox(height: DeckoSpacing.md),
        _MetaChips(diagnostics: diagnostics),
        if (diagnostics.attentionFindings.isNotEmpty) ...<Widget>[
          const SizedBox(height: DeckoSpacing.lg),
          _Findings(findings: diagnostics.attentionFindings),
        ],
        const SizedBox(height: DeckoSpacing.md),
        _TechnicalDetails(diagnostics: diagnostics),
      ],
    );
  }
}

({FaIconData icon, String title, String subtitle, Color bg, Color fg})
    _healthStyle(ImportDiagnostics d, ColorScheme scheme) {
  switch (d.health) {
    case ImportHealth.healthy:
      return (
        icon: FontAwesomeIcons.solidCircleCheck,
        title: 'Deck looks good',
        subtitle:
            'Decko found your notes, cards, and templates and didn’t detect '
                'anything that should affect study.',
        bg: scheme.primaryContainer,
        fg: scheme.onPrimaryContainer,
      );
    case ImportHealth.usableWithWarnings:
      return (
        icon: FontAwesomeIcons.triangleExclamation,
        title: 'Imported with a few notes',
        subtitle:
            'You can study this deck. Some media or template details may not '
                'appear exactly like they do in Anki.',
        bg: scheme.tertiaryContainer,
        fg: scheme.onTertiaryContainer,
      );
    case ImportHealth.blocked:
      return (
        icon: FontAwesomeIcons.circleXmark,
        title: 'Couldn’t import this deck',
        subtitle: d.blockingError ??
            'The file may be corrupted or use a structure Decko doesn’t '
                'support. Try exporting the deck again from Anki.',
        bg: scheme.errorContainer,
        fg: scheme.onErrorContainer,
      );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.diagnostics});

  final ImportDiagnostics diagnostics;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final style = _healthStyle(diagnostics, scheme);
    return Container(
      padding: const EdgeInsets.all(DeckoSpacing.lg),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(DeckoRadii.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FaIcon(style.icon, size: 22, color: style.fg),
          const SizedBox(width: DeckoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  style.title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: style.fg, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  style.subtitle,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: style.fg.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChips extends StatelessWidget {
  const _MetaChips({required this.diagnostics});

  final ImportDiagnostics diagnostics;

  @override
  Widget build(BuildContext context) {
    final ImportDiagnostics d = diagnostics;
    return Wrap(
      spacing: DeckoSpacing.sm,
      runSpacing: DeckoSpacing.sm,
      children: <Widget>[
        _Chip(icon: FontAwesomeIcons.fileLines, label: d.format.friendly),
        _Chip(icon: FontAwesomeIcons.noteSticky, label: _count(d.notes, 'note')),
        _Chip(icon: FontAwesomeIcons.layerGroup, label: _count(d.cards, 'card')),
        if (d.templates > 0)
          _Chip(
              icon: FontAwesomeIcons.clone,
              label: _count(d.templates, 'template')),
        if (d.mediaEntries > 0)
          _Chip(
              icon: FontAwesomeIcons.photoFilm,
              label: _count(d.mediaEntries, 'media file')),
      ],
    );
  }

  static String _count(int n, String noun) =>
      '$n $noun${n == 1 ? '' : 's'}';
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final FaIconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DeckoSpacing.md,
        vertical: DeckoSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(DeckoRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FaIcon(icon, size: 13, color: scheme.onSurfaceVariant),
          const SizedBox(width: DeckoSpacing.sm),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _Findings extends StatelessWidget {
  const _Findings({required this.findings});

  final List<ImportDiagnostic> findings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Map<DiagnosticCategory, List<ImportDiagnostic>> grouped =
        <DiagnosticCategory, List<ImportDiagnostic>>{};
    for (final ImportDiagnostic f in findings) {
      (grouped[f.category] ??= <ImportDiagnostic>[]).add(f);
    }

    return Container(
      padding: const EdgeInsets.all(DeckoSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(DeckoRadii.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final MapEntry<DiagnosticCategory, List<ImportDiagnostic>> e
              in grouped.entries) ...<Widget>[
            if (e.key != grouped.entries.first.key)
              const SizedBox(height: DeckoSpacing.lg),
            Text(
              e.key.label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.primary,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: DeckoSpacing.sm),
            for (final ImportDiagnostic f in e.value) _FindingRow(finding: f),
          ],
        ],
      ),
    );
  }
}

class _FindingRow extends StatelessWidget {
  const _FindingRow({required this.finding});

  final ImportDiagnostic finding;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color color = switch (finding.severity) {
      DiagnosticSeverity.error => scheme.error,
      DiagnosticSeverity.warning => scheme.tertiary,
      DiagnosticSeverity.info => scheme.onSurfaceVariant,
    };
    final FaIconData icon = switch (finding.severity) {
      DiagnosticSeverity.error => FontAwesomeIcons.circleXmark,
      DiagnosticSeverity.warning => FontAwesomeIcons.triangleExclamation,
      DiagnosticSeverity.info => FontAwesomeIcons.circleInfo,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DeckoSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: FaIcon(icon, size: 13, color: color),
          ),
          const SizedBox(width: DeckoSpacing.sm),
          Expanded(
            child: Text(finding.message, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// Collapsed disclosure with raw package metadata + per-finding detail.
class _TechnicalDetails extends StatefulWidget {
  const _TechnicalDetails({required this.diagnostics});

  final ImportDiagnostics diagnostics;

  @override
  State<_TechnicalDetails> createState() => _TechnicalDetailsState();
}

class _TechnicalDetailsState extends State<_TechnicalDetails> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final ImportDiagnostics d = widget.diagnostics;
    final List<String> details = <String>[
      'Package format: ${d.format.label}',
      if (d.collectionFile != null) 'Collection file: ${d.collectionFile}',
      'Media manifest: ${d.hasMediaManifest ? 'present' : 'none'}',
      'Decks: ${d.decks} · Notes: ${d.notes} · Cards: ${d.cards} · '
          'Note types: ${d.models} · Templates: ${d.templates} · '
          'Media: ${d.mediaEntries}',
      for (final ImportDiagnostic f in d.findings)
        if (f.technicalDetail != null) '• ${f.technicalDetail}',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InkWell(
          borderRadius: BorderRadius.circular(DeckoRadii.sm),
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: DeckoSpacing.xs),
            child: Row(
              children: <Widget>[
                Text(
                  'TECHNICAL DETAILS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Icon(_open ? Icons.expand_less : Icons.expand_more,
                    color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
        if (_open)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DeckoSpacing.md),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(DeckoRadii.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final String line in details)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      line,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontFeatures: const <FontFeature>[],
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
