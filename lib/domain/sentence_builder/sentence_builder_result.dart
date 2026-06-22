/// The recorded outcome for one sentence builder round.
class SentenceBuilderResult {
  const SentenceBuilderResult({
    required this.roundIndex,
    required this.correct,
    required this.attempts,
  });

  final int roundIndex;
  final bool correct;
  final int attempts;
}
