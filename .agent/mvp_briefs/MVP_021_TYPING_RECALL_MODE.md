# MVP_021 — Typing Recall Mode

## Status

Planned.

## Context

Decko now has the foundations for serious practice modes:

- Anki-compatible import with progress preservation.
- FSRS-based review scheduling.
- Media import and rendering.
- Note-type-aware cards.
- Bunburu sentence builder mode.
- Listening Challenge mode.
- PracticeModeRegistry / PracticeLauncher / PracticeOutcome.
- Activity ledger, XP, streaks, heatmap, and Firebase sync foundations.

MVP_021 should add Decko’s first text-input recall mode: a focused typing challenge where learners actively produce an answer rather than selecting or arranging one.

This is a higher-friction, higher-value mode than multiple choice. It must be forgiving enough for language learning, but strict enough to feel meaningful.

## Core mission

Add Decko’s third registered game/practice mode: a typing recall challenge that asks the learner to type the target expression, reading, meaning, or sentence from a prompt, using existing imported card fields and the PracticeModeRegistry.

## Product promise

Import your deck. Study it beautifully.

Typing Recall should feel like a natural Decko way to actively prove recall:

- See or hear a prompt.
- Type the answer.
- Get kind, useful feedback.
- Earn practice progress.

It must not feel like a harsh exam or a brittle string-comparison tool.

## Architectural boundary

Keep the existing learning-safety model:

```text
Scheduler decides which cards are due.
Review presentation decides how a due card is tested.
Manual practice modes provide extra practice without changing due state.
Practice outcomes may feed XP/activity, but must not silently rewrite FSRS state.
```

For MVP_021:

- Manual Typing Recall practice may award practice XP/activity events.
- Deck-level Typing Recall practice may award practice XP/activity events.
- Scheduled review presentation can be prepared as a capability, but only if it grades through `ReviewScheduler` and does not bypass the normal answer seam.
- If scheduled-review typing is too risky for this MVP, defer it explicitly.

## Scope

### 1. Register Typing Recall as a practice mode

Add a new registered practice mode:

```text
typing_recall
```

It should be discoverable through the existing `PracticeModeRegistry`.

Availability should be based on cards that have enough text fields to form a prompt and a target answer.

Initial eligible examples:

- Prompt meaning → type Japanese expression.
- Prompt English sentence → type Japanese sentence.
- Prompt Japanese expression → type reading.
- Prompt audio → type expression or sentence, if audio is available.

Do not require every variant in the first pass. Choose the safest useful subset and make the model extensible.

### 2. Add typing challenge domain models

Create pure domain models before UI:

```text
TypingRecallRound
TypingRecallPrompt
TypingRecallTarget
TypingRecallAnswerCheck
TypingRecallResult
```

The round should know:

- source deck id
- source learning item/card id
- prompt type
- prompt text/audio/image if available
- expected answer
- accepted alternatives if available
- display answer after submission
- explanation/meaning if available

### 3. Build a safe answer-checking layer

Do not use naive exact string comparison only.

MVP_021 should include a small but explicit answer-normalisation layer:

- trim whitespace
- normalise repeated spaces
- ignore common Japanese/English punctuation differences where safe
- optionally normalise full-width/half-width forms
- optionally ignore case for English meanings/readings where appropriate

For Japanese answers, be conservative:

- Do not pretend to solve all kana/kanji equivalence in this MVP.
- Do not silently accept unrelated answers.
- Show the expected answer clearly after submission.
- If fuzzy matching is added, keep it explainable and tested.

Recommended result categories:

```text
correct
almost
incorrect
```

`almost` is useful for punctuation/case/spacing/minor-normalisation differences, but should not be overused.

### 4. Manual per-card launch

On cards with a usable typing target, show a manual extra-practice action such as:

```text
Type this
```

or:

```text
Typing recall
```

This action should launch a single-card typing round.

Manual per-card practice must not mutate review state, due dates, FSRS state, daily review counters, or sibling burying state.

### 5. Deck-level practice launch

