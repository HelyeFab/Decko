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
- **Floating bottom nav bar (UI direction).** Replace the app-bar-action
  navigation with a modern floating, rounded bottom nav (Home/Library,
  Progress, Themes, …; active tab labelled). Needs a GoRouter
  `StatefulShellRoute.indexedStack` refactor so tabs keep state and the bar
  persists — its own MVP. (Requested during MVP_006.)
- ~~**Scheduling realism.**~~ DONE (MVP_007, DEC-013): replaced the fixed
  placeholder with an FSRS-5 policy behind the same seam. Future work: per-deck
  FSRS weight training, and intra-day learning steps (both deferred).
- **Review-state storage at scale.** Per-card review state is a per-deck JSON
  blob in shared_preferences, flushed on session exit. Very large libraries
  will want a real DB behind `ReviewStateRepository`. (DEC-011.)
- ~~**App shell + Home/Import crowding.**~~ DONE (MVP_008.5, DEC-017): added the
  reusable `DeckoAppBar`, made Home study-first (the `StudyRibbon` hero + compact
  `DeckRow` shelf + dashed Import row), moved the marketing promise grid to the
  empty state only, and kept Import on its own screen.
- ~~**Lossless Anki source.**~~ DONE (MVP_009, DEC-016): import now preserves the
  full Anki source — every named field (raw + plain + media refs), tags, model
  field/template definitions, and card→template links — persisted per deck, with a
  Decko-styled "View imported source" inspect screen on deck detail and
  named-field / Listening-Reading-Production template tests.
- ~~**Note-type-aware card mapping.**~~ DONE (MVP_010, DEC-019): a pure
  `NoteTypeAwareCardMapper` consumes the preserved source to produce distinct
  Listening / Reading / Production presentations (audio-first / text / English-
  prompt) instead of 3× lookalikes, with a quiet mode eyebrow on the card and
  mapping rationale in the inspect screen. `LearningItem.id` is unchanged so
  progress/FSRS are safe; simple decks fall back to generic.
- ~~**Study options & deck overrides.**~~ DONE (MVP_011, DEC-020): two-level
  options (global `StudyOptions` + nullable per-deck `DeckStudyOptions` →
  `EffectiveStudyOptions`), persisted via `StudyOptionsRepository`. Per-session
  queue caps (new/review/max), audio autoplay, image-display timing, and
  per-deck furigana preference. Settings tab is now a hub (Study defaults ·
  Themes); deck detail has a "Deck options" entry. FSRS/progress untouched.
  Daily limits are per-session for now. Next: MVP_012 — Advanced Deck Option
  Profiles (option groups shared across decks).

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
