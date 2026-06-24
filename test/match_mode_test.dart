// MVP_025: Match Mode pair extraction, fairness, availability, and registry.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:decko/data/decko_practice_mode_registry.dart';
import 'package:decko/domain/deck.dart';
import 'package:decko/domain/learning_item.dart';
import 'package:decko/domain/match/match_mode.dart';
import 'package:decko/domain/match/match_mode_builder.dart';
import 'package:decko/domain/practice/practice_mode.dart';

LearningItem _card(String id,
        {required String front,
        required String back,
        String? reading}) =>
    LearningItem(id: id, front: front, back: back, reading: reading);

Deck _deck(List<LearningItem> items) =>
    Deck(id: 'd', name: 'D', description: '', items: items);

/// A vocab deck of n clean cards (word i → meaning i → reading i).
Deck _vocabDeck(int n) => _deck(<LearningItem>[
      for (int i = 0; i < n; i++)
        _card('w$i', front: 'word$i', back: 'meaning$i', reading: 'reading$i'),
    ]);

void main() {
  const MatchModeBuilder builder = MatchModeBuilder();

  group('MatchModeBuilder (MVP_025)', () {
    test('builds boards of 4–6 pairs with distinct, non-blank sides', () {
      final List<MatchModeRound> rounds =
          builder.roundsForDeck(_vocabDeck(12), random: Random(1));
      expect(rounds, isNotEmpty);
      for (final MatchModeRound r in rounds) {
        expect(r.pairs.length, inInclusiveRange(4, MatchModeBuilder.boardSize));
        // No duplicate or blank sides within a board.
        expect(r.pairs.map((MatchModePair p) => p.left).toSet().length,
            r.pairs.length);
        expect(r.pairs.map((MatchModePair p) => p.right).toSet().length,
            r.pairs.length);
        for (final MatchModePair p in r.pairs) {
          expect(p.left, isNotEmpty);
          expect(p.right, isNotEmpty);
          expect(p.left, isNot(p.right));
        }
      }
    });

    test('skips unusable cards: blank, identical sides, and long values', () {
      final Deck deck = _deck(<LearningItem>[
        _card('a', front: '', back: 'meaning'), // blank front
        _card('b', front: 'same', back: 'same'), // identical sides
        _card('c',
            front: 'word',
            back: 'a very very very very very long sentence meaning indeed'),
      ]);
      expect(builder.isCapable(deck.items[0]), isFalse);
      // 'same/same' has no expression→meaning pair, but reading is null too.
      expect(
          builder.isCapable(_card('b', front: 'same', back: 'same')), isFalse);
      // long meaning is skipped for expression→meaning.
      final List<MatchModeRound> rounds = builder.roundsForDeck(deck);
      expect(rounds, isEmpty); // nothing fair enough for a board
    });

    test('deduplicates repeated meanings across cards', () {
      // Two different words sharing the exact same meaning → only one pair.
      final Deck deck = _deck(<LearningItem>[
        for (int i = 0; i < 6; i++)
          _card('w$i', front: 'word$i', back: 'same meaning'),
      ]);
      final List<MatchModeRound> rounds = builder.roundsForDeck(deck);
      // Only one card's meaning survives dedup → can't fill a 4-pair board.
      expect(rounds, isEmpty);
    });

    test('deck capability needs at least a full board', () {
      expect(builder.deckIsCapable(_vocabDeck(4)), isTrue);
      expect(builder.deckIsCapable(_vocabDeck(3)), isFalse);
    });

    test('works on media-only-front decks (word + meaning in the back)', () {
      // The Core 2k/6k shape: front is audio/image, back is "expression\nmeaning".
      final Deck deck = _deck(<LearningItem>[
        for (int i = 0; i < 6; i++)
          _card('w$i',
              front: '[sound:s$i.mp3] <img src="i$i.jpg">',
              back: 'word$i\nmeaning$i'),
      ]);
      expect(builder.deckIsCapable(deck), isTrue);
      final List<MatchModeRound> rounds =
          builder.roundsForDeck(deck, random: Random(1));
      expect(rounds, isNotEmpty);
      final MatchModePair sample = rounds.first.pairs.first;
      expect(sample.pairType, MatchPairType.expressionToMeaning);
      expect(sample.left, startsWith('word'));
      expect(sample.right, startsWith('meaning'));
    });
  });

  group('registry exposes match_mode (MVP_025)', () {
    const DeckoPracticeModeRegistry registry = DeckoPracticeModeRegistry();

    test('available for a vocab-rich deck', () {
      expect(
          registry.availableForDeck(_vocabDeck(6)).any(
              (PracticeMode m) => m.id == PracticeModeId.matchMode),
          isTrue);
    });

    test('manual + deck practice, review presentation deferred', () {
      final PracticeMode mode = registry.allModes
          .firstWhere((PracticeMode m) => m.id == PracticeModeId.matchMode);
      expect(mode.manualLaunch, isTrue);
      expect(mode.reviewPresentation, isFalse);
    });
  });
}
