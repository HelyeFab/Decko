import 'dart:math';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/constants/decko_spacing.dart';
import '../../../domain/sentence_builder/cube_token.dart';
import '../../../domain/sentence_builder/sentence_builder_round.dart';
import '../../../domain/sentence_builder/sentence_builder_token.dart';

/// The interactive sentence-builder surface (MVP_016): tap soft cube tokens
/// from the bank into the build row, check the order, and reveal the answer.
///
/// Self-contained and presentation-only — it never touches review/FSRS state.
/// The host decides what happens after [onResolved] (continue, or grade).
class SentenceBuilderView extends StatefulWidget {
  const SentenceBuilderView({
    super.key,
    required this.round,
    required this.onResolved,
    this.onPlayAudio,
  });

  final SentenceBuilderRound round;

  /// Called once, when the round is first resolved (checked correct, or the
  /// learner revealed the answer). [correct] is false on reveal-without-solving.
  final void Function(bool correct) onResolved;

  /// Optional sentence-audio playback; the audio button is hidden when null.
  final VoidCallback? onPlayAudio;

  @override
  State<SentenceBuilderView> createState() => _SentenceBuilderViewState();
}

class _SentenceBuilderViewState extends State<SentenceBuilderView> {
  late List<SentenceBuilderToken> _bank;
  final List<SentenceBuilderToken> _built = <SentenceBuilderToken>[];
  bool _resolved = false;
  bool _correct = false;
  bool _wrongShake = false;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _bank = List<SentenceBuilderToken>.of(widget.round.tokens);
    // Deterministic-ish shuffle so a rebuild doesn't reshuffle mid-play.
    _bank.shuffle(Random(widget.round.sentence.hashCode));
    // Guard against an already-ordered shuffle on short rounds.
    if (_bank.length > 1 &&
        widget.round.isCorrect(_bank) &&
        _bank.first != widget.round.tokens.last) {
      final SentenceBuilderToken first = _bank.removeAt(0);
      _bank.add(first);
    }
  }

  void _place(SentenceBuilderToken t) {
    if (_resolved) return;
    setState(() {
      _bank.remove(t);
      _built.add(t);
    });
  }

  void _unplace(SentenceBuilderToken t) {
    if (_resolved) return;
    setState(() {
      _built.remove(t);
      _bank.add(t);
    });
  }

  void _check() {
    if (_built.length != widget.round.tokens.length) return;
    _attempts++;
    final bool ok = widget.round.isCorrect(_built);
    if (ok) {
      setState(() {
        _resolved = true;
        _correct = true;
      });
      widget.onResolved(true);
    } else {
      setState(() => _wrongShake = true);
      Future<void>.delayed(const Duration(milliseconds: 360), () {
        if (mounted) setState(() => _wrongShake = false);
      });
    }
  }

  void _reveal() {
    if (_resolved) return;
    setState(() {
      _resolved = true;
      _correct = false;
    });
    widget.onResolved(false);
  }

  @override
  Widget build(BuildContext context) {
    final SentenceBuilderRound r = widget.round;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (r.translation != null) _PromptCard(translation: r.translation!),
        const SizedBox(height: DeckoSpacing.lg),
        _BuildRow(
          built: _built,
          shake: _wrongShake,
          resolved: _resolved,
          onTapToken: _unplace,
        ),
        const SizedBox(height: DeckoSpacing.lg),
        if (!_resolved) ...<Widget>[
          _Bank(tokens: _bank, onTap: _place),
          const SizedBox(height: DeckoSpacing.xl),
          FilledButton.icon(
            onPressed: _built.length == r.tokens.length ? _check : null,
            icon: const FaIcon(FontAwesomeIcons.check, size: 16),
            label: const Text('Check'),
          ),
          const SizedBox(height: DeckoSpacing.sm),
          Center(
            child: TextButton(
              onPressed: _reveal,
              child: const Text('Show answer'),
            ),
          ),
        ] else
          _Reveal(
            round: r,
            correct: _correct,
            attempts: _attempts,
            onPlayAudio: widget.onPlayAudio,
          ),
      ],
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.translation});

  final String translation;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DeckoSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(DeckoRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'BUILD THE SENTENCE',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.primary,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: DeckoSpacing.xs),
          Text(translation, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

/// The ordered slots where the learner assembles the sentence.
class _BuildRow extends StatelessWidget {
  const _BuildRow({
    required this.built,
    required this.shake,
    required this.resolved,
    required this.onTapToken,
  });

  final List<SentenceBuilderToken> built;
  final bool shake;
  final bool resolved;
  final ValueChanged<SentenceBuilderToken> onTapToken;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      transform: Matrix4.translationValues(shake ? 8 : 0, 0, 0),
      constraints: const BoxConstraints(minHeight: 88),
      width: double.infinity,
      padding: const EdgeInsets.all(DeckoSpacing.md),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(DeckoRadii.lg),
        border: Border.all(
          color: shake ? scheme.error : scheme.outlineVariant,
          width: shake ? 2 : 1,
        ),
      ),
      child: built.isEmpty
          ? Center(
              child: Text(
                'Tap the words below in order',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            )
          : Wrap(
              spacing: DeckoSpacing.sm,
              runSpacing: DeckoSpacing.sm,
              children: <Widget>[
                for (final SentenceBuilderToken t in built)
                  _TokenChip(
                    token: t,
                    filled: true,
                    onTap: resolved ? null : () => onTapToken(t),
                  ),
              ],
            ),
    );
  }
}

