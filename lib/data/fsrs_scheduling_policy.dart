import 'dart:math' as math;

import '../domain/review_card_state.dart';
import '../domain/review_rating.dart';
import '../domain/review_scheduling_policy.dart';

/// An FSRS-5 (Free Spaced Repetition Scheduler) scheduling policy.
///
/// This is a faithful implementation of the FSRS-5 memory model with the
/// published **default** parameters — it is FSRS-*style*, not a per-user trained
/// optimiser, and it does not model intra-day (same-day) learning steps. Each
/// grade updates the card's stability/difficulty and schedules it for the day
/// it would next drop to the target retention (DEC-013).
///
/// Pure: the clock is injected, so it is fully unit-testable. The UI depends
/// only on [ReviewSchedulingPolicy]; none of this maths lives in widgets.
class FsrsSchedulingPolicy extends ReviewSchedulingPolicy {
  const FsrsSchedulingPolicy({this.requestRetention = 0.9});

  /// Target probability of recall when a card next comes due.
  final double requestRetention;

  static const String version = 'fsrs-5';

  // FSRS-5 default weights (w0..w18).
  static const List<double> _w = <double>[
    0.40255, 1.18385, 3.17300, 15.69105, 7.19490, 0.53450, 1.46040, 0.00460,
    1.54575, 0.11920, 1.01925, 1.93950, 0.11000, 0.29605, 2.26980, 0.23150,
    2.89980, 0.51655, 0.66210,
  ];

  static const double _decay = -0.5;
  static double get _factor => math.pow(0.9, 1 / _decay) - 1; // ≈ 0.2345679

  @override
  ReviewCardState next(
      ReviewCardState state, ReviewRating rating, DateTime now) {
    final int g = _grade(rating); // 1..4
    final bool isAgain = g == 1;

    final double stability;
    final double difficulty;

    if (state.stability != null) {
      // A card already scheduled by FSRS.
      stability = _advanceStability(
        prevS: state.stability!,
        prevD: state.difficulty ?? _initialDifficulty(3),
        elapsedDays: _elapsedDays(state.lastReviewedAt, now),
        g: g,
      );
      difficulty = _nextDifficulty(
          state.difficulty ?? _initialDifficulty(3), g);
    } else if (state.reps > 0) {
      // Imported/legacy reviewed card: seed S/D from existing state, then apply
      // this review — never reset to new (DEC-005).
      final double seedS = _seedStability(state.intervalDays);
      final double seedD = _seedDifficulty(state.easeFactor, state.lapses);
      stability = _advanceStability(
        prevS: seedS,
        prevD: seedD,
        elapsedDays: _elapsedDays(state.lastReviewedAt, now),
        g: g,
      );
      difficulty = _nextDifficulty(seedD, g);
    } else {
      // Brand-new card's first review.
      stability = _initialStability(g);
      difficulty = _initialDifficulty(g);
    }

    final int interval = _intervalFor(stability);
    return state.copyWith(
      queueState:
          isAgain ? ReviewQueueState.relearning : ReviewQueueState.review,
      reps: state.reps + 1,
      lapses: isAgain ? state.lapses + 1 : state.lapses,
      intervalDays: interval,
      dueAt: now.add(Duration(days: interval)),
      lastReviewedAt: now,
      stability: stability,
      difficulty: difficulty,
      schedulerVersion: version,
    );
  }

  // --- FSRS maths ------------------------------------------------------------

  int _grade(ReviewRating r) => switch (r) {
        ReviewRating.again => 1,
        ReviewRating.hard => 2,
        ReviewRating.good => 3,
        ReviewRating.easy => 4,
      };

  double _initialStability(int g) => math.max(_w[g - 1], 0.1);

  double _initialDifficulty(int g) =>
      _clampD(_w[4] - math.exp(_w[5] * (g - 1)) + 1);

  double _nextDifficulty(double d, int g) {
    final double delta = -_w[6] * (g - 3);
    final double damped = d + delta * (10 - d) / 9; // linear damping
    final double reverted = _w[7] * _initialDifficulty(4) + (1 - _w[7]) * damped;
    return _clampD(reverted);
  }

  double _retrievability(double elapsedDays, double stability) =>
      math.pow(1 + _factor * elapsedDays / stability, _decay).toDouble();

  double _advanceStability({
    required double prevS,
    required double prevD,
    required double elapsedDays,
    required int g,
  }) {
    final double r = _retrievability(elapsedDays, prevS);
    if (g == 1) {
      // Forgotten: stability shrinks (never grows on a lapse).
      final double sForget = _w[11] *
          math.pow(prevD, -_w[12]) *
          (math.pow(prevS + 1, _w[13]) - 1) *
          math.exp((1 - r) * _w[14]);
      return math.min(sForget, prevS);
    }
    final double hardPenalty = g == 2 ? _w[15] : 1.0;
    final double easyBonus = g == 4 ? _w[16] : 1.0;
    return prevS *
        (1 +
            math.exp(_w[8]) *
                (11 - prevD) *
                math.pow(prevS, -_w[9]) *
                (math.exp((1 - r) * _w[10]) - 1) *
                hardPenalty *
                easyBonus);
  }

  /// Days until the card drops to [requestRetention]; at least 1.
  int _intervalFor(double stability) {
    final double days =
        stability / _factor * (math.pow(requestRetention, 1 / _decay) - 1);
    return math.max(1, days.round());
  }

  double _elapsedDays(DateTime? last, DateTime now) {
    if (last == null) return 0;
    final int seconds = now.difference(last).inSeconds;
    return seconds <= 0 ? 0 : seconds / 86400.0;
  }

  // --- conservative seeds for imported/legacy cards --------------------------

  double _seedStability(int intervalDays) =>
      intervalDays > 0 ? intervalDays.toDouble() : 1.0;

  double _seedDifficulty(double? easeFactor, int lapses) {
    final double base = easeFactor != null ? (11.0 - easeFactor * 2.0) : 5.0;
    return _clampD(base + lapses * 0.2);
  }

  double _clampD(double d) => d.clamp(1.0, 10.0);
}
