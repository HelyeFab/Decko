import '../domain/deck.dart';
import '../domain/import/source/imported_anki_source.dart';
import '../domain/learning_item.dart';
import '../domain/listening/listening_challenge_builder.dart';
import '../domain/practice/practice_mode.dart';
import '../domain/repositories/practice_mode_registry.dart';
import '../domain/sentence_builder/sentence_builder_mapper.dart';

/// Decko's built-in practice-mode registry (MVP_017). Registers Bunburu; future
/// games register here without any change to Deck Detail / Review / the Hub.
class DeckoPracticeModeRegistry implements PracticeModeRegistry {
  const DeckoPracticeModeRegistry();

  static const SentenceBuilderMapper _mapper = SentenceBuilderMapper();
  static const ListeningChallengeBuilder _listening = ListeningChallengeBuilder();

  static const PracticeMode _bunburu = PracticeMode(
    id: PracticeModeId.bunburuSentenceBuilder,
    title: 'Sentence builder',
    subtitle: 'Rebuild scrambled sentences',
    description: 'Put the words back in order to rebuild the sentence — '
        'great for word order and comprehension.',
    kind: PracticeModeKind.build,
    manualLaunch: true,
    reviewPresentation: true,
  );

  static const PracticeMode _listeningMode = PracticeMode(
    id: PracticeModeId.listeningChallenge,
    title: 'Listening',
    subtitle: 'Match the audio to its meaning',
    description: 'Hear a word and pick the right meaning from four choices — '
        'builds sound-to-meaning recognition.',
    kind: PracticeModeKind.listen,
    manualLaunch: true,
    // Review presentation deferred (MVP_018): manual + deck practice only.
    reviewPresentation: false,
  );

  @override
  List<PracticeMode> get allModes =>
      const <PracticeMode>[_bunburu, _listeningMode];

  @override
  List<PracticeMode> availableForCard(LearningItem item,
      {ImportedAnkiNote? note}) {
    return <PracticeMode>[
      if (_mapper.looksCapable(item, note: note)) _bunburu,
      if (_listening.isCapable(item, note: note)) _listeningMode,
    ];
  }

  @override
  List<PracticeMode> availableForDeck(Deck deck, {ImportedAnkiSource? source}) {
    return <PracticeMode>[
      if (_deckHasSentences(deck, source)) _bunburu,
      if (_listening.deckIsCapable(deck, source: source)) _listeningMode,
    ];
  }

  @override
  List<PracticeMode> manualModesForCard(LearningItem item,
          {ImportedAnkiNote? note}) =>
      availableForCard(item, note: note)
          .where((PracticeMode m) => m.manualLaunch)
          .toList();

  @override
  List<PracticeMode> reviewPresentationModesForCard(LearningItem item,
          {ImportedAnkiNote? note}) =>
      availableForCard(item, note: note)
          .where((PracticeMode m) => m.reviewPresentation)
          .toList();

  bool _deckHasSentences(Deck deck, ImportedAnkiSource? source,
      {int sample = 200}) {
    final int n = deck.items.length < sample ? deck.items.length : sample;
    for (int i = 0; i < n; i++) {
      final LearningItem item = deck.items[i];
      final String? noteId = item.importedProgress?.sourceNoteId;
      final ImportedAnkiNote? note =
          (noteId != null) ? source?.noteById(noteId) : null;
      if (_mapper.looksCapable(item, note: note)) return true;
    }
    return false;
  }
}
