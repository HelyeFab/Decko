import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../app/decko_app.dart';
import '../../core/constants/decko_spacing.dart';
import '../../core/widgets/decko_app_bar.dart';
import '../../domain/practice/practice_mode.dart';
import '../../domain/practice/practice_outcome.dart';
import '../../domain/sentence_builder/sentence_builder_result.dart';
import '../../domain/sentence_builder/sentence_builder_round.dart';
import '../../domain/sentence_builder/sentence_builder_session.dart';
import 'widgets/sentence_builder_view.dart';

/// Plays a sentence-builder session (manual single round or deck practice).
///
/// Motivation-only by design: it never records to the review/progress
/// repositories, so practising here cannot change FSRS state, due counts, or
/// imported progress (MVP_016, DEC-025).
class SentenceBuilderScreen extends StatefulWidget {
  const SentenceBuilderScreen({
    super.key,
    required this.rounds,
    this.title = 'Sentence builder',
    this.onCompleted,
  });

  final List<SentenceBuilderRound> rounds;
  final String title;

  /// Reports the motivational outcome when the session finishes (MVP_017).
  /// Null in contexts that shouldn't record (e.g. previews/tests).
  final void Function(PracticeOutcome outcome)? onCompleted;

  /// Motivational XP per correctly-built sentence.
  static const int xpPerCorrect = 5;

  @override
  State<SentenceBuilderScreen> createState() => _SentenceBuilderScreenState();
}

class _SentenceBuilderScreenState extends State<SentenceBuilderScreen> {
  late final SentenceBuilderSession _session =
      SentenceBuilderSession(widget.rounds);
  final AudioPlayer _player = AudioPlayer();
  late final DateTime _startedAt = DateTime.now();
  PracticeOutcome? _outcome;
  bool? _resolvedCorrect;
  int _attempts = 0;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  /// Plays the round's sentence audio, when present. Best-effort.
  Future<void> _playAudio(SentenceBuilderRound round) async {
    final String? fileName = round.audioRef;
    if (fileName == null) return;
    final String? path =
        await DeckoApp.mediaOf(context).resolveMedia(round.deckId, fileName);
    if (path == null || !mounted) return;
    try {
      await _player.stop();
      await _player.play(DeviceFileSource(path));
    } catch (_) {/* best-effort */}
  }

  void _onResolved(bool correct) {
    setState(() {
      _resolvedCorrect = correct;
      _attempts += 1;
    });
  }

  void _next() {
    _session.recordAndAdvance(SentenceBuilderResult(
      roundIndex: _session.currentIndex,
      correct: _resolvedCorrect ?? false,
      attempts: _attempts,
    ));
    if (_session.isComplete && _outcome == null) {
      final int correct = _session.correctCount;
      _outcome = PracticeOutcome(
        modeId: PracticeModeId.bunburuSentenceBuilder,
        deckId: widget.rounds.isNotEmpty ? widget.rounds.first.deckId : null,
        itemId: widget.rounds.length == 1 ? widget.rounds.first.itemId : null,
        startedAt: _startedAt,
        completedAt: DateTime.now(),
        correctCount: correct,
        incorrectCount: _session.total - correct,
        xpAwarded: correct * SentenceBuilderScreen.xpPerCorrect,
      );
      widget.onCompleted?.call(_outcome!);
    }
    setState(() {
      _resolvedCorrect = null;
      _attempts = 0;
    });
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
    final SentenceBuilderRound round = _session.current!;
    final bool multi = _session.total > 1;
    final bool resolved = _resolvedCorrect != null;
    final bool last = _session.currentIndex == _session.total - 1;
    return ListView(
      padding: const EdgeInsets.all(DeckoSpacing.pagePadding),
      children: <Widget>[
        if (multi)
          Padding(
            padding: const EdgeInsets.only(bottom: DeckoSpacing.md),
            child: Text(
              'Sentence ${_session.currentIndex + 1} of ${_session.total}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        SentenceBuilderView(
          key: ValueKey<int>(_session.currentIndex),
          round: round,
          onResolved: _onResolved,
          onPlayAudio:
              round.audioRef != null ? () => _playAudio(round) : null,
        ),
        if (resolved) ...<Widget>[
          const SizedBox(height: DeckoSpacing.xl),
          FilledButton.icon(
            onPressed: _next,
            icon: FaIcon(
              last ? FontAwesomeIcons.flagCheckered : FontAwesomeIcons.arrowRight,
              size: 16,
            ),
            label: Text(last ? 'Finish' : 'Next sentence'),
          ),
        ],
      ],
    );
  }
}

/// A calm, MVP_015-style practice result. Motivational only.
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
            FaIcon(FontAwesomeIcons.solidStar,
                size: 52, color: theme.colorScheme.primary),
            const SizedBox(height: DeckoSpacing.lg),
            Text(
              'Practice complete',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: DeckoSpacing.xs),
            Text(
              '$correct of $total built correctly',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
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
            Text(
              'Practice only — your review schedule is unchanged.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DeckoSpacing.xl),
            FilledButton(onPressed: onDone, child: const Text('Done')),
          ],
        ),
      ),
    );
  }
}
