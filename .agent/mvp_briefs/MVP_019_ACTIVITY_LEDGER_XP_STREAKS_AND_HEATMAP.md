# MVP_019 — Activity Ledger, XP, Streaks & Heatmap

## Status

Ready for implementation.

## Why this MVP exists

MVP_015 gave Decko a first motivational layer: XP, a daily goal, kinder streak language, achievement badges, and completion rewards.

MVP_016 and MVP_018 then proved that Decko can support game-like practice modes while keeping FSRS and Anki-style review state safe.

The next step is to stop treating progress as only a snapshot and introduce a real local activity history. Decko needs a durable, queryable ledger of what the learner actually did over time.

This MVP creates the foundation for:

- proper XP
- streak history
- daily activity heatmap
- session history
- review vs practice breakdowns
- future achievement unlocks
- future Firebase/cloud sync

## Core mission

Build a proper local activity ledger that records review and practice events over time, then derive XP, streaks, daily goals, achievements, and heatmap data from that ledger.

## Product principle

Review state answers:

> When is this card due?

Activity history answers:

> What did I do, earn, practise, and build over time?

These must remain separate.

## Non-negotiable safety rule

This MVP must not alter scheduling correctness.

Do not change:

- FSRS scheduling maths
- due queue ordering
- per-card review state semantics
- daily review/new counters
- sibling burying
- imported progress preservation
- LearningItem.id stability
- keep-progress / start-fresh import semantics

Activity events may be recorded when review or practice actions happen, but the activity ledger must not decide card due state.

## Key distinction

Decko should have two separate data layers:

```text
ReviewState / ReviewCardState
  -> scheduling, due dates, FSRS, Anki-parity learning correctness

ActivityLedger / ActivityEvent
  -> XP, streaks, heatmap, achievements, user motivation, history
```

## Scope

### 1. Add ActivityEvent domain model

Create a domain model capable of recording meaningful study activity.

Suggested fields:

```dart
class ActivityEvent {
  final String id;
  final DateTime occurredAt;
  final ActivitySource source;
  final String modeId;
  final String? deckId;
  final String? learningItemId;
  final ActivityOutcome outcome;
  final int xpAwarded;
  final Duration? duration;
  final Map<String, Object?> metadata;
}
```

Suggested enums:

```dart
enum ActivitySource {
  review,
  manualPractice,
  deckPractice,
  scheduledPractice,
}

enum ActivityOutcome {
  completed,
  correct,
  incorrect,
  abandoned,
}
```

Mode IDs should align with existing mode identifiers:

- `standard_review`
- `bunburu_sentence_builder`
- `listening_challenge`

### 2. Add ActivityLedgerRepository

Create a repository seam for storing and querying activity events.

Suggested API:

```dart
abstract class ActivityLedgerRepository {
  Future<void> record(ActivityEvent event);
  Future<List<ActivityEvent>> eventsBetween(DateTime start, DateTime end);
  Future<List<ActivityEvent>> recentEvents({int limit = 50});
  Future<List<ActivityEvent>> allEvents();
}
```

For this MVP, local persistence is enough.

SharedPreferences may be acceptable for a small first implementation, but the design should be migration-ready. If a file-backed JSON store already fits the app better, use that.

Do not introduce Firebase in this MVP.

### 3. Record review activity

When a review session completes or review answers are submitted, record activity events without changing review semantics.

Minimum acceptable approach:

- record one event per answered review card, or
- record one event per completed review session with enough metadata to derive totals

Prefer the model that will best support a future heatmap and mode breakdown.

Review XP should be derived consistently from review activity.

### 4. Record practice-mode activity

Manual and deck-level practice modes should record activity events.

At minimum:

- Bunburu completion records a practice event
- Listening Challenge completion records a practice event
- XP is recorded as practice XP
- practice does not mutate review state

Scheduled review presentation, if later enabled for a mode, must still grade through `ReviewScheduler` and should be clearly distinguishable in the activity source.

### 5. Derive progress from activity

Introduce a derived progress service or helper that can answer:

- total XP
- review XP
- practice XP
- XP today
- cards reviewed today
- practice rounds today
- current streak
- longest streak
- daily goal progress
- achievements earned
- recent activity

The old `ProgressSnapshot` can remain as a compatibility layer during this MVP, but the direction should be clear: motivational progress should increasingly come from the activity ledger.

Do not break existing UI while migrating.

### 6. Heatmap data

Add a heatmap-friendly derived model.

Suggested shape:

```dart
class ActivityDay {
  final DateTime day;
  final int xp;
  final int reviewCount;
  final int practiceCount;
  final int totalEvents;
}
```

The heatmap should group events by local calendar day.

For MVP_019, a simple visual heatmap is enough:

- last 7 days, 30 days, or 12 weeks
- intensity based on XP or event count
- empty days visible
- today clearly included

Do not overbuild calendar controls.

### 7. Progress screen upgrade

Update the Progress screen to use the activity-backed model where possible.

It should show:

