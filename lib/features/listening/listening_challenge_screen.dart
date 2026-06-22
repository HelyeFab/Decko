import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../app/decko_app.dart';
import '../../core/constants/decko_spacing.dart';
import '../../core/widgets/decko_app_bar.dart';
import '../../domain/listening/listening_challenge.dart';
import '../../domain/practice/practice_mode.dart';
import '../../domain/practice/practice_outcome.dart';

/// Plays a listening-challenge session: hear audio, pick the meaning from four
/// choices (MVP_018). Motivation-only — records a [PracticeOutcome], never
/// review/FSRS state (DEC-027).
class ListeningChallengeScreen extends StatefulWidget {
  const ListeningChallengeScreen({
    super.key,
    required this.rounds,
    this.title = 'Listening',
    this.onCompleted,
  });

  final List<ListeningChallengeRound> rounds;
  final String title;
  final void Function(PracticeOutcome outcome)? onCompleted;

  /// Motivational XP per correct answer.
  static const int xpPerCorrect = 5;

  @override
  State<ListeningChallengeScreen> createState() =>
      _ListeningChallengeScreenState();
}

class _ListeningChallengeScreenState extends State<ListeningChallengeScreen> {
  late final ListeningChallengeSession _session =
      ListeningChallengeSession(widget.rounds);
  final AudioPlayer _player = AudioPlayer();
  late final DateTime _startedAt = DateTime.now();
  String? _selected;
  bool _audioUnavailable = false;
  PracticeOutcome? _outcome;
  int _playedIndex = -1;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _autoplay();
  }

  /// Plays the current round's audio once when it first appears.
  void _autoplay() {
    if (_session.isComplete || _playedIndex == _session.currentIndex) return;
    _playedIndex = _session.currentIndex;
    _play();
  }

  Future<void> _play() async {
    final ListeningChallengeRound? round = _session.current;
    if (round == null) return;
    final String? path =
        await DeckoApp.mediaOf(context).resolveMedia(round.deckId, round.audioRef);
    if (!mounted) return;
    if (path == null) {
      setState(() => _audioUnavailable = true);
      return;
    }
    try {
      await _player.stop();
      await _player.play(DeviceFileSource(path));
    } catch (_) {
      if (mounted) setState(() => _audioUnavailable = true);
    }
  }

  void _choose(String choice) {
    if (_selected != null) return;
    setState(() => _selected = choice);
  }

  void _next() {
    final ListeningChallengeRound round = _session.current!;
    _session.recordAndAdvance(ListeningChallengeResult(
      roundIndex: _session.currentIndex,
      correct: round.isCorrect(_selected ?? ''),
    ));
    if (_session.isComplete && _outcome == null) {
      final int correct = _session.correctCount;
      _outcome = PracticeOutcome(
        modeId: PracticeModeId.listeningChallenge,
        deckId: widget.rounds.isNotEmpty ? widget.rounds.first.deckId : null,
        itemId: widget.rounds.length == 1 ? widget.rounds.first.itemId : null,
        startedAt: _startedAt,
        completedAt: DateTime.now(),
        correctCount: correct,
        incorrectCount: _session.total - correct,
        xpAwarded: correct * ListeningChallengeScreen.xpPerCorrect,
      );
      widget.onCompleted?.call(_outcome!);
    }
    setState(() {
      _selected = null;
      _audioUnavailable = false;
    });
    _autoplay();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DeckoAppBar(title: widget.title),
      body: SafeArea(
        child: _session.isComplete
            ? _Completion(
                correct: _session.correctCount,
                total: _session.total,
                xpAwarded: _outcome?.xpAwarded ?? 0,
                onDone: () => Navigator.of(context).pop(),
              )
            : _playing(),
      ),
    );
  }

  Widget _playing() {
    final ListeningChallengeRound round = _session.current!;
    final bool answered = _selected != null;
    final bool multi = _session.total > 1;
    final bool last = _session.currentIndex == _session.total - 1;
    final ThemeData theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(DeckoSpacing.pagePadding),
      children: <Widget>[
        if (multi)
          Padding(
            padding: const EdgeInsets.only(bottom: DeckoSpacing.md),
            child: Text(
              'Audio ${_session.currentIndex + 1} of ${_session.total}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        _PlayButton(onTap: _play, unavailable: _audioUnavailable),
        const SizedBox(height: DeckoSpacing.xs),
        Center(
          child: Text(
            _audioUnavailable ? 'Audio unavailable — pick the meaning'
                : 'Tap to replay',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: DeckoSpacing.xl),
        for (final String choice in round.choices) ...<Widget>[
          _ChoiceCard(
            label: choice,
            state: !answered
                ? _ChoiceState.idle
                : choice == round.answer
                    ? _ChoiceState.correct
                    : (choice == _selected
                        ? _ChoiceState.wrong
                        : _ChoiceState.muted),
            onTap: answered ? null : () => _choose(choice),
          ),
          const SizedBox(height: DeckoSpacing.md),
        ],
        if (answered) ...<Widget>[
          const SizedBox(height: DeckoSpacing.sm),
          if (round.promptText != null)
            Center(
              child: Text(
                round.promptText!,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          if (round.meaningContext != null)
            Padding(
              padding: const EdgeInsets.only(top: DeckoSpacing.xs),
              child: Center(
                child: Text(
                  round.meaningContext!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ),
          const SizedBox(height: DeckoSpacing.lg),
          FilledButton.icon(
            onPressed: _next,
            icon: FaIcon(
              last ? FontAwesomeIcons.flagCheckered : FontAwesomeIcons.arrowRight,
              size: 16,
            ),
            label: Text(last ? 'Finish' : 'Next'),
          ),
        ],
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.onTap, required this.unavailable});

  final VoidCallback onTap;
  final bool unavailable;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            height: 96,
            width: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: unavailable
                  ? scheme.surfaceContainerHighest
                  : scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: FaIcon(
              unavailable
                  ? FontAwesomeIcons.volumeXmark
                  : FontAwesomeIcons.volumeHigh,
              size: 34,
              color: unavailable
                  ? scheme.onSurfaceVariant
                  : scheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

enum _ChoiceState { idle, correct, wrong, muted }

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String label;
  final _ChoiceState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final (Color bg, Color fg, Color border, FaIconData? icon) = switch (state) {
      _ChoiceState.idle => (theme.cardColor, scheme.onSurface, scheme.outlineVariant, null),
      _ChoiceState.correct => (
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
          scheme.primary,
          FontAwesomeIcons.circleCheck,
        ),
      _ChoiceState.wrong => (
          scheme.errorContainer,
          scheme.onErrorContainer,
          scheme.error,
          FontAwesomeIcons.circleXmark,
        ),
      _ChoiceState.muted => (
          theme.cardColor,
          scheme.onSurfaceVariant,
          scheme.outlineVariant,
          null,
        ),
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(DeckoRadii.lg),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(DeckoSpacing.lg),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(DeckoRadii.lg),
            border: Border.all(color: border),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(label,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: fg, fontWeight: FontWeight.w600)),
              ),
              if (icon != null) FaIcon(icon, size: 18, color: border),
            ],
          ),
        ),
      ),
    );
  }
}

/// A calm, MVP_015-style result. Motivational only.
class _Completion extends StatelessWidget {
  const _Completion({
    required this.correct,
    required this.total,
    required this.xpAwarded,
    required this.onDone,
  });

  final int correct;
  final int total;
  final int xpAwarded;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DeckoSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: FaIcon(FontAwesomeIcons.headphones,
                  size: 52, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: DeckoSpacing.lg),
            Text('Listening complete',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: DeckoSpacing.xs),
            Text('$correct of $total correct',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
            if (xpAwarded > 0) ...<Widget>[
              const SizedBox(height: DeckoSpacing.md),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DeckoSpacing.md,
                    vertical: DeckoSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(DeckoRadii.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      FaIcon(FontAwesomeIcons.bolt,
                          size: 13,
                          color: theme.colorScheme.onPrimaryContainer),
                      const SizedBox(width: DeckoSpacing.sm),
                      Text('+$xpAwarded XP',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          )),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: DeckoSpacing.md),
            Text('Practice only — your review schedule is unchanged.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
            const SizedBox(height: DeckoSpacing.xl),
            FilledButton(onPressed: onDone, child: const Text('Done')),
          ],
        ),
      ),
    );
  }
}
