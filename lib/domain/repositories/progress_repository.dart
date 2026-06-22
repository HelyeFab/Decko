import '../practice/practice_outcome.dart';
import '../progress_snapshot.dart';
import '../review_session_result.dart';

/// Loads and updates the learner's local [ProgressSnapshot].
///
/// Async so storage can be swapped later. Implementations own the clock used
/// when recording (inject a fixed one in tests for determinism).
abstract class ProgressRepository {
  /// The current snapshot, or [ProgressSnapshot.empty] if nothing is stored.
  Future<ProgressSnapshot> getSnapshot();

  /// Folds a completed session into the stored snapshot and persists it.
  Future<void> recordSessionResult(ReviewSessionResult result);

  /// Folds a practice [outcome] into the snapshot — motivational only (practice
  /// XP + count). Never touches review state, streak, or counters (MVP_017).
  Future<void> recordPracticeOutcome(PracticeOutcome outcome);

  /// Clears stored progress. Useful for tests/debug.
  Future<void> resetProgress();
}
