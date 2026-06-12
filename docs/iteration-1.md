# Decko Iteration 1 — Beautiful Imported Deck Review

## Iteration name

**I1: Beautiful Imported Deck Review**

## Product promise

Decko lets users bring an existing study deck into a modern, beautiful, gamified review experience.

The first version should feel like:

> Anki-compatible thinking, Quizlet-like playfulness, modern Flutter polish.

## Target user

The initial user is someone who already understands flashcards or already has decks, but feels that existing tools are visually cold, rigid, or unmotivating on mobile.

They want:

- Better card design.
- Better review feedback.
- More enjoyable study sessions.
- A sense of progression.
- A path to import existing material.

## MVP scope

### Must have

1. Onboarding screen explaining Decko.
2. Local-first deck library.
3. Import flow for a simple deck format.
4. Deck detail screen.
5. Review session screen.
6. Four review ratings: Again, Hard, Good, Easy.
7. FSRS-ready scheduling data model.
8. Basic scheduler service that can later be replaced with a full FSRS implementation.
9. Three app themes.
10. Three card themes.
11. XP and streak tracking.
12. Session completion summary.

### Should have

1. Multiple review modes:
   - Recognition
   - Production
   - Multiple choice
   - Type answer
   - Matching
2. Daily goal.
3. Weak-card rescue round.
4. Theme preview screen.
5. Local import examples for testing.

### Not in Iteration 1

1. Full AnkiWeb sync.
2. Account system.
3. Cloud sync.
4. Paid subscriptions.
5. Social sharing.
6. Full Anki template rendering compatibility.
7. Advanced media handling.
8. Complete APKG parser if this blocks the MVP.

## Import strategy

Decko should use a layered import design:

```text
DeckImportAdapter
  ├── JsonDeckImportAdapter
  ├── CsvDeckImportAdapter
  └── ApkgDeckImportAdapter
```

Iteration 1 can start with JSON and CSV while the APKG adapter is implemented behind the same interface.

## Scheduling strategy

Iteration 1 should design the model for FSRS even if the first scheduler is a simplified implementation.

Each review card should store:

- dueAt
- stability
- difficulty
- elapsedDays
- scheduledDays
- reps
- lapses
- state
- lastReviewAt

Each review event should store:

- reviewCardId
- rating
- reviewedAt
- elapsedDays
- previousDueAt
- nextDueAt
- durationMs

## First themes

### App themes

1. **Clean Light** — minimal, bright, calm.
2. **Focus Dark** — low-light, distraction-free.
3. **Soft Study** — friendly, rounded, pastel-inspired.

### Card themes

1. **Minimal** — large front text, clean reveal.
2. **Detailed** — front, back, hint, tags, notes.
3. **Game Card** — XP, challenge framing, animated feedback.

## First gamification features

- XP per reviewed card.
- Bonus XP for perfect sessions.
- Daily streak.
- Daily goal completion.
- Session result screen.
- Gentle achievement badges.

## First navigation map

```text
Splash / Onboarding
  ↓
Home / Deck Library
  ├── Import Deck
  ├── Deck Detail
  │     └── Review Session
  │           └── Session Summary
  ├── Themes
  └── Profile / Progress
```

## Definition of done

Iteration 1 is successful when a user can:

1. Open Decko.
2. Import a sample deck.
3. See the deck in the library.
4. Start a review session.
5. Review cards with Again/Hard/Good/Easy.
6. See a beautiful card UI.
7. Switch between app/card themes.
8. Complete a session and receive XP/streak feedback.
9. Reopen the app and see progress persisted locally.
