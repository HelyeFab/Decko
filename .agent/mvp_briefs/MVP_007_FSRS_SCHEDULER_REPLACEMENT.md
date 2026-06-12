# MVP_007 — FSRS Scheduler Replacement

## Status

Planned.

## Mission

Replace Decko's temporary fixed scheduling policy with an FSRS-ready scheduler implementation behind the existing review scheduling seam.

MVP_006 made imported decks genuinely usable by adding persistent per-card review state, a due queue, and scheduler write-back. However, the current policy is intentionally temporary: `Again` returns immediately, `Hard` is roughly +1 day, `Good` is roughly +3 days, and `Easy` is roughly +7 days.

MVP_007 should make scheduling behaviour more credible while preserving the current product flow:

```text
Imported deck → due queue → review card → grade → persisted review state → due count updates
```

The goal is not to build every advanced Anki/FSRS feature. The goal is to replace the hard-coded placeholder policy with a proper FSRS-based or FSRS-compatible scheduler layer that can evolve safely.

## Product promise

After this MVP, Decko should be able to say:

```text
Decko now schedules reviews using an FSRS-style memory model instead of fixed placeholder intervals.
```

Do **not** claim exact Anki scheduling parity.

Do **not** claim full FSRS optimisation/training.

Do **not** claim that imported Anki progress has been perfectly converted into FSRS parameters unless the implementation genuinely supports that.

## Required context

Before coding, read:

```text
.agent/README.md
.agent/AGENT_OPERATING_SYSTEM.md
.agent/skills/orient/SKILL.md
.agent/skills/architect/SKILL.md
.agent/skills/execute/SKILL.md
.agent/skills/review/SKILL.md
.agent/skills/remember/SKILL.md
docs/DECISIONS.md
docs/ROADMAP.md
docs/import-progress.md
memory.md
```

Also inspect the current review-related code before planning:

```text
lib/domain/repositories/review_scheduler.dart
lib/data/simple_review_scheduler.dart
lib/domain/review_card_state.dart
lib/domain/review_answer.dart
lib/domain/review_rating.dart
lib/domain/review_session.dart
lib/domain/repositories/review_state_repository.dart
lib/features/review/review_session_screen.dart
```

Return a short implementation plan before making changes.

## Scope

### 1. Preserve the existing scheduling seam

Keep the review UI dependent on the scheduling abstraction, not on concrete scheduling maths.

The implementation may rename or refine the current temporary scheduler, but it must preserve the architecture principle:

```text
Review UI → scheduler interface → concrete scheduler implementation → persisted ReviewCardState
```

The UI must not contain FSRS maths.

### 2. Add FSRS-compatible review state fields if needed

If the current `ReviewCardState` does not already contain enough memory-state data, extend it carefully.

Potential fields:

```text
stability
difficulty
retrievability
lastReviewedAt
scheduledDays
elapsedDays
sourceSystem
schedulerVersion
```

Use nullable fields if needed so existing imported decks and older persisted states do not break.

The migration path must be safe.

### 3. Implement an FSRS-style scheduler

Implement a concrete scheduler such as:

```text
FsrsReviewScheduler
```

or:

```text
FsrsSchedulerPolicy
```

The scheduler should map Decko's four ratings:

```text
Again
Hard
Good
Easy
```

into updated review state.

It should update at least:

```text
queue state
due date
reps
lapses
interval/scheduled days
last reviewed timestamp
stability/difficulty if supported
```

If you use a simplified FSRS implementation, be explicit in comments and docs that it is FSRS-compatible/FSRS-style, not a fully trained optimiser.

### 4. Keep imported Anki progress protected

This MVP must not silently reset imported progress.

For cards imported with Anki progress:

```text
reviewed cards should remain reviewed
future cards should remain future-due
suspended cards should remain suspended
new cards should remain new
```

When FSRS fields are missing, initialise them conservatively from existing state such as interval, reps, lapses, queue state, and last reviewed date.

Do not make every imported card new.

Do not overwrite due dates for cards that were not reviewed in the current session.

### 5. Maintain due queue behaviour

After a card is reviewed:

```text
Due today should decrement when that card is scheduled into the future.
Again may keep/re-add a card as due depending on the policy.
Future-due cards should not appear in today's queue.
Suspended cards should not appear in the queue.
```

The deck detail screen should continue to show useful due/reviewed counts.

### 6. Preserve current UX

The current review flow should still work:

```text
Deck detail → Start review → Card X of N → Reveal → Grade → Next → Summary
```

The session summary can remain simple.

No need to expose FSRS details in the UI yet, unless a small debug-friendly line is helpful for development.

### 7. Tests are required

Add pure scheduler tests for:

```text
new card + Good schedules into the future
new card + Again remains due/relearning appropriately
review card + Good updates interval/state
review card + Easy schedules farther than Good
Hard schedules less far than Good
suspended cards remain excluded from due queue
future-due cards remain excluded from due queue
imported progress is not reset during scheduler initialisation
```

Add widget tests or update existing ones for:

```text
reviewing a due card decreases Due today when scheduled future
review flow still reaches summary
existing imported deck/deck detail flow still works
```

All tests must pass.

Run:

```bash
flutter analyze
flutter test
```

## Explicit non-goals

Do **not** implement:

```text
FSRS parameter optimisation/training from full review history
Anki scheduler parity
AnkiWeb sync
cloud sync
accounts
media import
modern .anki21b support
new study modes
floating bottom navigation
large UI redesign
```

Do not rewrite the import system unless required for safe FSRS initialisation.

Do not break current `.apkg` legacy import.

## Acceptance criteria

```text
[ ] Current temporary fixed scheduler is replaced or clearly wrapped by an FSRS-style scheduler.
[ ] Review state persists FSRS-compatible fields or can safely evolve to do so.
[ ] Existing imported progress is preserved.
[ ] Reviewing a card updates its due date and review state through the scheduler.
[ ] Due queue continues to exclude future and suspended cards.
[ ] Due today changes after review when appropriate.
[ ] Existing review flow still works.
[ ] Existing import flow still works.
[ ] No UI contains scheduler maths.
[ ] flutter analyze passes.
[ ] flutter test passes.
[ ] docs/DECISIONS.md is updated with the FSRS scheduling decision.
[ ] docs/ROADMAP.md deferred notes are updated if this closes/reframes the temporary scheduler gap.
[ ] memory.md is updated with the handoff state.
```

## Approval report required

When finished, return:

```text
MVP_007 Approval Report — FSRS Scheduler Replacement

1. Summary
2. Files changed
3. Scheduler behaviour included
4. How imported progress is preserved
5. Design decisions
6. Dependencies added
7. How to run
8. Known limitations
9. Manual test checklist
10. Recommendation for next MVP
```

## Suggested next MVPs after this

Likely next candidates:

```text
MVP_008 — Media Import for Anki Decks
MVP_008 — Modern .anki21b Support
MVP_008 — Floating Bottom Navigation UI
```

Choose based on the user's real deck testing results after FSRS replacement.
