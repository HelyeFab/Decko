# MVP_025 — Match Mode / Vocabulary Pairing Game

## Status

Planned.

## Mission

Add Decko’s next lightweight practice mode: a fast, playful matching game that helps learners strengthen recognition links between expressions, readings, meanings, and other available card fields.

This MVP should make Decko feel more game-like and more distinct from a traditional flashcard app, while staying safely outside the FSRS scheduling path.

## Product promise

> Import your deck. Study it beautifully.

Match Mode supports this by turning imported deck content into a low-friction practice game without requiring users to edit or rebuild their decks.

## Context

Decko already has:

- a `PracticeModeRegistry`
- `PracticeLauncher`
- `PracticeOutcome`
- an activity ledger
- practice XP
- Bunburu sentence builder
- Listening Challenge
- Typing Recall
- review-state sync for matching decks
- sync/account status UX
- first-run onboarding and import guidance

MVP_025 should build on the existing practice-mode architecture rather than creating a one-off game path.

## Core principle

```text
Review state answers: when is this card due?
Practice modes answer: what else can I do with this card or deck?
```

Match Mode is manual/deck practice only in this MVP.

It may record activity and award practice XP.

It must not mutate:

- FSRS state
- `ReviewCardState`
- due dates
- review queues
- daily review counters
- sibling burying state
- imported Anki progress
- synced review state

## Scope

### 1. Register a new practice mode

Add a new registered practice mode:

```text
match_mode
```

Suggested label:

```text
Match Mode
```

Suggested subtitle:

```text
Pair expressions, readings, and meanings.
```

The mode should be discoverable through the same registry flow as Bunburu, Listening Challenge, and Typing Recall.

### 2. Round builder

Create a pure builder that derives match rounds from available `LearningItem` data.

Suggested domain object names:

```text
MatchModeRound
MatchModePair
MatchModePrompt
MatchModeBuilder
```

A round should contain a small set of pairs, for example 4–6 pairs.

Each pair should have:

```text
left
right
pairType
sourceItemId
```

### 3. Initial pair types

Keep MVP_025 focused.

Include these pair types first:

```text
expression_to_meaning
expression_to_reading
reading_to_meaning
```

Only create a pair when both sides are present and clean enough.

Do not create broken pairs with empty strings, duplicate visible values, or unusable placeholder values.

### 4. Deck-level practice

Add deck-level Match Mode sessions.

From Deck Detail or Practice Hub, users should be able to start Match Mode when the deck has enough eligible cards.

If there are not enough eligible cards, show a friendly empty state explaining why.

Example:

```text
This deck does not have enough cards with both expressions and meanings yet.
Try importing a deck with named fields such as Expression, Reading, and Meaning.
```

### 5. Manual per-card practice, if useful

If the registry architecture supports it cleanly, expose Match Mode from a single card only when enough neighbouring eligible cards exist to form a small matching board.

If this makes the MVP too complex, it may be deferred. Deck-level practice is the primary scope.

### 6. Gameplay UX

The user should see two sets of tiles and match them.

Minimum interaction:

```text
Tap one tile from the left.
Tap its matching tile from the right.
Decko marks the pair correct or incorrect.
Continue until the board is cleared.
```

The experience should feel like Decko:

- playful
- calm
- readable
- mobile-first
- not stock Material UI
- accessible enough to use with clear visual states

Suggested states:

```text
idle
selected
correct
incorrect
completed
```

### 7. Completion and progress

On completion, record a `PracticeOutcome` / activity event.

Track at least:

```text
mode: match_mode
source: manual_practice
correctPairs
incorrectAttempts
totalPairs
completedAt
xpAwarded
```

Practice XP may be awarded, but it must remain motivational only.

No review scheduling state may be changed.

### 8. Matching fairness

Avoid unfair boards.

The builder should avoid:

- duplicate left values
- duplicate right values
- identical left/right strings when this makes the answer obvious or confusing
- blank values
- very long sentence content unless intentionally supported later

Prefer vocabulary-style fields in this MVP.

Sentence-level matching can be added later.

### 9. Accessibility and usability

Match Mode should be usable without relying only on colour.

Include:

- text labels or icons for correct/incorrect feedback
- enough contrast
- readable tap targets
- graceful small-screen layout
- no time pressure in this MVP

Timer/scored arcade variants are explicitly deferred.

## Out of scope

Do not implement in MVP_025:

- scheduled review presentation
- FSRS grading through Match Mode
- timed arcade mode
- leaderboards
- multiplayer
- cloud sync changes
- new Firebase paths
- deck/media/content sync
- sentence builder changes
- tokenizer changes
- import parser changes
- fuzzy matching or typing logic
- audio matching, unless it is trivial and does not expand scope

## Architecture expectations

The implementation should follow the existing practice-mode boundaries:

```text
PracticeModeRegistry
  -> discovers Match Mode availability

PracticeLauncher
  -> launches Match Mode screen

MatchModeBuilder
  -> builds pure match rounds from deck/card data

MatchModeScreen
  -> handles gameplay UI

PracticeOutcome / ActivityLedger
  -> records motivational progress
```

The game must not reach directly into scheduler internals.

## Data safety requirements

MVP_025 must preserve all existing safety guarantees:

- no imported progress reset
- no review-state mutation
- no FSRS mutation
- no due-date mutation
- no card ID changes
- no deck fingerprint changes
- no sync DTO changes unless purely adding metadata-free activity mode identifiers already supported by the ledger

## UX copy guidance

Use wording like:

```text
Match pairs from your deck.
```

```text
Pair Japanese expressions with their meanings or readings.
```

```text
This is extra practice. It will not change when your review cards are due.
```

Avoid wording that implies Match Mode replaces review scheduling.

## Tests expected

Add pure tests for:

- eligible pair extraction
- duplicate filtering
- empty/insufficient deck state
- correct pair recognition
- incorrect attempt tracking
- completion outcome
- XP/activity event creation
- no review-state mutation

Add widget tests for:

- deck-level launch availability
- unavailable deck message
- tile selection
- correct match feedback
- incorrect match feedback
- completion screen

Run:

```bash
flutter test
flutter analyze
```

Both should pass.

## Documentation updates

Update as appropriate:

```text
docs/DECISIONS.md
docs/ROADMAP.md
docs/UI_REGISTRY.md
memory.md
```

Only update `.agent/skills/` if this MVP changes reusable agent behaviour.

## Suggested decision record

```text
DEC-034 — Match Mode Is Manual Practice, Not Review Scheduling
```

Summary:

```text
Match Mode is a registered practice mode that can award practice XP and activity events, but it does not mutate FSRS, due dates, review counters, sibling burying, imported progress, or synced review state.
```

## Acceptance criteria

MVP_025 is complete when:

- `match_mode` is registered in the practice-mode registry
- eligible decks show Match Mode as an available practice option
- ineligible decks show a friendly explanation
- Match Mode can build fair expression/meaning/reading pair boards
- users can complete a matching session
- correct and incorrect attempts are tracked
- completion records motivational practice activity/XP
- no review/FSRS/scheduler state is mutated
- docs/memory/decision records are updated
- tests pass
- `flutter analyze` passes

## Next likely MVP

```text
MVP_026 — Import Recovery, Duplicate Import & Re-import Polish
```

This returns the roadmap to shippability and safety after the user-facing Match Mode addition.
