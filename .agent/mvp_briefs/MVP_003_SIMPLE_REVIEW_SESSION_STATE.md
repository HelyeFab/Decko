# Decko MVP Agent Brief — MVP_003: Simple Review Session State

## Mission

Turn Decko's review preview into a small but real local review session.

MVP_001 proved the product shell. MVP_002 proved local decks and navigation. MVP_003 should make the study loop feel real for the first time:

> Choose a deck → review its cards → grade each card → finish the session → see a summary.

This MVP must remain local, mock-data based, and deliberately simple. It should not implement FSRS yet, but it must introduce the right seam for FSRS to replace the temporary scheduler later.

---

## Before coding

Read these files first:

```txt
.agent/README.md
.agent/AGENT_OPERATING_SYSTEM.md
.agent/skills/orient/SKILL.md
.agent/skills/architect/SKILL.md
.agent/skills/execute/SKILL.md
.agent/skills/review/SKILL.md
.agent/mvp_briefs/MVP_001_FLUTTER_PRODUCT_SHELL.md
.agent/mvp_briefs/MVP_002_LOCAL_DEMO_DECK_MODEL_AND_NAVIGATION.md
docs/DECISIONS.md
docs/CODING_STANDARDS.md
docs/UI_REGISTRY.md
docs/ROADMAP.md
memory.md
```

Then return a short implementation plan before making changes.

---

# MVP_003 Scope

Build a simple local review session over the selected demo deck's items.

The session should:

- load the selected deck,
- create a queue from that deck's `LearningItem`s,
- show one card at a time,
- allow reveal,
- record a rating for each card,
- advance to the next card,
- show progress through the session,
- end with a small completion summary.

This is not a real scheduler yet. It is the first review-session state layer.

---

## 1. Review session domain model

Introduce small domain models for session state.

Suggested files:

```txt
lib/domain/review_session.dart
lib/domain/review_session_result.dart
lib/domain/review_answer.dart
```

Suggested concepts:

```dart
class ReviewSession {
  final String deckId;
  final List<LearningItem> items;
  final int currentIndex;
  final List<ReviewAnswer> answers;
}
```

```dart
class ReviewAnswer {
  final String itemId;
  final ReviewRating rating;
  final DateTime answeredAt;
}
```

```dart
class ReviewSessionResult {
  final String deckId;
  final int totalCards;
  final int againCount;
  final int hardCount;
  final int goodCount;
  final int easyCount;
}
```

Keep these models framework-light. Do not couple them to Flutter widgets.

---

## 2. Scheduler seam

Introduce a scheduler-facing interface, but keep the implementation very simple.

Suggested files:

```txt
lib/domain/repositories/review_scheduler.dart
lib/data/simple_review_scheduler.dart
```

The interface should be future-proof enough for FSRS later, but MVP_003 only needs a simple queue.

Suggested shape:

```dart
abstract class ReviewScheduler {
  ReviewSession createSession({required Deck deck});
  ReviewSession answerCurrentCard({
    required ReviewSession session,
    required ReviewRating rating,
    required DateTime answeredAt,
  });
  ReviewSessionResult completeSession(ReviewSession session);
}
```

`SimpleReviewScheduler` should:

- include all deck items in order,
- advance one card after each answer,
- record ratings,
- produce summary counts.

Do not implement FSRS intervals, due dates, stability, difficulty, or persistence yet.

---

## 3. Review screen behaviour

Update the review screen so `/deck/:deckId/review` becomes a real session screen.

Required behaviour:

1. Load the deck from the repository.
2. Build a local review session from that deck.
3. Show current card number, for example:

```txt
Card 1 of 5
```

4. Show a progress indicator.
5. Show the current card front.
6. Hide the answer until the learner taps reveal.
7. After reveal, show:

```txt
Again
Hard
Good
Easy
```

8. When a rating is tapped:
   - record the answer,
   - advance to the next card,
   - reset reveal state.
9. When all cards are answered, show a completion screen.

---

## 4. Completion summary

Add a simple completion state/screen inside the review flow.

It should show:

```txt
Session complete
Cards reviewed: N
Again: N
Hard: N
Good: N
Easy: N
```

Add actions:

```txt
Back to deck
Review again
```

`Back to deck` should return to the current deck detail screen.

`Review again` should restart the same simple session.

---

## 5. Empty deck handling

If a deck has zero items, the review screen must not fall back to the generic sample card.