- total XP
- review XP vs practice XP
- daily goal progress
- current streak
- longest streak
- heatmap
- recent activity summary
- achievement state

Keep the design beautiful and Decko-native. Do not ship a stock analytics dashboard.

### 8. Achievement unlocks

Achievements should be derived from activity history rather than only from a snapshot.

For this MVP, keep the existing small achievement set, but make it ledger-backed where possible:

- First review
- Daily goal reached
- 3-day streak
- 100 cards / reviews / meaningful activity milestone

If unlock timestamps are introduced, they must be migration-safe.

### 9. Settings / daily goal compatibility

Keep the existing daily goal setting from MVP_015.

Daily goal should now be calculated from activity-backed XP or event counts.

Clarify in code/docs whether daily goal is XP-based or card/activity-count-based. Prefer XP-based if it better unifies review and practice.

### 10. Migration strategy

Existing users may already have a `ProgressSnapshot` but no activity ledger.

Implement a safe migration/backfill strategy:

- do not erase existing XP/streak values
- do not create fake per-card history that did not happen
- if needed, create one legacy summary event or preserve old snapshot as a baseline
- document the limitation clearly

Possible approach:

```text
Legacy progress snapshot remains as a baseline.
New activity events accumulate from MVP_019 onward.
Derived progress = legacy baseline + activity ledger after migration.
```

The exact implementation may differ, but the outcome must be safe and honest.

## Out of scope

Do not implement:

- Firebase Auth
- Firestore sync
- account system
- subscription logic
- cloud backup
- social leaderboards
- competitive ranking
- new game modes
- typing recall mode
- match mode
- changes to FSRS
- changes to import behaviour

Firebase/Auth is expected after this MVP, likely MVP_020.

## Expected files / areas

Likely new files:

```text
lib/domain/activity_event.dart
lib/domain/activity_day.dart
lib/domain/repositories/activity_ledger_repository.dart
lib/data/local_activity_ledger_repository.dart
lib/domain/activity_progress.dart
lib/domain/activity_progress_calculator.dart
lib/features/progress/widgets/activity_heatmap.dart
lib/features/progress/widgets/recent_activity_list.dart
test/activity_ledger_test.dart
test/activity_progress_test.dart
```

Likely changed files:

```text
lib/domain/progress_snapshot.dart
lib/data/shared_prefs_progress_repository.dart
lib/features/progress/progress_screen.dart
lib/features/review/review_session_screen.dart
lib/features/review/widgets/session_summary.dart
lib/features/practice/practice_launcher.dart
lib/features/practice/practice_hub_screen.dart
lib/features/bunburu/...
lib/features/listening_challenge/...
lib/decko_app.dart
docs/DECISIONS.md
docs/ROADMAP.md
docs/UI_REGISTRY.md
memory.md
```

Use the actual existing file paths if they differ.

## Acceptance criteria

MVP_019 is complete when:

- [ ] ActivityEvent domain model exists.
- [ ] ActivityLedgerRepository seam exists.
- [ ] Local activity ledger persistence exists.
- [ ] Review activity is recorded without altering review scheduling.
- [ ] Bunburu/manual practice activity is recorded without altering review state.
- [ ] Listening Challenge/manual practice activity is recorded without altering review state.
- [ ] XP can be derived from activity events.
- [ ] Review XP and practice XP are distinguishable.
- [ ] Streaks are derived from activity days.
- [ ] Longest streak is preserved or derived safely.
- [ ] Daily goal progress uses the new activity-backed model.
- [ ] Progress screen includes a heatmap or heatmap-ready visual calendar.
- [ ] Recent activity is visible somewhere in Progress.
- [ ] Existing progress data is migrated or preserved safely.
- [ ] No FSRS, due queue, daily counter, sibling burying, or import-progress semantics are changed.
- [ ] Tests cover event serialization, XP derivation, streak derivation, heatmap grouping, and migration/backfill.
- [ ] Widget tests cover the heatmap/progress UI in empty and non-empty states.
- [ ] `flutter analyze` is clean.
- [ ] Existing tests pass.

## Decision record

Add a decision record, likely:

```text
DEC-028 — Activity ledger separates motivational progress from review scheduling
```

It should state:

- review state remains the source of truth for due scheduling
- activity ledger is the source of truth for XP/streaks/heatmap/history
- practice activity may reward motivation but must not mutate FSRS state unless it is explicitly a scheduled review presentation graded through the ReviewScheduler seam
- local ledger design prepares for future Firebase sync

## Memory update

After completion, update `memory.md` with:

- MVP_019 complete
- activity ledger added
- XP/streaks/heatmap are activity-backed
- review state and activity history remain separate
- tests/analyze status
- next recommended MVP: Auth & Firebase Sync Foundation

## Next likely MVP

```text
MVP_020 — Auth & Firebase Sync Foundation
```

Reason:

Once activity history exists locally, Decko has a clean progress model to sync across devices.

Auth and Firebase should sync the local-first model, not define it.