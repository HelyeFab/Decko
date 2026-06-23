import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/constants/decko_spacing.dart';
import '../../core/widgets/decko_app_bar.dart';
import '../../domain/practice/practice_mode.dart';
import '../../domain/practice/practice_outcome.dart';
import '../../domain/typing/typing_answer_checker.dart';
import '../../domain/typing/typing_recall.dart';

/// Decko's Typing Recall screen (MVP_021): see a word, type its reading or
/// meaning, get kind correct/almost/incorrect feedback. Practice only — it
/// reports a [PracticeOutcome] (motivational XP) and never touches review state.
class TypingRecallScreen extends StatefulWidget {
  const TypingRecallScreen({
    super.key,
    required this.rounds,
    required this.title,
    required this.onCompleted,
  });

  final List<TypingRecallRound> rounds;
  final String title;
  final void Function(PracticeOutcome outcome) onCompleted;

  static const int xpCorrect = 5;
  static const int xpAlmost = 2;

  @override
  State<TypingRecallScreen> createState() => _TypingRecallScreenState();
}

class _TypingRecallScreenState extends State<TypingRecallScreen> {
  static const TypingRecallChecker _checker = TypingRecallChecker();

  late final TypingRecallSession _session =
      TypingRecallSession(widget.rounds);
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  final DateTime _startedAt = DateTime.now();

  TypingResultCategory? _category; // null = not yet submitted
  bool _reported = false;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _check() {
    final String input = _controller.text;
    if (input.trim().isEmpty || _category != null) return;
    setState(() => _category =
        _checker.check(input, _session.current!));
  }

  void _next() {
    _session.recordAndAdvance(_category!);
    _controller.clear();
    setState(() => _category = null);
    if (_session.isComplete) {
      _report();
    } else {
      _focus.requestFocus();
    }
  }

  void _report() {
    if (_reported) return;
    _reported = true;
    final int xp = _session.correctCount * TypingRecallScreen.xpCorrect +
        _session.almostCount * TypingRecallScreen.xpAlmost;
    widget.onCompleted(PracticeOutcome(
      modeId: PracticeModeId.typingRecall,
      itemId: widget.rounds.length == 1 ? widget.rounds.first.itemId : null,
      deckId: widget.rounds.isEmpty ? null : widget.rounds.first.deckId,
      startedAt: _startedAt,
      completedAt: DateTime.now(),
      correctCount: _session.correctCount,
      incorrectCount: _session.total - _session.correctCount,
      xpAwarded: xp,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DeckoAppBar(title: widget.title),
      body: SafeArea(
        child: _session.isComplete
            ? _Completion(session: _session)
            : _buildRound(context),
      ),
    );
  }

  Widget _buildRound(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TypingRecallRound round = _session.current!;
    final bool answered = _category != null;

    return Padding(
      padding: const EdgeInsets.all(DeckoSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('${_session.currentIndex + 1} of ${_session.total}',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: DeckoSpacing.lg),
          // Prompt card.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: DeckoSpacing.lg, vertical: DeckoSpacing.xxl),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(DeckoRadii.lg),
            ),
            child: Column(
              children: <Widget>[
                Text(round.instruction.toUpperCase(),
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
                        letterSpacing: 1)),
                const SizedBox(height: DeckoSpacing.md),
                Text(round.promptText,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onPrimaryContainer)),
              ],
            ),
          ),
          const SizedBox(height: DeckoSpacing.xl),
          TextField(
            controller: _controller,
            focusNode: _focus,
            autofocus: true,
            enabled: !answered,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _check(),
            decoration: InputDecoration(
              hintText: round.instruction,
              border: const OutlineInputBorder(),
            ),
            style: theme.textTheme.titleLarge,
          ),
          if (answered) ...<Widget>[
            const SizedBox(height: DeckoSpacing.lg),
            _Feedback(category: _category!, round: round),
          ],
          const Spacer(),
          FilledButton(
            onPressed: answered
                ? _next
                : (_controller.text.trim().isEmpty ? null : _check),
            child: Text(answered
                ? (_session.currentIndex + 1 >= _session.total
                    ? 'Finish'
                    : 'Next')
                : 'Check'),
          ),
        ],
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({required this.category, required this.round});
  final TypingResultCategory category;
  final TypingRecallRound round;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final (Color color, FaIconData icon, String label) = switch (category) {
      TypingResultCategory.correct => (
          const Color(0xFF3FA66A),
          FontAwesomeIcons.solidCircleCheck,
          'Correct!'
        ),
      TypingResultCategory.almost => (
          const Color(0xFFE0883A),
          FontAwesomeIcons.circleHalfStroke,
          'So close!'
        ),
      TypingResultCategory.incorrect => (
          scheme.error,
          FontAwesomeIcons.circleXmark,
          'Not quite'
        ),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DeckoSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DeckoRadii.lg),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              FaIcon(icon, size: 18, color: color),
              const SizedBox(width: DeckoSpacing.sm),
              Text(label,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          if (category != TypingResultCategory.correct) ...<Widget>[
            const SizedBox(height: DeckoSpacing.sm),
            Text('Answer: ${round.answer}',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ],
          if (round.explanation != null) ...<Widget>[
            const SizedBox(height: DeckoSpacing.xs),
            Text(round.explanation!,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

class _Completion extends StatelessWidget {
  const _Completion({required this.session});
  final TypingRecallSession session;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final int xp = session.correctCount * TypingRecallScreen.xpCorrect +
        session.almostCount * TypingRecallScreen.xpAlmost;
    return Padding(
      padding: const EdgeInsets.all(DeckoSpacing.pagePadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: FaIcon(FontAwesomeIcons.keyboard,
                size: 52, color: scheme.primary),
          ),
          const SizedBox(height: DeckoSpacing.lg),
          Text('Typing complete',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: DeckoSpacing.xs),
          Text(
            '${session.correctCount} of ${session.total} correct'
            '${session.almostCount > 0 ? ' · ${session.almostCount} almost' : ''}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: DeckoSpacing.lg),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: DeckoSpacing.lg, vertical: DeckoSpacing.sm),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(DeckoRadii.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  FaIcon(FontAwesomeIcons.bolt,
                      size: 14, color: scheme.onPrimaryContainer),
                  const SizedBox(width: DeckoSpacing.sm),
                  Text('+$xp XP',
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onPrimaryContainer)),
                ],
              ),
            ),
          ),
          const SizedBox(height: DeckoSpacing.md),
          Text('Practice only — your review schedule is unchanged.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: DeckoSpacing.xl),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
