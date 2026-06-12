import 'package:flutter/foundation.dart';

import '../data/imported_deck_storage.dart';
import '../domain/deck.dart';
import '../domain/repositories/deck_repository.dart';

/// The app's live deck source: demo decks plus any imported decks.
///
/// Implements [DeckRepository] so screens/router resolve decks synchronously
/// from an in-memory cache, while [load]/[addImportedDeck] keep that cache in
/// sync with persistent storage. Being a [ChangeNotifier], the library can
/// rebuild when imported decks arrive or finish hydrating (DEC-010).
class DeckStore extends ChangeNotifier implements DeckRepository {
  DeckStore({
    required DeckRepository demoDecks,
    ImportedDeckStorage storage = const ImportedDeckStorage(),
  })  : _demo = demoDecks,
        // ignore: prefer_initializing_formals
        _storage = storage;

  final DeckRepository _demo;
  final ImportedDeckStorage _storage;

  List<Deck> _imported = const <Deck>[];

  /// Hydrates imported decks from storage. Safe to call once at startup.
  Future<void> load() async {
    _imported = await _storage.load();
    notifyListeners();
  }

  /// Imported decks first, then the demo decks.
  @override
  List<Deck> getDecks() => <Deck>[..._imported, ..._demo.getDecks()];

  @override
  Deck? getDeckById(String id) {
    for (final Deck deck in getDecks()) {
      if (deck.id == id) return deck;
    }
    return null;
  }

  /// Adds a freshly imported deck, persists the imported set, and notifies.
  Future<void> addImportedDeck(Deck deck) async {
    _imported = <Deck>[deck, ..._imported];
    await _storage.save(_imported);
    notifyListeners();
  }

  /// Removes an imported deck. Notifies immediately (so the list updates before
  /// persistence) and then saves. Demo decks are not removable.
  Future<void> removeImportedDeck(String id) async {
    _imported =
        _imported.where((Deck d) => d.id != id).toList(growable: false);
    notifyListeners();
    await _storage.save(_imported);
  }
}
