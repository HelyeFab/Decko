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

## I2 — APKG Import Beta

- Parse APKG package
- Extract notes/cards/media metadata
- Map imported notes to Decko LearningItems
- Preserve tags and deck names
- Handle unsupported templates gracefully

## I3 — Advanced Practice Modes

- Multiple choice
- Type answer
- Matching game
- Cloze deletion
- Listening mode

## I4 — FSRS Production Scheduler

- Add FsrsSchedulerService
- Migration from simple scheduler fields
- Scheduler tests
- Review analytics

## I5 — Cloud and Account Layer

Not in Iteration 1.

Potential future scope:

- optional account
- cross-device sync
- cloud backup
- paid themes or premium features
