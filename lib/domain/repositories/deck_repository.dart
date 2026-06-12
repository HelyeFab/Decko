import '../deck.dart';

/// Reads local decks for the app.
///
/// Kept deliberately small and framework-light so the UI depends on this
/// interface rather than a concrete source. The MVP is backed by mock data;
/// later MVPs can swap in a persistent implementation (Drift/Isar/Hive) without
/// touching the screens — see DEC-002 (adapters) and the roadmap's persistence
/// stage.
abstract class DeckRepository {
  /// All decks available locally, in display order. Empty when there are none.
  List<Deck> getDecks();

  /// The deck with [id], or null if it does not exist.
  Deck? getDeckById(String id);
}
