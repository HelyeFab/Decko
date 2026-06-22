import '../deck.dart';
import '../import/source/imported_anki_source.dart';
import '../learning_item.dart';
import '../practice/practice_mode.dart';

/// Discovers which practice modes are available for a card or a deck (MVP_017,
/// DEC-026). Lets Deck Detail / Review / the Practice Hub stay generic — they
/// ask the registry rather than hard-coding any one game.
abstract class PracticeModeRegistry {
  /// Every registered mode.
  List<PracticeMode> get allModes;

  /// Modes that can practise [item] (optionally with its imported [note]).
  List<PracticeMode> availableForCard(LearningItem item, {ImportedAnkiNote? note});

  /// Modes that any card in [deck] supports (optionally using its [source]).
  List<PracticeMode> availableForDeck(Deck deck, {ImportedAnkiSource? source});

  /// Modes that can be launched manually for [item].
  List<PracticeMode> manualModesForCard(LearningItem item, {ImportedAnkiNote? note});

  /// Modes usable as a scheduler-routed review presentation for [item].
  List<PracticeMode> reviewPresentationModesForCard(LearningItem item,
      {ImportedAnkiNote? note});
}
