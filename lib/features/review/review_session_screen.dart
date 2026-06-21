import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../app/decko_app.dart';
import '../../app/decko_router.dart';
import '../../app/furigana_controller.dart';
import '../../app/theme/card_theme_config.dart';
import '../../core/constants/decko_spacing.dart';
import '../../core/content/anki_content.dart';
import '../../core/widgets/decko_card.dart';
import '../../data/fsrs_scheduling_policy.dart';
import '../../data/simple_review_scheduler.dart';
import '../../domain/deck.dart';
import '../../domain/due_queue.dart';
import '../../domain/learning_item.dart';
import '../../domain/repositories/review_scheduler.dart';
import '../../domain/repositories/review_state_repository.dart';
import '../../domain/review_card_state.dart';
import '../../domain/review_rating.dart';
import '../../domain/review_scheduling_policy.dart';
import '../../domain/review_session.dart';
import '../../domain/review_session_result.dart';
import '../../domain/repositories/daily_study_counts_repository.dart';
import '../../domain/repositories/imported_source_store.dart';
import '../../domain/repositories/study_options_repository.dart';
import '../../domain/import/source/imported_anki_source.dart';
import '../../domain/study_options/daily_study_counts.dart';
import '../../domain/study_options/study_options.dart';
import 'widgets/rating_button_row.dart';
import 'widgets/session_summary.dart';

/// A real review session over a deck's **due queue**.
///
/// On open it loads per-card [ReviewCardState], builds the due queue, and walks
/// it card by card. Grading applies the (temporary) [ReviewSchedulingPolicy],
/// updates state in memory so the due count moves live, and flushes the changed
/// states to the [ReviewStateRepository] when the session ends or the screen is
/// left (DEC-011). The [ReviewScheduler] still drives in-session position.
class ReviewSessionScreen extends StatefulWidget {
  const ReviewSessionScreen({
    super.key,
    required this.deck,
    this.scheduler = const SimpleReviewScheduler(),
    this.policy = const FsrsSchedulingPolicy(),
  });

  final Deck deck;
  final ReviewScheduler scheduler;
  final ReviewSchedulingPolicy policy;

  @override
  State<ReviewSessionScreen> createState() => _ReviewSessionScreenState();
}

class _ReviewSessionScreenState extends State<ReviewSessionScreen> {
  ReviewStateRepository? _repo;
  final Map<String, ReviewCardState> _states = <String, ReviewCardState>{};
  final Map<String, ReviewCardState> _changed = <String, ReviewCardState>{};

  /// Effective study options for this deck (caps + media + furigana). Falls
  /// back to defaults until loaded.
  EffectiveStudyOptions _options =
      EffectiveStudyOptions.resolve(StudyOptions.defaults, null);
  final AudioPlayer _autoplayer = AudioPlayer();

  /// True daily limits + sibling burying (MVP_012).
  DailyStudyCountsRepository? _countsRepo;
  DailyStudyCounts _daily = DailyStudyCounts.empty(DateTime(2000));
  bool _dailyDirty = false;
  Map<String, String> _noteIdByItemId = const <String, String>{};
  final Random _random = Random();

