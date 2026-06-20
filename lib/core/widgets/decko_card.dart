import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/card_theme_config.dart';
import '../../domain/learning_item.dart';
import '../../domain/review_card_mode.dart';
import '../constants/decko_spacing.dart';
import 'decko_field_content.dart';

/// A two-sided flashcard that **flips** between a clean prompt (front) and a
/// distinct answer (back) with a 3D rotation — not a front that grows taller.
///
/// Front = the word + its audio. Back = meaning, reading, image, and the
/// example sentence. Fields render via [DeckoFieldContent] (furigana, audio,
/// images). [showFurigana] toggles readings.
class DeckoCard extends StatefulWidget {
  const DeckoCard({
    super.key,
    required this.item,
    required this.deckId,
    required this.style,
    this.revealed = false,
    this.showFurigana = true,
    this.showFrontImage = true,
  });

  final LearningItem item;
  final String deckId;
  final CardThemeStyle style;
  final bool revealed;
  final bool showFurigana;

  /// When false, the question-side image is hidden (image-display "after
  /// reveal"); the back always shows it.
  final bool showFrontImage;

  @override
  State<DeckoCard> createState() => _DeckoCardState();
}

class _DeckoCardState extends State<DeckoCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
    value: widget.revealed ? 1 : 0,
  );

  @override
  void didUpdateWidget(DeckoCard old) {
    super.didUpdateWidget(old);
    if (widget.revealed != old.revealed) {
      widget.revealed ? _flip.forward() : _flip.reverse();
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget front = _PromptFace(
      item: widget.item,
      deckId: widget.deckId,
      style: widget.style,
      furigana: widget.showFurigana,
      showImage: widget.showFrontImage,
    );
    final Widget back = _AnswerFace(
      item: widget.item,
      deckId: widget.deckId,
      style: widget.style,
      furigana: widget.showFurigana,
    );

    return AnimatedBuilder(
      animation: _flip,
      builder: (BuildContext context, _) {
        final double angle = _flip.value * math.pi;
        final bool showFront = angle <= math.pi / 2;
        final Matrix4 transform = Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateY(angle);
        return Transform(
          alignment: Alignment.center,
          transform: transform,
          child: showFront
              ? front
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: back,
                ),
        );
      },
    );
  }
}

/// A card surface (rounded, themed; gradient for the playful "game" theme),
/// sized so front and back read as the same physical card.
class _CardFace extends StatelessWidget {
  const _CardFace({required this.child, required this.style});

  final Widget child;
  final CardThemeStyle style;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bool game = style == CardThemeStyle.game;
    final Widget content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 260),
      child: Padding(
        padding: const EdgeInsets.all(DeckoSpacing.xl),
        child: Center(
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[child]),
          ),
        ),
      ),
    );

    if (game) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DeckoRadii.lg),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[scheme.primary, scheme.tertiary],
          ),
        ),
        child: content,
      );
    }
    return Card(child: SizedBox(width: double.infinity, child: content));
  }
}

class _PromptFace extends StatelessWidget {
  const _PromptFace({
    required this.item,
    required this.deckId,
    required this.style,
    required this.furigana,
    required this.showImage,
  });

  final LearningItem item;
  final String deckId;
  final CardThemeStyle style;
  final bool furigana;
  final bool showImage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color onSurface = style == CardThemeStyle.game
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;
    return _CardFace(
      style: style,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _ModeEyebrow(mode: item.mode, style: style),
          DeckoFieldContent(
            item.front,
            deckId: deckId,
            showFurigana: furigana,
            showImages: showImage,
            align: TextAlign.center,
            baseStyle: theme.textTheme.displaySmall
                ?.copyWith(fontWeight: FontWeight.w600, color: onSurface),
          ),
        ],
      ),
    );
  }
}

/// A quiet small-caps eyebrow naming what the card trains (Listening / Reading /
/// Production). Deliberately understated — muted colour, letter-spaced, no
/// badge or pill — so it guides without making Decko feel like Anki's chrome.
/// Renders nothing for [ReviewCardMode.generic].
class _ModeEyebrow extends StatelessWidget {
  const _ModeEyebrow({required this.mode, required this.style});

  final ReviewCardMode mode;
  final CardThemeStyle style;

  @override
  Widget build(BuildContext context) {
    final String? label = mode.label;
    if (label == null) return const SizedBox.shrink();
    final ThemeData theme = Theme.of(context);
    final Color color = style == CardThemeStyle.game
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
        : theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: DeckoSpacing.lg),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          letterSpacing: 2.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AnswerFace extends StatelessWidget {
  const _AnswerFace({
    required this.item,
    required this.deckId,
    required this.style,
    required this.furigana,
  });

  final LearningItem item;
  final String deckId;
  final CardThemeStyle style;
  final bool furigana;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool game = style == CardThemeStyle.game;
    final Color onSurface =
        game ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;
    final Color muted = game
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.85)
        : theme.colorScheme.onSurfaceVariant;

    return _CardFace(
      style: style,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _ModeEyebrow(mode: item.mode, style: style),
          if (item.reading != null) ...<Widget>[
            DeckoFieldContent(
              item.reading!,
              deckId: deckId,
              showFurigana: furigana,
              align: TextAlign.center,
              baseStyle: theme.textTheme.titleMedium?.copyWith(color: muted),
            ),
            const SizedBox(height: DeckoSpacing.sm),
          ],
          DeckoFieldContent(
            item.back,
            deckId: deckId,
            showFurigana: furigana,
            align: TextAlign.center,
            baseStyle: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700, color: onSurface),
          ),
          if (item.example != null) ...<Widget>[
            const SizedBox(height: DeckoSpacing.xl),
            _ExampleSection(
              example: item.example!,
              deckId: deckId,
              furigana: furigana,
              onGame: game,
            ),
          ],
        ],
      ),
    );
  }
}

/// The example sentence in its own clearly-separated, labelled box.
class _ExampleSection extends StatelessWidget {
  const _ExampleSection({
    required this.example,
    required this.deckId,
    required this.furigana,
    this.onGame = false,
  });

  final String example;
  final String deckId;
  final bool furigana;
  final bool onGame;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final List<String> lines = example.split('\n');
    final String sentence = lines.first;
    final String translation = lines.skip(1).join(' ').trim();
    final Color boxColor =
        onGame ? scheme.onPrimary.withValues(alpha: 0.16) : scheme.surfaceContainerHighest;
    final Color onBox = onGame ? scheme.onPrimary : scheme.onSurface;
    final Color label =
        onGame ? scheme.onPrimary.withValues(alpha: 0.85) : scheme.onSurfaceVariant;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DeckoSpacing.lg),
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(DeckoRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            'EXAMPLE',
            style: theme.textTheme.labelSmall?.copyWith(
              color: label,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: DeckoSpacing.md),
          DeckoFieldContent(
            sentence,
            deckId: deckId,
            showFurigana: furigana,
            align: TextAlign.center,
            baseStyle: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w600, height: 1.3, color: onBox),
          ),
          if (translation.isNotEmpty) ...<Widget>[
            const SizedBox(height: DeckoSpacing.sm),
            Text(
              translation,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: label),
            ),
          ],
        ],
      ),
    );
  }
}
