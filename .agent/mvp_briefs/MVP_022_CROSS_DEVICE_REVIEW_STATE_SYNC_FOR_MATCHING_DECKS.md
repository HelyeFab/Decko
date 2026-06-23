# MVP_022 — Cross-Device Review State Sync for Matching Decks

## Status

Proposed.

## Why this MVP exists

MVP_020 introduced the Auth and Firebase sync foundation, but deliberately limited sync to low-risk data: profile, safe settings, and the activity ledger.

That was the correct first sync boundary, but it is not enough for the user experience Decko needs.

A learner expects this:

```text
Device A:
Import deck → study cards → FSRS/review state changes.

Device B:
Import the same deck → Decko recognises it → the same review progress appears.
```

Decko should not sync deck packages, media blobs, or imported Anki content in this MVP. However, if the same deck and same cards are present locally on more than one device, Decko should be able to sync the user’s review state for those matching cards.

This is the missing bridge between “safe sync foundation” and “seamless cross-device learning”.

## Core mission

Allow users to move between devices by syncing review/progress state for decks that are already present locally and can be confidently matched, without syncing deck content or media.

## Product promise

```text
Import the same deck on another device, sign in, and continue studying where you left off.
```

## Non-negotiable architecture rule

```text
Decko syncs user state for matching decks.
Decko does not sync deck content in this MVP.
```

A synced review state may only attach to a local deck/card when Decko can confidently prove it is the same imported source/card identity.

## Existing foundations this MVP builds on

- Imported Anki card IDs are stable via `LearningItem.id = anki-card-<cardId>`.
- Imported progress must never be silently reset.
- `ReviewCardState` already holds per-card review/FSRS scheduling data.
- MVP_019 introduced the local activity ledger.
- MVP_020 introduced Auth/Firebase sync foundation.
- Decko already separates:
  - deck/card content
  - review scheduling state
  - activity/motivation history
  - practice-mode outcomes

## In scope

### 1. Deck identity / fingerprinting

Add a durable imported-deck identity layer.

Suggested model:

```dart
class DeckFingerprint {
  final String fingerprintVersion;
  final String sourceSystem; // anki
  final String sourceDeckName;
  final String? sourceDeckId;
  final int cardCount;
  final int noteCount;
  final String cardIdHash;
  final String noteIdHash;
  final String? packageHash;
  final String? modelHash;
}
```

The exact fields may vary, but the goal is stable matching across devices when the same deck is imported.

A good first-pass fingerprint should consider:

- Anki deck ID when available.
- Imported card IDs.
- Imported note IDs.
- Card count and note count.
- Model/template identity where available.
- Optional package/content hash if cheaply available.

### 2. Card identity matching

Decko should sync review state only when local card identity matches synced card identity.

For imported Anki decks, the safest initial card key remains:

```text
anki-card-<cardId>
```

If a card is not present locally, its synced state remains in cloud storage but is not applied.

### 3. Syncable review-state model

Create a cloud-safe representation of the review state needed to continue studying:

- queue/state kind
- due date
- interval
- lapses
- reps
- ease/stability/difficulty where present
- last reviewed timestamp
- source system metadata
- scheduler version / FSRS version if available
- updatedAt / deviceId metadata

This may be a DTO rather than the exact persistence model.

### 4. Firebase path for deck review state

Suggested structure:

```text
/users/{uid}/deckStates/{deckFingerprint}/cards/{learningItemId}
```

or equivalent.

The cloud key must be based on the stable deck identity, not on a local database path.

### 5. Attach synced state to a matching local deck

When a local imported deck matches a cloud deck fingerprint:

- show that synced progress is available;
- allow Decko to apply it safely;
- apply review state only for matching card IDs;
- leave unmatched local cards untouched;
- leave unmatched cloud card states unapplied but preserved.

This may be automatic if the match is high-confidence, or an explicit user confirmation if confidence is lower.

### 6. Import/re-import UX

After importing a deck, Decko should check whether cloud state exists for a matching deck.

Possible states:

