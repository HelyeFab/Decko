import '../domain/deck.dart';
import '../domain/repositories/deck_repository.dart';
import 'mock_decks.dart';

/// A [DeckRepository] backed by the in-memory [MockDecks] demo data.
///
/// No persistence (MVP_002 non-goal): the decks live in code and reset every
/// launch. This is the seam where a real local database will plug in later.
class MockDeckRepository implements DeckRepository {
  const MockDeckRepository();

  @override
  List<Deck> getDecks() => MockDecks.all;

  @override
  Deck? getDeckById(String id) {
    for (final Deck deck in MockDecks.all) {
      if (deck.id == id) return deck;
    }
    return null;
  }
}
