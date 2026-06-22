# MVP_020 — Auth & Firebase Sync Foundation

## Status

Planned.

## Context

Decko has moved from import correctness into a real learning platform:

- Anki import preserves progress and source data.
- FSRS and the due queue are protected behind the review scheduler seam.
- Practice modes now exist through `PracticeModeRegistry` and `PracticeLauncher`.
- Bunburu and Listening Challenge can award motivational practice progress without touching review state.
- MVP_019 introduces the Activity Ledger as the proper local source for XP, streaks, heatmap data, achievements, and practice history.

MVP_020 should introduce authentication and Firebase sync in a deliberately narrow, safe way.

The goal is not to sync everything immediately. The goal is to create the correct cloud identity and sync foundation so Decko can later support cross-device learning without risking imported Anki progress, FSRS scheduling state, or local deck integrity.

## Product Promise

Users should be able to sign in and begin protecting their Decko progress across devices, while Decko remains fully usable offline and without an account.

## Core Mission

Add a local-first Auth and Firebase sync foundation for user profile, settings, and the MVP_019 activity ledger, without syncing or mutating review scheduling state in this MVP.

## Architectural Principle

```text
Local-first stays the default.
Cloud sync protects user history.
Cloud sync must not silently rewrite learning state.
```

Decko now has two different kinds of state:

```text
Review state / imported deck state
  -> FSRS, due dates, imported progress, card IDs, deck data, media
  -> high-risk learning correctness data
  -> NOT synced in MVP_020

Activity state
  -> XP, streaks, heatmap, achievements, practice history
  -> motivational/user-history data
  -> synced in MVP_020
```

## Required Decision Record

Create a decision record, likely:

```text
DEC-029 — Local-First Auth and Activity Sync Boundary
```

The decision must state:

- Firebase Auth creates a user identity for sync.
- MVP_020 syncs user profile, app settings, and activity ledger events.
- MVP_020 does **not** sync imported decks, media, FSRS state, review card state, due queues, or Anki-derived progress.
- Review correctness remains local and protected until a later dedicated review-state sync MVP.
- Sync must be additive/idempotent where possible.
- Conflicts must not silently delete local data.

## In Scope

### 1. Firebase project wiring

Add Firebase client configuration for Flutter.

Requirements:

- Add Firebase dependencies required for Auth and Firestore.
- Keep platform configuration clean and documented.
- Do not commit secrets that should remain private.
- Add clear setup notes if generated platform files are required.

Likely packages:

```text
firebase_core
firebase_auth
cloud_firestore
```

Firebase Storage may be added only as a placeholder/foundation if needed, but this MVP must not upload deck packages or media files yet.

### 2. Auth domain seam

Create an auth abstraction rather than letting screens call Firebase directly.

Suggested domain types:

```text
DeckoUser
AuthState
AuthRepository
```

`DeckoUser` should include:

```text
uid
email optional
displayName optional
isAnonymous / isSignedIn
createdAt optional
```

`AuthRepository` should support at minimum:

```text
currentUser / authState stream
signInAnonymously or continue local-only
signInWithEmailAndPassword if practical
createAccountWithEmailAndPassword if practical
signOut
```

If Google sign-in is added, it must be treated as optional and must not block the MVP.

### 3. Account / Sync screen

Add a clear user-facing screen for identity and sync state.

Possible route:

```text
/settings/account
```

The screen should show:

- Current mode: local-only / signed in / anonymous cloud identity.
- User email or anonymous status.
- Last sync time, if available.
- Sync status: idle / syncing / error.
- Clear explanation that review scheduling remains local in this MVP.
- Sign in / create account / sign out actions.

This should be branded Decko UI, not stock Firebase-looking UI.

### 4. Sync domain seam

Create a sync abstraction.

Suggested types:

```text
SyncStatus
SyncResult
SyncRepository
CloudActivityRepository
```

The seam must make future sync expansion possible without tying app logic directly to Firestore.

### 5. Activity ledger sync

MVP_019 activity events become the first serious sync target.

Sync:

```text
ActivityEvent
DailyActivitySummary if already materialized
Achievement unlocks if stored as events
Daily goal setting if part of settings
```

Preferred model:

```text
/users/{uid}/activityEvents/{eventId}
/users/{uid}/settings/app
/users/{uid}/profile/main
```

Activity sync must be idempotent:

- Event IDs should be stable.
- Uploading the same event twice must not create duplicate progress.
- Downloading cloud events should merge with local events without deleting local-only events.

### 6. Settings sync

Sync safe user settings only:

```text
selected app theme
daily goal
furigana preference if global
other non-sensitive app preferences
```

