# MVP_005 — Progress-Aware Anki Deck Import

## Status

Ready for agent implementation.

## Mission

Build the first real Decko import path for existing Anki users.

The purpose of this MVP is not to build a perfect Anki clone. The purpose is to prove the core product promise:

> Import your deck. Keep your progress if you want. Study it beautifully.

A user should be able to choose an Anki `.apkg` deck, see what Decko found, choose whether to keep imported scheduling/progress or start fresh, and then see the imported deck in the Deck Library.

This MVP should let the product owner import real personal decks and test Decko with real study data.

---

## Before coding

Read these files first:

```text
.agent/README.md
.agent/AGENT_OPERATING_SYSTEM.md
.agent/skills/orient/SKILL.md
.agent/skills/architect/SKILL.md
.agent/skills/execute/SKILL.md
.agent/skills/review/SKILL.md
docs/DECISIONS.md
docs/import-progress.md
docs/CODING_STANDARDS.md
docs/UI_REGISTRY.md
docs/ROADMAP.md
memory.md
```

Then return a short implementation plan before making changes.

---

## Product context

Decko currently has:

- a Flutter app shell,
- local demo decks,
- deck detail navigation,
- an in-memory review session loop,
- local theme persistence,
- local progress snapshot persistence.

Deck data itself is still mock/in-memory. Import is still placeholder-only.

This MVP starts the import system.

---

## Critical product rule

Decko must never silently reset imported Anki progress.

Every import must clearly communicate whether progress is being kept or discarded.

The user must explicitly choose between:

```text
Keep Anki progress
Start fresh
```

If progress/scheduling data is unavailable or cannot be read, Decko must say so clearly.

---

## Scope

### 1. Add an import adapter seam

Create a small import abstraction, for example:

```text
lib/domain/import/
  deck_import_adapter.dart
  deck_import_result.dart
  imported_deck_progress_summary.dart
```

Suggested concepts:

```dart
abstract class DeckImportAdapter {
  Future<DeckImportPreview> preview(/* selected file */);
  Future<DeckImportResult> importDeck(DeckImportRequest request);
}
```

The exact API may differ, but the design must separate:

```text
File parsing
Import preview
User import choice
Deck persistence/update
```

Do not let the UI parse `.apkg` files directly.

---

### 2. Support a first `.apkg` vertical slice

Implement a first Anki package importer for `.apkg` files.

A `.apkg` package is a compressed Anki package. For this MVP, support a practical subset:

```text
Read package
Extract/open collection database
Read notes/cards enough to create Decko Deck + LearningItems
Ignore media initially unless trivial
Ignore complex card templates initially
Ignore full Anki model fidelity initially
```

The minimum acceptable import is:

```text
Deck title
Cards/notes count
Learning item front text
Learning item back text
Optional reading/example if easily derivable
Imported source ids where available
```

For Japanese decks, do not attempt magic parsing yet. Use the source fields conservatively.

A first simple mapping is acceptable:

```text
field 0 -> front / Japanese / prompt
field 1 -> back / meaning / answer
field 2+ -> optional extra text / notes / example, if present
```

Keep the mapping code isolated so better field mapping can be added later.

---

### 3. Detect whether scheduling/progress exists

The import preview should inspect whether card scheduling/progress information is present.

At minimum, try to detect and summarise:

```text
Total cards
New cards
Already reviewed cards
Learning/review/relearning cards, if available
Suspended cards, if available
Due cards, if safely derivable
Whether review/progress data appears available
```

Do not overclaim precision. If due-date interpretation is uncertain, label it as approximate or omit it.

---

### 4. Add the import choice screen

Replace or extend the current import placeholder screen with a real import flow:

```text
Import Anki deck (.apkg)
```

Flow:

```text
Choose .apkg file
      ↓
Decko analyses the file
      ↓
Import preview screen
      ↓
Choose import mode
      ├─ Keep Anki progress
      └─ Start fresh
      ↓
Import deck
      ↓
Success screen / return to deck library
```

The preview screen should show something like:

```text
Deck found: Japanese Core 2k
Cards found: 1,000
Already reviewed: 512
New cards: 488
Suspended: 12
Progress data: available

How would you like to import this deck?

[ Keep Anki progress ]
[ Start fresh ]
```

If no progress data is found:

```text
This deck does not appear to include scheduling information.
Decko can import the cards, but they will start as new.
```

---

### 5. Persist imported decks locally

MVP_004 persisted progress snapshots but not deck data.

This MVP must make imported decks available after import. Use the lightest acceptable local persistence that fits the current architecture.

Possible approaches:

```text
SharedPreferences JSON blob for imported decks, if the implementation is intentionally small
A simple local file/json store
A lightweight database only if clearly justified
```

Do not over-engineer. This MVP is about a working import vertical slice.

The existing `DeckRepository` seam should be preserved. Add or adapt a local implementation rather than making screens depend on storage directly.

The deck library should show:

```text
Demo decks + imported decks
```

or, if simpler and clearer:

```text
Imported decks first, demo decks still available
```

Do not remove the demo decks unless there is a strong reason.

---

### 6. Represent imported progress without pretending FSRS exists

If the user chooses **Keep Anki progress**, preserve practical imported state where available.

Create a small imported progress model if needed, for example:

```dart
class ImportedCardProgress {
  final String sourceCardId;
  final String sourceNoteId;
  final ImportedCardState state;
  final DateTime? dueAt;
  final int? intervalDays;
  final int? reps;
  final int? lapses;
  final double? easeFactor;
  final DateTime? lastReviewedAt;
}
```

This does not need to power the scheduler yet.

For this MVP, the important thing is:

```text
Decko imports and stores whether a card was new/reviewed/suspended where available.
Decko does not silently reset those cards if Keep progress was selected.
Decko clearly labels the imported progress as imported Anki state, not native FSRS state.
```

If the user chooses **Start fresh**, import the same cards but reset them to Decko-new state.

---

### 7. Update Deck Detail to show import provenance

For imported decks, show a small provenance/status section on the deck detail screen:

```text
Imported from Anki
Progress: kept from Anki
```

or:

```text
Imported from Anki
Progress: started fresh
```

If progress was unavailable:

```text
Imported from Anki
Progress: no scheduling data found
```

---

## Non-goals

Do not implement:

```text
AnkiWeb sync
AnkiConnect
AnkiDroid integration
Full Anki media support
Full Anki template rendering
Perfect Anki scheduler reproduction
FSRS scheduling
Cloud sync
Accounts
Payments
AI card generation
Multi-file import batch flow
Advanced field-mapping UI
```

Do not promise full `.apkg` compatibility. Use wording like:

```text
First import support
Basic Anki package import
Some complex decks may not import perfectly yet
```

---

## Technical guidance

Prefer small seams and clear boundaries:

```text
Import UI -> Import controller/service -> Import adapter -> Deck repository
```

Keep import parsing isolated under something like:

```text
lib/data/import/anki_apkg_import_adapter.dart
```

Do not put parsing code in widgets.

Add tests for import parsing using a fixture if possible. If a real `.apkg` fixture is too large or awkward, add parser-level tests around the transformation layer and clearly document the remaining manual test requirement.

If adding dependencies, justify them in the approval report.

Likely dependencies may include:

```text
file_picker or similar for choosing .apkg files
archive or similar for extracting package contents
sqlite/sqflite or similar for reading Anki's collection database
```

Only add what is actually needed.

---

## UX requirements

The import UX must feel safe and honest.

Good messages:

```text
Decko found progress in this deck.
You can keep it or start fresh.
```

```text
Decko could not find scheduling information in this package.
Your cards can still be imported, but they will start as new.
```

Avoid messages that imply perfect compatibility:

```text
Fully imported from Anki
100% Anki-compatible
Synced with Anki
```

Decko is importing a copy, not syncing.

---

## Acceptance criteria

```text
[ ] Import screen offers Anki `.apkg` import.
[ ] User can select an `.apkg` file.
[ ] Decko analyses the file before importing.
[ ] Import preview shows deck/card counts.
[ ] Import preview states whether progress data appears available.
[ ] User can choose Keep Anki progress when progress exists.
[ ] User can choose Start fresh.
[ ] If progress is unavailable, Decko clearly warns that cards will start as new.
[ ] Imported deck appears in the deck library.
[ ] Imported deck can be opened in deck detail.
[ ] Imported deck can enter the existing review session flow.
[ ] Imported deck survives app restart.
[ ] Deck detail shows whether progress was kept, started fresh, or unavailable.
[ ] No screen claims AnkiWeb sync or full Anki compatibility.
[ ] Existing demo deck flow still works.
[ ] Existing theme persistence still works.
[ ] Existing progress snapshot flow still works.
[ ] flutter analyze is clean.
[ ] Tests are added/updated for the import flow where practical.
```

---

## Manual test checklist

The agent must manually test with at least one real `.apkg` package if available.

```text
[ ] App launches successfully.
[ ] Import screen opens.
[ ] `.apkg` file can be selected.
[ ] Import preview appears.
[ ] Preview shows card count.
[ ] Preview shows progress availability.
[ ] Start fresh import works.
[ ] Keep progress import works when available.
[ ] Imported deck appears in library.
[ ] Imported deck opens in detail.
[ ] Imported deck starts a review session.
[ ] Imported deck is still present after app restart.
[ ] Complex/unsupported deck failure is graceful.
```

If a real `.apkg` cannot be included in automated tests, the agent must say so explicitly in the approval report.

---

## Approval report required

When done, return:

```text
MVP_005 Approval Report — Progress-Aware Anki Deck Import

1. Summary
2. Files changed
3. Import flow included
4. Progress handling behaviour
5. Data persistence behaviour
6. Design decisions
7. Dependencies added and why
8. How to run
9. Known limitations
10. Manual test checklist
11. Recommendation for next MVP
```

The report must explicitly answer:

```text
Can I import a real .apkg deck?
Can I choose Keep Anki progress?
Can I choose Start fresh?
Does the imported deck survive restart?
What kinds of Anki decks may fail or import imperfectly?
```

---

## Suggested next MVP after this

Likely next options:

```text
MVP_006 — Import Field Mapping and Compatibility Improvements
MVP_006 — Basic Due Queue from Imported Progress
MVP_006 — JSON/CSV Import Adapter
MVP_006 — Review History and Full Progress Storage
```

The best next MVP depends on what breaks or feels missing when importing real personal decks.
