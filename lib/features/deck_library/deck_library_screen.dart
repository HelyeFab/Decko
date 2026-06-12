import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/deck_store.dart';
import '../../app/decko_app.dart';
import '../../app/decko_router.dart';
import '../../core/constants/decko_spacing.dart';
import '../../core/constants/decko_strings.dart';
import '../../core/widgets/decko_snackbar.dart';
import '../../core/widgets/promise_tile.dart';
import '../../core/widgets/section_header.dart';
import '../../domain/deck.dart';
import 'widgets/deck_tile.dart';
import 'widgets/empty_library_card.dart';

/// Decko's home: the deck library.
///
/// Renders the local decks from the [DeckRepository]. When the repository has
/// no decks the MVP_001 empty state is shown as a fallback. Theme gallery and
/// progress remain reachable from the app bar.
class DeckLibraryScreen extends StatelessWidget {
  const DeckLibraryScreen({super.key});

  static const List<IconData> _promiseIcons = <IconData>[
    Icons.schedule_rounded,
    Icons.palette_rounded,
    Icons.local_fire_department_rounded,
    Icons.extension_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final DeckStore store = DeckoApp.deckStoreOf(context);

    void openImport() => context.push(DeckoRoutes.import);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: DeckoSpacing.pagePadding,
        title: Text(
          DeckoStrings.wordmark,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.primary,
            letterSpacing: -0.5,
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Theme gallery',
            icon: const Icon(Icons.palette_outlined),
            onPressed: () => context.push(DeckoRoutes.themes),
          ),
          IconButton(
            tooltip: 'Progress',
            icon: const Icon(Icons.insights_rounded),
            onPressed: () => context.push(DeckoRoutes.progress),
          ),
          const SizedBox(width: DeckoSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: store,
          builder: (BuildContext context, _) {
            final List<Deck> decks = store.getDecks();
            final bool hasDecks = decks.isNotEmpty;
            void openDemo() => context.push(
                  hasDecks
                      ? DeckoRoutes.deck(decks.first.id)
                      : DeckoRoutes.import,
                );

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                DeckoSpacing.pagePadding,
                DeckoSpacing.sm,
                DeckoSpacing.pagePadding,
                DeckoSpacing.xxxl,
              ),
              children: <Widget>[
                Text(
                  DeckoStrings.tagline,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: DeckoSpacing.xl),
                if (!hasDecks)
                  EmptyLibraryCard(onImport: openImport, onDemo: openDemo)
                else
                  _DeckList(
                      decks: decks, onImport: openImport, onDemo: openDemo),
                const SizedBox(height: DeckoSpacing.xxl),
                const SectionHeader(
                  title: 'Why you’ll love Decko',
                  subtitle: 'Everything coming to your study sessions.',
                ),
                const SizedBox(height: DeckoSpacing.lg),
                _PromiseGrid(icons: _promiseIcons),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DeckList extends StatelessWidget {
  const _DeckList({
    required this.decks,
    required this.onImport,
    required this.onDemo,
  });

  final List<Deck> decks;
  final VoidCallback onImport;
  final VoidCallback onDemo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SectionHeader(
          title: 'Your decks',
          subtitle: 'Pick a deck to start studying.',
        ),
        const SizedBox(height: DeckoSpacing.lg),
        for (final Deck deck in decks) ...<Widget>[
          _DeckListItem(deck: deck),
          const SizedBox(height: DeckoSpacing.md),
        ],
        const SizedBox(height: DeckoSpacing.sm),
        FilledButton.icon(
          onPressed: onImport,
          icon: const Icon(Icons.add_rounded),
          label: const Text(DeckoStrings.importCta),
        ),
        const SizedBox(height: DeckoSpacing.md),
        OutlinedButton.icon(
          onPressed: onDemo,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text(DeckoStrings.demoCta),
        ),
      ],
    );
  }
}

/// A deck row in the library. Imported decks can be swiped left to delete
/// (with confirmation); demo decks are not deletable.
class _DeckListItem extends StatelessWidget {
  const _DeckListItem({required this.deck});

  final Deck deck;

  void _open(BuildContext context) => context.push(DeckoRoutes.deck(deck.id));

  Future<bool> _confirmDelete(BuildContext context) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Delete “${deck.name}”?'),
        content: const Text(
          'This removes the deck and its review progress from Decko. '
          'Your original Anki file is untouched.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  void _delete(BuildContext context) {
    DeckoApp.deckStoreOf(context).removeImportedDeck(deck.id);
    DeckoApp.reviewStateOf(context).resetDeckStates(deck.id);
    DeckoSnackbar.showInfo(context, 'Deleted “${deck.name}”.');
  }

  @override
  Widget build(BuildContext context) {
    final DeckTile tile = DeckTile(deck: deck, onTap: () => _open(context));
    if (!deck.isImported) return tile;

    final scheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey<String>('deck-${deck.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => _delete(context),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: DeckoSpacing.xl),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(DeckoRadii.lg),
        ),
        child: Icon(Icons.delete_outline_rounded,
            color: scheme.onErrorContainer),
      ),
      child: tile,
    );
  }
}

class _PromiseGrid extends StatelessWidget {
  const _PromiseGrid({required this.icons});

  final List<IconData> icons;

  @override
  Widget build(BuildContext context) {
    final List<(String, String)> promises = DeckoStrings.promises;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: promises.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: DeckoSpacing.md,
        crossAxisSpacing: DeckoSpacing.md,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (BuildContext context, int index) {
        final (String title, String blurb) = promises[index];
        return PromiseTile(
          icon: icons[index % icons.length],
          title: title,
          blurb: blurb,
        );
      },
    );
  }
}
