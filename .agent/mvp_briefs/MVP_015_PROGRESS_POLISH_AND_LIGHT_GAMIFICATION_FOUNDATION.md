# MVP_015 — Progress Polish & Light Gamification Foundation

## Status

Planned.

## Context

Decko has now completed the core Anki-parity and import-trust foundations needed before moving toward Decko-native motivational features:

- Progress-aware `.apkg` import
- Imported progress preservation
- Persistent per-card review state
- FSRS scheduling
- Media import and rendering
- Lossless Anki source preservation
- Note-type-aware card mapping
- Study options and deck overrides
- Advanced deck option profiles
- True daily counters and sibling burying
- Modern `.anki21b` / zstd import compatibility
- Import validation and diagnostics UX

Decko can now begin becoming more emotionally rewarding without compromising review correctness.

This MVP is intentionally **not** the Bunburu game mode yet. It prepares the motivational layer that future game modes can reuse.

## Product Promise

> Import your deck. Study it beautifully.

MVP_015 should make the second half feel more alive: study should feel satisfying, warm, and motivating, while remaining trustworthy.

## Mission

Make studying feel rewarding, beautiful, and motivating without changing scheduling correctness.

Decko should begin to feel like a modern learning product, not just a prettier Anki shell.

## Non-negotiable safety constraints

Do **not** change:

- FSRS scheduling math
- due queue ordering semantics
- daily counter semantics
- sibling burying semantics
- imported progress preservation
- Keep progress / Start fresh behaviour
- `LearningItem.id` stability
- Anki import parsing or package compatibility

Gamification must be a presentation and motivation layer on top of correct study state. It must not silently distort what is due or reset progress.

## Scope

### 1. Progress screen polish

Upgrade the current progress screen from a basic snapshot into a more useful and emotionally satisfying overview.

It should show, at minimum:

- today’s study progress
- cards reviewed today
- daily goal progress
- current streak
- XP / level progress, if still part of the model
- last session summary
- a friendly empty state for new users

The screen should feel calm, visual, and Decko-branded. Avoid stock/utilitarian Material UI.

### 2. Daily goal card

Introduce a simple daily goal surface.

Initial goal can be fixed or locally configurable only if it stays small in scope.

Suggested initial behaviour:

- goal based on cards reviewed today
- visual progress toward the daily goal
- clear completed state
- no effect on scheduler or due counts

Important: daily goal is not the same as Anki daily limits. It is motivational only.

### 3. Streak polish

Improve streak presentation:

- show current streak clearly
- show whether today has already counted
- avoid guilt-heavy language
- make broken/zero streak states encouraging

Streak logic may use existing progress snapshot state, but do not rewrite scheduler/day-boundary logic unless absolutely necessary.

### 4. Review completion celebration

Improve the end-of-session state so completion feels satisfying.

Suggested elements:

- reviewed count
- grade breakdown
- XP gained or progress gained, if available
- daily goal progress update
- streak acknowledgement when applicable
- primary action back to deck / home
- optional secondary action to review more only if it respects due state

This should be delightful but not noisy.

### 5. Achievement foundation

Add the smallest useful achievement foundation, not a full achievement economy.

Acceptable scope:

- define an `Achievement` / `AchievementProgress` model or similar seam
- add a local repository if needed
- unlock a very small number of simple achievements
- show achievements on Progress or a lightweight achievements section

Suggested starter achievements:

- First Review
- Daily Goal Complete
- 3-Day Streak
- 100 Cards Reviewed

Avoid complex badges, social sharing, leaderboards, currencies, shops, or remote sync.

### 6. Visual consistency

Use Decko’s design language:

- soft, rounded, playful but calm
- branded cards and panels
- no stock alert-dialog or utilitarian debug surfaces
- accessible contrast and text sizes
- usable on small screens

## Out of scope

- Bunburu sentence builder mode
- boss battles, quests, mastery maps, leagues, shops, currencies
- changing FSRS scheduling
- changing due queue rules
- changing import behaviour
- changing Anki compatibility
- cloud sync
- notifications
- social features
- monetisation

## Architecture expectations

Keep the gamification layer separate from scheduling.

Preferred mental model:

```text
Review events / progress snapshot
        ↓
Progress presentation
        ↓
Light achievements / celebration
```

Do not let achievements become a scheduler dependency.

Do not let XP or streaks decide what is due.

## Data expectations

If new persistence is added:

- keep it local-first
- keep it migration-safe
- preserve old users’ existing progress snapshots
- handle missing data gracefully
- add tests for serialization/deserialization

Existing imported decks and review state must continue to work without re-import.

## Testing expectations

Add or update tests for:

- daily goal progress calculation
- streak display states
- review completion summary data
- achievement unlock rules, if added
- persistence round-trip for any new model
- progress screen widget states
- empty/no-progress state

`flutter analyze` must be clean.

Existing import, scheduler, FSRS, daily-limit, and sibling-burying tests must continue to pass.

## Acceptance criteria

MVP_015 is complete when:

- Progress screen feels like a real Decko product surface, not a placeholder.
- Daily goal progress is visible and motivational.
- Review completion feels rewarding.
- Streak display is clearer and kinder.
- A small achievement foundation exists, or a clear documented reason is given for deferring it.
- No scheduler/import/parity behaviour regresses.
- Existing users/decks continue to load safely.
- Tests cover the new progress/gamification behaviour.
- `flutter analyze` is clean.
- `memory.md` records MVP_015 completion and the next recommended MVP.
- `docs/DECISIONS.md` records any new durable decision.
- `docs/ROADMAP.md` is updated if the next MVP sequence changes.

## Suggested decision record

If implementation introduces an achievement model, add a decision such as:

```text
DEC-024: Light gamification is derived from review/progress events and must not drive scheduling.
```

## Next likely MVP

If MVP_015 succeeds, the next likely step is:

```text
MVP_016 — Bunburu Sentence Builder Mode
```

That MVP should integrate Bunburu as a Decko-native game mode powered by imported sentence fields, while keeping normal FSRS review scheduling separate.

Update `.agent/skills/` only if this MVP changes how future agents should operate.
