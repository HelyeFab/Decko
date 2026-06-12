# Decko Coding Agent Brief

## Role

You are the implementation agent for Decko, a Flutter flashcard app focused on imported decks, beautiful review experiences, FSRS-ready scheduling, themes, and gamification.

Your job is to build the app carefully, in small verifiable steps, without collapsing domain logic into UI widgets.

## Product goal

Build a first iteration where a user can:

1. Open the app.
2. Import a simple deck.
3. See the deck in a deck library.
4. Start a review session.
5. Review cards using Again, Hard, Good, and Easy.
6. See progress, XP, and streak feedback.
7. Switch app themes and card themes.

## Current priority

Start with a Flutter scaffold and local-first architecture.

Do not start with cloud sync, account systems, subscriptions, or AnkiWeb integration.

## Implementation phases

### Phase 0 — Flutter scaffold

Create the Flutter project structure and confirm the app runs.

Recommended packages:

- flutter_riverpod
- go_router
- uuid
- intl
- file_picker
- path_provider

For persistence, choose one:

- Drift for structured relational storage, or
- Isar for object persistence.

If unsure, start with an in-memory repository plus repository interfaces, then add persistence after the domain is stable.

### Phase 1 — Domain models

Create domain models for:

- Deck
- LearningItem
- ReviewCard
- ReviewEvent
- ReviewRating
- ReviewMode
- ReviewState
- AppThemeConfig
- CardThemeConfig
- UserProgress

### Phase 2 — Import MVP

Implement a JSON deck import adapter first.

Example JSON shape:

```json
{
  "title": "Sample Deck",
  "description": "A small sample deck for Decko.",
  "items": [
    {
      "front": "食べる",
      "back": "to eat",
      "hint": "verb",
      "tags": ["japanese", "verb"]
    }
  ]
}
```

The importer should produce Decko domain objects, not Anki-specific objects.

### Phase 3 — Deck library UI

Build screens:

- Home / Deck Library
- Deck Detail
- Import Deck
- Empty State

### Phase 4 — Review session

Build a beautiful review session with:

- Card front
- Reveal answer
- Again / Hard / Good / Easy buttons
- Session progress
- Animated feedback
- Session summary

### Phase 5 — Scheduler service

Create a scheduler interface.

Implement SimpleSchedulerService first:

- Again: +10 minutes
- Hard: +1 day
- Good: +3 days
- Easy: +7 days

Store FSRS-compatible fields even if the first implementation is simple.

### Phase 6 — Themes

Implement:

App themes:

- Clean Light
- Focus Dark
- Soft Study

Card themes:

- Minimal
- Detailed
- Game Card

Theme selection should be persisted locally.

### Phase 7 — Gamification

Add:

- XP per review
- Perfect session bonus
- Daily streak
- Daily goal
- Session summary

Gamification should be derived from ReviewEvent data.

## Non-goals for this iteration

Do not implement:

- AnkiWeb sync
- User accounts
- Cloud sync
- Payments
- Full APKG parser if it slows the app scaffold
- Advanced Anki HTML/CSS template compatibility
- Social features

## Architecture rules

1. Keep UI widgets simple.
2. Keep scheduling in scheduling services.
3. Keep XP/streak logic in gamification services.
4. Keep import logic in import adapters.
5. Do not couple APKG parsing to the core domain.
6. Design for replacement: SimpleSchedulerService should be replaceable by FsrsSchedulerService.
7. Write clear comments for all scheduling assumptions.

## Acceptance checklist

The first working version is acceptable when:

- The app launches.
- A sample JSON deck can be imported.
- Imported cards appear in a deck detail screen.
- A review session can be completed.
- Ratings update due dates.
- XP and streak are shown after a session.
- The user can switch between themes.
- The code structure matches the architecture documents.
