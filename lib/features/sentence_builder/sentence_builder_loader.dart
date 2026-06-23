import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/constants/decko_spacing.dart';
import '../../core/widgets/decko_app_bar.dart';
import '../../domain/sentence_builder/sentence_builder_round.dart';
import '../practice/practice_outcome_recorder.dart';
import '../../domain/sentence_builder/sentence_tokenizer.dart';
import 'sentence_builder_screen.dart';

/// Loads sentence-builder rounds (an async, networked tokenize) behind a calm
/// loading state, then hands off to [SentenceBuilderScreen]. Surfaces a clear
/// "tokenizer unavailable" error with retry, and a "no sentences" empty state
/// (MVP_016).
class SentenceBuilderLoader extends StatefulWidget {
  const SentenceBuilderLoader({
    super.key,
    required this.title,
    required this.load,
  });

  final String title;
  final Future<List<SentenceBuilderRound>> Function() load;

  @override
  State<SentenceBuilderLoader> createState() => _SentenceBuilderLoaderState();
}

class _SentenceBuilderLoaderState extends State<SentenceBuilderLoader> {
  late Future<List<SentenceBuilderRound>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  void _retry() => setState(() => _future = widget.load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SentenceBuilderRound>>(
      future: _future,
      builder: (BuildContext context,
          AsyncSnapshot<List<SentenceBuilderRound>> snap) {
        if (snap.connectionState != ConnectionState.done) {
          return _Scaffold(
            title: widget.title,
            child: const _Loading(),
          );
        }
        if (snap.hasError) {
          return _Scaffold(
            title: widget.title,
            child: _ErrorState(error: snap.error, onRetry: _retry),
          );
        }
        final List<SentenceBuilderRound> rounds = snap.data ?? const <SentenceBuilderRound>[];
        if (rounds.isEmpty) {
          return _Scaffold(title: widget.title, child: const _Empty());
        }
        return SentenceBuilderScreen(
          rounds: rounds,
          title: widget.title,
          onCompleted: practiceOutcomeSink(context),
        );
      },
    );
  }
}

class _Scaffold extends StatelessWidget {
  const _Scaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DeckoAppBar(title: title),
      body: SafeArea(child: child),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CircularProgressIndicator(),
          const SizedBox(height: DeckoSpacing.lg),
          Text('Preparing sentences…',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DeckoSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FaIcon(FontAwesomeIcons.cubesStacked,
                size: 44, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: DeckoSpacing.lg),
            Text('No sentences to build',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: DeckoSpacing.sm),
            Text(
              'These cards don’t have sentences Decko can rebuild yet.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  String get _message {
    if (error is TokenizerException) {
      switch ((error as TokenizerException).kind) {
        case TokenizerError.offline:
          return 'Couldn’t reach the sentence tokenizer. Check your connection '
              'and try again.';
        case TokenizerError.unauthorized:
          return 'The sentence tokenizer rejected this app’s key.';
        case TokenizerError.rateLimited:
          return 'The sentence tokenizer is busy. Please try again shortly.';
        case TokenizerError.invalidInput:
        case TokenizerError.server:
          return 'The sentence tokenizer had a problem. Please try again.';
      }
    }
    return 'Something went wrong preparing the sentences.';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DeckoSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FaIcon(FontAwesomeIcons.cloudArrowDown,
                size: 44, color: theme.colorScheme.error),
            const SizedBox(height: DeckoSpacing.lg),
            Text('Couldn’t prepare sentences',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: DeckoSpacing.sm),
            Text(_message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: DeckoSpacing.xl),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const FaIcon(FontAwesomeIcons.rotateRight, size: 16),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
