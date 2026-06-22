import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../app/decko_app.dart';
import '../../core/constants/decko_spacing.dart';
import '../../core/widgets/decko_app_bar.dart';
import '../../core/widgets/section_header.dart';
import '../../domain/deck.dart';
import '../../domain/import/source/imported_anki_source.dart';
import '../../domain/practice/practice_mode.dart';
import '../../domain/repositories/imported_source_store.dart';
import '../../domain/repositories/practice_mode_registry.dart';
import 'practice_launcher.dart';
import 'widgets/practice_mode_tile.dart';

typedef _DeckModes = ({Deck deck, List<PracticeMode> modes});

/// The central place for Decko's playful practice layer (MVP_017). Lists the
/// registered practice modes that are available, and the decks that support
/// them — discovered through the [PracticeModeRegistry], not hard-coded.
class PracticeHubScreen extends StatefulWidget {
  const PracticeHubScreen({super.key});

  @override
  State<PracticeHubScreen> createState() => _PracticeHubScreenState();
}

class _PracticeHubScreenState extends State<PracticeHubScreen> {
  Future<List<_DeckModes>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<List<_DeckModes>> _load() async {
    final ImportedSourceStore store = DeckoApp.sourceOf(context);
    final PracticeModeRegistry registry = DeckoApp.practiceRegistryOf(context);
    final List<Deck> decks = DeckoApp.repositoryOf(context).getDecks();
    final List<_DeckModes> out = <_DeckModes>[];
    for (final Deck deck in decks) {
      final ImportedAnkiSource? source =
          await store.getSourceForDeck(deck.id);
      final List<PracticeMode> modes =
          registry.availableForDeck(deck, source: source);
      if (modes.isNotEmpty) out.add((deck: deck, modes: modes));
    }
    return out;
  }

  void _openMode(PracticeMode mode, List<_DeckModes> supporting) {
    final List<Deck> decks = <Deck>[
      for (final _DeckModes d in supporting)
        if (d.modes.any((PracticeMode m) => m.id == mode.id)) d.deck,
    ];
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (BuildContext context) =>
          _ModeDeckPicker(mode: mode, decks: decks),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DeckoAppBar(title: 'Practice'),
      body: SafeArea(
        child: FutureBuilder<List<_DeckModes>>(
          future: _future,
          builder:
              (BuildContext context, AsyncSnapshot<List<_DeckModes>> snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final List<_DeckModes> supporting = snap.data ?? const <_DeckModes>[];
            if (supporting.isEmpty) return const _Empty();

            // Distinct modes available somewhere, in registry order.
            final List<PracticeMode> modes = <PracticeMode>[];
            for (final _DeckModes d in supporting) {
              for (final PracticeMode m in d.modes) {
                if (!modes.any((PracticeMode x) => x.id == m.id)) modes.add(m);
              }
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                DeckoSpacing.pagePadding,
                DeckoSpacing.lg,
                DeckoSpacing.pagePadding,
                DeckoSpacing.xxxl,
              ),
              children: <Widget>[
                const SectionHeader(
                  title: 'Available now',
                  subtitle: 'Ways to practise the words you’re learning.',
                ),
                const SizedBox(height: DeckoSpacing.lg),
                for (final PracticeMode mode in modes) ...<Widget>[
                  PracticeModeTile(
                    mode: mode,
                    accent: true,
                    onTap: () => _openMode(mode, supporting),
                  ),
                  const SizedBox(height: DeckoSpacing.md),
                ],
                const SizedBox(height: DeckoSpacing.xl),
                const SectionHeader(
                  title: 'From your decks',
                  subtitle: 'Decks that support a practice mode.',
                ),
                const SizedBox(height: DeckoSpacing.lg),
                for (final _DeckModes d in supporting) ...<Widget>[
                  _DeckRow(deck: d.deck, modes: d.modes),
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

/// A deck row that launches its (single) mode, or expands its modes if several.
class _DeckRow extends StatelessWidget {
  const _DeckRow({required this.deck, required this.modes});

  final Deck deck;
  final List<PracticeMode> modes;

  void _tap(BuildContext context) {
    if (modes.length == 1) {
      PracticeLauncher.launchDeck(context, modes.first, deck);
    } else {
      showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext sheet) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final PracticeMode mode in modes)
                ListTile(
                  leading: FaIcon(practiceModeIcon(mode.id), size: 18),
                  title: Text(mode.title),
                  onTap: () {
                    Navigator.of(sheet).pop();
                    PracticeLauncher.launchDeck(context, mode, deck);
                  },
                ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(DeckoRadii.lg),
        onTap: () => _tap(context),
        child: Ink(
          padding: const EdgeInsets.all(DeckoSpacing.lg),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(DeckoRadii.lg),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(deck.name,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(modes.map((PracticeMode m) => m.title).join(' · '),
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

/// Lists the decks that support a chosen mode, to pick one and play.
class _ModeDeckPicker extends StatelessWidget {
  const _ModeDeckPicker({required this.mode, required this.decks});

  final PracticeMode mode;
  final List<Deck> decks;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DeckoAppBar(title: mode.title),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            DeckoSpacing.pagePadding,
            DeckoSpacing.lg,
            DeckoSpacing.pagePadding,
            DeckoSpacing.xxxl,
          ),
          children: <Widget>[
            Text(mode.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
            const SizedBox(height: DeckoSpacing.lg),
            for (final Deck deck in decks) ...<Widget>[
              _PickerDeckTile(
                deck: deck,
                onTap: () => PracticeLauncher.launchDeck(context, mode, deck),
              ),
              const SizedBox(height: DeckoSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}

class _PickerDeckTile extends StatelessWidget {
  const _PickerDeckTile({required this.deck, required this.onTap});

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

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DeckoSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FaIcon(FontAwesomeIcons.gamepad,
                size: 44, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: DeckoSpacing.lg),
            Text('No practice modes yet',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: DeckoSpacing.sm),
            Text(
              'Import a deck with sentences to unlock practice modes.',
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
