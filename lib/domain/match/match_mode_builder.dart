import 'dart:math';

import '../card_fields.dart';
import '../deck.dart';
import '../learning_item.dart';
import 'match_mode.dart';

/// Builds fair match boards from imported card fields (MVP_025). Pure, local,
/// deterministic given a [Random]. Each board holds 4–6 pairs of a single pair
/// type; boards never contain duplicate or blank sides, and skip long
/// sentence-y values (Match Mode is vocabulary-focused).
class MatchModeBuilder {
  const MatchModeBuilder();

  static const int minPairs = 4;
  static const int boardSize = 5;
  static const int _maxLen = 40; // keep tiles short — vocabulary, not sentences

  bool isCapable(LearningItem item) => _pairsFor(item).isNotEmpty;

  /// Whether [deck] has enough clean cards for at least one full board.
  bool deckIsCapable(Deck deck) {
    for (final MatchPairType type in MatchPairType.values) {
      if (_eligible(deck, type).length >= minPairs) return true;
    }
    return false;
  }

  /// A short session of boards (rounds), each a single pair type. Mixes types.
  List<MatchModeRound> roundsForDeck(Deck deck,
      {int limit = 6, Random? random}) {
    final Random rng = random ?? Random();
    final List<MatchModeRound> rounds = <MatchModeRound>[];
    for (final MatchPairType type in MatchPairType.values) {
      final List<MatchModePair> pool = _eligible(deck, type)..shuffle(rng);
      for (int i = 0; i + minPairs <= pool.length; i += boardSize) {
        final List<MatchModePair> chunk =
            pool.sublist(i, min(i + boardSize, pool.length));
        rounds.add(MatchModeRound(pairType: type, pairs: chunk));
      }
    }
    rounds.shuffle(rng);
    return rounds.take(limit).toList();
  }

  /// Deduplicated, usable pairs for one type across the deck (no repeated left
  /// or right value, so a board is never ambiguous).
  List<MatchModePair> _eligible(Deck deck, MatchPairType type) {
    final Set<String> seenLeft = <String>{};
    final Set<String> seenRight = <String>{};
    final List<MatchModePair> out = <MatchModePair>[];
    for (final LearningItem item in deck.items) {
      final MatchModePair? p = _pairFor(item, type);
      if (p == null) continue;
      if (seenLeft.contains(p.left) || seenRight.contains(p.right)) continue;
      seenLeft.add(p.left);
      seenRight.add(p.right);
      out.add(p);
    }
    return out;
  }

  List<MatchModePair> _pairsFor(LearningItem item) => <MatchModePair>[
        for (final MatchPairType t in MatchPairType.values)
          if (_pairFor(item, t) != null) _pairFor(item, t)!,
      ];

  MatchModePair? _pairFor(LearningItem item, MatchPairType type) {
    final CardFields f = cardFieldsOf(item);
    final String reading = f.reading ?? '';
    final (String left, String right) = switch (type) {
      MatchPairType.expressionToMeaning => (f.expression, f.meaning),
      MatchPairType.expressionToReading => (f.expression, reading),
      MatchPairType.readingToMeaning => (reading, f.meaning),
    };
    if (!_usable(left) || !_usable(right)) return null;
    if (left == right) return null; // identical sides would be a giveaway
    return MatchModePair(
      left: left,
      right: right,
      pairType: type,
      sourceItemId: item.id,
    );
  }

  bool _usable(String s) => s.isNotEmpty && s.length <= _maxLen;
}
