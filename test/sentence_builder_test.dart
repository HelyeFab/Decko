// MVP_016: sentence text helpers, the sync sentence picker, the async round
// service (with a fake tokenizer + in-memory cache), and the review opt-in flag.

import 'package:flutter_test/flutter_test.dart';

import 'package:decko/domain/deck.dart';
import 'package:decko/domain/import/source/imported_anki_source.dart';
import 'package:decko/domain/learning_item.dart';
import 'package:decko/domain/repositories/sentence_token_cache.dart';
import 'package:decko/domain/sentence_builder/cube_token.dart';
import 'package:decko/domain/sentence_builder/sentence_builder_mapper.dart';
import 'package:decko/domain/sentence_builder/sentence_builder_round.dart';
import 'package:decko/domain/sentence_builder/sentence_builder_source.dart';
import 'package:decko/domain/sentence_builder/sentence_builder_token.dart';
import 'package:decko/domain/sentence_builder/sentence_text.dart';
import 'package:decko/domain/sentence_builder/sentence_tokenizer.dart';
import 'package:decko/domain/study_options/study_options.dart';
import 'package:decko/features/sentence_builder/sentence_round_service.dart';

/// A fake tokenizer that splits each line on spaces — deterministic, offline.
class _SplitTokenizer implements SentenceTokenizer {
  int calls = 0;

  @override
  Future<TokenizeResult> tokenize(List<String> lines) async {
    calls++;
    return TokenizeResult(
      lines: lines,
      tokens: <List<CubeToken>>[
        for (final String l in lines)
          <CubeToken>[
            for (final String w in l.split(' ').where((String w) => w.isNotEmpty))
              CubeToken(surface: w),
          ],
      ],
    );
  }
}

class _MemCache implements SentenceTokenCache {
  final Map<String, Map<String, CachedTokenization>> store =
      <String, Map<String, CachedTokenization>>{};

  @override
  Future<Map<String, CachedTokenization>> load(String deckId) async =>
      Map<String, CachedTokenization>.of(
          store[deckId] ?? const <String, CachedTokenization>{});

  @override
  Future<void> save(
          String deckId, Map<String, CachedTokenization> entries) async =>
      (store[deckId] ??= <String, CachedTokenization>{}).addAll(entries);

  @override
  Future<void> clear(String deckId) async => store.remove(deckId);
}

LearningItem _item(String id, {String? example}) =>
    LearningItem(id: id, front: id, back: 'b', example: example);

