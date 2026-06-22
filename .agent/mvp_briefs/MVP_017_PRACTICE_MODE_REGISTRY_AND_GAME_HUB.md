# MVP_017 — Practice Mode Registry & Game Hub

## Status

Ready for implementation.

## One-line mission

Turn Bunburu from a successful one-off game mode into the first registered Decko practice mode, then build the reusable discovery, launch, and outcome layer that future games can plug into cleanly.

## Why this MVP exists

MVP_016 proved that Decko can support a richer practice experience without breaking the review system:

- Bunburu can be launched manually from cards with sentences.
- Bunburu can be used as deck-level extra practice.
- Bunburu can be used as a scheduler-routed review presentation when explicitly enabled.
- Manual practice does not mutate FSRS or card due state.
- Scheduled review presentations still report answers through the normal review scheduler seam.

That worked, but it should not remain a special-case feature. Before adding Listening Challenge, Typing Recall, Matching, Kanji Quest, or other game modes, Decko needs a shared practice-mode platform.

This MVP makes practice modes first-class citizens in Decko.

## Product principle

Games are not decorations.

Games are alternative ways of practising or testing the same learning item.

## Durable architecture principle

Keep this distinction explicit:

```text
Scheduler decides which cards are due.
Review presentation decides how a due card is tested.
Manual practice modes provide extra practice without changing due state.
Practice outcomes may feed motivation/progress, but must not silently rewrite FSRS state.
```

This MVP should make that architecture easier to preserve as more games are added.

## Core user story

As a learner, I want Decko to show me the practice modes that are available for a deck or card, so that I can choose the best way to test myself without needing to know which fields or templates the deck contains.

Examples:

```text
A card with a sentence       → Bunburu Sentence Builder
A card with audio            → future Listening Challenge
A card with image + word     → future Image Recall
A vocabulary card            → future Typing / Multiple Choice
A kanji-focused card         → future Kanji / Meaning Match
```

## Scope

### 1. Add a PracticeMode domain model

Create a reusable domain model for practice modes.

Suggested model concepts:

```dart
class PracticeMode {
  final PracticeModeId id;
  final String title;
  final String subtitle;
  final String description;
  final PracticeModeKind kind;
  final PracticeModeLaunchSurface launchSurface;
  final PracticeModeAvailability availability;
}
```

Exact implementation can differ, but the domain should clearly represent:

- stable mode id
- title
- short description
- icon metadata / display affordance
- whether the mode can be launched manually
- whether it can be used as a review presentation
- what card/deck data it requires

Suggested IDs:

```text
bunburu_sentence_builder
```

Future IDs should be easy to add:

```text
listening_challenge
typing_recall
matching_game
image_recall
kanji_quest
```

### 2. Add a PracticeModeRegistry

Create a registry/discovery layer that knows which practice modes are available for a card or deck.

Suggested responsibilities:

```text
availableForCard(card)
availableForDeck(deck)
reviewPresentationModesForCard(card)
manualPracticeModesForCard(card)
```

For MVP_017, the registry may only register Bunburu, but it must be shaped so the next game does not need to hard-code logic into Deck Detail, Review, or Practice Hub.

### 3. Register Bunburu as the first practice mode

Refactor existing Bunburu launch logic so Bunburu is discovered through the registry rather than treated as a one-off feature.

Bunburu availability should be based on usable sentence content.

A card should be Bunburu-capable if Decko can derive a valid playable sentence from available fields, for example:

```text
Sentence
Sentence-Kana
Sentence-English
Example
Japanese sentence field
```

Do not make field names too brittle. Use the existing note-type-aware mapping and source preservation where possible.

### 4. Improve the Practice Hub

Upgrade the Practice Hub so it feels like the central place for Decko’s playful practice layer.

It should show available practice modes in a way that scales beyond Bunburu.

Suggested sections:

```text
Available now
From your decks
Coming next
```

For MVP_017, Bunburu should appear as the first real registered mode.

Future modes can be shown as locked/coming-soon only if this fits the existing visual language and does not feel like fake functionality.

### 5. Show available practice modes on Deck Detail

Deck detail should show a clear, beautiful “Practice modes” area when a deck supports one or more modes.

For MVP_017:

- decks with sentence-capable cards should show Bunburu
- decks without sentence-capable cards should not show a broken/empty Bunburu action
- do not clutter the screen if no practice modes are available

### 6. Show extra practice actions on cards/review where appropriate

When a card has available manual modes, Decko should be able to expose them consistently.

For MVP_017, preserve the MVP_016 behaviour:

```text
Build this sentence
```

But route/discover the action through the new practice-mode registry.

This is important because the next cards may show:

```text
Listen again
Type answer
Match meaning
Build sentence
```

