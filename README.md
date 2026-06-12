# Decko

**Decko** is a modern flashcard app focused on beautiful study decks, FSRS-powered review, themed card experiences, and playful gamification.

The first iteration is not trying to replace every advanced Anki feature. It focuses on one clear promise:

> Import your deck. Study it beautifully.

## Iteration 1 goals

Decko Iteration 1 focuses on:

1. Importing an existing deck file.
2. Displaying decks, cards, and review sessions with a polished Flutter UI.
3. Using an FSRS-ready review model.
4. Supporting beautiful app themes and card themes.
5. Adding lightweight gamification: XP, streaks, daily goals, and completion feedback.

## Core product pillars

### 1. Deck compatibility

Decko should support imported study decks, starting with a pragmatic import layer. The long-term goal is to support Anki-style `.apkg` decks, but the MVP should isolate deck import behind an adapter so early development can start with JSON/CSV fixtures before full APKG parsing is implemented.

### 2. FSRS-first review

Decko should treat review scheduling as a first-class domain. The data model should be compatible with FSRS concepts such as difficulty, stability, retrievability, review state, due date, review history, and ratings.

### 3. Beautiful themes

Decko should separate:

- App themes: the shell around the learning experience.
- Card themes: how each flashcard itself looks and feels.

The first version should include a small number of high-quality themes rather than many unfinished ones.

### 4. Multiple practice modes

Decko should not limit a learning item to a single front/back card. The app should support review modes such as recognition, production, listening, cloze deletion, matching, and typing challenges.

### 5. Gamified motivation

Decko should make review sessions feel rewarding through streaks, XP, levels, achievements, progress feedback, and session summaries.

## Suggested first Flutter stack

- Flutter
- Riverpod for state management
- GoRouter for navigation
- Drift or Isar for local persistence
- File picker for import
- A dedicated scheduling/domain layer for FSRS-compatible review data

## Repository status

This repository currently starts with product and architecture foundation documents. The Flutter app scaffold can be added after the product foundation is accepted.
