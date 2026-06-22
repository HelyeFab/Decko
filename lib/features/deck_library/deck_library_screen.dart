import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../app/deck_store.dart';
import '../../app/decko_app.dart';
import '../../app/decko_router.dart';
import '../../core/constants/decko_spacing.dart';
import '../../core/constants/decko_strings.dart';
import '../../core/widgets/decko_app_bar.dart';
import '../../core/widgets/decko_confirm_dialog.dart';
import '../../core/widgets/decko_snackbar.dart';
import '../../core/widgets/promise_tile.dart';
import '../../core/widgets/section_header.dart';
import '../../domain/deck.dart';
import '../../domain/due_queue.dart';
import '../../domain/repositories/review_state_repository.dart';
import '../../domain/review_card_state.dart';
import '../practice/practice_hub_screen.dart';
import 'widgets/deck_row.dart';
import 'widgets/empty_library_card.dart';
import 'widgets/study_ribbon.dart';

/// Decko's home (MVP_008.5, Direction A — "Study ribbon").
///
/// Home answers three questions and nothing more: what can I study now, what
/// decks do I have, and how do I import another. The hero is the next study
/// action; the deck list is a calm shelf; Import is a quiet ghost row. The
/// import workflow lives on its own screen (DEC-017). The product promise grid
/// only appears in the empty state, so a learner with decks sees decks.
class DeckLibraryScreen extends StatefulWidget {
  const DeckLibraryScreen({super.key});

  @override
  State<DeckLibraryScreen> createState() => _DeckLibraryScreenState();
}

class _DeckLibraryScreenState extends State<DeckLibraryScreen> {
  /// deckId -> cards available to study now. Null entry = still loading.
  Future<Map<String, int>>? _counts;
  String _signature = '';

  Future<Map<String, int>> _loadCounts(
      List<Deck> decks, ReviewStateRepository repo) async {
    final DateTime now = DateTime.now();
    final Map<String, int> out = <String, int>{};
    for (final Deck deck in decks) {
      final List<ReviewCardState> states = await repo.getStatesForDeck(deck.id);
      final Map<String, ReviewCardState> byId = <String, ReviewCardState>{
        for (final ReviewCardState s in states) s.itemId: s,
      };
      out[deck.id] = DueQueue.build(deck.items, byId, now).length;
    }
    return out;
  }

  /// Builds the counts future once per distinct deck set; recomputed on demand
  /// (e.g. after a session) via [_reload].
  void _ensureCounts(List<Deck> decks, ReviewStateRepository repo) {
    final String sig = decks.map((Deck d) => d.id).join(',');
    if (sig != _signature || _counts == null) {
      _signature = sig;
      _counts = _loadCounts(decks, repo);
    }
  }

  void _reload(List<Deck> decks, ReviewStateRepository repo) {
    if (!mounted) return;
    final Future<Map<String, int>> next = _loadCounts(decks, repo);
    setState(() {
      _counts = next;
    });
  }

  /// Opens a route, then refreshes the live counts when it returns so the
  /// ribbon and badges reflect any study that happened.
  Future<void> _pushThenReload(
      String location, List<Deck> decks, ReviewStateRepository repo) async {
    await context.push(location);
    _reload(decks, repo);
  }

