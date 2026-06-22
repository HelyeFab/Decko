// MVP_018: listening-challenge availability, choice generation, and registry.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:decko/data/decko_practice_mode_registry.dart';
import 'package:decko/domain/deck.dart';
import 'package:decko/domain/learning_item.dart';
import 'package:decko/domain/listening/listening_challenge.dart';
import 'package:decko/domain/listening/listening_challenge_builder.dart';
import 'package:decko/domain/practice/practice_mode.dart';

/// A card with embedded word audio in its front and a distinct meaning.
LearningItem _audio(String id, String meaning) =>
    LearningItem(id: id, front: '$id [sound:$id.mp3]', back: meaning);

Deck _deck(List<LearningItem> items) =>
    Deck(id: 'd', name: 'D', description: '', items: items);

Deck _audioDeck(int n) => _deck(<LearningItem>[
      for (int i = 0; i < n; i++) _audio('w$i', 'meaning $i'),
    ]);

void main() {
  const ListeningChallengeBuilder builder = ListeningChallengeBuilder();

  group('ListeningChallengeBuilder (MVP_018)', () {
    test('a card with audio + a meaning is capable', () {
      expect(builder.isCapable(_audio('a', 'thing')), isTrue);
    });

    test('a card without audio is not capable', () {
      expect(
          builder.isCapable(const LearningItem(id: 'a', front: 'a', back: 'b')),
          isFalse);
    });

    test('deck capability needs at least four audio cards', () {
      expect(builder.deckIsCapable(_audioDeck(4)), isTrue);
      expect(builder.deckIsCapable(_audioDeck(3)), isFalse);
    });

    test('a round has four distinct choices including the correct answer', () {
      final Deck deck = _audioDeck(6);
      final ListeningChallengeRound? round = builder.roundForItem(
        deck.items.first,
        deck,
        random: Random(1),
      );
      expect(round, isNotNull);
      expect(round!.choices, hasLength(4));
      expect(round.choices.toSet(), hasLength(4)); // no duplicates
      expect(round.choices, contains(round.answer));
      expect(round.answer, 'meaning 0');
      expect(round.audioRef, 'w0.mp3');
    });

    test('a sentence-audio card builds a sentence-level round, not word choices',
        () {
      // Cards with only sentence audio (in example) and no translation.
      final Deck deck = _deck(<LearningItem>[
        for (int i = 0; i < 4; i++)
          LearningItem(
            id: 's$i',
            front: 'word$i',
            back: 'word meaning $i',
            example: 'これはぶん$iです。 [sound:s$i.mp3]',
          ),
      ]);
      final ListeningChallengeRound? round =
          builder.roundForItem(deck.items.first, deck, random: Random(3));
      expect(round, isNotNull);
      expect(round!.promptKind, ListeningPromptKind.sentence);
      // The answer + choices are sentence-level, not the word meaning.
      expect(round.answer, 'これはぶん0です。');
      expect(round.choices, isNot(contains('word meaning 1')));
      expect(round.choices, contains('これはぶん0です。'));
      expect(round.choices, hasLength(4));
      // Without a translation, the reveal still shows the word + its meaning.
      expect(round.meaningContext, 'word0 — word meaning 0');
    });

    test('roundsForDeck builds rounds; an audio-poor deck builds none', () {
      expect(builder.roundsForDeck(_audioDeck(6), random: Random(2)),
          isNotEmpty);
      expect(builder.roundsForDeck(_audioDeck(2)), isEmpty);
    });
  });

  group('registry exposes listening_challenge (MVP_018)', () {
    const DeckoPracticeModeRegistry registry = DeckoPracticeModeRegistry();

    test('available for an audio card and an audio-rich deck', () {
      expect(
          registry
              .availableForCard(_audio('a', 'x'))
              .any((PracticeMode m) => m.id == PracticeModeId.listeningChallenge),
          isTrue);
      expect(
          registry
              .availableForDeck(_audioDeck(5))
              .any((PracticeMode m) => m.id == PracticeModeId.listeningChallenge),
          isTrue);
    });

    test('listening is a manual mode, not a review presentation (deferred)', () {
      final PracticeMode mode = registry.allModes.firstWhere(
          (PracticeMode m) => m.id == PracticeModeId.listeningChallenge);
      expect(mode.manualLaunch, isTrue);
      expect(mode.reviewPresentation, isFalse);
    });
  });
}
