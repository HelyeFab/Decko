import 'package:flutter/material.dart';

import '../../app/decko_app.dart';
import '../../core/widgets/decko_snackbar.dart';
import '../../domain/deck.dart';
import '../../domain/import/source/imported_anki_source.dart';
import '../../domain/learning_item.dart';
import '../../domain/listening/listening_challenge.dart';
import '../../domain/listening/listening_challenge_builder.dart';
import '../../domain/practice/practice_mode.dart';
import '../../domain/repositories/imported_source_store.dart';
import '../../domain/sentence_builder/sentence_builder_round.dart';
import '../../domain/sentence_builder/sentence_builder_source.dart';
import '../listening/listening_challenge_screen.dart';
import '../sentence_builder/sentence_builder_loader.dart';
import '../sentence_builder/sentence_round_service.dart';
import 'practice_outcome_recorder.dart';

/// The single place that maps a [PracticeMode] to its screen (MVP_017+). Deck
/// Detail / Review / the Hub call these; adding a future game means one new
/// `case`, not edits across unrelated screens.
class PracticeLauncher {
  const PracticeLauncher._();

  static const ListeningChallengeBuilder _listening = ListeningChallengeBuilder();

  /// Launches deck-level practice for [mode] over [deck].
  static void launchDeck(BuildContext context, PracticeMode mode, Deck deck) {
    switch (mode.id) {
      case PracticeModeId.bunburuSentenceBuilder:
        final ImportedSourceStore store = DeckoApp.sourceOf(context);
        final SentenceRoundService service = DeckoApp.sentenceRoundsOf(context);
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (BuildContext context) => SentenceBuilderLoader(
            title: deck.name,
            load: () async {
              final ImportedAnkiSource? source =
                  await store.getSourceForDeck(deck.id);
              return service.roundsForDeck(
                deck,
                ankiSource: source,
                source: SentenceBuilderSource.deckPractice,
              );
            },
          ),
        ));
      case PracticeModeId.listeningChallenge:
        _launchListening(context, deck, mode.title, item: null);
    }
  }

  /// Launches manual single-card practice for [mode] on [item] in [deck].
  static void launchCard(
    BuildContext context,
    PracticeMode mode,
    LearningItem item, {
    required Deck deck,
    ImportedAnkiNote? note,
  }) {
    switch (mode.id) {
      case PracticeModeId.bunburuSentenceBuilder:
        final SentenceRoundService service = DeckoApp.sentenceRoundsOf(context);
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (BuildContext context) => SentenceBuilderLoader(
            title: mode.title,
            load: () async {
              final SentenceBuilderRound? round = await service.roundForItem(
                item,
                deckId: deck.id,
                source: SentenceBuilderSource.manualCard,
                note: note,
              );
              return <SentenceBuilderRound>[?round];
            },
          ),
        ));
      case PracticeModeId.listeningChallenge:
        _launchListening(context, deck, mode.title, item: item);
    }
  }

  /// Loads the deck's preserved source (so sentence translations are used when
  /// present), builds the rounds, and opens the screen. [item] non-null = a
  /// single manual round; null = deck practice.
  static Future<void> _launchListening(
    BuildContext context,
    Deck deck,
    String title, {
    required LearningItem? item,
  }) async {
    final ImportedSourceStore store = DeckoApp.sourceOf(context);
    final recordOutcome = practiceOutcomeSink(context);
    final ImportedAnkiSource? source = await store.getSourceForDeck(deck.id);
    if (!context.mounted) return;

    final List<ListeningChallengeRound> rounds;
    if (item != null) {
      final ListeningChallengeRound? round =
          _listening.roundForItem(item, deck, source: source);
      rounds = <ListeningChallengeRound>[?round];
    } else {
      rounds = _listening.roundsForDeck(deck, source: source);
    }

    if (rounds.isEmpty) {
      DeckoSnackbar.showInfo(context,
          'Not enough audio for a listening challenge here yet.');
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (BuildContext context) => ListeningChallengeScreen(
        rounds: rounds,
        title: title,
        onCompleted: recordOutcome,
      ),
    ));
  }
}
