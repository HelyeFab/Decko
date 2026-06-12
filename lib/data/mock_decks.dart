import '../domain/deck.dart';
import '../domain/learning_item.dart';

/// Hard-coded demo content for the MVP_001 product shell.
///
/// This stands in for the import + persistence layers that arrive in later
/// MVPs. Nothing here is real user data — it exists only to populate the
/// preview screens so the product direction is visible.
abstract final class MockDecks {
  /// A small Japanese vocabulary deck used by the "Explore demo deck" flow.
  static const Deck demoJapanese = Deck(
    id: 'demo-japanese',
    name: 'Everyday Japanese',
    description: 'A taste of Decko — common words to get you started.',
    items: <LearningItem>[
      LearningItem(
        id: 'jp-taberu',
        front: '食べる',
        reading: 'たべる',
        back: 'to eat',
        example: '毎日ご飯を食べます。',
        tags: <String>['verb', 'food'],
      ),
      LearningItem(
        id: 'jp-nomu',
        front: '飲む',
        reading: 'のむ',
        back: 'to drink',
        example: '水を飲みます。',
        tags: <String>['verb', 'food'],
      ),
      LearningItem(
        id: 'jp-hon',
        front: '本',
        reading: 'ほん',
        back: 'book',
        example: '本を読みます。',
        tags: <String>['noun'],
      ),
    ],
  );

  /// The single card shown on the review preview screen.
  static LearningItem get sampleCard => demoJapanese.items.first;
}
