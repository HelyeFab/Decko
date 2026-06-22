import 'dart:math';

import '../deck.dart';
import '../import/source/imported_anki_source.dart';
import '../learning_item.dart';
import '../sentence_builder/sentence_text.dart';
import 'listening_challenge.dart';

/// An audio-capable card extracted for the listening challenge.
class _ListeningCard {
  const _ListeningCard({
    required this.itemId,
    required this.audioRef,
    required this.kind,
    required this.answer,
    required this.promptText,
    this.context = '',
  });

  final String itemId;
  final String audioRef;
  final ListeningPromptKind kind;
  final String answer;
  final String promptText;
  final String context;
}

/// Builds listening-challenge rounds from imported audio (MVP_018, DEC-027).
/// Pure and deterministic given a [Random]; never touches review/FSRS state.
class ListeningChallengeBuilder {
  const ListeningChallengeBuilder();

  /// Fewest audio-capable cards a deck needs (1 correct + 3 distractors).
  static const int minCards = 4;
  static const int choiceCount = 4;

  /// Whether [item] has playable audio + a usable answer.
  bool isCapable(LearningItem item, {ImportedAnkiNote? note}) =>
      _variantsFor(item, note: note).isNotEmpty;

  /// Whether [deck] has at least [minCards] audio-capable cards.
  bool deckIsCapable(Deck deck, {ImportedAnkiSource? source, int sample = 400}) {
    int found = 0;
    final int n = deck.items.length < sample ? deck.items.length : sample;
    for (int i = 0; i < n; i++) {
      if (_variantsFor(deck.items[i], note: _noteFor(deck.items[i], source))
          .isNotEmpty) {
        found++;
        if (found >= minCards) return true;
      }
    }
    return false;
  }

  /// A single round for [item] (manual), using [deck] for distractors. Picks a
  /// random available variant (word or sentence audio).
  ListeningChallengeRound? roundForItem(
    LearningItem item,
    Deck deck, {
    ImportedAnkiSource? source,
    Random? random,
  }) {
    final Random rng = random ?? Random();
    final List<_ListeningCard> variants =
        _variantsFor(item, note: _noteFor(item, source));
    if (variants.isEmpty) return null;
    final _ListeningCard card = variants[rng.nextInt(variants.length)];
    final List<_ListeningCard> pool = _pool(deck, source);
    return _round(card, pool, deck.id, ListeningChallengeSource.manualCard, rng);
  }

  /// Up to [limit] rounds for [deck], a fresh random selection each time.
  List<ListeningChallengeRound> roundsForDeck(
    Deck deck, {
    ImportedAnkiSource? source,
    int limit = 20,
    Random? random,
  }) {
    final List<_ListeningCard> pool = _pool(deck, source);
    if (pool.length < minCards) return <ListeningChallengeRound>[];
    final Random rng = random ?? Random();
    final List<_ListeningCard> shuffled = <_ListeningCard>[...pool]..shuffle(rng);
    final List<ListeningChallengeRound> rounds = <ListeningChallengeRound>[];
    for (final _ListeningCard c in shuffled.take(limit)) {
      final ListeningChallengeRound? r = _round(
          c, pool, deck.id, ListeningChallengeSource.deckPractice, rng);
      if (r != null) rounds.add(r);
    }
    return rounds;
  }

  // --- internals -------------------------------------------------------------

  List<_ListeningCard> _pool(Deck deck, ImportedAnkiSource? source) {
    final List<_ListeningCard> cards = <_ListeningCard>[];
    for (final LearningItem item in deck.items) {
      cards.addAll(_variantsFor(item, note: _noteFor(item, source)));
    }
    return cards;
  }

