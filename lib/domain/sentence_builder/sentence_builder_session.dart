import 'sentence_builder_result.dart';
import 'sentence_builder_round.dart';

/// Deliberately mutable session holder for the sentence builder game loop.
class SentenceBuilderSession {
  SentenceBuilderSession(this.rounds);

  final List<SentenceBuilderRound> rounds;
  int currentIndex = 0;
  final List<SentenceBuilderResult> results = <SentenceBuilderResult>[];

  /// The active round, or null after the session is complete.
  SentenceBuilderRound? get current {
    return currentIndex < rounds.length ? rounds[currentIndex] : null;
  }

  /// Whether every round has been recorded.
  bool get isComplete => currentIndex >= rounds.length;

  /// Total number of rounds in this session.
  int get total => rounds.length;

  /// Number of recorded rounds that were answered correctly.
  int get correctCount {
    return results
        .where((SentenceBuilderResult result) => result.correct)
        .length;
  }

  /// Records [result] and advances to the next round.
  void recordAndAdvance(SentenceBuilderResult result) {
    results.add(result);
    currentIndex++;
  }
}
