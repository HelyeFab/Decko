# MVP_026 — Import Recovery, Duplicate Import & Re-import Polish

## Status

Planned.

This MVP is part of the store-readiness path after MVP_025.

## Mission

Make Decko’s import and re-import experience safe, understandable, and recoverable for real users.

A user should never feel that importing, cancelling, retrying, deleting, or re-importing a deck could accidentally destroy their learning progress.

## Product promise protected by this MVP

```text
Import your deck. Study it beautifully.
```

For that promise to be trustworthy, import must feel calm and reversible, especially for users bringing valuable Anki decks with existing progress.

## Background

Decko already supports:

- Anki `.apkg` import.
- Modern package compatibility including `collection.anki21b` / zstd.
- Lossless source preservation.
- Media import and cleanup.
- Progress-aware import choices.
- Persistent FSRS review state.
- Cross-device review-state sync for matching decks.
- Import diagnostics and reports.

The next gap is not raw import capability. The next gap is **import lifecycle safety**.

Real users will:

- import the same deck twice;
- re-export an updated version from Anki;
- cancel imports midway;
- import a broken deck;
- delete a deck and later re-import it;
- run out of storage during media extraction;
- wonder whether synced progress will reattach;
- wonder whether existing local progress will be replaced.

Decko must handle these situations explicitly and safely.

## Core principle

```text
Never lose or overwrite review progress during import, duplicate import, or re-import.
```

Decko may replace deck content only after a clear user choice.

Decko may attach review state only when card identity is confidently matched.

Decko must never silently reset FSRS, due dates, lapses, reps, intervals, imported progress, synced review state, or activity history.

## Scope

### 1. Duplicate import detection

When a user imports a deck that appears to already exist locally, Decko should detect this before committing the import.

Detection should use the strongest available signals:

- `DeckFingerprint` where available.
- Original Anki deck ID/name where available.
- Stable imported card IDs.
- Card count similarity.
- Package/source metadata.
- Existing Decko import metadata.

The result should be classified as one of:

```text
- new deck
- likely duplicate
- likely updated version of existing deck
- uncertain match
```

### 2. Duplicate import UX

When a likely duplicate is detected, show a clear Decko-styled confirmation screen or panel.

Possible actions:

```text
Keep existing deck
Import as a separate copy
Update existing deck
Cancel
```

For MVP_026, `Update existing deck` may be limited if true content reconciliation is too risky. If so, the UI must be honest and use safe wording such as:

```text
This looks like a deck you already imported. You can keep both copies for now, or cancel and continue studying the existing deck.
```

Do not offer a destructive replace action unless it is fully safe.

### 3. Re-import safety

If the user re-imports the same deck, Decko should preserve or reattach:

- review state;
- FSRS state;
- due dates;
- queue state;
- lapses/reps;
- imported progress choices;
- synced review state if the deck fingerprint/card IDs match.

Re-import must continue using stable card IDs:

```text
LearningItem.id = anki-card-<cardId>
```

If a card exists in both the old and new import, its state must be retained.

If a card is new, it starts as new.

If a card no longer exists, its state should not be immediately destroyed unless the user explicitly confirms cleanup.

### 4. Failed import recovery

Improve handling for failed imports.

Failures should leave no half-imported deck visible as if it were usable.

Decko should:

- clean temporary files after failure;
- avoid orphaned media directories where practical;
- show a friendly failure summary;
- preserve technical diagnostics behind disclosure;
- offer retry where appropriate;
- keep existing decks and progress untouched.

Failure examples:

```text
- unsupported package
- corrupted package
- invalid SQLite database
- missing collection file
- media extraction failure
- low storage / write failure
- user cancellation
```

### 5. Import cancellation safety

If the user cancels file picking or backs out before commit, Decko must not create deck records, media folders, review states, or import reports.

If cancellation occurs during a long import, Decko should either:

- safely abort and clean up; or
- finish the current atomic step and then stop before commit.

No partial deck should appear as successfully imported.

### 6. Media and storage edge cases

Handle media-related partial failures more clearly.

Examples:

- some media missing from package;
- some media references unresolved;
- media extraction partially fails;
- not enough device storage;
- media cleanup after delete/re-import.