  /// The playable variants for [item]: a word-audio round (front) and/or a
  /// sentence-audio round (example), so practice mixes both.
  List<_ListeningCard> _variantsFor(LearningItem item, {ImportedAnkiNote? note}) {
    final List<_ListeningCard> out = <_ListeningCard>[];

    // Word audio (front) → the card's meaning (back).
    final String? wordAudio = soundRefIn(<String?>[
      item.front,
      note?.fieldByName('Audio')?.rawValue,
      note?.fieldByName('Word Audio')?.rawValue,
    ]);
    if (wordAudio != null) {
      final String answer = cleanSentence(item.back);
      if (answer.isNotEmpty) {
        out.add(_ListeningCard(
          itemId: item.id,
          audioRef: wordAudio,
          kind: ListeningPromptKind.word,
          answer: answer,
          promptText: cleanSentence(item.front),
        ));
      }
    }

    // Sentence audio (example). The answer must be sentence-level so the four
    // choices match the prompt: the sentence's English meaning when available,
    // otherwise the matching written sentence itself — never a word meaning.
    final String? sentenceAudio = soundRefIn(<String?>[
      item.example,
      note?.fieldByName('Sentence Audio')?.rawValue,
    ]);
    if (sentenceAudio != null) {
      final String translation =
          cleanSentence(note?.fieldByName('Sentence-English')?.plainTextValue ?? '');
      final String sentence = cleanSentence(item.example ?? '');
      if (translation.isNotEmpty) {
        // Hear the sentence → pick its English meaning; reveal the sentence.
        out.add(_ListeningCard(
          itemId: item.id,
          audioRef: sentenceAudio,
          kind: ListeningPromptKind.sentence,
          answer: translation,
          promptText: sentence,
        ));
      } else if (sentence.isNotEmpty) {
        // No translation: matching mode (choices are sentences). Reveal the
        // word + meaning the sentence features, which we do have.
        final String word = cleanSentence(item.front);
        final String meaning = cleanSentence(item.back);
        final String context = (word.isNotEmpty && meaning.isNotEmpty)
            ? '$word — $meaning'
            : meaning;
        out.add(_ListeningCard(
          itemId: item.id,
          audioRef: sentenceAudio,
          kind: ListeningPromptKind.sentence,
          answer: sentence,
          promptText: '',
          context: context,
        ));
      }
    }
    return out;
  }

  ListeningChallengeRound? _round(
    _ListeningCard card,
    List<_ListeningCard> pool,
    String deckId,
    ListeningChallengeSource source,
    Random rng,
  ) {
    // Distractors: distinct answers from other cards (same kind preferred).
    final List<String> sameKind = <String>[
      for (final _ListeningCard c in pool)
        if (c.itemId != card.itemId &&
            c.kind == card.kind &&
            c.answer != card.answer)
          c.answer,
    ];
    final List<String> anyKind = <String>[
      for (final _ListeningCard c in pool)
        if (c.itemId != card.itemId && c.answer != card.answer) c.answer,
    ];
    final List<String> candidates = (sameKind.toSet().length >= 3
        ? sameKind
        : <String>[...sameKind, ...anyKind])
      ..shuffle(rng);

    final List<String> distractors = <String>[];
    for (final String a in candidates) {
      if (distractors.length >= choiceCount - 1) break;
      if (a != card.answer && !distractors.contains(a)) distractors.add(a);
    }
    if (distractors.isEmpty) return null;

    final List<String> choices = <String>[card.answer, ...distractors]
      ..shuffle(rng);
    return ListeningChallengeRound(
      itemId: card.itemId,
      deckId: deckId,
      audioRef: card.audioRef,
      promptKind: card.kind,
      answer: card.answer,
      choices: choices,
      source: source,
      promptText: card.promptText.isEmpty ? null : card.promptText,
      meaningContext: card.context.isEmpty ? null : card.context,
    );
  }

  ImportedAnkiNote? _noteFor(LearningItem item, ImportedAnkiSource? source) {
    final String? noteId = item.importedProgress?.sourceNoteId;
    if (noteId == null || source == null) return null;
    return source.noteById(noteId);
  }
}
