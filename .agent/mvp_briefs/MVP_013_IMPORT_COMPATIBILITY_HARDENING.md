# MVP_013 — Import Compatibility Hardening

## Status

Ready for build.

## Context

MVP_009 made Anki import lossless at the source-data layer.
MVP_010 used that preserved source to map card templates into Decko modes such as Listening, Reading, and Production.
MVP_011 introduced study options and deck overrides.
MVP_012 added advanced deck option profiles, true daily study counters, and enforced sibling burying.

Decko can now import and study real Anki decks in a serious way, with preserved progress, FSRS scheduling, media, note-type-aware rendering, profile-driven options, and Anki-parity queue behaviours.

The next risk is not the study experience itself. The next risk is import reliability across the messy reality of Anki package formats and deck structures.

MVP_013 exists to harden Decko's import layer before moving into Decko-native gamification modes such as Bunburu.

## Product goal

Make Decko feel trustworthy with real-world Anki packages.

A user should be able to choose an Anki export and understand one of three outcomes clearly:

1. The deck imported successfully.
2. The deck imported with non-blocking warnings.
3. The deck cannot yet be imported, with a useful explanation rather than a crash or silent data loss.

## Core promise

Decko must never silently discard imported data or silently reset progress.

This MVP must preserve the existing import choice:

- Keep imported progress
- Start fresh

It must also keep the existing per-card identity rule:

```text
LearningItem.id = anki-card-<cardId>
```

Import hardening must not invalidate FSRS state for already-imported cards unless an explicit migration or re-import notice is provided.

## Scope

### 1. Modern Anki package detection

Add robust detection for common Anki export variants, including:

- legacy `.apkg` packages
- modern `.apkg` packages using newer internal collection formats
- `.anki21` / `.anki21b` collection files inside package exports, where applicable
- unsupported package structures

Decko should report the detected internal collection format in diagnostics.

### 2. Modern collection support where practical

Extend the importer to support newer Anki collection database files when feasible within this MVP.

At minimum, the importer should avoid treating modern packages as generic invalid files.

If full `.anki21b` support cannot be completed safely in this MVP, Decko must surface a clear unsupported-format message and record the gap in docs and memory.

### 3. Import diagnostics

Add a structured import diagnostics result that can describe:

- package type
- collection file found
- collection database version or detected schema variant, when available
- media manifest status
- number of decks found
- number of notes found
- number of cards found
- number of note types/models found
- number of templates found
- number of media entries found
- warnings
- blocking errors

Diagnostics should be available to the import preview and useful in tests.

### 4. Better failure states

Replace vague import failures with user-facing errors such as:

- No Anki collection database found in this package.
- This package uses a newer Anki collection format that Decko does not yet support.
- This package appears to be corrupted or incomplete.
- Media manifest is missing; the deck can still import but media may be unavailable.
- Collection opened, but required Anki tables were missing.

Do not expose raw SQLite exceptions as the primary user message.

### 5. Media edge-case hardening

Keep MVP_008 media import behaviour working, but harden edge cases:

- missing media manifest
- media manifest contains entries missing from the zip
- zip contains media not referenced by notes
- fields reference media that is not present
- duplicate or unusual media filenames
- image/audio references inside preserved fields

Missing media must degrade gracefully. The card should remain studyable.

### 6. Template and field edge-case hardening

Keep MVP_009 and MVP_010 behaviour working, but harden edge cases:

- note types with unusual field names
- note types with missing or empty templates
- cards whose template ordinal no longer maps cleanly
- notes with empty fields
- HTML-heavy fields
- fields containing multiple media references
- notes/cards from subdecks

Unknown note types should fall back to generic mapping rather than failing import.

### 7. Regression fixtures

Add focused import test fixtures for at least:

- a legacy `.apkg` that already works
- a package with media manifest anomalies
- a note type with multiple templates
- a note type with unfamiliar field names
- an unsupported or malformed package

If practical, add a fixture or mocked package for a modern `.anki21b` collection path.

Tests should verify not just success/failure, but also diagnostics and user-facing error quality.

### 8. Documentation and decisions

Update:

- `docs/DECISIONS.md`
- `docs/ROADMAP.md`
- `memory.md`

Add a decision if the MVP introduces a new import diagnostics model or a clear modern-package support boundary.

Possible decision title:

```text
DEC-023: Import diagnostics and modern Anki package compatibility boundary
```

Check the current decision number before assigning.

## Non-goals

Do not build Bunburu or other game modes in this MVP.

Do not change FSRS scheduling maths.

Do not redesign the review screen.

Do not implement cloud sync.

Do not attempt perfect Anki HTML/CSS rendering fidelity.

Do not silently migrate or rewrite imported deck state without an explicit safety path.

## Architecture constraints

The import layer should remain separated from the review experience.

Target shape:

```text
Anki package
  ↓
Package detector / diagnostics
  ↓
Collection reader
  ↓
Lossless source preservation
  ↓
Note-type-aware Decko mapping
  ↓
Decko review cards and media references
```

Existing responsibilities should remain intact:

- Import adapter reads and preserves source data.
- Media repository stores and resolves media.
- NoteTypeAwareCardMapper maps preserved source into Decko study cards.
- Scheduler uses existing review state and FSRS rules.

## Acceptance criteria

- [ ] Existing supported `.apkg` imports still work.
- [ ] Existing imported progress preservation still works.
- [ ] `LearningItem.id = anki-card-<cardId>` remains stable.
- [ ] Import preview can show useful diagnostics or warnings.
- [ ] Unsupported modern packages fail with a clear message, not a crash.
- [ ] Supported modern package variants import, if implemented in scope.
- [ ] Missing or inconsistent media does not block studying text cards.
- [ ] Unknown note types fall back to generic mapping.
- [ ] Multi-template note types still preserve and map distinct card templates.
- [ ] Import failures distinguish corrupted, unsupported, and incomplete packages where possible.
- [ ] Tests cover success, warning, and blocking-error import paths.
- [ ] Existing MVP_008–MVP_012 tests still pass.
- [ ] `flutter analyze` is clean.
- [ ] `memory.md` records MVP_013 completion status and the next step.

## Review checklist for the build report

The completion report must explicitly state:

- whether `.anki21b` is supported, partially supported, or still unsupported
- what import diagnostics were added
- whether any re-import is required for old decks
- whether media edge cases were tested
- whether note-type-aware mapping still works
- whether FSRS state/progress safety was preserved
- test count
- `flutter analyze` result

## Suggested next step after MVP_013

If MVP_013 completes modern import hardening successfully, the likely next MVP is:

```text
MVP_014 — Decko Progress & Light Gamification Polish
```

or, if import hardening reveals a major unresolved compatibility gap:

```text
MVP_014 — Remaining Anki Import Compatibility Pass
```

Bunburu sentence builder mode remains planned under Advanced Practice Modes after the Anki-parity import and scheduler foundation is trustworthy.

## Agent note

Update `.agent/skills/` only if this MVP changes how future agents should operate.
