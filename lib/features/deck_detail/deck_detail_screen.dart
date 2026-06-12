import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/decko_router.dart';
import '../../core/constants/decko_spacing.dart';
import '../../core/widgets/section_header.dart';
import '../../domain/deck.dart';
import '../../domain/import/deck_import_info.dart';
import '../../domain/import/imported_card_progress.dart';
import '../../domain/import/imported_card_state.dart';
import '../../domain/learning_item.dart';
import 'widgets/sample_item_row.dart';

/// Detail view for a single [Deck].
///
/// Shows the deck's title, description, card count and a sample of its items,
/// plus a placeholder progress summary. "Start review" opens the review preview
/// with this deck's first card. All figures are demo/local data for MVP_002 —
/// there is no scheduler or review history yet.
class DeckDetailScreen extends StatelessWidget {
  const DeckDetailScreen({super.key, required this.deck});

  final Deck deck;

  /// How many items to preview before "+N more".
  static const int _previewCount = 4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<LearningItem> preview = deck.items.take(_previewCount).toList();
    final int remaining = deck.itemCount - preview.length;

    return Scaffold(
      appBar: AppBar(title: Text(deck.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DeckoSpacing.pagePadding),
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  deck.isImported ? 'IMPORTED' : 'DEMO DECK',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DeckoSpacing.sm),
            Text(
              deck.name,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: DeckoSpacing.xs),
            Text(
              deck.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (deck.importInfo != null) ...<Widget>[
              const SizedBox(height: DeckoSpacing.lg),
              _ProvenanceCard(info: deck.importInfo!),
            ],
            const SizedBox(height: DeckoSpacing.xl),
            _ProgressSummary(deck: deck),
            const SizedBox(height: DeckoSpacing.xl),
            SectionHeader(
              title: 'Cards',
              subtitle: '${deck.itemCount} cards in this deck',
            ),
            const SizedBox(height: DeckoSpacing.sm),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DeckoSpacing.lg,
                  vertical: DeckoSpacing.sm,
                ),
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < preview.length; i++) ...<Widget>[
                      SampleItemRow(item: preview[i]),
                      if (i != preview.length - 1)
                        Divider(
                          height: 1,
                          color: theme.colorScheme.outlineVariant,
                        ),
                    ],
                  ],
                ),
              ),
            ),
            if (remaining > 0) ...<Widget>[
              const SizedBox(height: DeckoSpacing.sm),
              Text(
                '+$remaining more',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: DeckoSpacing.xl),
            FilledButton.icon(
              onPressed: () => context.push(DeckoRoutes.deckReview(deck.id)),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start review'),
            ),
            const SizedBox(height: DeckoSpacing.md),
            Center(
              child: Text(
                'Review modes coming soon',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProvenanceCard extends StatelessWidget {
  const _ProvenanceCard({required this.info});

  final DeckImportInfo info;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(DeckoSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(DeckoRadii.md),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.download_done_rounded,
              color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: DeckoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  info.sourceLine,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  info.progressMode.provenanceLine,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({required this.deck});

  final Deck deck;

  /// Due/Reviewed are derived from imported progress when it was kept; otherwise
  /// there is no scheduling data to report, so they stay as a dash.
  bool get _hasImportedProgress =>
      deck.importInfo?.progressMode == ImportProgressMode.kept;

  int get _reviewed => deck.items.where((LearningItem i) {
        final ImportedCardProgress? p = i.importedProgress;
        return p != null &&
            (p.state == ImportedCardState.review ||
                p.state == ImportedCardState.relearning ||
                (p.reps ?? 0) > 0);
      }).length;

  int get _dueToday {
    final DateTime now = DateTime.now();
    final DateTime endOfToday =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    return deck.items.where((LearningItem i) {
      final DateTime? due = i.importedProgress?.dueAt;
      return due != null && due.isBefore(endOfToday);
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final String due = _hasImportedProgress ? '$_dueToday' : '—';
    final String reviewed = _hasImportedProgress ? '$_reviewed' : '—';
    return Row(
      children: <Widget>[
        Expanded(
          child: _StatBox(value: '${deck.itemCount}', label: 'Total cards'),
        ),
        const SizedBox(width: DeckoSpacing.md),
        Expanded(child: _StatBox(value: due, label: 'Due today')),
        const SizedBox(width: DeckoSpacing.md),
        Expanded(child: _StatBox(value: reviewed, label: 'Reviewed')),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: DeckoSpacing.lg,
        horizontal: DeckoSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(DeckoRadii.md),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: DeckoSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
