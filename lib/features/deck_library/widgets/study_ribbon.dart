import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/constants/decko_spacing.dart';
import '../../../domain/deck.dart';

/// The Home hero (MVP_008.5, Direction A): the single next study action.
///
/// When cards are waiting it renders as a tactile stack of flashcards — the
/// signature motif — naming the deck to resume and how many cards are ready.
/// When everything is reviewed it softens into a calm "all caught up" state so
/// Home never nags. It is the one bold element on Home; everything else stays
/// quiet.
class StudyRibbon extends StatelessWidget {
  const StudyRibbon({
    super.key,
    required this.target,
    required this.cardsToStudy,
    required this.onStudy,
  });

  /// The deck the learner would resume — the one with the most cards waiting.
  final Deck target;

  /// Cards available to study now in [target] (due review + due learning + new).
  final int cardsToStudy;

  /// Starts a review session for [target].
  final VoidCallback onStudy;

  bool get _caughtUp => cardsToStudy == 0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    // The stacked-card edges peeking from behind the face.
    Widget stackedEdge(double inset, Color color) => Positioned(
          left: inset,
          right: inset,
          top: -inset,
          height: 28,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(DeckoRadii.lg),
              ),
            ),
          ),
        );

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        if (!_caughtUp) ...<Widget>[
          stackedEdge(28, scheme.primary.withValues(alpha: 0.28)),
          stackedEdge(14, scheme.primary.withValues(alpha: 0.55)),
        ],
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(DeckoRadii.lg),
            onTap: onStudy,
            child: Ink(
              decoration: BoxDecoration(
                gradient: _caughtUp
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          scheme.primary,
                          Color.lerp(scheme.primary, scheme.tertiary, 0.45) ??
                              scheme.primary,
                        ],
                      ),
                color: _caughtUp ? scheme.surfaceContainerHighest : null,
                borderRadius: BorderRadius.circular(DeckoRadii.lg),
                border: _caughtUp
                    ? Border.all(color: scheme.outlineVariant)
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(DeckoSpacing.xl),
                child: _caughtUp
                    ? _CaughtUp(scheme: scheme, theme: theme)
                    : _Resume(
                        theme: theme,
                        scheme: scheme,
                        target: target,
                        cardsToStudy: cardsToStudy,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Resume extends StatelessWidget {
  const _Resume({
    required this.theme,
    required this.scheme,
    required this.target,
    required this.cardsToStudy,
  });

  final ThemeData theme;
  final ColorScheme scheme;
  final Deck target;
  final int cardsToStudy;

  @override
  Widget build(BuildContext context) {
    final Color onPrimary = scheme.onPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'CONTINUE STUDYING',
          style: theme.textTheme.labelMedium?.copyWith(
            color: onPrimary.withValues(alpha: 0.75),
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: DeckoSpacing.sm),
        Text(
          target.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: onPrimary,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: DeckoSpacing.lg),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                cardsToStudy == 1
                    ? '1 card ready'
                    : '$cardsToStudy cards ready',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: onPrimary.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: DeckoSpacing.md),
            _StudyButton(scheme: scheme),
          ],
        ),
      ],
    );
  }
}

class _StudyButton extends StatelessWidget {
  const _StudyButton({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DeckoSpacing.lg,
        vertical: DeckoSpacing.md,
      ),
      decoration: BoxDecoration(
        color: scheme.onPrimary,
        borderRadius: BorderRadius.circular(DeckoRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Study',
            style: TextStyle(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: DeckoSpacing.sm),
          FaIcon(FontAwesomeIcons.play, size: 12, color: scheme.primary),
        ],
      ),
    );
  }
}

class _CaughtUp extends StatelessWidget {
  const _CaughtUp({required this.scheme, required this.theme});

  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          height: 48,
          width: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(DeckoRadii.md),
          ),
          child: FaIcon(FontAwesomeIcons.solidCircleCheck,
              size: 22, color: scheme.onPrimaryContainer),
        ),
        const SizedBox(width: DeckoSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'You’re all caught up',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                'Nothing due right now. Pick a deck to review ahead.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
