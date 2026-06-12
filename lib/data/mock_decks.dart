import '../domain/deck.dart';
import '../domain/learning_item.dart';

/// Hard-coded demo content for the local-first MVP flow.
///
/// This stands in for the import + persistence layers that arrive in later
/// MVPs. Nothing here is real user data — it exists so the deck library, deck
/// detail and review screens have believable local decks to render.
abstract final class MockDecks {
  /// Every demo deck, in the order the library should show them.
  static const List<Deck> all = <Deck>[_japaneseStarter, _travelPhrases];

  /// The deck used by the "Explore demo deck" shortcut and review preview.
  static const Deck demoJapanese = _japaneseStarter;

  /// The single card shown when the review screen has no deck context.
  static LearningItem get sampleCard => _japaneseStarter.items.first;

  static const Deck _japaneseStarter = Deck(
    id: 'demo-japanese',
    name: 'Japanese Starter Deck',
    description: 'A tiny sample deck for testing Decko’s review experience.',
    items: <LearningItem>[
      LearningItem(
        id: 'jp-taberu',
        front: '食[た]べる',
        back: 'to eat',
        example: '毎日[まいにち]ご飯[はん]を食[た]べます。\nI eat a meal every day.',
        tags: <String>['verb', 'food'],
      ),
      LearningItem(
        id: 'jp-nomu',
        front: '飲[の]む',
        back: 'to drink',
        example: '水[みず]を飲[の]みます。\nI drink water.',
        tags: <String>['verb', 'food'],
      ),
      LearningItem(
        id: 'jp-hon',
        front: '本[ほん]',
        back: 'book',
        example: '本[ほん]を読[よ]みます。\nI read a book.',
        tags: <String>['noun'],
      ),
    ],
  );

  static const Deck _travelPhrases = Deck(
    id: 'demo-travel',
    name: 'Travel Phrases',
    description: 'Handy expressions for your first trip to Japan.',
    items: <LearningItem>[
      LearningItem(
        id: 'jp-konnichiwa',
        front: 'こんにちは',
        reading: 'konnichiwa',
        back: 'hello / good afternoon',
        example: 'こんにちは、元気ですか？',
        tags: <String>['greeting'],
      ),
      LearningItem(
        id: 'jp-arigatou',
        front: 'ありがとう',
        reading: 'arigatou',
        back: 'thank you',
        example: '本当にありがとう。',
        tags: <String>['greeting'],
      ),
    ],
  );
}
