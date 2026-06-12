# Decko Roadmap

## I1 — Beautiful Imported Deck Review

Goal: prove the core promise.

> Import your deck. Study it beautifully.

### I1.1 Foundation

- Product docs
- Architecture docs
- Agent operating system
- Flutter scaffold
- Basic routing
- Theme foundation

### I1.2 Local deck flow

- Sample JSON deck format
- Import adapter interface
- JSON import adapter
- Deck library screen
- Deck detail screen

### I1.3 Review loop

- Review queue
- Review session screen
- Reveal answer interaction
- Again / Hard / Good / Easy ratings
- SimpleSchedulerService behind SchedulerService interface
- ReviewEvent recording

### I1.4 Beautiful cards and themes

- AppThemeConfig
- CardThemeConfig
- Minimal card theme
- Detailed card theme
- Game card theme
- Theme selector

### I1.5 Gamification

- XP from review events
- Daily goal
- Streak calculation
- Session summary
- Simple achievements

### I1.6 Persistence

- Select persistence library
- Persist imported decks
- Persist review cards and review events
- Persist theme choice and progress

## Deferred Notes

Small, intentionally-postponed improvements captured so they are not lost.

- **Empty deck handling (review).** Review currently falls back to the sample
  card when a deck has zero items (acceptable while data is mock). Once imported
  decks are real, an empty deck should show an explicit "This deck has no cards
  yet." state instead of a fallback card. (From MVP_002 review.)
- **Reading normalisation (Japanese data).** Demo readings are mixed: the
  Japanese Starter Deck uses kana (たべる) while Travel Phrases uses romaji
  (konnichiwa). Fine for demo data, but real Japanese decks should normalise
  readings to kana where possible. (From MVP_002 review.)
- **Scheduler write-back / due-queue (BLOCKS several things).** Reviewing a card
  doesn't reschedule it: the session is in-memory and only updates the XP/streak
  snapshot. So an imported deck's "Due today" count never decrements after
  review. Needs a scheduler that persists review outcomes back to per-card state
  (the DEC-003 seam, `ReviewScheduler`, already exists). Strong next-MVP
  candidate. (From MVP_005 testing.)
- **Import: media (images/audio).** Import strips `[sound:…]` and `<img>` and
  doesn't extract media files, so audio is dropped and image-only cards import
  near-empty. Add media support later. (From MVP_005 testing.)
- **Import: modern `.anki21b` (zstd).** Only the legacy uncompressed `.apkg` is
  supported; modern exports are rejected with guidance. Decode zstd later. (DEC-010.)
- **Import: smarter field mapping.** Field→Decko mapping is heuristic
  (front/back positional, kana→reading, sentence→example). Note-type-aware
  mapping would import more decks cleanly. (From MVP_005 testing.)

## I2 — APKG Import Beta

- Parse APKG package
- Extract notes/cards/media metadata
- Map imported notes to Decko LearningItems
- Preserve tags and deck names
- Handle unsupported templates gracefully
- Detect whether the package contains scheduling/progress data
- Do not silently reset progress

## I3 — Progress-Aware Import

Goal: make Decko safe for existing deck users who already have study progress.

See: `docs/import-progress.md`

- Detect scheduling/progress information in imported decks
- Show an import summary before confirmation
- Offer Keep progress and Start fresh when progress exists
- Warn clearly when progress is missing or unsupported
- Preserve reviewed/new/learning/relearning state where available
- Preserve due dates or due positions where available
- Preserve reps, lapses, intervals, and ease where available
- Preserve suspended state where available
- Record whether progress was preserved during import

## I4 — Advanced Practice Modes

- Multiple choice
- Type answer
- Matching game
- Cloze deletion
- Listening mode

## I5 — FSRS Production Scheduler

- Add FsrsSchedulerService
- Migration from simple scheduler fields
- Scheduler tests
- Review analytics
- Use imported review history where available to initialise or improve FSRS-compatible state

## I6 — Cloud and Account Layer

Not in Iteration 1.

Potential future scope:

- optional account
- cross-device sync
- cloud backup
- paid themes or premium features
