# MVP_023 — Sync Status, Conflict UX & Account Polish

## Status

Ready for implementation.

## Context

Decko now has three sync layers in place:

1. **MVP_020 — Auth & Firebase Sync Foundation**
   - User account/auth foundation.
   - Safe sync for user profile, settings, and activity ledger.
   - Does not sync deck content, media, imported source, or review state.

2. **MVP_022 — Cross-Device Review State Sync for Matching Decks**
   - Syncs review/FSRS state for locally present matching decks.
   - Uses deterministic deck fingerprints and stable imported card ids.
   - Does not sync deck content or media.
   - Cloud-to-local review state apply is explicit, not silent.

3. **Existing import/review safety rules**
   - Never silently reset imported progress.
   - `LearningItem.id = anki-card-<cardId>` remains the imported card identity seam.
   - FSRS/review state must never be overwritten by unclear or unsafe sync.

The technical sync foundation now exists. The next problem is user trust: users need to understand what is synced, what is not synced, whether a deck is matched, whether progress is waiting to be applied, and whether there are conflicts or offline states.

## Core mission

Make Decko’s account and sync system visible, understandable, and trustworthy.

Users should be able to answer:

- Am I signed in?
- Is Decko syncing?
- When did this device last sync?
- Is my activity synced?
- Is this imported deck matched across devices?
- Is there synced review progress available for this deck?
- Is my local progress newer than the cloud state?
- What happens if I press “Apply synced progress”?
- What is not being synced yet?

## Product principle

Sync must feel calm and safe.

Decko should never make the user feel that their study progress could disappear or be overwritten silently.

## Architecture principle

Keep the existing sync boundary intact:

```text
Deck content / media / imported source
  -> not synced in this MVP

Activity ledger / profile / safe settings
  -> synced through MVP_020 infrastructure

Review state for matching local decks
  -> synced through MVP_022 infrastructure
  -> applied only with explicit user action when coming from cloud to local
```

## Non-negotiable safety rules

- Do not sync `.apkg` files.
- Do not sync media files.
- Do not sync imported Anki source data.
- Do not auto-create decks from cloud state.
- Do not apply cloud review state to a deck unless the local deck fingerprint/card identity match is confident.
- Do not silently overwrite local review state with cloud state.
- Do not mutate FSRS math, scheduler policy, due queue logic, daily counters, or sibling burying.
- Do not reset imported progress.

## Scope

### 1. Global sync status model

Add a small domain model representing global sync status.

Suggested shape:

```dart
enum SyncConnectionState {
  signedOut,
  online,
  offline,
  syncing,
  error,
}

class GlobalSyncStatus {
  final SyncConnectionState connectionState;
  final DateTime? lastSuccessfulSyncAt;
  final int pendingUploads;
  final int pendingApplies;
  final String? errorMessage;
}
```

This should describe the account/sync layer, not review scheduling.

### 2. Deck sync status model

Add a deck-level sync status concept for imported decks.

Suggested shape:

```dart
enum DeckSyncState {
  notImportedDeck,
  signedOut,
  notMatched,
  matchedUpToDate,
  localAhead,
  cloudAhead,
  conflict,
  offline,
  error,
}

class DeckSyncStatus {
  final String deckId;
  final String? deckFingerprint;
  final DeckSyncState state;
  final DateTime? lastPushedAt;
  final DateTime? lastPulledAt;
  final int cloudCardsAvailable;
  final int localCardsMatched;
  final int cardsWithCloudProgress;
  final String? explanation;
}
```

The model should be derivable from existing MVP_020/MVP_022 sync services where possible.

### 3. Account / Sync page polish

Improve the account/settings surface so users can see:

- signed-in email or account identity;
- last activity sync time;
- activity ledger sync state;
- review-state sync availability;
- what Decko syncs now;
- what Decko does not sync yet;
- manual sync button;
- offline/error state.

Suggested copy:

```text
Synced now
Your activity, XP, streaks, settings, and matching-deck review progress can sync across devices.

Not synced yet
Deck files, media, and imported Anki content stay local to each device. To continue a deck on another device, import the same deck there first.
```

### 4. Deck Detail sync status chip

Imported deck detail screens should show a clear sync chip/banner when signed in.

Examples:

```text
Synced
This deck’s review progress is up to date.
```

```text
Synced progress available
This looks like a deck you studied on another device. You can apply that progress here.
```