/// The shuffled pool of remaining tokens.
class _Bank extends StatelessWidget {
  const _Bank({required this.tokens, required this.onTap});

  final List<SentenceBuilderToken> tokens;
  final ValueChanged<SentenceBuilderToken> onTap;

  @override
  Widget build(BuildContext context) {
    if (tokens.isEmpty) {
      return const SizedBox(height: DeckoSpacing.sm);
    }
    return Wrap(
      spacing: DeckoSpacing.sm,
      runSpacing: DeckoSpacing.sm,
      alignment: WrapAlignment.center,
      children: <Widget>[
        for (final SentenceBuilderToken t in tokens)
          _TokenChip(token: t, filled: false, onTap: () => onTap(t)),
      ],
    );
  }
}

class _TokenChip extends StatelessWidget {
  const _TokenChip({
    required this.token,
    required this.filled,
    required this.onTap,
  });

  final SentenceBuilderToken token;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color bg = filled ? scheme.primaryContainer : scheme.surface;
    final Color fg = filled ? scheme.onPrimaryContainer : scheme.onSurface;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(DeckoRadii.md),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: DeckoSpacing.lg,
            vertical: DeckoSpacing.md,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(DeckoRadii.md),
            border: Border.all(color: scheme.outlineVariant),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _RubyLine(
            segments: token.furigana,
            surface: token.text,
            style: theme.textTheme.titleMedium
                ?.copyWith(color: fg, fontWeight: FontWeight.w600),
            rubyColor: fg.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

/// Renders a token's surface with per-segment furigana ruby above it. Falls
/// back to plain surface text when there are no readings.
class _RubyLine extends StatelessWidget {
  const _RubyLine({
    required this.segments,
    required this.surface,
    required this.style,
    required this.rubyColor,
  });

  final List<FuriganaSegment> segments;
  final String surface;
  final TextStyle? style;
  final Color rubyColor;

  @override
  Widget build(BuildContext context) {
    final bool hasRuby = segments.any((FuriganaSegment s) => s.ruby != null);
    if (!hasRuby) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(height: 11),
          Text(surface, style: style),
        ],
      );
    }
    final TextStyle rubyStyle = TextStyle(
      fontSize: 9,
      height: 1.1,
      color: rubyColor,
      fontWeight: FontWeight.w600,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        for (final FuriganaSegment seg in segments)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                height: 11,
                child: Text(seg.ruby ?? '', style: rubyStyle),
              ),
              Text(seg.text, style: style),
            ],
          ),
      ],
    );
  }
}

/// The resolved state: correct/encouraging header, the full sentence, the
/// translation, and an optional audio button.
class _Reveal extends StatelessWidget {
  const _Reveal({
    required this.round,
    required this.correct,
    required this.attempts,
    required this.onPlayAudio,
  });

  final SentenceBuilderRound round;
  final bool correct;
  final int attempts;
  final VoidCallback? onPlayAudio;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool good = correct;
    final Color bg = good ? scheme.primaryContainer : scheme.tertiaryContainer;
    final Color fg =
        good ? scheme.onPrimaryContainer : scheme.onTertiaryContainer;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DeckoSpacing.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DeckoRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              FaIcon(
                good
                    ? FontAwesomeIcons.solidCircleCheck
                    : FontAwesomeIcons.circleInfo,
                size: 18,
                color: fg,
              ),
              const SizedBox(width: DeckoSpacing.sm),
              Text(
                good
                    ? (attempts <= 1 ? 'Perfect!' : 'Got it!')
                    : 'Here’s the sentence',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: fg, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (onPlayAudio != null)
                IconButton(
                  onPressed: onPlayAudio,
                  tooltip: 'Play audio',
                  icon: FaIcon(FontAwesomeIcons.volumeHigh, size: 18, color: fg),
                ),
            ],
          ),
          const SizedBox(height: DeckoSpacing.sm),
          Text(
            round.sentence,
            style: theme.textTheme.headlineSmall
                ?.copyWith(color: fg, fontWeight: FontWeight.w700),
          ),
          if (round.translation != null) ...<Widget>[
            const SizedBox(height: DeckoSpacing.xs),
            Text(
              round.translation!,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: fg.withValues(alpha: 0.9)),
            ),
          ],
        ],
      ),
    );
  }
}
