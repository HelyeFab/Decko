import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/decko_app.dart';
import '../../app/decko_router.dart';
import '../../app/theme/card_theme_config.dart';
import '../../core/constants/decko_spacing.dart';
import '../../core/widgets/decko_card.dart';
import '../../data/simple_review_scheduler.dart';
import '../../domain/deck.dart';
import '../../domain/repositories/review_scheduler.dart';
import '../../domain/review_rating.dart';
import '../../domain/review_session.dart';
import '../../domain/review_session_result.dart';
import 'widgets/rating_button_row.dart';
import 'widgets/session_summary.dart';

/// A real (in-memory) review session over a deck's cards.
///
/// Shows one card at a time, reveals the answer on demand, records a rating,
/// advances, and ends with a completion summary. All session state is held here
/// and driven by a [ReviewScheduler]; the scheduler is injectable so this screen
/// can be tested without app-scope wiring. No scheduling/persistence yet — that
/// arrives behind the same [ReviewScheduler] interface (DEC-003).
class ReviewSessionScreen extends StatefulWidget {
  const ReviewSessionScreen({
    super.key,
    required this.deck,
    this.scheduler = const SimpleReviewScheduler(),
  });

  final Deck deck;
  final ReviewScheduler scheduler;

  @override
  State<ReviewSessionScreen> createState() => _ReviewSessionScreenState();
}

class _ReviewSessionScreenState extends State<ReviewSessionScreen> {
  late ReviewSession _session =
      widget.scheduler.createSession(deck: widget.deck);
  bool _revealed = false;
  bool _recorded = false;
  CardThemeStyle _cardStyle = CardThemeStyle.minimal;

  void _reveal() => setState(() => _revealed = true);

  void _rate(ReviewRating rating) {
    setState(() {
      _session = widget.scheduler.answerCurrentCard(
        session: _session,
        rating: rating,
        answeredAt: DateTime.now(),
      );
      _revealed = false;
    });
    if (_session.isComplete) _recordResult();
  }

  /// Persist the finished session's result exactly once.
  void _recordResult() {
    if (_recorded) return;
    _recorded = true;
    final ReviewSessionResult result =
        widget.scheduler.completeSession(_session);
    DeckoApp.progressOf(context).recordSessionResult(result);
  }

  void _restart() {
    setState(() {
      _session = widget.scheduler.createSession(deck: widget.deck);
      _revealed = false;
      _recorded = false;
    });
  }

  void _backToDeck() => context.go(DeckoRoutes.deck(widget.deck.id));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deck.name),
        actions: _session.isEmpty || _session.isComplete
            ? null
            : <Widget>[_cardThemeMenu(), const SizedBox(width: DeckoSpacing.sm)],
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (_session.isEmpty) {
      return _EmptyDeckState(onBackToDeck: _backToDeck);
    }
    if (_session.isComplete) {
      return SessionSummary(
        result: widget.scheduler.completeSession(_session),
        onBackToDeck: _backToDeck,
        onReviewAgain: _restart,
      );
    }
    return _reviewingBody();
  }

  Widget _reviewingBody() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(DeckoSpacing.pagePadding),
      child: Column(
        children: <Widget>[
          _ProgressHeader(
            cardNumber: _session.cardNumber,
            total: _session.total,
            progress: _session.progress,
          ),
          const SizedBox(height: DeckoSpacing.lg),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: DeckoCard(
                  item: _session.currentItem!,
                  style: _cardStyle,
                  revealed: _revealed,
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

class _EmptyDeckState extends StatelessWidget {
  const _EmptyDeckState({required this.onBackToDeck});

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
            Icon(
              Icons.inbox_rounded,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: DeckoSpacing.lg),
            Text(
              'This deck has no cards yet.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
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
