import 'practice_mode.dart';

/// The recorded outcome of a completed practice activity.
class PracticeOutcome {
  /// Creates an immutable practice outcome.
  const PracticeOutcome({
    required this.modeId,
    required this.itemId,
    required this.deckId,
    required this.startedAt,
    required this.completedAt,
    required this.correctCount,
    required this.incorrectCount,
    required this.xpAwarded,
  });

  /// Practice mode that produced this outcome.
  final PracticeModeId modeId;

  /// Source learning item or card id, when known.
  final String? itemId;

  /// Source deck id, when known.
  final String? deckId;

  /// Time when the practice activity started.
  final DateTime startedAt;

  /// Time when the practice activity completed.
  final DateTime completedAt;

  /// Number of correct answers or actions.
  final int correctCount;

  /// Number of incorrect answers or actions.
  final int incorrectCount;

  /// XP awarded for this outcome.
  final int xpAwarded;

  /// Total counted answers or actions.
  int get total => correctCount + incorrectCount;

  /// Whether every counted answer or action was correct.
  bool get allCorrect => incorrectCount == 0 && correctCount > 0;

  /// Converts this outcome to a JSON-compatible map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'modeId': modeId.storageKey,
    'itemId': itemId,
    'deckId': deckId,
    'startedAt': startedAt.toIso8601String(),
    'completedAt': completedAt.toIso8601String(),
    'correctCount': correctCount,
    'incorrectCount': incorrectCount,
    'xpAwarded': xpAwarded,
  };

  /// Creates a practice outcome from a JSON-compatible map.
  factory PracticeOutcome.fromJson(Map<String, dynamic> json) {
    final PracticeModeId modeId =
        practiceModeIdFromKey(json['modeId'] as String? ?? '') ??
        PracticeModeId.bunburuSentenceBuilder;

    return PracticeOutcome(
      modeId: modeId,
      itemId: json['itemId'] as String?,
      deckId: json['deckId'] as String?,
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: DateTime.parse(json['completedAt'] as String),
      correctCount: json['correctCount'] as int,
      incorrectCount: json['incorrectCount'] as int,
      xpAwarded: json['xpAwarded'] as int,
    );
  }
}
