# MVP_014 — Import Validation & Diagnostics UX

## Status

Planned.

## Context

MVP_013 made Decko's Anki import layer much more capable:

- legacy `.apkg` import remains supported
- modern `.apkg` packages are detected and imported
- `collection.anki2`, `collection.anki21`, and `collection.anki21b` are supported
- zstd-compressed `collection.anki21b` packages are supported
- structured import diagnostics and package metadata now exist
- import warnings can identify package, media, field, and template concerns

The next problem is not raw format support. The next problem is trust.

A user importing a real Anki deck needs to understand what Decko found, what imported cleanly, what was approximated, what may need attention, and whether the deck is safe to study.

MVP_014 turns the diagnostics work from MVP_013 into a clear, calm, Decko-quality user experience.

## Product promise

> Import your deck. Study it beautifully.

For MVP_014 this means:

> Import your deck and know exactly what happened.

## Mission

Create a user-facing import validation and diagnostics experience that makes Decko's import results understandable, trustworthy, and actionable without exposing raw technical noise by default.

## Primary goals

1. Show a clear import health summary after preview/import.
2. Convert structured `ImportDiagnostics` into friendly, human-readable UI.
3. Distinguish between successful imports, warning imports, and blocking failures.
4. Make package format details understandable to non-technical users.
5. Explain media, field, template, and source-card warnings clearly.
6. Preserve the ability to inspect technical details when needed.
7. Keep the import flow beautiful and calm, not alarming or utilitarian.
8. Keep Anki-parity foundations stable: no progress reset, no scheduler changes, no FSRS changes.

## Non-goals

- Do not build new import engines unless a tiny parser change is needed to expose diagnostics.
- Do not change FSRS scheduling.
- Do not change review queue logic.
- Do not change daily limits or sibling burying.
- Do not add Bunburu or game modes yet.
- Do not attempt full Anki HTML/CSS rendering fidelity.
- Do not add cloud sync, accounts, or subscriptions.
- Do not silently drop diagnostics because they are hard to present.

## Required UX states

### 1. Clean import

When no meaningful warnings are present, the user should see a confident, reassuring success state.

Example tone:

> Deck looks good. Decko found your notes, cards, media, and templates and did not detect any issues that should affect study.

### 2. Import with warnings

When warnings exist but the deck is usable, the user should see a calm warning state.

Example tone:

> Deck imported with a few notes. You can study this deck, but some media or template details may not display exactly like Anki.

Warnings should be grouped and explained.

### 3. Blocking failure

When import cannot continue, the user should see a clear failure state with the most likely reason and a practical next step.

Example tone:

> Decko could not read this package. The file may be corrupted or use an unsupported structure. Try exporting the deck again from Anki.

### 4. Unsupported but recognised package

When Decko recognises a package format but still cannot import it, the message should explain the exact boundary.

Example tone:

> Decko recognised this as a modern Anki package, but this specific variant is not supported yet.

If there is an Anki export workaround, show it.

## Diagnostics categories

The UI should group diagnostics into a small number of understandable categories.

Suggested categories:

- Package
- Collection database
- Notes and fields
- Card templates
- Media
- Review progress
- Scheduling compatibility

Do not show raw enum names or low-level parser wording in the primary UI.

## Suggested UI surfaces

### Import preview screen

Add an import health section to preview before the user commits the deck.

It should show:

- package type
- collection type
- compression format when relevant
- note count
- card count
- media count
- warning count
- a clear health status

### Import result screen or post-import confirmation

After the deck is committed, show a concise result summary:

- imported successfully
- imported with warnings
- failed with actionable explanation

### Deck detail screen

For imported decks, expose a way to revisit import diagnostics.

Possible label:

- Import report
- Import health
- Deck import report

### Diagnostics detail view

Add an expandable or separate Decko-styled diagnostics view that shows:

- friendly summary
- grouped warnings
- technical details only when expanded
- package metadata
- source model/template information where helpful

The detail view should help future debugging without overwhelming normal users.

## Design principles

Decko must not feel like a raw parser log.

Use:

- calm copy
- clear severity hierarchy
- small icons or badges where useful
- progressive disclosure
- human-readable explanations
- actionable next steps

Avoid:

- stock Material alert walls
- raw stack traces
- unexplained enum names
- frightening warnings for harmless differences
- hiding important warnings completely

## Severity model

Introduce or formalise a severity model if one does not already exist.

Suggested levels:

- info
- warning
- error/blocking

The health summary should derive from these levels.

Example:

- no warnings/errors → healthy
- warnings only → usable with notes
- blocking error → cannot import

## Required acceptance criteria

- [ ] Import preview shows a clear health summary for supported packages.
- [ ] Modern `.apkg` / `collection.anki21b` / zstd imports show understandable package metadata.
- [ ] Clean imports show a reassuring success state.
- [ ] Warning imports show grouped, understandable warnings.
- [ ] Blocking failures show a clear reason and practical next step.
- [ ] Media warnings are understandable to a normal learner.
- [ ] Template/field warnings are understandable without raw Anki jargon where possible.
- [ ] Technical diagnostics remain available through progressive disclosure.
- [ ] Imported deck detail exposes a way to revisit the import report.
- [ ] Existing import functionality from MVP_013 remains intact.
- [ ] Existing progress-preservation behaviour remains intact.
- [ ] FSRS scheduling remains unchanged.
- [ ] Review queue and sibling burying remain unchanged.
- [ ] The UI follows Decko's design-first standard and does not use stock/utilitarian warning blocks.
- [ ] Tests cover healthy, warning, and blocking diagnostics states.
- [ ] `flutter analyze` passes.
- [ ] All tests pass.

## Suggested tests

Add unit/widget coverage for:

- healthy diagnostics summary
- warning diagnostics summary
- blocking diagnostics summary
- modern package metadata display
- media warning display
- template warning display
- technical details expansion
- deck detail link to import report
- import flow remains successful for known good fixtures

## Documentation updates

Update:

- `docs/DECISIONS.md` with a new decision for user-facing import diagnostics UX
- `docs/ROADMAP.md` to mark MVP_014 complete when delivered
- `docs/UI_REGISTRY.md` if new reusable UI components are added
- `memory.md` with completion status and next MVP

## Potential decision record

Suggested title:

> DEC-024: Import diagnostics are user-facing trust signals, not raw parser logs

Decision content should capture:

- diagnostics are grouped by user-understandable categories
- raw technical details are available only through progressive disclosure
- import health derives from structured severity
- clean/warning/blocking states are represented clearly
- diagnostics must support trust without creating unnecessary alarm

Check existing decision numbering before assigning the final DEC number.

## Handoff note for future agents

Update `.agent/skills/` only if this MVP changes how future agents should operate.

Do not modify `.agent/skills/` merely because this MVP adds new app features or UI screens.

## Completion report requirements

When complete, report:

- key files changed
- import diagnostics UX surfaces added
- health states implemented
- tests added
- analyze/test result
- any remaining import diagnostics limitations
- whether the next recommended MVP remains app polish/light gamification preparation or another import-parity follow-up