  @override
  Widget build(BuildContext context) {
    final DeckStore store = DeckoApp.deckStoreOf(context);
    final ReviewStateRepository reviewState = DeckoApp.reviewStateOf(context);

    // Import lives on its own tab now; the Home affordances switch to it.
    void openImport() => context.go(DeckoRoutes.import);

    return Scaffold(
      appBar: const DeckoAppBar.wordmark(),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: store,
          builder: (BuildContext context, _) {
            final List<Deck> decks = store.getDecks();
            _ensureCounts(decks, reviewState);

            if (decks.isEmpty) {
              return _EmptyHome(onImport: openImport, onDemo: openImport);
            }

            return FutureBuilder<Map<String, int>>(
              future: _counts,
              builder: (BuildContext context,
                  AsyncSnapshot<Map<String, int>> snap) {
                final Map<String, int>? counts = snap.data;
                return _PopulatedHome(
                  decks: decks,
                  counts: counts,
                  onOpenDeck: (Deck d) => _pushThenReload(
                      DeckoRoutes.deck(d.id), decks, reviewState),
                  onStudy: (Deck d) => _pushThenReload(
                      DeckoRoutes.deckReview(d.id), decks, reviewState),
                  onImport: openImport,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Home with at least one deck: ribbon hero, deck shelf, import ghost row.
class _PopulatedHome extends StatelessWidget {
  const _PopulatedHome({
    required this.decks,
    required this.counts,
    required this.onOpenDeck,
    required this.onStudy,
    required this.onImport,
  });

  final List<Deck> decks;
  final Map<String, int>? counts;
  final ValueChanged<Deck> onOpenDeck;
  final ValueChanged<Deck> onStudy;
  final VoidCallback onImport;

  /// Decks as study entries, ordered most-ready first so the resume deck leads
  /// the rolodex; ties keep the deck's existing order.
  List<StudyEntry> get _entries {
    final List<StudyEntry> entries = <StudyEntry>[
      for (final Deck d in decks) (deck: d, count: counts?[d.id] ?? 0),
    ];
    entries.sort((StudyEntry a, StudyEntry b) => b.count.compareTo(a.count));
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final List<StudyEntry> entries = _entries;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DeckoSpacing.pagePadding,
        DeckoSpacing.lg,
        DeckoSpacing.pagePadding,
        DeckoSpacing.xxxl,
      ),
      children: <Widget>[
        if (entries.length == 1)
          StudyRibbon(
            target: entries.first.deck,
            cardsToStudy: entries.first.count,
            onStudy: () => onStudy(entries.first.deck),
          )
        else
          StudyRolodex(entries: entries, onStudy: onStudy),
        const SizedBox(height: DeckoSpacing.xxl),
        const SectionHeader(
          title: 'Your decks',
          subtitle: 'Pick a deck to study or review.',
        ),
        const SizedBox(height: DeckoSpacing.lg),
        for (final Deck deck in decks) ...<Widget>[
          _DeckListItem(
            deck: deck,
            toStudy: counts?[deck.id],
            onOpen: () => onOpenDeck(deck),
          ),
          const SizedBox(height: DeckoSpacing.md),
        ],
        if (_hasSentenceDecks) ...<Widget>[
          const SizedBox(height: DeckoSpacing.xl),
          const SectionHeader(
            title: 'Practice',
            subtitle: 'Play with the words in your decks.',
          ),
          const SizedBox(height: DeckoSpacing.lg),
          const _PracticeRow(),
        ],
        const SizedBox(height: DeckoSpacing.lg),
        _ImportGhostRow(onTap: onImport),
      ],
    );
  }

  // The hub accurately filters to sentence-capable decks (async); the Home
  // entry just needs an imported deck to point at.
  bool get _hasSentenceDecks => decks.any((Deck d) => d.isImported);
}

/// The Home entry into the practice hub (MVP_016; registry-driven in MVP_017).
class _PracticeRow extends StatelessWidget {
  const _PracticeRow();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(DeckoRadii.lg),
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (BuildContext context) => const PracticeHubScreen(),
        )),
        child: Ink(
          padding: const EdgeInsets.all(DeckoSpacing.lg),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(DeckoRadii.lg),
          ),
          child: Row(
            children: <Widget>[
              Container(
                height: 44,
                width: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.onPrimaryContainer.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(DeckoRadii.md),
                ),
                child: FaIcon(FontAwesomeIcons.gamepad,
                    size: 18, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: DeckoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Practice modes',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(height: 2),
                    Text('Play with the words in your decks',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onPrimaryContainer.withValues(alpha: 0.85),
                        )),
                  ],
                ),
              ),
              FaIcon(FontAwesomeIcons.play,
                  size: 14, color: scheme.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

/// A deck row on Home. Imported decks can be swiped left to delete (with
/// confirmation); demo decks are not deletable.
class _DeckListItem extends StatelessWidget {
  const _DeckListItem({
    required this.deck,
    required this.toStudy,
    required this.onOpen,
  });

  final Deck deck;
  final int? toStudy;
  final VoidCallback onOpen;

  Future<bool> _confirmDelete(BuildContext context) {
    return DeckoConfirmDialog.show(
      context,
      icon: FontAwesomeIcons.trashCan,
      title: 'Delete “${deck.name}”?',
      message: 'This removes the deck and its review progress from Decko. '
          'Your original Anki file is untouched.',
      confirmLabel: 'Delete deck',
      destructive: true,
    );
  }

  void _delete(BuildContext context) {
    DeckoApp.deckStoreOf(context).removeImportedDeck(deck.id);
    DeckoApp.reviewStateOf(context).resetDeckStates(deck.id);
    DeckoApp.mediaOf(context).deleteMediaForDeck(deck.id);
    DeckoApp.sourceOf(context).deleteSourceForDeck(deck.id);
    DeckoApp.studyOptionsOf(context).deleteDeckOptions(deck.id);
    DeckoSnackbar.showInfo(context, 'Deleted “${deck.name}”.');
  }

  @override
  Widget build(BuildContext context) {
    final DeckRow row =
        DeckRow(deck: deck, toStudy: toStudy, onTap: onOpen);
    if (!deck.isImported) return row;

    final ColorScheme scheme = Theme.of(context).colorScheme;
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
        child:
            FaIcon(FontAwesomeIcons.trashCan, color: scheme.onErrorContainer),
      ),
      child: row,
    );
  }
}

/// The calm, quiet import affordance at the foot of the shelf.
class _ImportGhostRow extends StatelessWidget {
  const _ImportGhostRow({required this.onTap});

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
        child: DottedOutline(
          color: scheme.outline,
          radius: DeckoRadii.lg,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DeckoSpacing.lg,
              vertical: DeckoSpacing.lg,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FaIcon(FontAwesomeIcons.plus,
                    size: 15, color: scheme.primary),
                const SizedBox(width: DeckoSpacing.sm),
                Text(
                  DeckoStrings.importCta,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Home before any deck exists: the inviting empty card plus the product
/// promise grid (the only place the marketing grid still lives, MVP_008.5).
class _EmptyHome extends StatelessWidget {
  const _EmptyHome({required this.onImport, required this.onDemo});

  final VoidCallback onImport;
  final VoidCallback onDemo;

  static const List<FaIconData> _promiseIcons = <FaIconData>[
    FontAwesomeIcons.clock,
    FontAwesomeIcons.palette,
    FontAwesomeIcons.fire,
    FontAwesomeIcons.puzzlePiece,
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
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
        EmptyLibraryCard(onImport: onImport, onDemo: onDemo),
        const SizedBox(height: DeckoSpacing.xxl),
        const SectionHeader(
          title: 'Why you’ll love Decko',
          subtitle: 'Everything coming to your study sessions.',
        ),
        const SizedBox(height: DeckoSpacing.lg),
        _PromiseGrid(icons: _promiseIcons),
      ],
    );
  }
}

class _PromiseGrid extends StatelessWidget {
  const _PromiseGrid({required this.icons});

  final List<FaIconData> icons;

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

/// A rounded dashed border used by the import ghost row.
class DottedOutline extends StatelessWidget {
  const DottedOutline({
    super.key,
    required this.child,
    required this.color,
    required this.radius,
  });

  final Widget child;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: color, radius: radius),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final RRect rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final Path path = Path()..addRRect(rrect);

    const double dash = 6;
    const double gap = 5;
    for (final ui in path.computeMetrics()) {
      double distance = 0;
      while (distance < ui.length) {
        canvas.drawPath(
          ui.extractPath(distance, distance + dash),
          paint,
        );
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
