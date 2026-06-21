# MVP_016 — Bunburu Sentence Builder Mode

## Status

Planned.

This MVP begins Decko's first larger Decko-native game mode after the core Anki-parity/import/progress foundations have been stabilised.

## Mission

Integrate the existing Bunburu sentence-unscramble game concept into Decko as a beautiful sentence-builder practice mode powered by Decko's imported sentence fields.

Bunburu must support **two valid entry paths**:

1. **Scheduler-routable mode** — Decko may choose Bunburu as a review/practice presentation for a due card when the card has a usable sentence.
2. **Manual per-card mode** — the learner may trigger Bunburu from an individual card whenever that card has a usable sentence, as an extra way to test knowledge of that sentence.

This is not just a separate deck-level toy mode. It must be available close to the card when the card contains sentence material.

## Product principle

Decko's promise remains:

```text
Import your deck. Study it beautifully.
```

Bunburu expands this into:

```text
Import your deck. Review it normally. When a card has a sentence, rebuild it beautifully.
```

Normal review correctness is sacred. Bunburu may become one of Decko's review presentations, but it must only do so through the existing review-mode/scheduler boundaries. It must never silently reset imported progress or mutate FSRS state outside the intended review-answer flow.

## Context

Decko now has:

- progress-aware Anki import
- modern `.apkg` / `.anki21b` / zstd support
- lossless note preservation
- note-type-aware card mapping
- media import and rendering
- FSRS scheduling
- true daily limits
- sibling burying
- progress polish and light achievements

The separate `HelyeFab/bunburu` repo already contains a working Flutter sentence-builder game concept with sentence tokens, hearts, scoring, practice/daily structures, furigana-aware tokens, haptics, audio, and local motivation loops.

This MVP should adapt the useful ideas into Decko's architecture rather than blindly copying the whole app.

## Primary user stories

### Scheduled review story

As a learner, I want Decko to be able to show a sentence-builder challenge for a suitable due card, so that some reviews test whether I can reconstruct the sentence rather than only recognise the answer.

### Manual card story

As a learner, I want to tap a sentence-builder action on any card that contains a sentence, so that I can immediately test my knowledge of that exact sentence as an additional practice mode.

### Deck practice story

As a learner, I want to practise sentence building from a suitable deck, so that I can work through multiple sentences outside the normal review queue when I feel like extra practice.

## Scope

### 1. Card-level sentence-builder affordance

Add a manual Bunburu/Sentence Builder action on a card when the current card has a usable sentence.

Possible surfaces:

- review card overflow/action row
- revealed answer area
- deck detail sample card row
- future card detail screen, if present

The action must only appear when sentence-capable content exists, or it must gracefully explain why the mode is unavailable.

This is a primary requirement, not a nice-to-have.

### 2. Scheduler-routable sentence-builder presentation

Prepare Bunburu so it can be used as a review presentation mode for suitable cards.

The MVP does not need a sophisticated mode-selection policy, but the architecture must not prevent this path.

Acceptable first version:

- expose a clean `ReviewCardMode` / review-presentation seam for sentence-builder-capable cards, or
- create a clearly isolated adapter that can turn a due `LearningItem` into a `SentenceBuilderRound`, or
- add a setting/flag allowing sentence-builder review mode for cards with sentences, if this fits the existing option system.

The important boundary:

```text
Scheduler decides which card is due.
Review presentation decides whether that card is shown as standard flashcard, listening, reading, production, or sentence builder.
```

If Bunburu is used as the actual review presentation for a due card, then the final user outcome may flow through the normal review-answer path. It must not create a second, hidden scheduler path.

### 3. Deck-level practice entry point

Add an optional Bunburu/Sentence Builder entry point from appropriate imported decks.

Suggested surfaces:

- deck detail screen
- practice/actions section
- future Practice tab if one exists

This deck-level mode should be extra practice and motivational. It should not consume daily review limits unless explicitly wired through normal review mode in a future MVP.

### 4. Sentence-capable item extraction

Create a pure mapping layer that derives sentence-builder rounds from Decko data.

Candidate source fields from imported Anki decks:

- `Sentence`
- `Sentence-Kana`
- `Sentence-English`
- `Sentence Audio`
- related reading/furigana data when available

The mapper should prefer preserved imported source fields when available, and fall back gracefully when only mapped `LearningItem` content exists.

Do not require every deck or every card to support Bunburu.

### 5. Sentence builder domain model

Introduce Decko-native domain models rather than importing Bunburu's old app state wholesale.

Suggested concepts:

- `SentenceBuilderRound`
- `SentenceBuilderToken`
- `SentenceBuilderSession`
- `SentenceBuilderResult`
- `SentenceBuilderSource`

Each round should include:

- source deck id
- source learning item/card id when available
- source note/template identity when available
- sentence text
- token list
- optional translation
- optional sentence audio reference
- optional furigana/readings
- stable source identity for analytics/progress/review attribution
- source context: manual card practice, deck practice, or review presentation

### 6. Basic gameplay loop

Implement a first Decko-native sentence-builder loop:

- show shuffled sentence tokens/cubes
- let the user build the sentence in slots
- check answer
- show correct sentence and translation on completion
- provide retry / next / finish flow depending on entry path

The first version may be simple. It does not need every feature from the standalone Bunburu app.

### 7. Result handling by entry path

Result handling must depend on how Bunburu was launched.

#### Manual per-card mode

Allowed:

