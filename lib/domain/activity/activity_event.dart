// The activity ledger (MVP_019, DEC-028): a durable local history of what the
// learner did — the source of truth for XP / streaks / heatmap / achievements,
// kept entirely separate from review/FSRS scheduling state. Framework-light.

import '../practice/practice_mode.dart';
import '../practice/practice_outcome.dart';
import '../review_session_result.dart';

/// Where an activity came from.
enum ActivitySource { review, manualPractice, deckPractice, scheduledPractice }

/// How an activity ended.
enum ActivityOutcome { completed, correct, incorrect, abandoned }

/// Stable mode identifiers used in the ledger (align with practice mode keys).
class ActivityModeIds {
  const ActivityModeIds._();
  static const String standardReview = 'standard_review';
  static const String bunburuSentenceBuilder = 'bunburu_sentence_builder';
  static const String listeningChallenge = 'listening_challenge';
}

/// One recorded study activity. Immutable.
class ActivityEvent {
  const ActivityEvent({
    required this.id,
    required this.occurredAt,
    required this.source,
    required this.modeId,
    required this.outcome,
    required this.xpAwarded,
    this.deckId,
    this.learningItemId,
    this.duration,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final DateTime occurredAt;
  final ActivitySource source;
  final String modeId;
  final String? deckId;
  final String? learningItemId;
  final ActivityOutcome outcome;
  final int xpAwarded;
  final Duration? duration;
  final Map<String, Object?> metadata;

  /// Whether this is the migrated legacy-progress baseline (excluded from the
  /// heatmap/streak, included in XP totals).
  bool get isLegacy => metadata['legacy'] == true;

  /// True for review-derived activity (vs practice).
  bool get isReview =>
      source == ActivitySource.review ||
      source == ActivitySource.scheduledPractice;

  /// A completed standard-review session event (XP = cards × 10).
  factory ActivityEvent.review(
    ReviewSessionResult result, {
    required DateTime occurredAt,
    required int xpAwarded,
  }) =>
      ActivityEvent(
        id: 'ev-${occurredAt.microsecondsSinceEpoch}-review',
        occurredAt: occurredAt,
        source: ActivitySource.review,
        modeId: ActivityModeIds.standardReview,
        deckId: result.deckId,
        outcome: ActivityOutcome.completed,
        xpAwarded: xpAwarded,
        metadata: <String, Object?>{
          'reviewedCards': result.totalCards,
          'again': result.againCount,
          'hard': result.hardCount,
          'good': result.goodCount,
          'easy': result.easyCount,
        },
      );

  /// A completed practice-mode event (Bunburu / Listening / …).
  factory ActivityEvent.practice(PracticeOutcome o) => ActivityEvent(
        id: 'ev-${o.completedAt.microsecondsSinceEpoch}-${o.modeId.storageKey}',
        occurredAt: o.completedAt,
        source: o.itemId != null
            ? ActivitySource.manualPractice
            : ActivitySource.deckPractice,
        modeId: o.modeId.storageKey,
        deckId: o.deckId,
        learningItemId: o.itemId,
        outcome:
            o.allCorrect ? ActivityOutcome.correct : ActivityOutcome.completed,
        xpAwarded: o.xpAwarded,
        duration: o.completedAt.difference(o.startedAt),
        metadata: <String, Object?>{
          'correct': o.correctCount,
          'total': o.total,
        },
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'occurredAt': occurredAt.toIso8601String(),
        'source': source.name,
        'modeId': modeId,
        if (deckId != null) 'deckId': deckId,
        if (learningItemId != null) 'learningItemId': learningItemId,
        'outcome': outcome.name,
        'xpAwarded': xpAwarded,
        if (duration != null) 'durationMs': duration!.inMilliseconds,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  static ActivityEvent fromJson(Map<String, dynamic> m) => ActivityEvent(
        id: m['id'] as String,
        occurredAt: DateTime.parse(m['occurredAt'] as String),
        source: _enumByName(ActivitySource.values, m['source'],
            ActivitySource.review),
        modeId: m['modeId'] as String? ?? ActivityModeIds.standardReview,
        deckId: m['deckId'] as String?,
        learningItemId: m['learningItemId'] as String?,
        outcome: _enumByName(
            ActivityOutcome.values, m['outcome'], ActivityOutcome.completed),
        xpAwarded: m['xpAwarded'] as int? ?? 0,
        duration: m['durationMs'] == null
            ? null
            : Duration(milliseconds: m['durationMs'] as int),
        metadata: (m['metadata'] as Map?)?.cast<String, Object?>() ??
            const <String, Object?>{},
      );
}

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final T v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}
