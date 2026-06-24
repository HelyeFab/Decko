import 'dart:math';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/constants/decko_spacing.dart';
import '../../core/widgets/decko_app_bar.dart';
import '../../domain/match/match_mode.dart';
import '../../domain/practice/practice_mode.dart';
import '../../domain/practice/practice_outcome.dart';

/// Decko's Match Mode screen (MVP_025): tap a tile on the left, then its match
/// on the right, until the board clears. Practice only — it reports a
/// [PracticeOutcome] (motivational XP) and never touches review state.
class MatchModeScreen extends StatefulWidget {
  const MatchModeScreen({
    super.key,
    required this.rounds,
    required this.title,
    required this.onCompleted,
  });

  final List<MatchModeRound> rounds;
  final String title;
  final void Function(PracticeOutcome outcome) onCompleted;

  static const int xpPerPair = 2;

  @override
  State<MatchModeScreen> createState() => _MatchModeScreenState();
}

class _MatchModeScreenState extends State<MatchModeScreen> {
  late final MatchModeSession _session = MatchModeSession(widget.rounds);
  final DateTime _startedAt = DateTime.now();
  final Random _rng = Random();

  List<MatchModePair> _left = <MatchModePair>[];
  List<MatchModePair> _right = <MatchModePair>[];
  final Set<String> _matched = <String>{};
  String? _selectedId; // sourceItemId of the currently selected tile
  bool _selectedIsLeft = false;
  ({String id, bool isLeft})? _wrongA;
  ({String id, bool isLeft})? _wrongB;
  bool _busy = false; // brief lock during incorrect/clear animations
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    _loadBoard();
  }

  void _loadBoard() {
    final MatchModeRound? round = _session.current;
    if (round == null) return;
    _left = round.pairs.toList()..shuffle(_rng);
    _right = round.pairs.toList()..shuffle(_rng);
    _matched.clear();
    _selectedId = null;
    _wrongA = null;
    _wrongB = null;
    _busy = false;
  }

  void _tap(MatchModePair pair, bool isLeft) {
    if (_busy || _matched.contains(pair.sourceItemId)) return;

    // First selection, or re-selecting within the same column.
    if (_selectedId == null ||
        (_selectedId == pair.sourceItemId && _selectedIsLeft == isLeft)) {
      setState(() {
        _selectedId =
            (_selectedId == pair.sourceItemId && _selectedIsLeft == isLeft)
                ? null
                : pair.sourceItemId;
        _selectedIsLeft = isLeft;
      });
      return;
    }
    if (_selectedIsLeft == isLeft) {
      setState(() => _selectedId = pair.sourceItemId); // switch within a column
      return;
    }

    // Tapped the other column → check the match (same source pair?).
    if (_selectedId == pair.sourceItemId) {
      setState(() {
        _matched.add(pair.sourceItemId);
        _selectedId = null;
        _session.recordCorrect();
      });
      if (_matched.length == _session.current!.size) {
        _busy = true;
        Future<void>.delayed(const Duration(milliseconds: 450), _nextBoard);
      }
    } else {
      // Incorrect — flash both tiles briefly, then clear.
      setState(() {
        _busy = true;
        _wrongA = (id: _selectedId!, isLeft: _selectedIsLeft);
        _wrongB = (id: pair.sourceItemId, isLeft: isLeft);
        _session.recordIncorrect();
      });
      Future<void>.delayed(const Duration(milliseconds: 650), () {
        if (!mounted) return;
        setState(() {
          _wrongA = null;
          _wrongB = null;
          _selectedId = null;
          _busy = false;
        });
      });
    }
  }

  void _nextBoard() {
    if (!mounted) return;
    setState(() {
      _session.advance();
      if (!_session.isComplete) {
        _loadBoard();
      } else {
        _report();
      }
    });
  }

  void _report() {
    if (_reported) return;
    _reported = true;
    widget.onCompleted(PracticeOutcome(
      modeId: PracticeModeId.matchMode,
      itemId: null,
      deckId: widget.rounds.isEmpty ? null : widget.rounds.first.pairs.first.sourceItemId,
      startedAt: _startedAt,
      completedAt: DateTime.now(),
      correctCount: _session.correctPairs,
      incorrectCount: _session.incorrectAttempts,
      xpAwarded: _session.correctPairs * MatchModeScreen.xpPerPair,
    ));
  }

  _TileState _stateFor(MatchModePair pair, bool isLeft) {
    if (_matched.contains(pair.sourceItemId)) return _TileState.correct;
    if (_wrongA?.id == pair.sourceItemId && _wrongA?.isLeft == isLeft ||
        _wrongB?.id == pair.sourceItemId && _wrongB?.isLeft == isLeft) {
      return _TileState.wrong;
    }
    if (_selectedId == pair.sourceItemId && _selectedIsLeft == isLeft) {
      return _TileState.selected;
    }
    return _TileState.idle;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DeckoAppBar(title: widget.title),
      body: SafeArea(
        child: _session.isComplete
            ? _Completion(session: _session)
            : _buildBoard(context),
      ),
    );
  }

  Widget _buildBoard(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final MatchModeRound round = _session.current!;
    return Padding(
      padding: const EdgeInsets.all(DeckoSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Board ${_session.currentIndex + 1} of ${_session.rounds.length}',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: DeckoSpacing.xs),
          Text(round.pairType.instruction,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: DeckoSpacing.lg),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: _column(_left, isLeft: true)),
                const SizedBox(width: DeckoSpacing.md),
                Expanded(child: _column(_right, isLeft: false)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _column(List<MatchModePair> pairs, {required bool isLeft}) {
    return Column(
      children: <Widget>[
        for (final MatchModePair p in pairs)
          Padding(
            padding: const EdgeInsets.only(bottom: DeckoSpacing.md),
            child: _MatchTile(
              text: isLeft ? p.left : p.right,
              state: _stateFor(p, isLeft),
              onTap: () => _tap(p, isLeft),
            ),
          ),
      ],
    );
  }
}

enum _TileState { idle, selected, correct, wrong }

class _MatchTile extends StatelessWidget {
  const _MatchTile({
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String text;
  final _TileState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    const Color green = Color(0xFF3FA66A);
    final (Color bg, Color fg, Color border, FaIconData? icon) = switch (state) {
      _TileState.idle => (theme.cardColor, scheme.onSurface, scheme.outlineVariant, null),
      _TileState.selected => (
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
          scheme.primary,
          null
        ),
      _TileState.correct => (
          green.withValues(alpha: 0.15),
          green,
          green,
          FontAwesomeIcons.check
        ),
      _TileState.wrong => (
          scheme.errorContainer,
          scheme.onErrorContainer,
          scheme.error,
          FontAwesomeIcons.xmark
        ),
    };
    return Semantics(
      button: true,
      selected: state == _TileState.selected,
      label: text,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(DeckoRadii.md),
          onTap: state == _TileState.correct ? null : onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(
                horizontal: DeckoSpacing.md, vertical: DeckoSpacing.lg),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(DeckoRadii.md),
              border: Border.all(
                  color: border,
                  width: state == _TileState.idle ? 1 : 1.6),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                        color: fg, fontWeight: FontWeight.w600),
                  ),
                ),
                if (icon != null) ...<Widget>[
                  const SizedBox(width: DeckoSpacing.xs),
                  FaIcon(icon, size: 13, color: fg),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Completion extends StatelessWidget {
  const _Completion({required this.session});
  final MatchModeSession session;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final int xp = session.correctPairs * MatchModeScreen.xpPerPair;
    return Padding(
      padding: const EdgeInsets.all(DeckoSpacing.pagePadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: FaIcon(FontAwesomeIcons.tableCellsLarge,
                size: 52, color: scheme.primary),
          ),
          const SizedBox(height: DeckoSpacing.lg),
          Text('Match complete',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: DeckoSpacing.xs),
          Text(
            '${session.correctPairs} pairs'
            '${session.incorrectAttempts > 0 ? ' · ${session.incorrectAttempts} misses' : ' · no misses'}',
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
          Text('Extra practice — your review schedule is unchanged.',
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
