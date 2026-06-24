import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../app/decko_app.dart';
import '../../app/decko_router.dart';
import '../../core/widgets/decko_app_bar.dart';
import '../../core/constants/decko_spacing.dart';
import '../../core/widgets/section_header.dart';
import '../../domain/deck.dart';
import '../../domain/import/deck_import_info.dart';
import '../../domain/learning_item.dart';
import '../../domain/practice/practice_mode.dart';
import '../../domain/review_card_state.dart';
import '../practice/practice_launcher.dart';
import '../practice/widgets/practice_mode_tile.dart';
import 'widgets/review_sync_banner.dart';
import 'widgets/sample_item_row.dart';

/// Detail view for a single [Deck].
///
/// Shows the deck's title, description, card count, a sample of its items, and
/// live Due today / Reviewed counts from persisted review state. "Start review"
/// opens the due-queue session; on return the counts are reloaded so they
/// reflect the just-finished review (DEC-011).
class DeckDetailScreen extends StatefulWidget {
  const DeckDetailScreen({super.key, required this.deck});

  final Deck deck;

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  /// How many items to preview before "+N more".
  static const int _previewCount = 4;

  Future<List<ReviewCardState>>? _statesFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _statesFuture ??= _loadStates();
  }

  Future<List<ReviewCardState>> _loadStates() =>
      DeckoApp.reviewStateOf(context).getStatesForDeck(widget.deck.id);

  void _reload() {
    setState(() {
      _statesFuture = _loadStates();
    });
  }

  /// Opens the review session and refreshes the counts once it returns.
  Future<void> _startReview() async {
    await context.push(DeckoRoutes.deckReview(widget.deck.id));
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final Deck deck = widget.deck;
    final theme = Theme.of(context);
    final List<LearningItem> preview = deck.items.take(_previewCount).toList();
    final int remaining = deck.itemCount - preview.length;

    return Scaffold(
      appBar: DeckoAppBar(title: deck.name),
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
            ReviewSyncBanner(deck: deck, onApplied: _reload),
            _ProgressSummary(deck: deck, statesFuture: _statesFuture),
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
              onPressed: _startReview,
              icon: const FaIcon(FontAwesomeIcons.play),
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
            const SizedBox(height: DeckoSpacing.xl),
            _DeckActionTile(
              icon: FontAwesomeIcons.sliders,
              title: 'Deck options',
              subtitle: 'Daily limits, audio, images, and readings',
              onTap: () => context.push(DeckoRoutes.deckOptions(deck.id)),
            ),
            if (deck.isImported) ...<Widget>[
              if (deck.importInfo?.diagnostics != null) ...<Widget>[
                const SizedBox(height: DeckoSpacing.md),
                _DeckActionTile(
                  icon: FontAwesomeIcons.clipboardCheck,
                  title: 'Import report',
                  subtitle: 'What Decko found when it imported this deck',
                  onTap: () => context.push(DeckoRoutes.deckReport(deck.id)),
                ),
              ],
              const SizedBox(height: DeckoSpacing.md),
              _DeckActionTile(
                icon: FontAwesomeIcons.layerGroup,
                title: 'View imported source',
                subtitle: 'Original Anki fields, tags, and card templates',
                onTap: () => context.push(DeckoRoutes.deckSource(deck.id)),
              ),
            ],
            _PracticeModesSection(deck: deck),
          ],
        ),
      ),
    );
  }
}

/// The deck's available practice modes, discovered via the registry (MVP_017).
/// Hidden when the deck supports none.
class _PracticeModesSection extends StatelessWidget {
  const _PracticeModesSection({required this.deck});

  final Deck deck;

  @override
  Widget build(BuildContext context) {
    final List<PracticeMode> modes =
        DeckoApp.practiceRegistryOf(context).availableForDeck(deck);
    if (modes.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: DeckoSpacing.xl),
        const SectionHeader(
          title: 'Practice modes',
          subtitle: 'Other ways to test yourself — practice only.',
        ),
        const SizedBox(height: DeckoSpacing.lg),
        for (final PracticeMode mode in modes) ...<Widget>[
          PracticeModeTile(
            mode: mode,
            onTap: () => PracticeLauncher.launchDeck(context, mode, deck),
          ),
          const SizedBox(height: DeckoSpacing.md),
        ],
      ],
    );
  }
}

/// A quiet, tappable row linking to a deck-scoped screen.
class _DeckActionTile extends StatelessWidget {
  const _DeckActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final FaIconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(DeckoRadii.lg),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(DeckoSpacing.lg),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(DeckoRadii.lg),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: <Widget>[
              FaIcon(icon, size: 18, color: scheme.primary),
              const SizedBox(width: DeckoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              FaIcon(FontAwesomeIcons.chevronRight,
                  size: 14, color: scheme.onSurfaceVariant),
            ],
          ),
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
          FaIcon(FontAwesomeIcons.download,
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

/// Live Due today / Reviewed counts, read from persisted review state so they
/// reflect actual study (and decrement after review) rather than fixed numbers.
class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({required this.deck, required this.statesFuture});

  final Deck deck;
  final Future<List<ReviewCardState>>? statesFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ReviewCardState>>(
      future: statesFuture,
      builder: (BuildContext context,
          AsyncSnapshot<List<ReviewCardState>> snap) {
        final String due;
        final String reviewed;
        if (!snap.hasData) {
          due = '…';
          reviewed = '…';
        } else {
          final DateTime now = DateTime.now();
          final List<ReviewCardState> states = snap.data!;
          due = '${states.where((s) => s.isDueForReview(now)).length}';
          reviewed = '${states.where((s) => s.hasBeenReviewed).length}';
        }
        return Row(
          children: <Widget>[
            Expanded(
              child:
                  _StatBox(value: '${deck.itemCount}', label: 'Total cards'),
            ),
            const SizedBox(width: DeckoSpacing.md),
            Expanded(child: _StatBox(value: due, label: 'Due today')),
            const SizedBox(width: DeckoSpacing.md),
            Expanded(child: _StatBox(value: reviewed, label: 'Reviewed')),
          ],
        );
      },
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