Typing Recall should appear in the Practice Hub / Deck Detail practice-mode list when a deck has enough eligible cards.

Deck-level practice should create a short session from eligible cards.

Suggested MVP limits:

- 5 to 10 rounds per session.
- Skip cards without suitable target fields.
- Show friendly empty/insufficient-content states.

### 6. Typing Recall screen

Create a Decko-native screen, not a stock form.

The screen should include:

- prompt area
- optional audio replay if audio is part of the prompt
- input field
- submit/check button
- feedback state
- expected answer reveal
- next button
- completion summary

Feedback should be encouraging:

- Correct: celebrate clearly.
- Almost: show what was different.
- Incorrect: show the correct answer without shame.

### 7. Practice outcomes and activity ledger

Manual/deck Typing Recall practice should produce `PracticeOutcome` / activity ledger events.

At minimum record:

- practice mode id: `typing_recall`
- deck id
- item/card id if available
- result: correct / almost / incorrect / completed
- XP awarded
- timestamp

XP should be motivational, not equivalent to FSRS grading.

Example:

- Correct: meaningful practice XP.
- Almost: smaller practice XP.
- Incorrect: low/no XP, but still record activity.

Do not inflate review counts.

### 8. Optional scheduled-review presentation seam

It is acceptable for MVP_021 to mark Typing Recall as not yet available for scheduled review presentation, if grading risk is high.

If scheduled-review presentation is enabled:

- It must launch through the review flow.
- It must submit grade through `ReviewScheduler`.
- It must not directly mutate `ReviewCardState`.
- It must provide a user-controlled grade or a very conservative mapping.

Do not silently map typo/error categories to FSRS grades unless the decision is explicit and documented.

### 9. Documentation and decisions

Add a decision record, likely:

```text
DEC-029 — Typing Recall Answer Checking and Review-State Boundary
```

Record:

- how answers are normalised
- what counts as correct/almost/incorrect
- why manual typing practice does not affect FSRS state
- whether scheduled review presentation is deferred or enabled

Update:

- `docs/ROADMAP.md`
- `docs/DECISIONS.md`
- `docs/UI_REGISTRY.md`
- `memory.md`

Update `.agent/skills/` only if this MVP changes how future agents should operate.

## Out of scope

Do not implement in MVP_021:

- Full fuzzy Japanese NLP matching.
- AI answer grading.
- Cloud conflict resolution changes.
- New auth/sync capabilities beyond using existing activity sync boundaries.
- New spaced-repetition algorithms.
- FSRS parameter changes.
- Due queue changes.
- Daily limit changes.
- Sibling burying changes.
- Large new game modes such as matching, kanji quest, or vocabulary quest.

## Acceptance criteria

MVP_021 is complete when:

- `typing_recall` is registered as a practice mode.
- Eligible cards/decks expose Typing Recall through the existing registry/discovery system.
- Manual per-card Typing Recall works for at least one robust prompt/target type.
- Deck-level Typing Recall works for a short session.
- Answer checking handles normalisation safely and predictably.
- Feedback states are clear and kind.
- Practice outcomes are recorded for activity/XP.
- Manual/deck practice does not mutate review state or FSRS state.
- Empty/insufficient-content states are friendly.
- Tests cover answer checking, availability rules, launch routing, outcome recording, and safety boundaries.
- `flutter analyze` is clean.

## Testing expectations

Add tests for:

- answer normalisation
- correct / almost / incorrect result classification
- availability for cards with suitable fields
- non-availability for unsuitable cards
- per-card launch
- deck-level session generation
- practice outcome creation
- no review-state mutation for manual/deck practice
- UI feedback states
- empty states

## Suggested next MVP

After MVP_021, likely next options:

```text
MVP_022 — Matching Game Mode
MVP_023 — Image / Meaning Recall Mode
MVP_024 — Kanji / Vocabulary Quest
```

Typing Recall gives Decko its first productive-input practice mode. Matching or image recall can then add faster, lighter game loops on top of the same practice-mode platform.
