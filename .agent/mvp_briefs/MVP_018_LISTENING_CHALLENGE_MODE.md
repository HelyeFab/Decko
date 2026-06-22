# MVP_018 — Listening Challenge Mode

## Status

Proposed.

## Mission

Add Decko’s second registered game mode: a listening recognition challenge that uses imported audio fields to test whether the learner can connect sound to meaning, sentence, or card identity.

This MVP should prove that the MVP_017 `PracticeModeRegistry` can support a second real mode beyond Bunburu, while preserving the review-state safety boundaries established in DEC-026.

## Product intent

Decko should start to feel like a language-learning app, not only a prettier Anki reader.

Listening Challenge should be useful, fast, and confidence-building:

- hear a word or sentence
- choose the correct answer from four options
- get immediate feedback
- earn light motivational progress when used as manual practice
- optionally use the same interaction as a scheduled review presentation later

The first version should be deliberately modest. Do not start with typing, speech recognition, fuzzy matching, or transcription scoring.

## Core principle

```text
Scheduler decides which cards are due.
Review presentation decides how a due card is tested.
Manual practice modes provide extra practice without changing due state.
Practice outcomes may feed motivation/progress, but must not silently rewrite FSRS state.
```

Listening Challenge may exist in three contexts:

1. **Manual per-card practice** — available from an individual card when audio exists.
2. **Deck-level practice** — available from the Practice Hub / Deck Detail when enough cards in the deck have audio.
3. **Scheduler-routable review presentation** — optional and opt-in; if used during scheduled review, grading must go through the normal `ReviewScheduler` seam.

## Existing architecture to build on

Use the MVP_017 platform:

- `PracticeMode`
- `PracticeModeId`
- `PracticeModeRegistry`
- `PracticeOutcome`
- `PracticeLauncher`
- Practice Hub
- Deck Detail practice-mode discovery
- Review-card manual mode discovery
- Review-presentation mode discovery

Use the existing imported card/media foundations:

- imported word audio
- imported sentence audio
- media repository / media references
- note-type-aware card mapping
- `LearningItem.id = anki-card-<cardId>` safety seam
- progress XP / achievement layer from MVP_015

## In scope

### 1. Register a new practice mode

Add a new registered practice mode:

```text
listening_challenge
```

The mode should appear only when the relevant item/deck has usable audio.

Minimum availability rules:

- card-level available if the card has word audio or sentence audio
- deck-level available if the deck has at least a small number of playable audio cards
- review-presentation available only for due cards that have usable audio

### 2. Listening challenge domain model

Create small, pure domain models for a listening round.

Suggested concepts:

```text
ListeningChallengeRound
ListeningChallengePrompt
ListeningChallengeChoice
ListeningChallengeResult
ListeningChallengeSource
```

A round should know:

- source learning item id
- audio reference to play
- prompt type: word audio or sentence audio
- correct answer
- distractor choices
- whether the answer target is meaning, sentence, or card identity

Keep the first implementation simple and deterministic enough to test.

### 3. First challenge type: audio → 4 choices

The MVP interaction should be:

```text
Play audio → choose the correct answer from four choices.
```

Preferred first answer targets:

- word audio → choose meaning
- sentence audio → choose sentence meaning or matching sentence

Do not include typing yet.

### 4. Choice generation

Generate four choices:

- one correct answer
- three plausible distractors from the same deck when possible
- fall back gracefully if there are not enough suitable distractors

The implementation must avoid duplicate choices.

If the deck cannot produce enough choices, the mode should not be offered or should show a friendly unavailable state.

### 5. Listening Challenge screen

Build a Decko-styled screen for the mode.

Must include:

- clear mode title
- play/replay audio button
- four answer choices
- selected-answer feedback
- correct / incorrect state
- continue / next action
- completion summary for deck-level practice
- friendly empty/unavailable state

Design must follow the Decko principle: no stock/utilitarian Material UI.

Use existing Decko components/patterns where possible.

### 6. Launch paths

Support all relevant MVP_017 launch paths:

- from Practice Hub / deck-level mode list
- from Deck Detail practice section
- from a review card’s extra practice actions when audio is present
- as a review presentation mode if the existing architecture supports it cleanly

Manual per-card and deck-level practice must record only practice outcomes, not scheduled review outcomes.

### 7. Outcome handling

Manual practice outcomes may feed:

- practice XP
- session reward chips
- future achievements
- practice history / lightweight counters if already present

They must not:

- mutate FSRS state
- mark scheduled review cards as reviewed
- alter due dates
- increment review-only counters
- bypass daily limits / sibling burying semantics

Scheduled review presentation outcomes, if implemented, must still grade through the normal `ReviewScheduler` seam.

### 8. Audio handling

Use existing audio/media playback mechanisms.

The screen should handle:

- replay
- missing audio
- unsupported media
- audio unavailable state

Do not implement a new media storage layer.

### 9. Tests

Add tests for:

- practice mode availability for cards with/without audio
- deck-level availability with enough/not enough audio cards
- choice generation includes one correct answer and no duplicates
- manual outcome records practice XP only
- scheduled review path, if included, uses `ReviewScheduler`
- missing audio state
- widget flow: play prompt → choose answer → feedback → next/complete

### 10. Docs and memory

Update:

- `docs/DECISIONS.md`
- `docs/ROADMAP.md`
- `docs/UI_REGISTRY.md` if new reusable UI patterns are added
- `memory.md`
- `.agent/memory.md` if used in this repo

Suggested decision record:

```text
DEC-027 — Listening Challenge as Registered Practice Mode
```

The decision should state that Listening Challenge is a registered practice mode powered by imported audio, with manual practice outcomes separated from scheduled review state.

## Out of scope

Do not implement in this MVP:

- typing/transcription recall
- speech recognition
- fuzzy matching
- pronunciation scoring
- AI-generated audio
- new TTS generation
- new media storage architecture
- spaced-repetition algorithm changes
- FSRS changes
- due queue changes
- daily counter changes
- bury sibling changes
- cloud sync
- leaderboards
- social features

Typing recall should be considered for a later MVP after Listening Challenge is stable.

## Acceptance criteria

MVP_018 is complete when:

- `listening_challenge` is registered in the practice-mode registry
- cards with usable audio expose Listening Challenge as an available mode
- decks with enough usable audio expose Listening Challenge in the Practice Hub / Deck Detail practice section
- the user can play audio and choose from four options
- feedback is immediate and clear
- deck-level practice supports multiple rounds and a completion state
- manual practice records only practice/motivation outcomes
- scheduled review presentation, if implemented, grades only through `ReviewScheduler`
- missing/insufficient audio produces a friendly unavailable state
- tests cover domain, registry, outcome boundary, and core widget flow
- `flutter analyze` is clean
- all tests pass

## Implementation notes for agents

- Start by orienting around MVP_017 implementation.
- Reuse the registry and launcher; do not create a parallel launch system.
- Keep game logic pure where possible.
- Prefer small, testable classes for round construction and choice generation.
- Keep the UI beautiful and Decko-branded.
- Do not change scheduler semantics to make the game easier to implement.
- Update `.agent/skills/` only if this MVP changes how future agents should operate.

## Recommended next MVP

After MVP_018, the likely next game mode is:

```text
MVP_019 — Typing Recall Mode
```

Typing should come after this because it needs fuzzy matching, kana/kanji tolerance, punctuation handling, and frustration controls.
