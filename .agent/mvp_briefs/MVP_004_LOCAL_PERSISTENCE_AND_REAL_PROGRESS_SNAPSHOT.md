# Decko MVP Agent Brief — MVP_004: Local Persistence and Real Progress Snapshot

## Mission

Add the first small persistence layer to Decko so the app starts remembering meaningful local user state.

MVP_003 made review sessions real, but all session outcomes disappear when the user leaves the screen or closes the app. MVP_004 should preserve the most important lightweight state locally:

- selected app theme
- latest review session result
- basic progress snapshot shown on the Progress screen

This MVP is not about full deck persistence, real FSRS scheduling, import, accounts, or cloud sync.

The goal is to make Decko feel like it is starting to remember the learner.

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
docs/DECISIONS.md
docs/CODING_STANDARDS.md
docs/UI_REGISTRY.md
docs/ROADMAP.md
memory.md
```

Then inspect the current code, especially:

```txt
lib/app/decko_app.dart
lib/app/theme/theme_controller.dart
lib/app/theme/theme_registry.dart
lib/domain/review_session_result.dart
lib/domain/repositories/review_scheduler.dart
lib/data/simple_review_scheduler.dart
lib/features/review/review_session_screen.dart
lib/features/progress/progress_placeholder_screen.dart
test/review_session_test.dart
test/widget_test.dart
```

Return a short implementation plan before making changes.

---

# MVP_004 Scope

Build a minimal local persistence and progress layer.

## 1. Add a local settings store

Persist the selected app theme locally.

The user should be able to change theme in the Theme Gallery, leave the app, relaunch, and still see the chosen theme.

Recommended interface:

```dart
abstract class SettingsRepository {
  Future<String?> getSelectedAppThemeId();
  Future<void> saveSelectedAppThemeId(String themeId);
}
```

Use a simple local persistence mechanism appropriate for this MVP. `shared_preferences` is acceptable for settings and tiny snapshots. Do not introduce a heavy database unless you have a strong reason.

If adding a dependency, explain why.

---

## 2. Add a progress repository seam

Create a small `ProgressRepository` interface responsible for saving and loading a local progress snapshot.

Suggested model:

```dart
class ProgressSnapshot {
  final int totalXp;
  final int currentLevel;
  final int currentStreakDays;
  final int cardsReviewedToday;
  final DateTime? lastReviewedAt;
  final ReviewSessionResult? lastSessionResult;
}
```

Suggested interface:

```dart
abstract class ProgressRepository {
  Future<ProgressSnapshot> getSnapshot();
  Future<void> recordSessionResult(ReviewSessionResult result);
  Future<void> resetProgress(); // optional, useful for tests/debug only
}
```

Keep the first implementation intentionally simple.

MVP_004 can calculate simple gamification values such as:

```txt
+10 XP per reviewed card
Level = totalXp ~/ 100 + 1
cards reviewed today = count from latest local state
current streak = 1 initially, simple date-based increment if straightforward
```

Do not over-engineer streaks. A clear simple model is better than a clever broken one.

---

## 3. Save session results after review completion

When a review session completes, persist its `ReviewSessionResult` through the progress repository.

The completion summary should still work as it does now, but the Progress screen should now reflect the completed session after the user leaves review.

The persisted data should survive app restart where possible.

---

## 4. Replace mock Progress screen values

Update the Progress screen so it reads from `ProgressRepository` instead of showing fixed mock values.

It should still look polished and friendly.

It should show at least:

```txt
XP
Level
Current streak
Cards reviewed today
Last session summary, if available
Badges / achievements preview
```

If there is no progress yet, show a warm empty progress state, for example:

```txt
Complete your first review session to start building your Decko streak.
```

Do not pretend there is progress if no session has happened.

---

## 5. Keep repositories injectable

Follow the MVP_002 pattern: app-level dependencies should be injectable so tests can use in-memory/fake repositories.

Avoid global mutable singletons unless they are wrapped cleanly.

The app should remain easy to test.

---

# Explicit non-goals

Do not implement these yet:

```txt
Real FSRS scheduling
Due dates and intervals
Full deck persistence
JSON import
APKG import
Anki progress import
Accounts
Cloud sync
Payments
AI card generation
Complex analytics
Riverpod migration unless absolutely necessary
```

MVP_004 is about tiny, useful local memory only.

---

# Technical preferences

- Keep code simple and readable.
- Prefer small repository interfaces over direct package calls from UI.
- Keep domain models framework-light.
- Use async APIs for repositories so storage can be swapped later.
- Keep tests deterministic.
- Avoid time-dependent flaky tests by allowing current time injection where useful.
- Do not make the Progress screen depend on hard-coded mock values.

---

# UI expectations

The app should still feel like Decko:

```txt
modern
warm
beautiful
mobile-first
friendly
motivating
```

Progress should feel encouraging, not punitive.

Use copy such as:

```txt
Your latest review
Cards reviewed today
Current streak
XP earned
Keep going
```

Avoid guilt-based language.

---

# What to return for approval

Before finalising, return this approval report:

## 1. Summary

Briefly explain what was built.

## 2. Files changed

List every created, changed, and deleted file.

Use this format:

```txt
Created:
- ...

Changed:
- ...

Deleted:
- ...
```

## 3. Persistence included

Explain exactly what is now persisted:

```txt
- selected app theme
- latest session result
- XP / progress snapshot
```

Also explain what is not persisted.

## 4. Design decisions

Explain decisions around:

```txt
settings repository
progress repository
storage package choice
session result recording
streak / XP calculation
app dependency injection
```

## 5. Dependencies added

List dependencies added to `pubspec.yaml`.

If none were added, say:

```txt
No external dependencies added.
```

If `shared_preferences` or another package was added, explain why it is appropriate for MVP_004.

## 6. How to run

Provide exact commands:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## 7. Known limitations

Clearly state limitations, for example:

```txt
- Progress is local only.
- Session results are simple snapshots, not full review history.
- No FSRS intervals or due dates yet.
- Deck data is still mock/in-memory.
- Import remains placeholder-only.
```

## 8. Manual test checklist

Return a checklist we can use:

```txt
[ ] App launches successfully
[ ] Changing theme updates the app immediately
[ ] Selected theme survives app restart
[ ] Complete a review session
[ ] Progress screen reflects completed session
[ ] XP and level are calculated from stored progress
[ ] Last session summary appears after review
[ ] No-progress state appears before any session, if storage is empty
[ ] Existing deck library/detail/review flows still work
[ ] Import placeholder still works
[ ] Widget/unit tests pass
```

## 9. Recommendation for next MVP

Suggest the next smallest implementation step.

Expected candidates:

```txt
MVP_005: JSON Deck Import
MVP_005: Basic Due Queue and Review State
MVP_005: First Real Gamification Badges
```

Do not start the next MVP without approval.

---

# Acceptance criteria

MVP_004 is complete when:

```txt
[ ] Selected app theme is persisted locally.
[ ] Review session result is saved on completion.
[ ] Progress screen reads from a repository instead of fixed mock values.
[ ] Progress screen shows meaningful no-progress state when appropriate.
[ ] XP / level / cards reviewed today are based on stored local data.
[ ] Existing review session flow still works.
[ ] Existing deck library and deck detail flow still works.
[ ] Repositories are injectable/testable.
[ ] Tests cover theme persistence and progress recording.
[ ] No real FSRS, import, accounts, or cloud sync are introduced.
[ ] The agent returns the approval report above.
```
