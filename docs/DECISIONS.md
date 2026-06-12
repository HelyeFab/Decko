# Decko Decisions

This file records durable product and architecture decisions.

## DEC-001: Decko is local-first for Iteration 1

Date: 2026-06-12
Status: Accepted

### Context

Iteration 1 needs to prove the core review experience before accounts, cloud sync, payments, or collaboration are introduced.

### Decision

Decko Iteration 1 is local-first. Imported decks, review state, themes, XP, streaks, and session history should work without login.

### Consequences

- Faster MVP implementation.
- Easier offline support.
- No backend required for first agent work.
- Future sync must be designed as an additional layer, not baked into the UI.

### Alternatives considered

- Start with cloud sync: rejected because it would delay the core product experience.

## DEC-002: Imported deck formats are adapters, not the internal model

Date: 2026-06-12
Status: Accepted

### Context

Decko should support imported decks, including Anki-style decks long term, but imported structures should not control the app architecture.

### Decision

Use import adapters that translate external files into Decko domain objects: Deck, LearningItem, ReviewCard, and ReviewEvent.

### Consequences

- JSON/CSV fixtures can unblock early development.
- APKG support can arrive later without rewriting the app.
- The rest of the app stays independent from external deck internals.

### Alternatives considered

- Make APKG the internal model: rejected because it would make UI, scheduling, and gamification dependent on an external format.

## DEC-003: Scheduling must be FSRS-ready from the start

Date: 2026-06-12
Status: Accepted

### Context

Decko wants modern spaced repetition without forcing the first build to implement full FSRS immediately.

### Decision

The data model should include FSRS-compatible fields, but the first implementation may use a SimpleSchedulerService behind the same SchedulerService interface.

### Consequences

- The MVP can be tested quickly.
- FSRS can replace the simple scheduler later.
- Review UI remains independent from scheduling details.

### Alternatives considered

- Implement full FSRS before any UI: rejected because it would delay product validation.

## DEC-004: App themes and card themes are separate systems

Date: 2026-06-12
Status: Accepted

### Context

Decko differentiates itself through beautiful UI and card experiences.

### Decision

Separate AppThemeConfig from CardThemeConfig.

### Consequences

- Users can mix app shell themes with flashcard presentation themes.
- Card rendering can evolve independently from app navigation.
- UI consistency must be tracked in `docs/UI_REGISTRY.md`.

## DEC-005: Decko must never silently reset imported progress

Date: 2026-06-12
Status: Accepted

### Context

Existing deck users may have hundreds or thousands of cards with meaningful study history. For them, the deck content is not enough: due dates, intervals, review state, suspended cards, reps, lapses, and review history are part of the value of the deck.

If Decko imports a deck and treats all cards as new without warning, the user loses trust immediately.

### Decision

Decko must distinguish between clean import and progress-aware import.

When scheduling/progress information exists, the user must be offered a clear choice:

- keep existing progress
- start fresh

When scheduling/progress information does not exist or cannot be read, Decko must clearly warn that the deck will be imported as new.

### Consequences

- APKG import must eventually inspect both content and scheduling/progress data.
- Import UX must include a pre-confirmation summary.
- The domain model needs an import progress mapping layer, not only card content import.
- A progress-aware import MVP is required before Decko can confidently target serious existing Anki users.

### Alternatives considered

- Always start imported decks as new: rejected because it would make Decko unsafe for users with existing progress.
- Try to perfectly reproduce external scheduler state immediately: rejected for early MVPs because preserving practical progress is more important than exact scheduler compatibility.

### Related docs

- `docs/import-progress.md`