Do not sync deck-specific study options unless the existing model is clearly stable and safe.

If deck-specific settings are synced, they must be keyed by stable deck IDs and must not alter imported progress.

### 7. Sync status and error handling

The user should not need to understand Firebase.

Required states:

```text
Not signed in
Signed in, sync idle
Syncing
Synced
Sync failed
Offline / will retry
```

Errors must be friendly and recoverable.

### 8. Offline-first behaviour

Decko must remain usable without network and without authentication.

Acceptance rule:

```text
Opening Decko, importing decks, reviewing cards, and using practice modes must still work when signed out or offline.
```

Activity events created offline should remain local and be eligible for later upload.

### 9. Tests

Add tests for:

- Auth repository fake implementation.
- Sync repository merge/idempotency behaviour.
- Activity event upload/download mapping.
- Settings sync mapping.
- Account screen states.
- Offline/signed-out path.
- No review-state mutation from sync.

## Out of Scope

This MVP must **not** implement:

- Full deck sync.
- Imported `.apkg` backup/upload.
- Media file sync.
- FSRS state sync.
- ReviewCardState sync.
- Due queue sync.
- Cross-device conflict resolution for review scheduling.
- Stripe subscriptions.
- Premium gating.
- Push notifications.
- Social/community features.

These can come later after the cloud identity and activity-sync foundation is stable.

## Non-Negotiable Safety Rules

### 1. Never silently reset imported progress

This remains a permanent rule.

```text
Cloud sync must not overwrite imported Anki progress or FSRS review state.
```

### 2. Sync cannot decide what is due

```text
ReviewScheduler remains the only path for due/review mutations.
```

### 3. Activity sync is not review sync

```text
Syncing XP/streak/history must not imply syncing card due dates.
```

### 4. Local data wins over destructive cloud operations

If conflict handling is incomplete, choose additive merge and warn rather than delete.

## Suggested Implementation Shape

```text
lib/domain/auth/
  decko_user.dart
  auth_repository.dart
  auth_state.dart

lib/data/firebase/
  firebase_auth_repository.dart
  firestore_activity_sync_repository.dart
  firestore_settings_sync_repository.dart

lib/domain/sync/
  sync_status.dart
  sync_repository.dart
  sync_result.dart

lib/features/account/
  account_screen.dart
  widgets/

lib/features/settings/
  settings_hub_screen.dart  // add Account / Sync entry
```

Use fake/in-memory repositories heavily in tests.

## Firestore Draft Shape

```text
/users/{uid}/profile/main
  uid
  email
  displayName
  createdAt
  updatedAt

/users/{uid}/settings/app
  dailyGoal
  selectedThemeId
  furiganaEnabled
  updatedAt

/users/{uid}/activityEvents/{eventId}
  id
  occurredAt
  source
  mode
  deckId
  learningItemId
  outcome
  xpAwarded
  durationMs
  clientCreatedAt
  clientUpdatedAt
```

Do not store raw imported card content in this MVP unless already needed by an activity event summary. Prefer IDs and metadata only.

## User Experience Acceptance Criteria

A user can:

- Continue using Decko fully without signing in.
- Open Settings → Account / Sync.
- See whether Decko is local-only or signed in.
- Sign in or create an account if supported in this pass.
- See a friendly sync status.
- Complete reviews/practice offline without losing local progress.
- Later sync activity events when signed in.

A user must not:

- Be forced to sign in to import or review.
- See review progress reset after signing in.
- See imported decks disappear because cloud sync is empty.
- Need to understand Firestore/Firebase terminology.

## Developer Acceptance Criteria

- Firebase is behind repository seams.
- Tests can run without hitting real Firebase.
- Activity sync is idempotent by event ID.
- Settings sync is safe and limited.
- Review state is untouched by sync.
- `flutter analyze` clean.
- Tests pass.

## Reporting Requirements

The MVP completion report must state:

- Which auth methods were implemented.
- Which collections/documents are used.
- Which local data is synced.
- Which local data is deliberately not synced.
- How duplicate activity events are prevented.
- How offline/local-only behaviour was verified.
- Confirmation that review state, FSRS, due queues, imported deck data, and media were not synced or mutated.
- Test count and analyze status.

## Suggested Next MVP

After MVP_020, likely candidates:

```text
MVP_021 — Typing Recall Mode
```

or, if sync needs strengthening first:

```text
MVP_021 — Review-State Cloud Sync Design & Safety Harness
```

Do not attempt review-state sync until the safety model is explicitly designed and tested.

## Agent Reminder

Update `.agent/skills/` only if this MVP changes how future agents should operate.
