// Typing Recall (MVP_021, DEC-030): Decko's third registered practice mode —
// a productive-input challenge (prompt → type the reading or meaning). Pure
// models; framework-light.

/// What the learner is asked to type.
enum TypingTargetKind { reading, meaning }

/// Where a round came from (motivation only — never review state).
enum TypingRecallSource { manualCard, deckPractice }

/// How an answer was judged.
enum TypingResultCategory { correct, almost, incorrect }

/// One typing round: a prompt + the expected answer (with accepted variants)
/// and what to reveal afterwards.
class TypingRecallRound {
  const TypingRecallRound({
    required this.itemId,
    required this.deckId,
    required this.targetKind,
    required this.promptText,
    required this.answer,
    required this.accepted,
    required this.source,
    this.explanation,
  });

  final String itemId;
  final String deckId;
  final TypingTargetKind targetKind;

  /// The expression shown to the learner (e.g. 食べる).
  final String promptText;

  /// The canonical expected answer (shown on reveal).
  final String answer;

  /// All answers accepted as correct (canonical + alternatives).
  final List<String> accepted;

  final TypingRecallSource source;

  /// Extra context revealed after answering (e.g. the meaning for a reading
  /// round, or the reading for a meaning round).
  final String? explanation;

  /// A short instruction for the input ("Type the reading" / "Type the meaning").
  String get instruction =>
      targetKind == TypingTargetKind.reading ? 'Type the reading' : 'Type the meaning';
}

/// The recorded result of one round.
class TypingRecallResult {
  const TypingRecallResult({required this.roundIndex, required this.category});
  final int roundIndex;
  final TypingResultCategory category;

  bool get isCorrect => category == TypingResultCategory.correct;
  bool get isAlmost => category == TypingResultCategory.almost;
}

/// Mutable session state across a set of rounds.
class TypingRecallSession {
  TypingRecallSession(this.rounds);

  final List<TypingRecallRound> rounds;
  final List<TypingRecallResult> results = <TypingRecallResult>[];
  int currentIndex = 0;

  TypingRecallRound? get current =>
      currentIndex < rounds.length ? rounds[currentIndex] : null;

  int get total => rounds.length;
  bool get isComplete => currentIndex >= rounds.length;

  int get correctCount =>
      results.where((TypingRecallResult r) => r.isCorrect).length;
  int get almostCount =>
      results.where((TypingRecallResult r) => r.isAlmost).length;

  /// Records the [category] for the current round and advances.
  void recordAndAdvance(TypingResultCategory category) {
    results.add(TypingRecallResult(roundIndex: currentIndex, category: category));
    currentIndex++;
  }
}
