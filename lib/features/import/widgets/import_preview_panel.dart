import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/constants/decko_spacing.dart';
import '../../../domain/import/deck_import_preview.dart';
import '../../../domain/import/import_diagnostics.dart';

/// Shows what an import adapter found and lets the user choose how to import.
///
/// When progress data exists, offers "Keep Anki progress" / "Start fresh".
/// Otherwise it honestly warns that cards will start as new.
class ImportPreviewPanel extends StatelessWidget {
  const ImportPreviewPanel({
    super.key,
    required this.preview,
    required this.onKeepProgress,
    required this.onStartFresh,
    required this.onCancel,
  });

  final DeckImportPreview preview;
  final VoidCallback onKeepProgress;
  final VoidCallback onStartFresh;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasProgress = preview.hasProgressData;
    final ImportDiagnostics? diag = preview.diagnostics;
    final List<String> warnings = diag?.warnings ?? preview.notes;

    return ListView(
      padding: const EdgeInsets.all(DeckoSpacing.pagePadding),
      children: <Widget>[
        Text(
          'Deck found',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: DeckoSpacing.xs),
        Text(
          preview.deckName,
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: DeckoSpacing.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DeckoSpacing.lg,
              vertical: DeckoSpacing.sm,
            ),
            child: Column(
              children: <Widget>[
                _Stat(label: 'Cards found', value: '${preview.totalCards}'),
                _Stat(label: 'New cards', value: '${preview.newCards}'),
                _Stat(
                    label: 'Already reviewed',
                    value: '${preview.reviewedCards}'),
                if (preview.suspendedCards > 0)
                  _Stat(
                      label: 'Suspended', value: '${preview.suspendedCards}'),
                if (preview.approxDueToday != null)
                  _Stat(
                    label: 'Due today (approx.)',
                    value: '${preview.approxDueToday}',
                  ),
                _Stat(
                  label: 'Progress data',
                  value: hasProgress ? 'Available' : 'Not found',
                ),
                if (preview.hasMedia) ...<Widget>[
                  if (preview.audioRefs > 0)
                    _Stat(
                        label: 'Audio references',
                        value: '${preview.audioRefs}'),
                  if (preview.imageRefs > 0)
                    _Stat(
                        label: 'Image references',
                        value: '${preview.imageRefs}'),
                  _Stat(
                      label: 'Media files', value: '${preview.mediaFiles}'),
                ],
                if (diag != null) ...<Widget>[
                  _Stat(
                      label: 'Collection',
                      value: diag.collectionFile ?? 'Unknown'),
                  if (diag.models > 0)
                    _Stat(label: 'Note types', value: '${diag.models}'),
                  if (diag.templates > 0)
                    _Stat(
                        label: 'Card templates',
                        value: '${diag.templates}'),
                ],
              ],
            ),
          ),
        ),
        if (warnings.isNotEmpty) ...<Widget>[
          const SizedBox(height: DeckoSpacing.md),
          _Warnings(warnings: warnings),
        ],
        const SizedBox(height: DeckoSpacing.xl),
        if (hasProgress) ...<Widget>[
          Text(
            'Decko found progress in this deck. You can keep it or start fresh.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: DeckoSpacing.lg),
          FilledButton.icon(
            onPressed: onKeepProgress,
            icon: const FaIcon(FontAwesomeIcons.clockRotateLeft),
            label: const Text('Keep Anki progress'),
          ),
          const SizedBox(height: DeckoSpacing.md),
          OutlinedButton.icon(
            onPressed: onStartFresh,
            icon: const FaIcon(FontAwesomeIcons.seedling),
            label: const Text('Start fresh'),
          ),
        ] else ...<Widget>[
          Container(
            padding: const EdgeInsets.all(DeckoSpacing.lg),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(DeckoRadii.md),
            ),
            child: Text(
              'Decko could not find scheduling information in this package. '
              'Your cards can still be imported, but they will start as new.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: DeckoSpacing.lg),
          FilledButton.icon(
            onPressed: onStartFresh,
            icon: const FaIcon(FontAwesomeIcons.plus),
            label: const Text('Import as new'),
          ),
        ],
        const SizedBox(height: DeckoSpacing.md),
        TextButton(onPressed: onCancel, child: const Text('Cancel')),
      ],
    );
  }
}

/// Non-blocking import warnings in a soft, attention-getting block.
class _Warnings extends StatelessWidget {
  const _Warnings({required this.warnings});

  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(DeckoSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(DeckoRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < warnings.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: DeckoSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: FaIcon(FontAwesomeIcons.triangleExclamation,
                      size: 13, color: scheme.onTertiaryContainer),
                ),
                const SizedBox(width: DeckoSpacing.sm),
                Expanded(
                  child: Text(
                    warnings[i],
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onTertiaryContainer),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DeckoSpacing.sm),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