```text
Local progress newer
Your progress on this device is newer than the synced version.
```

```text
Not matched
Import the same deck on another device to sync review progress.
```

### 5. Improve “Apply synced progress” UX

MVP_022 added explicit cloud-to-local apply behavior. MVP_023 should make that flow more explanatory and safe.

Before applying, show:

- how many local cards match;
- how many cloud card states are available;
- what will happen;
- what will not happen;
- confirmation button.

Suggested copy:

```text
Apply synced progress?
Decko found review progress for this same deck from another device.

This will update the review state for matching cards only. It will not change the deck content, media, or card text.

Local progress that is newer or safer will not be overwritten.
```

### 6. Conflict and non-regression explanation

If local and cloud review states cannot be safely resolved, show a calm conflict message.

The user does not need raw timestamps or JSON. They need the conclusion:

```text
Decko kept your local progress
The progress on this device appears newer or safer than the synced version, so nothing was overwritten.
```

If possible, add a details expander for technical state:

- local updated at;
- cloud updated at;
- cards compared;
- cards applied;
- cards skipped.

### 7. Offline and Firebase unavailable states

Add friendly states for:

- signed out;
- offline;
- Firebase unavailable;
- sync failed but local data is safe;
- pending upload waiting for connection.

Suggested copy:

```text
Offline — studying still works
Decko will keep your progress locally and try to sync again when you are back online.
```

### 8. Import / re-import handoff messaging

When a user imports a deck and Decko detects matching cloud review state, the message should be clear.

Examples:

```text
Matching synced progress found
This deck appears to match a deck you studied on another device.
```

```text
No synced progress found
This deck is ready to study. Progress will sync after you review cards on this device.
```

This should not block import unless absolutely necessary.

### 9. Tests

Add tests for:

- global sync status derivation;
- deck sync status derivation;
- signed-out state;
- offline state;
- matched up-to-date state;
- cloud-ahead state;
- local-ahead state;
- conflict-safe explanation;
- “Apply synced progress” confirmation copy;
- deck detail sync chip/banner;
- account page sync copy;
- no review-state mutation from status display;
- no deck/media sync behavior added.

## Out of scope

- Full deck/content cloud sync.
- Media sync.
- `.apkg` cloud backup.
- Automatic deck reconstruction on a new device.
- Changing FSRS scheduling math.
- Changing due queue logic.
- Changing daily counters.
- Changing sibling burying.
- Adding a new game mode.
- Subscription/paywall enforcement.

## Required documentation updates

Update:

- `docs/DECISIONS.md`
- `docs/ROADMAP.md`
- `docs/UI_REGISTRY.md` if new sync UI components are added
- `memory.md`

Add a decision record.

Suggested decision:

```text
DEC-032 — Sync Status and Explicit Review-State Apply UX
```

Decision summary:

```text
Decko exposes sync status at global and deck level. Review-state sync for matching decks remains explicit and non-silent: cloud state may be applied only through a clear user action, and local progress is never overwritten when it appears newer or safer.
```

## Acceptance criteria

- A signed-in user can see account/global sync status.
- Imported deck detail screens show a clear deck-level sync status.
- The user can understand whether a deck is matched, up to date, cloud-ahead, local-ahead, conflicted, or offline.
- Applying synced progress is clearly explained before confirmation.
- Conflict handling is understandable in plain language.
- Offline sync state reassures the user that local study still works.
- Deck/media/content sync remains out of scope.
- Review-state sync remains tied to confident matching deck/card identity.
- No FSRS/scheduler/due queue behavior changes.
- Tests cover the new sync status and UX behavior.
- `flutter analyze` passes.

## Final report must include

- Files changed.
- New sync status models/services/widgets.
- Account page changes.
- Deck detail sync UX changes.
- Apply synced progress UX changes.
- Conflict/offline behavior.
- Safety statement confirming no deck/media/content sync was added.
- Safety statement confirming no FSRS/scheduler/due queue changes.
- Test count and analyze result.

## Next likely MVP

After MVP_023, Decko can safely return to feature expansion.

Likely options:

```text
MVP_024 — Match Mode / Vocabulary Pairing Game
```

or

```text
MVP_024 — Deck Import & Sync Onboarding Polish
```

Choose based on whether the app feels ready for another game mode or needs more onboarding clarity first.
