# MVP_006 — Due Queue and Scheduler Write-Back

## Status

Ready for agent implementation.

## Context

Decko has now reached the point where users can import real Anki decks and study them in a basic review loop. MVP_005 proved the key product promise:

> Import your deck. Study it beautifully.

However, imported progress is not yet truly actionable during review. A user can import a deck with progress, see due/reviewed counts, and review cards, but reviewing a card does not write anything back to per-card scheduling state.

This creates the current critical gap:

> Due today does not decrement after review.

This MVP must close that gap with the smallest useful local-first scheduler layer.

This is not the full FSRS implementation. It is a simple, persistent, FSRS-ready due-queue and write-back layer that makes imported decks usable day-to-day.

## Mission

Implement a persistent due-queue and scheduler write-back system so that reviewing cards changes their local review state.

After this MVP:

- Imported decks should have a meaningful due queue.
- Starting review should prefer due cards, not blindly walk every card.
- Grading a card should persist updated local review state.
- Due counts should decrement after cards are reviewed.
- Updated due/reviewed state should survive app restart.
- The architecture must remain ready for FSRS later.

## Before Coding

Read these files first:

```text
.agent/README.md
.agent/AGENT_OPERATING_SYSTEM.md
.agent/skills/orient/SKILL.md
.agent/skills/architect/SKILL.md
.agent/skills/execute/SKILL.md
.agent/skills/review/SKILL.md
docs/DECISIONS.md
docs/ROADMAP.md
docs/import-progress.md
docs/UI_REGISTRY.md
memory.md
```

Then inspect the current implementation for:

```text
lib/domain/repositories/review_scheduler.dart
lib/data/simple_review_scheduler.dart
lib/domain/review_session.dart
lib/domain/review_answer.dart
lib/domain/review_session_result.dart
lib/domain/deck.dart
lib/domain/learning_item.dart
lib/data/anki_apkg_import_adapter.dart
lib/data/deck_store.dart
lib/features/review/review_session_screen.dart
lib/features/deck_detail/deck_detail_screen.dart
lib/features/progress/progress_screen.dart
```

Return a short implementation plan before making code changes.

## Scope

### 1. Add persistent per-card review state

Introduce a framework-light domain model for per-card review state.

Suggested model name:

```dart
class ReviewCardState {
  final String deckId;
  final String itemId;
  final ReviewQueueState queueState;
  final DateTime? dueAt;
  final int reps;
  final int lapses;
  final int intervalDays;
  final double? easeFactor;
  final DateTime? lastReviewedAt;
  final String sourceSystem; // e.g. "anki", "decko"
}
```

Suggested enum:

```dart
enum ReviewQueueState {
  newCard,
  learning,
  review,
  relearning,
  suspended,
}
```

Use names that fit the existing codebase if these exact names conflict.

### 2. Add repository seam for review state

Add a small async repository interface.

Suggested path:

```text
lib/domain/repositories/review_state_repository.dart
```

Suggested methods:

```dart
abstract class ReviewStateRepository {
  Future<List<ReviewCardState>> getStatesForDeck(String deckId);
  Future<ReviewCardState?> getState(String deckId, String itemId);
  Future<void> saveState(ReviewCardState state);
  Future<void> saveStates(List<ReviewCardState> states);
  Future<void> resetDeckStates(String deckId);
}
```

The UI and scheduler should depend on the interface, not on the storage implementation.

### 3. Persist review state locally

Implement a lightweight local persistence layer using the same approach as MVP_004/MVP_005 unless there is already a better persistent deck store available.

Acceptable MVP storage:

- JSON blob in `shared_preferences`, hidden behind `ReviewStateRepository`; or
- Extend the existing DeckStore if that is already responsible for imported deck persistence and can cleanly store per-card state.

Do not introduce a heavy database unless absolutely necessary.

The important architectural rule is:

> The storage backend must be replaceable later without changing UI screens.

### 4. Initialise states for imported decks

When an imported deck is committed, ensure every imported LearningItem has an associated ReviewCardState.

Rules:

- If the user selected **Keep Anki progress**, initialise from imported Anki progress when available.
- If the user selected **Start fresh**, initialise all non-suspended cards as new.
- If progress is unavailable, initialise as new and keep the warning behaviour from MVP_005.
- Suspended cards, if imported, should not appear in the due queue.

Do not silently reset imported progress. DEC-005 remains binding.

### 5. Build a real due queue

Update the review scheduler/session creation so that starting review for a deck creates a queue based on review state.

The simplest acceptable rule:

```text
Due queue = cards where:
- state is not suspended
- and either queueState is newCard
- or dueAt is null
- or dueAt <= now
```

For MVP_006, it is acceptable to include new cards in the same queue after due cards.

