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

## DEC-006: GoRouter now, Riverpod deferred until there is real state

Date: 2026-06-12
Status: Accepted

### Context

`docs/CODING_STANDARDS.md` names Riverpod + GoRouter as the preferred stack, but the MVP_001 brief lists "complex state management" and "large dependencies" as non-goals. MVP_001 is a static product shell with no real domain state.

### Decision

Add `go_router` for navigation now (it matches the standards and the roadmap's "basic routing"). Defer `flutter_riverpod` until a later MVP introduces genuine state (review sessions, persistence). For MVP_001, the only mutable UI state — the selected app theme — is driven by a lightweight `ThemeController` (`ValueNotifier`) exposed via an `InheritedWidget`.

### Consequences

- Smaller dependency surface for the first build.
- Navigation is structured correctly from day one.
- Riverpod can be introduced in MVP_004+ without reworking routing.
- The theme controller is a deliberate stop-gap; it will likely become a Riverpod provider later.

### Alternatives considered

- Add Riverpod now: rejected as premature for a shell with no real state.
- Zero dependencies (Navigator only): rejected because it diverges from the documented stack and would need rework as routing grows.

## DEC-007: Decks are read through a DeckRepository, resolved by id in routes

Date: 2026-06-12
Status: Accepted

### Context

MVP_002 makes the library render real local decks and adds a deck detail screen. The UI needs a source of decks and a way to carry the selected deck into detail/review, without persistence or Riverpod yet.

### Decision

Introduce a small `DeckRepository` interface (`getDecks()`, `getDeckById(id)`) with a `MockDeckRepository` backed by `MockDecks`. The repository is provided through the existing app-scope `InheritedWidget` (`DeckoApp.repositoryOf`), the same mechanism used for the theme controller. Deck context flows through the URL: routes are `/deck/:deckId` and `/deck/:deckId/review`, and route builders resolve the `Deck` from the repository by id (falling back to a "deck not found" screen).

### Consequences

- Screens depend on an interface, not concrete data — a persistent repo can replace the mock later with no UI change.
- Navigation is URL-driven and link/deep-link friendly; no `Deck` objects passed via router `extra`.
- The repository is injectable, so tests can supply an empty repo to exercise the empty state.
- A non-existent deck id is handled explicitly rather than crashing.

### Alternatives considered

- Pass the `Deck` object via GoRouter `extra`: rejected because it breaks on refresh/deep-link and couples navigation to in-memory objects.
- Constructor-inject the repository into each screen: rejected because GoRouter builders make that awkward; the existing scope pattern is simpler and consistent.

## DEC-008: The review scheduler seam is `ReviewScheduler`

Date: 2026-06-12
Status: Accepted

### Context

DEC-003 said scheduling must be FSRS-ready behind an interface and tentatively named it "SchedulerService". MVP_003 implements the first real review-session layer and needs to fix that name and shape.

### Decision

The seam is `ReviewScheduler` (`lib/domain/repositories/review_scheduler.dart`) with `createSession` / `answerCurrentCard` / `completeSession`. MVP_003 ships `SimpleReviewScheduler` (in-order queue, tally counts, no intervals/due dates/persistence). Implementations are pure: transitions return a new immutable `ReviewSession`, and `answeredAt` is passed in rather than read from the clock, so sessions are deterministic and unit-testable. The review screen depends only on this interface and holds session state in local `State` (no Riverpod). The scheduler is an injectable constructor parameter (defaulting to `const SimpleReviewScheduler()`).

### Consequences

- This is the concrete realisation of the DEC-003 seam; a future `FsrsReviewScheduler` implements the same interface with no review-UI change.
- Session logic is testable in pure Dart (no widget pumping).
- Naming supersedes the tentative "SchedulerService" wording in DEC-003.

### Alternatives considered

- Keep the "SchedulerService" name: rejected — `ReviewScheduler` reads better alongside `ReviewSession`/`ReviewAnswer` and matches the MVP_003 brief.
- Put scheduling state in a Riverpod provider now: rejected as premature; local `State` is enough for a single-screen session.

## DEC-009: Local persistence uses shared_preferences behind repository seams

Date: 2026-06-12
Status: Accepted

### Context

MVP_004 needs to remember a little state across launches — the selected app theme and a small progress snapshot (XP, streak, today's count, last session result). Full deck persistence and a real database are deferred to roadmap I1.6.

### Decision

Use `shared_preferences` as the storage backend, hidden behind two small async repository interfaces: `SettingsRepository` and `ProgressRepository` (in `lib/domain/repositories/`), with `SharedPrefs*` implementations in `lib/data/`. The progress snapshot is stored as a single JSON blob. The XP/streak/"today" maths lives in a pure `ProgressSnapshot.recordingSession(result, now)` method (time injected), so it is deterministic and unit-testable; the repository just loads → applies → saves. Repositories are injectable via `DeckoApp` (defaulting to the `SharedPrefs*` impls) and exposed through the app scope, matching the DEC-007 pattern.

### Consequences

- Theme choice and progress survive restart with no DB or migrations.
- UI depends on interfaces, so a Drift/Isar/Hive backend can replace the `SharedPrefs*` impls later without touching screens (the I1.6 step).
- Progress logic is fully unit-testable without storage or Flutter.
- `shared_preferences` is the 2nd dependency (after go_router); justified by being the lightest fit for tiny key/value + a small snapshot.

### Alternatives considered

- Drift/Isar/Hive now: rejected as over-engineered for theme + one snapshot; reserved for full deck/review-history persistence (I1.6).
- Store progress as separate prefs keys: rejected — a single JSON blob keeps the snapshot atomic and easy to evolve.
- Compute progress inside the repository: rejected — keeping the maths in a pure domain method makes it testable and storage-agnostic.