Instead it should show a graceful empty state:

```txt
This deck has no cards yet.
```

with a button:

```txt
Back to deck
```

This is important for future imports.

---

## 6. Standalone `/review` route

The old standalone `/review` route may remain as a demo preview, but it must not interfere with deck review sessions.

Acceptable options:

- keep `/review` as a standalone demo preview, or
- redirect `/review` to the first demo deck review, or
- show a friendly message asking the user to choose a deck first.

Choose the least disruptive option and explain it in the approval report.

---

# Explicit non-goals

Do **not** implement these yet:

```txt
FSRS scheduling
Anki scheduling import
Due dates
Persistence
Database storage
JSON import
APKG import
CSV import
Cloud sync
Accounts
Payments
AI card generation
Real gamification state
Daily streak mutation
Spaced-repetition intervals
```

This MVP is only about session state and the review loop.

---

# Technical guidance

- Keep state local to the review screen unless a tiny controller class improves clarity.
- Do not add Riverpod yet unless absolutely necessary.
- Do not add dependencies unless strongly justified.
- Preserve existing routes and MVP_001/MVP_002 screens.
- Keep domain models testable without Flutter.
- Keep the UI polished and consistent with the existing Decko style.
- Keep user-facing copy warm, simple, and honest.

---

# Tests required

Update widget tests to cover the new review loop.

Required test coverage:

```txt
[ ] Starting review from deck detail opens session card 1
[ ] Reveal shows the answer and rating buttons
[ ] Rating advances to the next card
[ ] Progress text updates from Card 1 of N to Card 2 of N
[ ] Completing all cards shows session summary
[ ] Review again restarts the session
[ ] Back to deck returns to deck detail
```

Add a test for empty deck handling if it can be done cleanly with an injected repository.

---

# What to return for approval

Before finalising, return this approval report:

## 1. Summary

Briefly explain what was built.

## 2. Files changed

List every created or changed file.

Use this format:

```txt
Created:
- lib/domain/review_session.dart
- ...

Changed:
- lib/features/review/review_placeholder_screen.dart
- ...
```

## 3. Review flow included

Describe the actual review flow now supported:

```txt
Deck detail → Start review → Card 1 → Reveal → Grade → Next card → Completion summary
```

## 4. Design decisions

Explain decisions around:

```txt
ReviewSession model
ReviewScheduler interface
SimpleReviewScheduler behaviour
Review screen state management
Standalone /review behaviour
Empty deck handling
```

## 5. Dependencies added

List any dependencies added.

If no dependencies were added, say:

```txt
No external dependencies added.
```

## 6. How to run

Provide exact commands:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## 7. Known limitations

Clearly state what is still fake/placeholder.

For example:

```txt
- Ratings only affect the current in-memory session.
- No scheduling or due dates are calculated yet.
- Session results are not persisted.
- Progress and streaks remain mock data.
```

## 8. Manual test checklist

Return a checklist we can use:

```txt
[ ] App launches successfully
[ ] Deck library still shows demo deck tiles
[ ] Deck detail opens from a deck tile
[ ] Start review opens card 1 of the selected deck
[ ] Card answer is hidden before reveal
[ ] Reveal shows the answer and rating buttons
[ ] Again / Hard / Good / Easy advances to the next card
[ ] Progress indicator updates
[ ] Final card leads to session complete summary
[ ] Summary shows rating counts
[ ] Review again restarts the session
[ ] Back to deck returns to deck detail
[ ] Theme gallery still works
[ ] Import placeholder still works
[ ] Progress placeholder still works
```

## 9. Recommendation for next MVP

Suggest the next smallest implementation step.

Likely options:

```txt
MVP_004: JSON deck import adapter
MVP_004: Persist local decks and theme selection
MVP_004: FSRS-ready review state model
```

Do not start the next MVP without approval.

---

# Acceptance criteria

MVP_003 is complete when:

```txt
[ ] A deck review session is created from the selected deck.
[ ] The review screen advances card by card.
[ ] Ratings are recorded in memory for the session.
[ ] The UI shows current position and progress.
[ ] The session ends with a completion summary.
[ ] The user can restart the session.
[ ] The user can return to deck detail.
[ ] Empty decks do not fall back to sample cards.
[ ] No real FSRS, persistence, or import work is added.
[ ] Existing MVP_001 and MVP_002 flows still work.
[ ] Tests cover the review loop.
[ ] The agent returns the approval report above.
```
