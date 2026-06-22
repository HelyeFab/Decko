import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../app/decko_app.dart';
import '../../core/constants/decko_spacing.dart';
import '../../core/widgets/decko_app_bar.dart';
import '../../domain/deck.dart';
import '../../domain/import/source/imported_anki_source.dart';
import '../../domain/repositories/imported_source_store.dart';
import '../../domain/sentence_builder/sentence_builder_source.dart';
import 'sentence_builder_loader.dart';
import 'sentence_round_service.dart';

/// A practice hub listing the decks that can be played as a sentence builder
/// (MVP_016). Capability is determined from each deck's imported source; playing
/// records nothing to review/progress — it never changes the schedule (DEC-025).
class SentenceBuilderHubScreen extends StatefulWidget {
  const SentenceBuilderHubScreen({super.key});

  @override
  State<SentenceBuilderHubScreen> createState() =>
      _SentenceBuilderHubScreenState();
}

class _SentenceBuilderHubScreenState extends State<SentenceBuilderHubScreen> {
  Future<List<Deck>>? _capable;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _capable ??= _loadCapableDecks();
  }

  Future<List<Deck>> _loadCapableDecks() async {
    final ImportedSourceStore store = DeckoApp.sourceOf(context);
    final List<Deck> decks = DeckoApp.repositoryOf(context).getDecks();
    final List<Deck> capable = <Deck>[];
    for (final Deck deck in decks) {
      final ImportedAnkiSource? source =
          await store.getSourceForDeck(deck.id);
      if (deckHasLikelySentences(deck, ankiSource: source)) capable.add(deck);
    }
    return capable;
  }

  void _play(Deck deck) {
    // Capture dependencies before the async gap.
    final ImportedSourceStore store = DeckoApp.sourceOf(context);
    final SentenceRoundService service = DeckoApp.sentenceRoundsOf(context);
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (BuildContext context) => SentenceBuilderLoader(
        title: deck.name,
        load: () async {
          final ImportedAnkiSource? source =
              await store.getSourceForDeck(deck.id);
          return service.roundsForDeck(
            deck,
            ankiSource: source,
            source: SentenceBuilderSource.deckPractice,
          );
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DeckoAppBar(title: 'Sentence builder'),
      body: SafeArea(
        child: FutureBuilder<List<Deck>>(
          future: _capable,
          builder:
              (BuildContext context, AsyncSnapshot<List<Deck>> snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final List<Deck> decks = snap.data ?? const <Deck>[];
            if (decks.isEmpty) return const _NoDecks();
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                DeckoSpacing.pagePadding,
                DeckoSpacing.lg,
                DeckoSpacing.pagePadding,
                DeckoSpacing.xxxl,
              ),
              children: <Widget>[
                Text(
                  'Rebuild sentences from your decks. This is practice only — '
                  'it won’t change your review schedule.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: DeckoSpacing.lg),
                for (final Deck deck in decks) ...<Widget>[
                  _DeckTile(deck: deck, onTap: () => _play(deck)),
                  const SizedBox(height: DeckoSpacing.md),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DeckTile extends StatelessWidget {
  const _DeckTile({required this.deck, required this.onTap});

  final Deck deck;
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
              Container(
                height: 44,
                width: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(DeckoRadii.md),
                ),
                child: FaIcon(FontAwesomeIcons.cubesStacked,
                    size: 18, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: DeckoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(deck.name,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('${deck.items.length} cards',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              FaIcon(FontAwesomeIcons.play, size: 14, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoDecks extends StatelessWidget {
  const _NoDecks();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DeckoSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FaIcon(FontAwesomeIcons.cubesStacked,
                size: 44, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: DeckoSpacing.lg),
            Text('No sentences yet',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: DeckoSpacing.sm),
            Text(
              'Import a deck with example sentences to play the sentence builder.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
