// Match Mode (MVP_025, DEC-034): Decko's fourth registered practice mode — a
// fast tap-to-pair vocabulary game. Manual/deck practice only; it awards
// motivational XP and never touches review/FSRS state. Pure models.

/// What the two sides of a pair represent.
enum MatchPairType { expressionToMeaning, expressionToReading, readingToMeaning }

extension MatchPairTypeLabel on MatchPairType {
  String get leftLabel => switch (this) {
        MatchPairType.expressionToMeaning => 'Word',
        MatchPairType.expressionToReading => 'Word',
        MatchPairType.readingToMeaning => 'Reading',
      };
  String get rightLabel => switch (this) {
        MatchPairType.expressionToMeaning => 'Meaning',
        MatchPairType.expressionToReading => 'Reading',
        MatchPairType.readingToMeaning => 'Meaning',
      };

  /// A short instruction shown on the board.
  String get instruction => switch (this) {
        MatchPairType.expressionToMeaning => 'Match each word to its meaning',
        MatchPairType.expressionToReading => 'Match each word to its reading',
        MatchPairType.readingToMeaning => 'Match each reading to its meaning',
      };
}

/// One matching pair, sourced from a single card.
class MatchModePair {
  const MatchModePair({
    required this.left,
    required this.right,
    required this.pairType,
    required this.sourceItemId,
  });

  final String left;
  final String right;
  final MatchPairType pairType;
  final String sourceItemId;
}

/// One board — a small set of pairs of a single [pairType] to clear.
class MatchModeRound {
  const MatchModeRound({required this.pairType, required this.pairs});

  final MatchPairType pairType;
  final List<MatchModePair> pairs;

  int get size => pairs.length;
}

/// Mutable session across several boards.
class MatchModeSession {
  MatchModeSession(this.rounds);

  final List<MatchModeRound> rounds;
  int currentIndex = 0;
  int correctPairs = 0;
  int incorrectAttempts = 0;

  MatchModeRound? get current =>
      currentIndex < rounds.length ? rounds[currentIndex] : null;

  bool get isComplete => currentIndex >= rounds.length;
  int get totalPairs =>
      rounds.fold(0, (int sum, MatchModeRound r) => sum + r.size);

  void recordCorrect() => correctPairs++;
  void recordIncorrect() => incorrectAttempts++;
  void advance() => currentIndex++;
}
