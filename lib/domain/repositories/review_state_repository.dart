import '../review_card_state.dart';

/// Persists per-card [ReviewCardState]. Async so the storage backend can be
/// swapped (e.g. for a database) without touching the UI or scheduler.
abstract class ReviewStateRepository {
  /// All stored states for a deck (empty if none have been saved yet).
  Future<List<ReviewCardState>> getStatesForDeck(String deckId);

  /// The state for one card, or null if not stored.
  Future<ReviewCardState?> getState(String deckId, String itemId);

  /// Upserts a single card's state.
  Future<void> saveState(ReviewCardState state);

  /// Upserts many states (used to initialise an imported deck or flush a
  /// session). All states are expected to share a deckId.
  Future<void> saveStates(List<ReviewCardState> states);

  /// Clears all stored state for a deck.
  Future<void> resetDeckStates(String deckId);
}
