# MVP_016 — Bunburu Sentence Builder Mode

## Status

Planned.

This MVP begins Decko's first larger Decko-native game mode after the core Anki-parity/import/progress foundations have been stabilised.

## Mission

Integrate the existing Bunburu sentence-unscramble game concept into Decko as a beautiful, optional sentence-builder practice mode powered by Decko's imported sentence fields.

Bunburu must feel like a natural Decko learning mode, not a separate toy bolted onto the app.

## Product principle

Decko's promise remains:

```text
Import your deck. Study it beautifully.
```

Bunburu expands this into:

```text
Import your deck. Review it normally. Then play with the sentences you are learning.
```

Normal review correctness is sacred. Bunburu may reward motivation and practice, but it must not compromise FSRS scheduling, imported progress, daily review limits, burying, or Anki-parity behaviour.

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

## Primary user story

As a learner, I want to take Japanese sentences from an imported deck and practise rebuilding them in the correct order, so that I can strengthen comprehension and production without affecting my normal spaced-repetition schedule.

## Scope

### 1. Game-mode entry point

Add an optional Bunburu/Sentence Builder entry point from appropriate imported decks.

Suggested surfaces:

- deck detail screen
- possibly Progress or future Practice tab if one exists

The entry point should only appear or should gracefully explain itself when sentence-capable content exists.

### 2. Sentence-capable item extraction

Create a pure mapping layer that derives sentence-builder rounds from Decko data.

Candidate source fields from imported Anki decks:

- `Sentence`
- `Sentence-Kana`
- `Sentence-English`
- `Sentence Audio`
- related reading/furigana data when available

The mapper should prefer preserved imported source fields when available, and fall back gracefully when only mapped `LearningItem` content exists.

Do not require every deck to support Bunburu.

### 3. Sentence builder domain model

Introduce Decko-native domain models rather than importing Bunburu's old app state wholesale.

Suggested concepts:

- `SentenceBuilderRound`
- `SentenceBuilderToken`
- `SentenceBuilderSession`
- `SentenceBuilderResult`

Each round should include:

- source deck id
- source learning item/card id when available
- sentence text
- token list
- optional translation
- optional sentence audio reference
- optional furigana/readings
- stable source identity for analytics/progress attribution

### 4. Basic gameplay loop

Implement a first Decko-native sentence-builder loop:

- show shuffled sentence tokens/cubes
- let the user build the sentence in slots
- check answer
- show correct sentence and translation on completion
- provide next round / finish flow

The first version may be simple. It does not need every feature from the standalone Bunburu app.

### 5. Motivation layer integration

Bunburu should report practice outcomes into Decko's existing progress/motivation layer only.

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

### 6. UX and design

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

### 7. Tests

Add tests for:

- sentence-capable content detection
- sentence-to-token mapping
- graceful handling of decks without sentence fields
- gameplay state transitions
- correct/incorrect answer checks
- result reporting does not touch FSRS/review state
- route/entry point behaviour

## Out of scope

- No FSRS changes
- No review scheduler changes
- No due queue changes
- No daily limit changes
- No sibling burying changes
- No Anki import changes unless a tiny field-access helper is genuinely required
- No full migration of the standalone Bunburu app as-is
- No online leaderboard
- No subscriptions/cloud sync
- No daily challenge system unless trivial and clearly isolated
- No replacing normal review with Bunburu

## Safety requirements

The following must remain true after MVP_016:

```text
Scheduler decides when.
Review mode decides how.
Game modes motivate and practise, but do not decide due state.
```

Bunburu must be optional. A learner who ignores it should have the same review schedule and imported progress as before.

Imported progress must never be reset or silently changed.

## Architectural guidance

Prefer this flow:

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

Do not couple Bunburu directly to the Anki adapter, FSRS scheduler, or persistent review card state.

## Decisions to record

Add a decision record if implementation confirms the expected boundary:

```text
DEC-025: Bunburu/Sentence Builder is an optional practice mode that consumes Decko learning content and reports motivational progress only. It does not mutate FSRS scheduling, due queues, imported progress, daily review counters, or sibling burying.
```

## Acceptance criteria

MVP_016 is complete when:

- a sentence-builder game mode is accessible from a suitable deck
- Decko can derive playable rounds from imported sentence fields
- decks without usable sentences degrade gracefully
- the game loop supports building/checking at least one sentence round
- completion produces a Decko-style motivational result
- progress/achievement integration is motivational only
- FSRS/review state is untouched by game play
- tests cover the safety boundary
- docs/memory/roadmap are updated
- `flutter analyze` is clean
- the full test suite passes

## Recommended report format

When reporting completion, include:

- files added/changed
- how rounds are derived from Decko data
- what Bunburu features were included
- what Bunburu features were intentionally deferred
- proof that FSRS/review state was not touched
- test count and analyze result

## Likely follow-up MVPs

Possible next steps after this MVP:

- richer Bunburu modes: hearts, daily challenge, timed mode
- sentence audio and shadowing integration
- achievement expansion for game modes
- game-mode hub
- other Decko-native practice modes