  ReviewSession? _session;
  bool _loading = true;
  bool _revealed = false;
  bool _recorded = false;
  bool _initialised = false;
  CardThemeStyle _cardStyle = CardThemeStyle.minimal;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialised) {
      _initialised = true;
      _repo = DeckoApp.reviewStateOf(context);
      _load();
    }
  }

  @override
  void dispose() {
    _flush(); // best-effort for non-button exits (e.g. system back)
    _autoplayer.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    // Capture repos/stores before awaiting so we don't use context across gaps.
    final StudyOptionsRepository optionsRepo = DeckoApp.studyOptionsOf(context);
    _countsRepo = DeckoApp.dailyCountsOf(context);
    final ImportedSourceStore sourceStore = DeckoApp.sourceOf(context);
    final DateTime now = DateTime.now();

    final List<ReviewCardState> stored =
        await _repo!.getStatesForDeck(widget.deck.id);
    _options = await optionsRepo.getEffectiveOptions(widget.deck.id);
    _daily = await _countsRepo!.getCounts(widget.deck.id, now);
    _noteIdByItemId = await _loadNoteMap(sourceStore);
    _states
      ..clear()
      ..addEntries(stored.map((s) => MapEntry<String, ReviewCardState>(
          s.itemId, s)));
    if (!mounted) return;
    setState(() {
      _session = _buildSession();
      _loading = false;
    });
    _autoplayQuestion();
  }

  /// Maps each item to its source Anki note id (for sibling burying): from
  /// imported progress when present, else from the preserved source's card
  /// links. Empty for decks with no Anki source (demo decks).
  Future<Map<String, String>> _loadNoteMap(ImportedSourceStore store) async {
    final Map<String, String> map = <String, String>{};
    for (final LearningItem item in widget.deck.items) {
      final String? nid = item.importedProgress?.sourceNoteId;
      if (nid != null) map[item.id] = nid;
    }
    final ImportedAnkiSource? source =
        await store.getSourceForDeck(widget.deck.id);
    if (source != null) {
      for (final ImportedAnkiCardSource c in source.cardSources) {
        map.putIfAbsent('anki-card-${c.sourceCardId}', () => c.sourceNoteId);
      }
    }
    return map;
  }

  ReviewSession _buildSession() {
    // Caps respect what's already been studied *today* (true daily limits,
    // MVP_012); burying drops same-note siblings. State is never touched —
    // only which cards enter the queue.
    final List<LearningItem> queue = DueQueue.build(
      widget.deck.items,
      _states,
      DateTime.now(),
      maxNew: _daily.remainingNew(_options.newCardsPerDay),
      maxReview: _daily.remainingReview(_options.reviewCardsPerDay),
      maxSession: _options.maxSessionCards,
      newCardOrder: _options.newCardOrder,
      random: _random,
      noteIdByItemId: _noteIdByItemId,
      studiedNotesToday: _daily.studiedNoteIds,
      buryByNote: _options.burySiblingsUntilTomorrow,
    );
    return ReviewSession(
        deckId: widget.deck.id, items: List<LearningItem>.unmodifiable(queue));
  }

  void _reveal() {
    setState(() => _revealed = true);
    _autoplayAnswer();
  }

  /// Plays the first audio on the question side when a card appears, if the
  /// deck's autoplay mode asks for it.
  void _autoplayQuestion() {
    if (_options.audioAutoplayMode != AudioAutoplayMode.beforeQuestion) return;
    final LearningItem? item = _session?.currentItem;
    if (item != null) _play(_firstAudio(item.front));
  }

  /// Plays the answer-side audio after the reveal, if configured.
  void _autoplayAnswer() {
    if (_options.audioAutoplayMode != AudioAutoplayMode.afterReveal) return;
    final LearningItem? item = _session?.currentItem;
    if (item == null) return;
    _play(_firstAudio(item.back) ??
        _firstAudio(item.example ?? '') ??
        _firstAudio(item.front));
  }

  String? _firstAudio(String field) {
    for (final AnkiSegment seg in parseAnkiContent(field)) {
      if (seg is AudioSegment) return seg.fileName;
    }
    return null;
  }

  Future<void> _play(String? fileName) async {
    if (fileName == null) return;
    final String? path =
        await DeckoApp.mediaOf(context).resolveMedia(widget.deck.id, fileName);
    if (path == null || !mounted) return;
    try {
      await _autoplayer.stop();
      await _autoplayer.play(DeviceFileSource(path));
    } catch (_) {/* autoplay is best-effort */}
  }

  void _rate(ReviewRating rating) {
    final ReviewSession session = _session!;
    final LearningItem item = session.currentItem!;
    final DateTime now = DateTime.now();

    final ReviewCardState current = _states[item.id] ??
        ReviewCardState.newCard(deckId: widget.deck.id, itemId: item.id);
    // Count this card against today's allowance by its pre-grade kind, and mark
    // its note studied (for burying) — before the policy mutates the state.
    _daily = _daily.record(
        isNew: current.isNew, noteId: _noteIdByItemId[item.id]);
    _dailyDirty = true;
    final ReviewCardState next = widget.policy.next(current, rating, now);
    _states[item.id] = next;
    _changed[item.id] = next;

    setState(() {
      _session = widget.scheduler.answerCurrentCard(
        session: session,
        rating: rating,
        answeredAt: now,
      );
      _revealed = false;
    });
    if (_session!.isComplete) {
      _onComplete();
    } else {
      _autoplayQuestion();
    }
  }

  void _toggleReveal() {
    final bool next = !_revealed;
    setState(() => _revealed = next);
    if (next) _autoplayAnswer();
  }

  void _onComplete() {
    if (_recorded) return;
    _recorded = true;
    final ReviewSessionResult result =
        widget.scheduler.completeSession(_session!);
    DeckoApp.progressOf(context).recordSessionResult(result);
    _flush();
  }

  /// Persists changed states + today's study counts, once. Awaited before
  /// leaving so the deck detail reads fresh counts; also best-effort from
  /// dispose. Daily counts persist so a second same-day session keeps the
  /// remaining allowance (MVP_012).
  Future<void> _flush() async {
    if (_dailyDirty && _countsRepo != null) {
      _dailyDirty = false;
      await _countsRepo!.saveCounts(widget.deck.id, _daily);
    }
    if (_changed.isEmpty || _repo == null) return;
    final List<ReviewCardState> pending = _changed.values.toList();
    _changed.clear();
    await _repo!.saveStates(pending);
  }

  void _restart() {
    setState(() {
      _session = _buildSession();
      _revealed = false;
      _recorded = false;
    });
  }

  /// Flushes review state, then returns to the deck (which reloads its counts).
  Future<void> _leave() async {
    await _flush();
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(DeckoRoutes.deck(widget.deck.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ReviewSession? session = _session;
    final bool reviewing =
        session != null && !session.isEmpty && !session.isComplete;
    return PopScope(
      // Intercept the app-bar/system back so state is flushed before we leave.
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.deck.name),
          actions: reviewing
              ? <Widget>[
                  _furiganaToggle(),
                  _cardThemeMenu(),
                  const SizedBox(width: DeckoSpacing.sm)
                ]
              : null,
        ),
        body: SafeArea(child: _body()),
      ),
    );
  }

  Widget _body() {
    if (_loading || _session == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final ReviewSession session = _session!;
    if (session.isEmpty) {
      return widget.deck.isEmpty
          ? _CaughtUpState(
              icon: FontAwesomeIcons.inbox,
              title: 'This deck has no cards yet.',
              onBackToDeck: _leave,
            )
          : _CaughtUpState(
              icon: FontAwesomeIcons.circleCheck,
              title: 'All caught up.',
              subtitle: 'No cards are due right now.',
              onBackToDeck: _leave,
            );
    }
    if (session.isComplete) {
      return SessionSummary(
        result: widget.scheduler.completeSession(session),
        onBackToDeck: _leave,
        onReviewAgain: _restart,
      );
    }
    return _reviewingBody(session);
  }

  Widget _reviewingBody(ReviewSession session) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(DeckoSpacing.pagePadding),
      child: Column(
        children: <Widget>[
          _ProgressHeader(
            cardNumber: session.cardNumber,
            total: session.total,
            progress: session.progress,
          ),
          const SizedBox(height: DeckoSpacing.lg),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: GestureDetector(
                  // Tap to flip either way (front ⇄ back).
                  onTap: _toggleReveal,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: DeckoApp.furiganaOf(context),
                    builder: (BuildContext context, bool globalFurigana, _) {
                      final bool showFront =
                          _options.imageDisplayMode == ImageDisplayMode.withQuestion ||
                              _revealed;
                      return DeckoCard(
                        item: session.currentItem!,
                        deckId: widget.deck.id,
                        style: _cardStyle,
                        revealed: _revealed,
                        showFurigana:
                            _options.resolveShowFurigana(globalFurigana),
                        showFrontImage: showFront,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: DeckoSpacing.lg),
          if (!_revealed)
            FilledButton.icon(
              onPressed: _reveal,
              icon: const FaIcon(FontAwesomeIcons.eye),
              label: const Text('Show answer'),
            )
          else ...<Widget>[
            Text(
              'How well did you know it?',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DeckoSpacing.md),
            RatingButtonRow(onRate: _rate),
          ],
        ],
      ),
    );
  }

  Widget _furiganaToggle() {
    final FuriganaController controller = DeckoApp.furiganaOf(context);
    return ValueListenableBuilder<bool>(
      valueListenable: controller,
      builder: (BuildContext context, bool on, _) {
        return IconButton(
          tooltip: on ? 'Hide furigana' : 'Show furigana',
          isSelected: on,
          icon: const FaIcon(FontAwesomeIcons.language),
          onPressed: controller.toggle,
        );
      },
    );
  }

  Widget _cardThemeMenu() {
    return PopupMenuButton<CardThemeStyle>(
      tooltip: 'Card theme',
      icon: const FaIcon(FontAwesomeIcons.layerGroup),
      initialValue: _cardStyle,
      onSelected: (CardThemeStyle style) =>
          setState(() => _cardStyle = style),
      itemBuilder: (BuildContext context) =>
          const <PopupMenuEntry<CardThemeStyle>>[
        PopupMenuItem<CardThemeStyle>(
          value: CardThemeStyle.minimal,
          child: Text('Minimal Card'),
        ),
        PopupMenuItem<CardThemeStyle>(
          value: CardThemeStyle.detailed,
          child: Text('Detailed Card'),
        ),
        PopupMenuItem<CardThemeStyle>(
          value: CardThemeStyle.game,
          child: Text('Game Card'),
        ),
      ],
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.cardNumber,
    required this.total,
    required this.progress,
  });

  final int cardNumber;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Card $cardNumber of $total',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: DeckoSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(DeckoRadii.pill),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}

class _CaughtUpState extends StatelessWidget {
  const _CaughtUpState({
    required this.icon,
    required this.title,
    required this.onBackToDeck,
    this.subtitle,
  });

  final FaIconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onBackToDeck;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DeckoSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FaIcon(icon, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: DeckoSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: DeckoSpacing.xs),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: DeckoSpacing.xl),
            OutlinedButton.icon(
              onPressed: onBackToDeck,
              icon: const FaIcon(FontAwesomeIcons.arrowLeft),
              label: const Text('Back to deck'),
            ),
          ],
        ),
      ),
    );
  }
}
