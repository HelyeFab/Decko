// Domain models for the Listening Challenge practice mode (MVP_018, DEC-027).
// Framework-light, deterministic, no review/FSRS coupling.

/// What kind of audio a round plays.
enum ListeningPromptKind { word, sentence }

/// How a listening round was launched (manual practice never touches review).
enum ListeningChallengeSource { manualCard, deckPractice }

/// One audio → 4-choice round.
class ListeningChallengeRound {
  const ListeningChallengeRound({
    required this.itemId,
    required this.deckId,
    required this.audioRef,
    required this.promptKind,
    required this.answer,
    required this.choices,
    required this.source,
    this.promptText,
    this.meaningContext,
  });

  /// Source learning item / card id.
  final String itemId;
  final String deckId;

  /// Media filename to play.
  final String audioRef;
  final ListeningPromptKind promptKind;

  /// The correct choice text (the card's meaning).
  final String answer;

  /// Four shuffled choices, including [answer].
  final List<String> choices;

  final ListeningChallengeSource source;

  /// The word/sentence text, revealed after answering (for feedback).
  final String? promptText;

  /// Extra meaning context shown after answering — the sentence's translation,
  /// or (when none exists) the word + meaning the sentence features.
  final String? meaningContext;

  bool isCorrect(String choice) => choice == answer;
}

/// The outcome of one round.
class ListeningChallengeResult {
  const ListeningChallengeResult({required this.roundIndex, required this.correct});
  final int roundIndex;
  final bool correct;
}

/// A deliberately mutable progress holder for a listening session (manual /
/// deck practice). Carries no scheduling concern.
class ListeningChallengeSession {
  ListeningChallengeSession(this.rounds);

  final List<ListeningChallengeRound> rounds;
  int currentIndex = 0;
  final List<ListeningChallengeResult> results = <ListeningChallengeResult>[];

  ListeningChallengeRound? get current =>
      currentIndex < rounds.length ? rounds[currentIndex] : null;
  bool get isComplete => currentIndex >= rounds.length;
  int get total => rounds.length;
  int get correctCount =>
      results.where((ListeningChallengeResult r) => r.correct).length;

  void recordAndAdvance(ListeningChallengeResult result) {
    results.add(result);
    currentIndex++;
  }
}
