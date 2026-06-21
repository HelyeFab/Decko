import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/constants/decko_spacing.dart';
import '../../../domain/deck.dart';

/// One deck's entry in the study hero: the deck and how many cards are ready.
typedef StudyEntry = ({Deck deck, int count});

/// The Home hero (MVP_008.5, Direction A): the next study action as a tactile
/// stack of flashcards — naming the deck to resume and how many cards are ready,
/// softening to a calm "all caught up" state. Used for a single deck; the
/// multi-deck rolodex is [StudyRolodex].
class StudyRibbon extends StatelessWidget {
  const StudyRibbon({
    super.key,
    required this.target,
    required this.cardsToStudy,
    required this.onStudy,
  });

  final Deck target;
  final int cardsToStudy;
  final VoidCallback onStudy;

  @override
  Widget build(BuildContext context) {
    return _StudyCard(
      deck: target,
      count: cardsToStudy,
      onStudy: onStudy,
      showEyebrow: true,
    );
  }
}

/// A real "rolodex" of study cards for multiple decks (MVP_012.1): a persistent
/// CONTINUE STUDYING header over a stack of deck cards you flip **vertically**
/// — drag up/down (or use the chevrons) and the front card pivots on its
/// central horizontal axis, revealing the next deck behind it. A position rail
/// sits on the right. Entries are ordered most-ready first.
class StudyRolodex extends StatefulWidget {
  const StudyRolodex({
    super.key,
    required this.entries,
    required this.onStudy,
  });

  final List<StudyEntry> entries;
  final ValueChanged<Deck> onStudy;

  @override
  State<StudyRolodex> createState() => _StudyRolodexState();
}

class _StudyRolodexState extends State<StudyRolodex>
    with SingleTickerProviderStateMixin {
  static const double _cardHeight = 150;
  static const double _topOverhang = 18; // room for the stacked edges

  // Created in initState (not a lazy field) so the vsync lookup never runs while
  // the Home branch is being deactivated/reactivated by the shell route.
  late final AnimationController _anim;

  int _index = 0;

  /// Flip angle of the front card around its central X axis (radians). 0 = flat
  /// front. Negative = flipping up toward the next deck; positive = toward the
  /// previous deck.
  double _angle = 0;

  int get _len => widget.entries.length;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() {
      _angle += (d.primaryDelta ?? 0) * 0.012;
      // Rubber-band resistance at the two ends of the stack.
      if (_index == _len - 1 && _angle < 0) _angle = (_angle * 0.3).clamp(-0.3, 0);
      if (_index == 0 && _angle > 0) _angle = (_angle * 0.3).clamp(0, 0.3);
      _angle = _angle.clamp(-math.pi, math.pi);
    });
  }

  void _onDragEnd(DragEndDetails d) {
    final double v = d.primaryVelocity ?? 0; // up = negative
    final bool canNext = _index < _len - 1;
    final bool canPrev = _index > 0;
    if (canNext && (_angle < -math.pi / 2 || v < -700)) {
      _flipTo(_index + 1, -math.pi);
    } else if (canPrev && (_angle > math.pi / 2 || v > 700)) {
      _flipTo(_index - 1, math.pi);
    } else {
      _flipTo(_index, 0);
    }
  }

  /// Animates [_angle] to [end], then settles on [commitIndex] flat.
  void _flipTo(int commitIndex, double end) {
    if (_angle == end && commitIndex == _index) return;
    final double from = _angle;
    final CurvedAnimation curve =
        CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    void tick() => setState(() => _angle = from + (end - from) * curve.value);
    _anim
      ..removeListener(tick)
      ..reset()
      ..addListener(tick);
    _anim.forward().whenComplete(() {
      _anim.removeListener(tick);
      if (!mounted) return;
      setState(() {
        _index = commitIndex;
        _angle = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final List<StudyEntry> entries = widget.entries;

    final bool goingNext = _angle < 0;
    final int targetIndex = goingNext ? _index + 1 : _index - 1;
    final bool hasTarget = targetIndex >= 0 && targetIndex < _len;
    final bool frontVisible = _angle.abs() <= math.pi / 2;

    Widget face(int i, {required bool showStack}) {
      final StudyEntry e = entries[i];
      return _StudyCard(
        deck: e.deck,
        count: e.count,
        onStudy: () => widget.onStudy(e.deck),
        showEyebrow: false,
        height: _cardHeight,
        showStack: showStack,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: DeckoSpacing.xs),
          child: Text(
            'CONTINUE STUDYING',
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: DeckoSpacing.sm),
        GestureDetector(
          onVerticalDragUpdate: _onDragUpdate,
          onVerticalDragEnd: _onDragEnd,
          child: SizedBox(
            height: _cardHeight + _topOverhang,
            child: Padding(
              padding: const EdgeInsets.only(top: _topOverhang),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  // The next/previous deck behind, revealed as the front card
                  // pivots away.
                  if (_angle != 0 && hasTarget)
                    face(targetIndex, showStack: false),
                  // The front card, flipping on its central X axis. Hidden once
                  // it passes edge-on so we never show its back.
                  if (frontVisible)
                    Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0012)
                        ..rotateX(_angle),
                      child: face(_index, showStack: true),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The single study card (gradient resume face or calm caught-up face), with
/// the stacked-flashcard edges behind it. [height] fixes the card height for
/// the rolodex; null lets it size to content (single-deck ribbon).
class _StudyCard extends StatelessWidget {
  const _StudyCard({
    required this.deck,
    required this.count,
    required this.onStudy,
    required this.showEyebrow,
    this.height,
    this.showStack = true,
  });

  final Deck deck;
  final int count;
  final VoidCallback onStudy;
  final bool showEyebrow;
  final double? height;

  /// Whether to draw the stacked-flashcard edges behind the card.
  final bool showStack;

  bool get _caughtUp => count == 0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

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
        if (showStack && !_caughtUp) ...<Widget>[
          stackedEdge(18, scheme.primary.withValues(alpha: 0.28)),
          stackedEdge(9, scheme.primary.withValues(alpha: 0.55)),
        ],
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(DeckoRadii.lg),
            onTap: onStudy,
            child: Ink(
              height: height,
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
                border:
                    _caughtUp ? Border.all(color: scheme.outlineVariant) : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(DeckoSpacing.xl),
                child: _caughtUp
                    ? _CaughtUp(scheme: scheme, theme: theme, deck: deck)
                    : _Resume(
                        theme: theme,
                        scheme: scheme,
                        deck: deck,
                        count: count,
                        showEyebrow: showEyebrow,
                        fill: height != null,
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
    required this.deck,
    required this.count,
    required this.showEyebrow,
    required this.fill,
  });

  final ThemeData theme;
  final ColorScheme scheme;
  final Deck deck;
  final int count;
  final bool showEyebrow;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final Color onPrimary = scheme.onPrimary;
    return Column(
      mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (showEyebrow) ...<Widget>[
          Text(
            'CONTINUE STUDYING',
            style: theme.textTheme.labelMedium?.copyWith(
              color: onPrimary.withValues(alpha: 0.75),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: DeckoSpacing.sm),
        ],
        Text(
          deck.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            color: onPrimary,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        if (fill) const Spacer() else const SizedBox(height: DeckoSpacing.lg),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                count == 1 ? '1 card ready' : '$count cards ready',
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
  const _CaughtUp({
    required this.scheme,
    required this.theme,
    required this.deck,
  });

  final ColorScheme scheme;
  final ThemeData theme;
  final Deck deck;

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
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                deck.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                'All caught up — nothing due right now.',
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