void main() {
  group('sentence text helpers', () {
    test('cleanSentence strips [sound:…] and collapses whitespace', () {
      expect(cleanSentence('[sound:a.mp3] hello   world'), 'hello world');
      expect(cleanSentence('<b>hi</b>&nbsp;there'), 'hi there');
    });

    test('soundRefIn finds the audio filename', () {
      expect(soundRefIn(<String?>['x', '[sound:foo.mp3]']), 'foo.mp3');
      expect(soundRefIn(<String?>['none']), isNull);
    });

    test('looksLikeSentence is a cheap capability heuristic', () {
      expect(looksLikeSentence('hello there'), isTrue);
      expect(looksLikeSentence('日本語が話せます'), isTrue);
      expect(looksLikeSentence('猫'), isFalse); // too short
      expect(looksLikeSentence(null), isFalse);
    });
  });

  group('SentenceBuilderMapper (sync picker)', () {
    const SentenceBuilderMapper mapper = SentenceBuilderMapper();

    test('uses the item example and is capable', () {
      final SentenceSource? s = mapper.sourceFor(_item('a', example: 'one two'));
      expect(s, isNotNull);
      expect(s!.sentence, 'one two');
      expect(mapper.looksCapable(_item('a', example: 'one two')), isTrue);
    });

    test('is not capable without a sentence', () {
      expect(mapper.looksCapable(_item('a')), isFalse);
    });

    test('prefers the Sentence field and extracts [sound:] audio', () {
      final ImportedAnkiNote note = ImportedAnkiNote(
        sourceNoteId: 'n1',
        sourceGuid: 'g',
        sourceModelId: 'm',
        modelName: 'M',
        deckId: 'd',
        tags: const <String>[],
        fields: const <ImportedAnkiField>[
          ImportedAnkiField(
            name: 'Sentence',
            ordinal: 0,
            rawValue: '[sound:s.mp3] from the note',
            plainTextValue: '[sound:s.mp3] from the note',
          ),
          ImportedAnkiField(
            name: 'Sentence-English',
            ordinal: 1,
            rawValue: 'translation',
            plainTextValue: 'translation',
          ),
        ],
      );
      final SentenceSource? s =
          mapper.sourceFor(_item('a', example: 'from the item'), note: note);
      expect(s!.sentence, 'from the note');
      expect(s.audioRef, 's.mp3');
      expect(s.translation, 'translation');
      expect(s.noteId, 'n1');
    });
  });

  group('SentenceBuilderRound', () {
    SentenceBuilderRound round() => const SentenceBuilderRound(
          deckId: 'd',
          source: SentenceBuilderSource.deckPractice,
          sentence: 'a b c',
          tokens: <SentenceBuilderToken>[
            SentenceBuilderToken(text: 'a', position: 0),
            SentenceBuilderToken(text: 'b', position: 1),
            SentenceBuilderToken(text: 'c', position: 2),
          ],
        );

    test('isCorrect only for the right order and length', () {
      final SentenceBuilderRound r = round();
      expect(r.isCorrect(r.tokens), isTrue);
      expect(
          r.isCorrect(<SentenceBuilderToken>[
            r.tokens[1],
            r.tokens[0],
            r.tokens[2],
          ]),
          isFalse);
      expect(r.isCorrect(<SentenceBuilderToken>[r.tokens[0]]), isFalse);
    });
  });

  group('SentenceRoundService (async, cached)', () {
    test('tokenizes a card, builds tiles, and caches the result', () async {
      final _SplitTokenizer tok = _SplitTokenizer();
      final _MemCache cache = _MemCache();
      final SentenceRoundService service =
          SentenceRoundService(tokenizer: tok, cache: cache);

      final SentenceBuilderRound? r = await service.roundForItem(
        _item('a', example: 'one two three'),
        deckId: 'd',
        source: SentenceBuilderSource.manualCard,
      );
      expect(r, isNotNull);
      expect(r!.tokens.map((SentenceBuilderToken t) => t.text).toList(),
          <String>['one', 'two', 'three']);
      expect(tok.calls, 1);

      // Second build hits the cache — no extra tokenizer call.
      await service.roundForItem(
        _item('a', example: 'one two three'),
        deckId: 'd',
        source: SentenceBuilderSource.manualCard,
      );
      expect(tok.calls, 1);
    });

    test('returns null when the sentence yields fewer than two tiles', () async {
      final SentenceRoundService service = SentenceRoundService(
          tokenizer: _SplitTokenizer(), cache: _MemCache());
      final SentenceBuilderRound? r = await service.roundForItem(
        _item('a', example: 'singleword'),
        deckId: 'd',
        source: SentenceBuilderSource.manualCard,
      );
      expect(r, isNull);
    });

    test('roundsForDeck builds one round per capable card up to the limit',
        () async {
      final Deck deck = Deck(
        id: 'd',
        name: 'D',
        description: '',
        items: <LearningItem>[
          _item('a', example: 'one two'),
          _item('b'), // no sentence
          _item('c', example: 'three four five'),
        ],
      );
      final List<SentenceBuilderRound> rounds = await SentenceRoundService(
        tokenizer: _SplitTokenizer(),
        cache: _MemCache(),
      ).roundsForDeck(deck);
      expect(rounds, hasLength(2));
    });

    test('deckHasLikelySentences detects sentence-bearing decks (sync)', () {
      expect(
          deckHasLikelySentences(Deck(
              id: 'd',
              name: 'D',
              description: '',
              items: <LearningItem>[_item('a', example: 'one two')])),
          isTrue);
      expect(
          deckHasLikelySentences(Deck(
              id: 'd',
              name: 'D',
              description: '',
              items: <LearningItem>[_item('a')])),
          isFalse);
    });
  });

  group('sentenceBuilderReview option', () {
    test('defaults off and round-trips through serialization', () {
      expect(const StudyOptions().sentenceBuilderReview, isFalse);
      final StudyOptions restored = StudyOptions.fromMap(
          const StudyOptions().copyWith(sentenceBuilderReview: true).toMap());
      expect(restored.sentenceBuilderReview, isTrue);
    });

    test('resolves into EffectiveStudyOptions from the global base', () {
      expect(
          EffectiveStudyOptions.resolve(
                  const StudyOptions(sentenceBuilderReview: true), null)
              .sentenceBuilderReview,
          isTrue);
    });
  });
}