The user-facing message should distinguish:

```text
The deck can still be studied, but some media is missing.
```

from:

```text
This import could not be completed safely.
```

### 7. Import history / report access

Deck detail already has import report access for newer imports.

MVP_026 should make sure duplicate/re-import decisions are reflected in the report where useful:

- imported as new deck;
- likely duplicate detected;
- re-imported/updated from matching source;
- synced progress available;
- synced progress applied or not applied;
- media warnings;
- cleanup recommendations.

### 8. Sync-aware re-import messaging

If a user imports a matching deck on a signed-in device and cloud review state exists, Decko should explain:

```text
Synced progress was found for this deck.
You can apply it after import.
```

Do not automatically apply synced progress.

This must remain aligned with MVP_022 and MVP_023:

- matching deck review-state sync exists;
- cloud-to-local apply is explicit;
- deck content/media are not synced;
- local progress is never silently overwritten.

## Out of scope

Do not add:

- automatic cloud sync of deck content;
- automatic cloud sync of media files;
- full Anki two-way sync;
- editing imported cards;
- AnkiWeb integration;
- destructive replace without explicit safe design;
- FSRS algorithm changes;
- scheduler changes;
- due queue changes;
- daily counter changes;
- sibling burying changes;
- new practice modes.

## Required UX states

MVP_026 should include polished user-facing states for:

```text
- New deck import
- Duplicate detected
- Possible updated version detected
- Import cancelled
- Import failed safely
- Import completed with warnings
- Import completed cleanly
- Synced progress available after import
- Existing local progress preserved
```

## Data and architecture expectations

Potential new or extended models:

```text
ImportIdentityMatch
ImportLifecycleState
ImportCommitPlan
ImportRecoveryReport
DuplicateImportDecision
ReimportDecision
ImportCleanupResult
```

Potential service boundaries:

```text
ImportIdentityMatcher
ImportCommitPlanner
ImportRecoveryService
ImportCleanupService
```

Names are flexible, but responsibilities should remain clear.

## Acceptance criteria

MVP_026 is complete when:

- Duplicate imports are detected before commit where confident.
- The user is shown a clear choice when a duplicate or likely update is detected.
- Re-importing the same deck does not silently reset local review state.
- Existing card review state is preserved when stable card IDs match.
- New cards are treated as new.
- Removed cards do not cause immediate destructive state deletion without explicit cleanup.
- Failed imports leave no visible half-imported deck.
- Cancelled imports do not create decks/media/review state.
- Media/storage errors are separated into warning vs blocking states.
- Import reports reflect meaningful duplicate/re-import outcomes.
- Synced progress messaging remains explicit and safe.
- Deck/media cloud sync is not introduced.
- FSRS, scheduler, due queue, daily limits, and sibling burying remain unchanged.
- Tests cover duplicate import, re-import, cancellation, failed import, and warning import cases.
- `flutter analyze` passes.

## Testing expectations

Add tests for:

```text
- importing a new deck
- importing the same deck twice
- importing a deck with same fingerprint/card IDs
- importing a deck with overlapping but not identical cards
- preserving ReviewCardState across re-import
- new cards starting as new
- removed cards not deleting state by default
- cancellation before commit
- failure before commit
- partial media warning
- blocking media/storage failure
- sync-progress-available messaging
```

## Documentation updates

Update, as appropriate:

- `docs/DECISIONS.md`
- `docs/ROADMAP.md`
- `docs/STORE_READINESS_ROADMAP.md`
- `docs/UI_REGISTRY.md` if new UI components are added
- `memory.md`

## Suggested decision record

```text
DEC-035 — Import and Re-import Must Preserve Learning State
```

Decision summary:

```text
Decko treats import/re-import as a planned commit operation. Duplicate and re-import cases must be detected before commit where possible, and existing review state must be preserved whenever stable card identity matches. Failed or cancelled imports must not leave partial decks or reset learning state.
```

## Success definition

A user can safely import, cancel, retry, duplicate, or re-import a deck without fearing that Decko will lose their progress.

Decko should feel calm, honest, and protective of the learner’s history.