```text
Synced progress found
We found review progress for this deck from another device.
Apply it now?

Already in sync
This deck’s review progress is synced.

No synced progress yet
Study this deck and Decko will sync your progress.

Similar deck found
This looks similar to a synced deck, but not similar enough to apply automatically.
```

### 7. Conflict-safe merge policy

This MVP must define and implement a simple, safe merge policy.

Recommended first rule:

```text
For the same card, the newer review-state update wins if it was produced by a normal review answer.
```

But be careful:

- never replace a more advanced local state with an older cloud state;
- never reset reps/lapses/stability/difficulty silently;
- preserve local state if cloud state is missing or incomplete;
- log or surface conflict cases where confidence is low.

A practical MVP may implement:

```text
latest reviewedAt / updatedAt wins,
with monotonic safeguards for reps/lapses where possible.
```

### 8. Sync status visibility

Add a small amount of UI so users understand what is happening:

- deck detail sync badge/status;
- account/sync page entry for review-state sync;
- “last synced” or “sync pending” where appropriate;
- clear explanation that deck files/media are not synced yet.

### 9. Tests

Add tests for:

- deterministic deck fingerprint generation;
- same deck imported on two devices produces same fingerprint;
- different decks do not collide in obvious cases;
- review state serialisation/deserialisation;
- applying cloud state to matching cards only;
- not applying state to non-matching cards;
- conflict policy;
- no mutation of deck/media/content data;
- no silent reset of existing review state.

## Out of scope

- Syncing `.apkg` packages.
- Syncing media files.
- Syncing images/audio blobs.
- Reconstructing decks from cloud state.
- Full deck backup/restore.
- Cross-user sharing.
- Collaborative decks.
- Subscription limits.
- Server-side FSRS scheduling.
- Changing FSRS math.
- Changing due queue policy.
- Changing daily limits or sibling burying.
- Syncing unsupported non-imported/demo decks unless they have stable identity.

## Explicit safety boundaries

### Safe to sync in MVP_022

```text
- deck fingerprint metadata
- per-card review state for matching local cards
- FSRS state values attached to those cards
- due dates / intervals / reps / lapses
- sync timestamps and device metadata
```

### Not synced in MVP_022

```text
- deck content
- imported source notes
- media files
- images/audio
- raw .apkg files
- card templates
- note models
```

## Acceptance criteria

MVP_022 is complete when:

- A deck fingerprint is generated and persisted for imported Anki decks.
- Review state can be serialised to a cloud-safe model.
- Review state can be uploaded for a signed-in user.
- A second device importing the same deck can detect matching cloud review state.
- Matching card review states can be applied locally.
- Non-matching card states are ignored/preserved, not forced.
- Deck/media/content are not synced.
- The user can see whether a deck is synced or has synced progress available.
- Existing local review state is never silently reset.
- Tests cover matching, non-matching, merge, and safety cases.
- `flutter analyze` is clean.
- Existing tests pass.

## Recommended decision record

Create:

```text
docs/decisions/DEC-030-sync-user-review-state-not-deck-content.md
```

Suggested decision title:

```text
DEC-030 — Sync User Review State, Not Deck Content
```

Decision summary:

```text
Decko syncs review/FSRS user state only for decks and cards that are already present locally and can be confidently matched. Deck packages, media, and imported source content are not synced in this phase.
```

## Implementation notes for agents

- Start by reading the current review-state persistence layer.
- Identify the existing stable imported-card identity seam.
- Add deck fingerprinting before Firebase writes.
- Prefer pure domain tests for fingerprinting and merge policy before wiring Firebase.
- Keep cloud DTOs separate from local persistence models if that avoids coupling.
- Do not make deck content sync “just for convenience”.
- Do not add automatic destructive merge logic.
- Update `.agent/skills/` only if this MVP changes how future agents should operate.

## Suggested next MVP

```text
MVP_023 — Sync Status, Conflict UX & Recovery Polish
```

Why: once review-state sync works, Decko will need better user-facing explanations for sync conflicts, pending uploads, offline behaviour, and recovery flows.
