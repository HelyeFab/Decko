# Decko Architecture Foundation

## Architecture principle

Decko should separate the learning content from the way the learner practises it.

That means the app should not treat a flashcard as only:

```text
front → back
```

Instead, Decko should model:

```text
LearningItem → generated ReviewCards → ReviewEvents → Progress
```

## Core domain concepts

### Deck

A deck is a user-visible collection of learning items.

Example fields:

```dart
class Deck {
  final String id;
  final String title;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DeckSource source;
}
```

### LearningItem

A learning item is the canonical piece of content.

Examples:

- A vocabulary item.
- A definition.
- A sentence.
- A kanji.
- A concept.
- A grammar point.

Example fields:

```dart
class LearningItem {
  final String id;
  final String deckId;
  final String front;
  final String back;
  final String? hint;
  final String? notes;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### ReviewCard

A review card is a particular way of testing a learning item.

Example modes:

- recognition
- production
- listening
- shadowing
- cloze
- conjugation
- kanjiReading
- multipleChoice
- typeAnswer
- matchPair

Example fields:

```dart
enum ReviewMode {
  recognition,
  production,
  listening,
  shadowing,
  cloze,
  conjugation,
  kanjiReading,
  multipleChoice,
  typeAnswer,
  matchPair,
}

class ReviewCard {
  final String id;
  final String learningItemId;
  final ReviewMode mode;
  final DateTime dueAt;
  final double stability;
  final double difficulty;
  final int elapsedDays;
  final int scheduledDays;
  final int reps;
  final int lapses;
  final ReviewState state;
  final DateTime? lastReviewAt;
}
```

### ReviewEvent

A review event records what happened during a review.

```dart
enum ReviewRating {
  again,
  hard,
  good,
  easy,
}

class ReviewEvent {
  final String id;
  final String reviewCardId;
  final ReviewRating rating;
  final DateTime reviewedAt;
  final DateTime previousDueAt;
  final DateTime nextDueAt;
  final int durationMs;
}
```

### ThemeConfig

Decko has two levels of theme configuration.

```text
AppThemeConfig  → whole app shell
CardThemeConfig → individual flashcard presentation
```

This allows combinations such as:

```text
App theme: Focus Dark
Card theme: Minimal
```

or:

```text
App theme: Soft Study
Card theme: Game Card
```

## Suggested feature folders

```text
lib/
  main.dart

  app/
    decko_app.dart
    router.dart
    theme/
      app_theme_config.dart
      card_theme_config.dart
      theme_controller.dart

  core/
    ids.dart
    result.dart
    clock.dart

  features/
    onboarding/
    deck_library/
    import/
    review/
    gamification/
    themes/
    progress/

  data/
    local/
    repositories/

  domain/
    deck/
    review/
    scheduling/
    gamification/
```

## Import architecture

Deck import should be adapter-based.

```dart
abstract class DeckImportAdapter {
  bool canImport(ImportedFile file);
  Future<ImportedDeck> importDeck(ImportedFile file);
}
```

Initial adapters:

- JsonDeckImportAdapter
- CsvDeckImportAdapter
- ApkgDeckImportAdapter

The APKG importer should not leak Anki-specific structures into the rest of the app. It should translate imported data into Decko domain objects.

## Scheduler architecture

The review UI should depend on a scheduler interface, not on a concrete scheduler.

```dart
abstract class SchedulerService {
  ReviewScheduleResult schedule({
    required ReviewCard card,
    required ReviewRating rating,
    required DateTime reviewedAt,
  });
}
```

Initial implementations:

- SimpleSchedulerService for early MVP testing.
- FsrsSchedulerService for production scheduling.

## Gamification architecture

Gamification should be derived from review events, not manually scattered through the UI.

```text
ReviewEvent → XpService → StreakService → AchievementsService
```

This keeps the logic testable and prevents the review screen from becoming too complex.

## Key technical rule

The review screen should not directly calculate scheduling, XP, streaks, or achievements.

It should call services and render the result.