- show success/failure feedback
- award motivational XP/practice credit if consistent with MVP_015
- unlock/advance achievements
- return to the same card/review state

Not allowed:

- mark the card reviewed
- change FSRS state
- consume daily review counters
- affect bury-sibling logic

#### Deck-level practice mode

Allowed:

- practice count
- XP-style motivational reward, if already consistent with Decko progress
- achievement hooks
- session completion celebration

Not allowed:

- changing FSRS due dates
- marking Anki review cards as reviewed
- mutating per-card review state
- consuming normal daily review counters
- overriding bury-sibling logic

#### Scheduler-routed review presentation

Allowed:

- use Bunburu as the way the due card is tested
- map the outcome to the normal review answer flow only after the user completes/grades the review
- preserve all existing review-state invariants

Required:

- no hidden duplicate review event
- no direct FSRS mutation from game widgets
- no bypassing `ReviewScheduler` / review-answer seam
- clear UX so the learner understands they are reviewing the card, not merely doing bonus practice

### 8. UX and design

This MVP must preserve Decko's design principle:

```text
Beautiful design is part of the product, not decoration.
```

Avoid stock/utilitarian Material UI. The game should feel playful, calm, tactile, and Decko-native.

Suggested UI elements:

- soft card/cube tokens
- clear drop/build area
- gentle feedback for correct/incorrect attempts
- optional sentence audio button
- completion reward panel consistent with MVP_015
- subtle card-level action: "Build sentence" / "Test this sentence"

### 9. Tests

Add tests for:

- sentence-capable content detection per card
- manual card-level action appears only when sentence exists
- sentence-to-token mapping
- graceful handling of cards/decks without sentence fields
- gameplay state transitions
- correct/incorrect answer checks
- manual card mode does not touch FSRS/review state
- deck practice mode does not touch FSRS/review state
- scheduler-routed review presentation, if implemented, goes through the normal review-answer seam
- route/entry point behaviour

## Out of scope

- No direct FSRS mutation from Bunburu widgets
- No hidden review-state writes outside the review-answer seam
- No due queue rewrite unless required only to expose a presentation-mode option safely
- No daily limit changes
- No sibling burying changes
- No Anki import changes unless a tiny field-access helper is genuinely required
- No full migration of the standalone Bunburu app as-is
- No online leaderboard
- No subscriptions/cloud sync
- No daily challenge system unless trivial and clearly isolated
- No replacing normal review globally with Bunburu

## Safety requirements

The following must remain true after MVP_016:

```text
Scheduler decides which cards are due.
Review presentation decides how a due card is tested.
Manual game modes provide extra practice without changing due state.
```

Bunburu must be optional. A learner who ignores it should have the same review schedule and imported progress as before.

Imported progress must never be reset or silently changed.

Manual Bunburu practice must not be confused with completing a scheduled review.

If Bunburu is used as a scheduled review presentation, it must complete through the normal review flow and preserve all existing review invariants.

## Architectural guidance

Prefer this flow for manual/deck practice:

```text
Imported Anki source / LearningItem
        ↓
SentenceBuilderMapper
        ↓
SentenceBuilderRound
        ↓
SentenceBuilderSession
        ↓
Motivational progress event only
```

Prefer this flow for scheduled review presentation:

```text
Due LearningItem from ReviewScheduler
        ↓
Review presentation selection
        ↓
SentenceBuilderRound
        ↓
SentenceBuilder interaction
        ↓
Normal review answer / grade seam
        ↓
ReviewScheduler write-back
```

Do not couple Bunburu directly to the Anki adapter, FSRS scheduler internals, or persistent review card state.

## Decisions to record

Add a decision record if implementation confirms the expected boundary:

```text
DEC-025: Bunburu/Sentence Builder can be used both as manual sentence practice and, where explicitly routed, as a review presentation for due cards. Manual practice reports motivational progress only and never mutates FSRS/review state. Scheduled Bunburu reviews must complete through the normal review-answer seam and must not bypass the ReviewScheduler.
```

## Acceptance criteria

MVP_016 is complete when:

- a sentence-builder action is available from an individual card when that card has a usable sentence
- Decko can derive a playable round from that card's sentence fields
- a deck-level sentence-builder practice entry point exists for suitable decks
- cards/decks without usable sentences degrade gracefully
- the game loop supports building/checking at least one sentence round
- manual card practice returns cleanly to the card/review context
- manual/deck practice produces Decko-style motivational results only
- if scheduler-routed Bunburu review is implemented in this MVP, it uses the normal review-answer seam
- FSRS/review state is untouched by manual/deck practice
- tests cover the safety boundary for all implemented entry paths
- docs/memory/roadmap are updated
- `flutter analyze` is clean
- the full test suite passes

## Recommended report format

When reporting completion, include:

- files added/changed
- how rounds are derived from Decko data
- where manual card-level Bunburu appears
- whether scheduler-routed Bunburu was implemented or only prepared architecturally
- what Bunburu features were included
- what Bunburu features were intentionally deferred
- proof that manual/deck practice did not touch FSRS/review state
- proof that any scheduled Bunburu path uses the normal review-answer seam
- test count and analyze result

## Likely follow-up MVPs

Possible next steps after this MVP:

- richer Bunburu modes: hearts, daily challenge, timed mode
- stronger scheduler policy for when to use sentence-builder presentation
- sentence audio and shadowing integration
- achievement expansion for game modes
- game-mode hub
- other Decko-native practice modes
