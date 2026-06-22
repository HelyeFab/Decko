import 'package:flutter/material.dart';

import '../../app/decko_app.dart';
import '../../domain/deck.dart';
import '../../domain/import/source/imported_anki_source.dart';
import '../../domain/learning_item.dart';
import '../../domain/practice/practice_mode.dart';
import '../../domain/repositories/imported_source_store.dart';
import '../../domain/sentence_builder/sentence_builder_round.dart';
import '../../domain/sentence_builder/sentence_builder_source.dart';
import '../sentence_builder/sentence_builder_loader.dart';
import '../sentence_builder/sentence_round_service.dart';

/// The single place that maps a [PracticeMode] to its screen (MVP_017). Deck
/// Detail / Review / the Hub call these; adding a future game means one new
/// `case`, not edits across unrelated screens.
class PracticeLauncher {
  const PracticeLauncher._();

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
    }
  }

  /// Launches manual single-card practice for [mode] on [item].
  static void launchCard(
    BuildContext context,
    PracticeMode mode,
    LearningItem item, {
    required String deckId,
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
                deckId: deckId,
                source: SentenceBuilderSource.manualCard,
                note: note,
              );
              return <SentenceBuilderRound>[?round];
            },
          ),
        ));
    }
  }
}
