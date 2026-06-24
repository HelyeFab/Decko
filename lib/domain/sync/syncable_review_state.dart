// Cloud-safe representation of a card's review/FSRS state (MVP_022, DEC-031).
// Keeps the cloud DTO decoupled from the local persistence model. It carries
// only scheduling state — never card content. Framework-light.

import '../review_card_state.dart';

class SyncableReviewState {
  const SyncableReviewState({
    required this.itemId,
    required this.queueState,
    required this.reps,
    required this.lapses,
    required this.intervalDays,
    required this.updatedAt,
    this.dueAt,
    this.easeFactor,
    this.stability,
    this.difficulty,
    this.lastReviewedAt,
    this.sourceSystem = 'anki',
    this.schedulerVersion,
    this.deviceId,
  });

  final String itemId;
  final ReviewQueueState queueState;
  final int reps;
  final int lapses;
  final int intervalDays;
  final DateTime updatedAt;
  final DateTime? dueAt;
  final double? easeFactor;
  final double? stability;
  final double? difficulty;
  final DateTime? lastReviewedAt;
  final String sourceSystem;
  final String? schedulerVersion;
  final String? deviceId;

  /// True if this state represents real review progress (vs an untouched card).
  bool get hasProgress =>
      reps > 0 ||
      lastReviewedAt != null ||
      (queueState != ReviewQueueState.newCard &&
          queueState != ReviewQueueState.suspended);

  factory SyncableReviewState.fromReviewCardState(
    ReviewCardState s, {
    required DateTime updatedAt,
    String? deviceId,
  }) =>
      SyncableReviewState(
        itemId: s.itemId,
        queueState: s.queueState,
        reps: s.reps,
        lapses: s.lapses,
        intervalDays: s.intervalDays,
        updatedAt: updatedAt,
        dueAt: s.dueAt,
        easeFactor: s.easeFactor,
        stability: s.stability,
        difficulty: s.difficulty,
        lastReviewedAt: s.lastReviewedAt,
        sourceSystem: s.sourceSystem,
        schedulerVersion: s.schedulerVersion,
        deviceId: deviceId,
      );

  ReviewCardState toReviewCardState(String deckId) => ReviewCardState(
        deckId: deckId,
        itemId: itemId,
        queueState: queueState,
        dueAt: dueAt,
        reps: reps,
        lapses: lapses,
        intervalDays: intervalDays,
        easeFactor: easeFactor,
        lastReviewedAt: lastReviewedAt,
        sourceSystem: sourceSystem,
        stability: stability,
        difficulty: difficulty,
        schedulerVersion: schedulerVersion,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'itemId': itemId,
        'queueState': queueState.name,
        'reps': reps,
        'lapses': lapses,
        'intervalDays': intervalDays,
        'updatedAt': updatedAt.toIso8601String(),
        if (dueAt != null) 'dueAt': dueAt!.toIso8601String(),
        if (easeFactor != null) 'easeFactor': easeFactor,
        if (stability != null) 'stability': stability,
        if (difficulty != null) 'difficulty': difficulty,
        if (lastReviewedAt != null)
          'lastReviewedAt': lastReviewedAt!.toIso8601String(),
        'sourceSystem': sourceSystem,
        if (schedulerVersion != null) 'schedulerVersion': schedulerVersion,
        if (deviceId != null) 'deviceId': deviceId,
      };

  static SyncableReviewState fromJson(Map<String, dynamic> m) =>
      SyncableReviewState(
        itemId: m['itemId'] as String,
        queueState: ReviewQueueState.values.firstWhere(
          (ReviewQueueState q) => q.name == m['queueState'],
          orElse: () => ReviewQueueState.newCard,
        ),
        reps: m['reps'] as int? ?? 0,
        lapses: m['lapses'] as int? ?? 0,
        intervalDays: m['intervalDays'] as int? ?? 0,
        updatedAt: DateTime.parse(m['updatedAt'] as String),
        dueAt: _date(m['dueAt']),
        easeFactor: (m['easeFactor'] as num?)?.toDouble(),
        stability: (m['stability'] as num?)?.toDouble(),
        difficulty: (m['difficulty'] as num?)?.toDouble(),
        lastReviewedAt: _date(m['lastReviewedAt']),
        sourceSystem: m['sourceSystem'] as String? ?? 'anki',
        schedulerVersion: m['schedulerVersion'] as String?,
        deviceId: m['deviceId'] as String?,
      );

  static DateTime? _date(Object? v) =>
      v == null ? null : DateTime.parse(v as String);
}
