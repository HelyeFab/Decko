import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/decko_app.dart';
import '../../app/decko_router.dart';
import '../../app/furigana_controller.dart';
import '../../app/theme/card_theme_config.dart';
import '../../core/constants/decko_spacing.dart';
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
    super.dispose();
  }

  Future<void> _load() async {
    final List<ReviewCardState> stored =
        await _repo!.getStatesForDeck(widget.deck.id);
    _states
      ..clear()
      ..addEntries(stored.map((s) => MapEntry<String, ReviewCardState>(
          s.itemId, s)));
    if (!mounted) return;
    setState(() {
      _session = _buildSession();
      _loading = false;
    });
  }

  ReviewSession _buildSession() {
    final List<LearningItem> queue =
        DueQueue.build(widget.deck.items, _states, DateTime.now());
    return ReviewSession(
        deckId: widget.deck.id, items: List<LearningItem>.unmodifiable(queue));
  }

  void _reveal() => setState(() => _revealed = true);

  void _rate(ReviewRating rating) {
    final ReviewSession session = _session!;
    final LearningItem item = session.currentItem!;
    final DateTime now = DateTime.now();

    final ReviewCardState current = _states[item.id] ??
        ReviewCardState.newCard(deckId: widget.deck.id, itemId: item.id);
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
    if (_session!.isComplete) _onComplete();
  }

  void _onComplete() {
    if (_recorded) return;
    _recorded = true;
    final ReviewSessionResult result =
        widget.scheduler.completeSession(_session!);
    DeckoApp.progressOf(context).recordSessionResult(result);
    _flush();
  }

  /// Persists changed states, once. Awaited before leaving so the deck detail
  /// reads fresh counts; also called best-effort from dispose.
  Future<void> _flush() async {
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
              icon: Icons.inbox_rounded,
              title: 'This deck has no cards yet.',
              onBackToDeck: _leave,
            )
          : _CaughtUpState(
              icon: Icons.check_circle_rounded,
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
                child: ValueListenableBuilder<bool>(
                  valueListenable: DeckoApp.furiganaOf(context),
                  builder: (BuildContext context, bool furigana, _) {
                    return DeckoCard(
                      item: session.currentItem!,
                      style: _cardStyle,
                      revealed: _revealed,
                      showFurigana: furigana,
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: DeckoSpacing.lg),
          if (!_revealed)
            FilledButton.icon(
              onPressed: _reveal,
              icon: const Icon(Icons.visibility_rounded),
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
          icon: const Icon(Icons.translate_rounded),
          onPressed: controller.toggle,
        );
      },
    );
  }

  Widget _cardThemeMenu() {
    return PopupMenuButton<CardThemeStyle>(
      tooltip: 'Card theme',
      icon: const Icon(Icons.style_outlined),
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

  final IconData icon;
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
            Icon(icon, size: 56, color: theme.colorScheme.primary),
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
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back to deck'),
            ),
          ],
        ),
      ),
    );
  }
}
