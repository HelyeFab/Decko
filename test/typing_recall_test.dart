// MVP_021: typing-recall answer checking, builder availability/variants, and
// registry exposure.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:decko/data/decko_practice_mode_registry.dart';
import 'package:decko/domain/deck.dart';
import 'package:decko/domain/learning_item.dart';
import 'package:decko/domain/practice/practice_mode.dart';
import 'package:decko/domain/typing/typing_answer_checker.dart';
import 'package:decko/domain/typing/typing_recall.dart';
import 'package:decko/domain/typing/typing_recall_builder.dart';

TypingRecallRound _round(
  TypingTargetKind kind,
  String answer, {
  List<String>? accepted,
}) =>
    TypingRecallRound(
      itemId: 'w',
      deckId: 'd',
      targetKind: kind,
      promptText: '食べる',
      answer: answer,
      accepted: accepted ?? <String>[answer],
      source: TypingRecallSource.manualCard,
    );

LearningItem _item({
  String id = 'w',
  String front = '食べる',
  String back = 'to eat',
  String? reading = 'たべる',
}) =>
    LearningItem(id: id, front: front, back: back, reading: reading);

Deck _deck(List<LearningItem> items) =>
    Deck(id: 'd', name: 'D', description: '', items: items);

void main() {
  const TypingRecallChecker checker = TypingRecallChecker();
  const TypingRecallBuilder builder = TypingRecallBuilder();

  group('answer checker (MVP_021)', () {
    TypingResultCategory reading(String input, String answer) =>
        checker.check(input, _round(TypingTargetKind.reading, answer));
    TypingResultCategory meaning(String input, String answer,
            {List<String>? accepted}) =>
        checker.check(
            input, _round(TypingTargetKind.meaning, answer, accepted: accepted));

    test('exact reading is correct', () {
      expect(reading('たべる', 'たべる'), TypingResultCategory.correct);
    });

    test('katakana input matches a hiragana reading', () {
      expect(reading('タベル', 'たべる'), TypingResultCategory.correct);
    });

    test('trailing punctuation + full-width space are forgiven', () {
      expect(reading('たべる。', 'たべる'), TypingResultCategory.correct);
    });

    test('meaning is case-insensitive', () {
      expect(meaning('To Eat', 'to eat'), TypingResultCategory.correct);
    });

    test('any listed alternative meaning is accepted', () {
      expect(
          meaning('that',
              'that, that one', accepted: <String>['that, that one', 'that', 'that one']),
          TypingResultCategory.correct);
    });

    test('dropped spacing is "almost", not correct', () {
      expect(meaning('toeat', 'to eat'), TypingResultCategory.almost);
    });

    test('a single-character typo on a longer answer is "almost"', () {
      expect(meaning('aple', 'apple'), TypingResultCategory.almost);
    });

    test('an unrelated answer is incorrect', () {
      expect(reading('いぬ', 'たべる'), TypingResultCategory.incorrect);
    });

    test('an empty answer is incorrect', () {
      expect(reading('', 'たべる'), TypingResultCategory.incorrect);
    });
  });

  group('builder (MVP_021)', () {
    test('a kanji card with a reading + meaning yields both variants', () {
      final List<TypingRecallRound> rounds =
          builder.roundsForDeck(_deck(<LearningItem>[
        for (int i = 0; i < 4; i++) _item(id: 'w$i'),
      ]), random: Random(1));
      final Set<TypingTargetKind> kinds =
          rounds.map((TypingRecallRound r) => r.targetKind).toSet();
      expect(kinds, containsAll(<TypingTargetKind>[
        TypingTargetKind.reading,
        TypingTargetKind.meaning,
      ]));
    });

    test('a kana word (reading == expression) yields only a meaning variant',
        () {
      final LearningItem kana =
          _item(front: 'それ', reading: 'それ', back: 'that');
      expect(builder.isCapable(kana), isTrue);
      final TypingRecallRound? r =
          builder.roundForItem(kana, _deck(<LearningItem>[kana]),
              random: Random(1));
      expect(r!.targetKind, TypingTargetKind.meaning);
    });

    test('a card with no back and no reading is not capable', () {
      expect(builder.isCapable(_item(back: '', reading: null)), isFalse);
    });

    test('deck capability needs at least four usable cards', () {
      expect(
          builder.deckIsCapable(
              _deck(<LearningItem>[for (int i = 0; i < 4; i++) _item(id: 'w$i')])),
          isTrue);
      expect(
          builder.deckIsCapable(
              _deck(<LearningItem>[for (int i = 0; i < 3; i++) _item(id: 'w$i')])),
          isFalse);
    });

    test('meaning rounds accept comma-separated alternatives', () {
      final LearningItem item =
          _item(front: '大きい', reading: 'おおきい', back: 'big, large');
      final List<TypingRecallRound> rounds = builder.roundsForDeck(
          _deck(<LearningItem>[for (int i = 0; i < 4; i++) _item(id: 'x$i'), item]),
          limit: 50,
          random: Random(3));
      final TypingRecallRound meaningRound = rounds.firstWhere(
          (TypingRecallRound r) =>
              r.itemId == item.id && r.targetKind == TypingTargetKind.meaning);
      expect(meaningRound.accepted, containsAll(<String>['big', 'large']));
    });
  });

  group('registry exposes typing_recall (MVP_021)', () {
    const DeckoPracticeModeRegistry registry = DeckoPracticeModeRegistry();

    test('available for a capable card + deck', () {
      expect(
          registry.availableForCard(_item()).any(
              (PracticeMode m) => m.id == PracticeModeId.typingRecall),
          isTrue);
      expect(
          registry
              .availableForDeck(_deck(<LearningItem>[
                for (int i = 0; i < 4; i++) _item(id: 'w$i')
              ]))
              .any((PracticeMode m) => m.id == PracticeModeId.typingRecall),
          isTrue);
    });

    test('is a manual mode, review presentation deferred', () {
      final PracticeMode mode = registry.allModes
          .firstWhere((PracticeMode m) => m.id == PracticeModeId.typingRecall);
      expect(mode.manualLaunch, isTrue);
      expect(mode.reviewPresentation, isFalse);
    });
  });
}
