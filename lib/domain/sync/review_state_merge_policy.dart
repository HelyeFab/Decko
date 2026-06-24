// Conflict-safe merge for cross-device review state (MVP_022, DEC-031).
//
// The cardinal rule (project-wide): never silently regress or reset a card's
// review/FSRS progress. So cloud state is applied only when it is unambiguously
// the same-or-more-advanced continuation of the local card. Pure + deterministic.

import 'syncable_review_state.dart';

enum MergeDecision {
  /// Keep the local state; cloud has nothing newer/safe to offer.
  keepLocal,

  /// Adopt the cloud state — it's a strictly safe, newer continuation.
  useCloud,

  /// Ambiguous (cloud newer but would regress progress): keep local, surface it.
  conflict,
}

class ReviewStateMergePolicy {
  const ReviewStateMergePolicy();

  /// Decides what to do for one card given the [local] state (null if the card
  /// somehow has no local state) and a matching [cloud] state.
  MergeDecision decide(SyncableReviewState? local, SyncableReviewState cloud) {
    // A matching local card always has a local state after import; if not, the
    // cloud progress is safe to adopt.
    if (local == null) return MergeDecision.useCloud;

    // Cloud has no real progress → never overwrite local with a blank.
    if (!cloud.hasProgress) return MergeDecision.keepLocal;

    // Local is a fresh/untouched card but cloud has progress → adopt it.
    if (!local.hasProgress) return MergeDecision.useCloud;

    // Both have progress — prefer the more recent review, but never regress.
    final DateTime? lr = local.lastReviewedAt;
    final DateTime? cr = cloud.lastReviewedAt;

    if (lr != null && cr != null) {
      if (cr.isAfter(lr)) {
        return _monotonic(local, cloud)
            ? MergeDecision.useCloud
            : MergeDecision.conflict;
      }
      // Local is the same age or newer → keep it.
      return MergeDecision.keepLocal;
    }

    // Missing review timestamps: fall back to rep count as the advancement
    // signal, still guarding against regression.
    if (cloud.reps > local.reps && _monotonic(local, cloud)) {
      return MergeDecision.useCloud;
    }
    return MergeDecision.keepLocal;
  }

  /// Cloud must not move reps or lapses backwards relative to local.
  bool _monotonic(SyncableReviewState local, SyncableReviewState cloud) =>
      cloud.reps >= local.reps && cloud.lapses >= local.lapses;
}
