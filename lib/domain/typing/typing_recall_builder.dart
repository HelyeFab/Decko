import 'dart:math';

import '../deck.dart';
import '../learning_item.dart';
import '../sentence_builder/sentence_text.dart';
import 'typing_recall.dart';

typedef _Variant = ({
  TypingTargetKind kind,
  String prompt,
  String answer,
  List<String> accepted,
  String? explanation,
});

/// Builds [TypingRecallRound]s from imported card fields (MVP_021). Pure, local,
/// deterministic given a [Random]. Per card it can emit a reading round (show
/// the expression → type the reading) and/or a meaning round (→ type the
/// meaning), so a session mixes both.
class TypingRecallBuilder {
  const TypingRecallBuilder();

  static const int minCards = 4;

  bool isCapable(LearningItem item) => _variantsFor(item).isNotEmpty;

  /// Whether [deck] has at least [minCards] cards with a usable typing target.
  bool deckIsCapable(Deck deck, {int sample = 400}) {
    int found = 0;
    final int n = deck.items.length < sample ? deck.items.length : sample;
    for (int i = 0; i < n; i++) {
      if (_variantsFor(deck.items[i]).isNotEmpty) {
        found++;
        if (found >= minCards) return true;
      }
    }
    return false;
  }

  /// A single round for [item] (manual) — a random available variant.
  TypingRecallRound? roundForItem(LearningItem item, Deck deck,
      {Random? random}) {
    final List<_Variant> variants = _variantsFor(item);
    if (variants.isEmpty) return null;
    final _Variant v = variants[(random ?? Random()).nextInt(variants.length)];
    return _round(v, item.id, deck.id, TypingRecallSource.manualCard);
  }

  /// A short shuffled session of rounds for [deck] (mixing reading + meaning).
  List<TypingRecallRound> roundsForDeck(Deck deck,
      {int limit = 8, Random? random}) {
    int capableItems = 0;
    final List<TypingRecallRound> pool = <TypingRecallRound>[];
    for (final LearningItem item in deck.items) {
      final List<_Variant> variants = _variantsFor(item);
      if (variants.isEmpty) continue;
      capableItems++;
      for (final _Variant v in variants) {
        pool.add(_round(v, item.id, deck.id, TypingRecallSource.deckPractice));
      }
    }
    if (capableItems < minCards) return <TypingRecallRound>[];
    pool.shuffle(random ?? Random());
    return pool.take(limit).toList();
  }

  TypingRecallRound _round(
          _Variant v, String itemId, String deckId, TypingRecallSource source) =>
      TypingRecallRound(
        itemId: itemId,
        deckId: deckId,
        targetKind: v.kind,
        promptText: v.prompt,
        answer: v.answer,
        accepted: v.accepted,
        source: source,
        explanation: v.explanation,
      );

  List<_Variant> _variantsFor(LearningItem item) {
    final List<_Variant> out = <_Variant>[];
    final String expr = cleanSentence(item.front);
    if (expr.isEmpty) return out;

    final String reading = cleanSentence(item.reading ?? '');
    final String meaning = cleanSentence(item.back);

    // Reading recall — only when the reading differs from the shown expression
    // (no recall value when the word is already its own reading).
    if (reading.isNotEmpty && reading != expr) {
      out.add((
        kind: TypingTargetKind.reading,
        prompt: expr,
        answer: reading,
        accepted: <String>[reading],
        explanation: meaning.isEmpty ? null : meaning,
      ));
    }

    // Meaning recall — type the (English) meaning; any listed alternative works.
    if (meaning.isNotEmpty && meaning != expr) {
      out.add((
        kind: TypingTargetKind.meaning,
        prompt: expr,
        answer: meaning,
        accepted: _alternatives(meaning),
        explanation: reading.isEmpty ? null : reading,
      ));
    }
    return out;
  }

  /// The full meaning plus each comma/slash/semicolon-separated alternative.
  List<String> _alternatives(String meaning) {
    final List<String> parts = meaning
        .split(RegExp(r'[,/;、・]'))
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toList();
    return <String>{meaning, ...parts}.toList();
  }
}