The UI should not hard-code each one directly into unrelated screens.

### 7. Add a lightweight PracticeOutcome model

Create a small outcome model for manual/deck-level practice.

Suggested fields:

```text
modeId
itemId/cardId optional
sourceDeckId optional
startedAt
completedAt
score or result
correctCount
incorrectCount
xpAwarded optional
```

For MVP_017, this does not need to become a complex analytics system.

It should provide a stable seam so future game modes can report motivational results into the progress/achievement layer without touching FSRS.

### 8. Connect manual practice outcomes to motivation only

Manual/deck-level practice outcomes may update motivational progress, such as:

- XP
- practice count
- achievements
- completion celebration

Manual practice must not:

- change card due dates
- mutate ReviewCardState
- increment Anki-style review counters
- bypass the ReviewScheduler seam
- affect daily new/review counters
- affect sibling burying

Scheduled review presentation remains different: if Bunburu is used to answer a due card, it must still submit the final grade through the normal ReviewScheduler seam.

## Out of scope

Do not add a second full game in MVP_017.

Specifically out of scope:

- Listening Challenge implementation
- Typing Recall implementation
- Matching Game implementation
- Kanji Quest implementation
- leaderboards
- cloud sync
- social challenges
- new FSRS behaviour
- scheduler changes
- import changes
- daily-limit changes
- bury-sibling changes

This MVP builds the platform for those things.

## Safety requirements

The following must remain true:

```text
LearningItem.id stability is unchanged.
Imported progress is not reset.
FSRS scheduling is unchanged.
Due queue generation is unchanged.
Daily counters are unchanged.
Sibling burying is unchanged.
Manual practice does not mutate review state.
Scheduled review-mode practice still routes through ReviewScheduler.
```

Add regression tests around these boundaries where practical.

## Suggested files / areas

Likely new files:

```text
lib/domain/practice_mode.dart
lib/domain/practice_mode_availability.dart
lib/domain/practice_outcome.dart
lib/domain/repositories/practice_mode_registry.dart
lib/data/decko_practice_mode_registry.dart
lib/features/practice/practice_hub_screen.dart
lib/features/practice/widgets/practice_mode_tile.dart
```

Likely updated files:

```text
lib/decko_app.dart
lib/decko_router.dart
lib/features/deck_detail/deck_detail_screen.dart
lib/features/review/review_session_screen.dart
lib/features/bunburu/...
lib/domain/achievement.dart
lib/domain/progress_snapshot.dart
lib/data/shared_prefs_progress_repository.dart
```

Exact paths can differ if the existing structure suggests better names.

## Acceptance criteria

MVP_017 is complete when:

- [ ] A reusable PracticeMode domain model exists.
- [ ] A PracticeModeRegistry or equivalent discovery service exists.
- [ ] Bunburu is registered as `bunburu_sentence_builder`.
- [ ] Decko can ask which practice modes are available for a card.
- [ ] Decko can ask which practice modes are available for a deck.
- [ ] Deck Detail shows available practice modes without hard-coding Bunburu directly.
- [ ] Practice Hub shows registered available modes.
- [ ] Manual per-card Bunburu launch still works from sentence-capable cards.
- [ ] Deck-level Bunburu practice still works for sentence-capable decks.
- [ ] Scheduler-routed Bunburu review presentation remains possible if enabled.
- [ ] Manual practice outcomes are recorded or represented through a lightweight PracticeOutcome seam.
- [ ] Manual practice can feed motivational progress only.
- [ ] Manual practice does not mutate FSRS/review state.
- [ ] Scheduled review presentation still grades through ReviewScheduler.
- [ ] Tests cover availability detection for card/deck modes.
- [ ] Tests cover the manual-practice-vs-scheduled-review boundary.
- [ ] `flutter analyze` is clean.
- [ ] Existing tests pass.

## Documentation updates required

Update:

```text
docs/DECISIONS.md
docs/ROADMAP.md
docs/UI_REGISTRY.md
memory.md
.agent/memory.md if present
```

Add a decision record, likely:

```text
DEC-026 — Practice Mode Registry and Outcome Boundary
```

Decision should capture:

```text
Decko practice modes are registered capabilities that can be discovered per card and per deck. Manual practice outcomes may update motivational progress, but they do not mutate review state. Scheduler-routed practice presentations must still grade through the ReviewScheduler seam.
```

## Review report expectations

When reporting completion, include:

- commit SHA
- changed files summary
- registered modes
- how Bunburu is discovered
- where modes appear in UI
- how manual outcomes are handled
- explicit confirmation that FSRS/review queue/daily counters/burying were not changed
- test count
- `flutter analyze` result

## Agent operating reminder

Update `.agent/skills/` only if this MVP changes how future agents should operate.