Preferred ordering:

```text
1. overdue/due review cards first
2. learning/relearning cards due now
3. new cards
```

Keep it deterministic and easy to test.

### 6. Write back after grading

When the user taps Again / Hard / Good / Easy, the scheduler must update and persist that card's ReviewCardState.

Use a simple placeholder scheduling policy, not FSRS.

Suggested temporary policy:

```text
Again:
- queueState = relearning
- lapses += 1
- reps += 1
- dueAt = now
- intervalDays = 0

Hard:
- queueState = review
- reps += 1
- dueAt = tomorrow
- intervalDays = 1

Good:
- queueState = review
- reps += 1
- dueAt = now + 3 days
- intervalDays = 3

Easy:
- queueState = review
- reps += 1
- dueAt = now + 7 days
- intervalDays = 7
```

This is intentionally simple. The goal is write-back behaviour, not perfect scheduling.

Document clearly in comments that this policy is temporary and will be replaced by FSRS later.

### 7. Make Due Today and Reviewed counts real

Update deck detail/provenance/progress UI so that imported decks reflect persisted review state.

At minimum:

- Due today count should come from ReviewStateRepository.
- Reviewed count should come from reps > 0 or preserved imported progress.
- After reviewing due cards, returning to deck detail should show reduced due count.
- Counts should survive app restart.

Do not show fake due/reviewed numbers once review state exists.

### 8. Empty due queue state

If a deck has no due cards and no new cards available, the review screen should show a friendly state such as:

```text
All caught up.
No cards are due right now.
```

Provide a button back to the deck detail screen.

Do not show a sample card fallback.

### 9. Tests

Add or update tests for:

- ReviewCardState serialisation/deserialisation if using JSON.
- Repository save/load/reset.
- Imported deck state initialisation.
- Due queue ordering.
- Again/Hard/Good/Easy write-back behaviour.
- Due count decrement after reviewing cards.
- Suspended cards excluded from due queue.
- Empty due queue screen.
- Existing import, deck library, theme, progress, and review flows still work.

Keep `flutter analyze` clean.

## Non-Goals

Do not implement:

- FSRS production scheduling.
- Full Anki scheduler compatibility.
- AnkiWeb sync.
- Cloud sync or accounts.
- Media import.
- Modern `.anki21b` zstd support.
- Smarter note-type-aware field mapping.
- Full review history analytics.
- Multiple study modes.
- A heavy database migration unless the current storage approach truly cannot support the MVP.

## Acceptance Criteria

```text
[ ] Imported decks initialise persistent review state.
[ ] Start fresh imports initialise cards as new.
[ ] Keep progress imports preserve usable review state where available.
[ ] Suspended cards do not enter the due queue.
[ ] Starting review uses a due/new queue rather than blindly all cards.
[ ] Grading a card updates and persists ReviewCardState.
[ ] Due today count decrements after review where appropriate.
[ ] Reviewed count increases or remains consistent after review.
[ ] Due/reviewed counts survive app restart.
[ ] Empty due queue shows a friendly all-caught-up state.
[ ] Existing imported decks still appear in the library.
[ ] Existing demo decks still work.
[ ] No claim is made that FSRS is implemented.
[ ] `flutter analyze` is clean.
[ ] Relevant unit/widget tests pass.
```

## Approval Report Required

When finished, return an approval report with this structure:

```text
MVP_006 Approval Report — Due Queue and Scheduler Write-Back

1. Summary
2. Files changed
3. Review state / due queue behaviour included
4. Design decisions
5. Dependencies added
6. How to run
7. Known limitations
8. Manual test checklist
9. Recommendation for next MVP
```

In the design decisions section, explicitly explain:

- Where per-card review state is stored.
- How imported Anki progress maps into ReviewCardState.
- How Start fresh differs from Keep progress.
- How due cards are selected.
- How rating write-back works.
- Why this remains FSRS-ready.

## Manual Test Checklist

```text
[ ] Import a real `.apkg` deck with Keep Anki progress.
[ ] Confirm due/reviewed counts appear on deck detail.
[ ] Start review from the imported deck.
[ ] Review one due card with Good.
[ ] Return to deck detail.
[ ] Confirm Due today decreased if that card was due.
[ ] Restart the app.
[ ] Confirm the updated due/reviewed counts remain.
[ ] Import another deck with Start fresh.
[ ] Confirm cards start as new.
[ ] Review a few cards.
[ ] Confirm reviewed count changes.
[ ] Confirm empty/no-due state appears when appropriate.
```

## Product Rule

This MVP must protect the user's trust.

Decko must never make a user feel that imported Anki progress was silently lost.

If progress cannot be mapped perfectly, preserve what is useful, clearly mark limitations, and keep the data model ready for better migration later.
