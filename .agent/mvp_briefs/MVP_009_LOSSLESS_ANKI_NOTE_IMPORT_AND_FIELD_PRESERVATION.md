# MVP_009 — Lossless Anki Note Import and Field Preservation

## Status

Planned.

This MVP replaces the earlier MVP_009 priority around Study Options. Study Options and Advanced Deck Option Profiles are still valuable, but they must wait until Decko stops losing real Anki note data during import.

## Mission

Stop Decko from performing lossy Anki imports.

Decko must preserve the original Anki note structure — all named fields, tags, card-template identity, media references, and source metadata — before generating the beautiful simplified Decko study card used in review.

The goal is not to make the review UI show every field immediately. The goal is to make sure imported data is not discarded, so future mapping, card-type-specific behaviour, deck options, and advanced study modes have the original source data available.

## Why this matters now

Real Anki decks contain much richer note data than Decko’s current simplified study model.

For example, a real Japanese deck may have fields such as:

- `Reading`
- `Audio`
- `Sentence`
- `Sentence-Kana`
- `Sentence-English`
- `Sentence Audio`
- `Image_URI`
- `Tags`

Decko currently extracts enough to create a nice card, but risks discarding or flattening fields it does not yet understand.

That is dangerous because later features depend on the original data:

- Listening / Reading / Production card behaviour
- audio-first or image-first deck options
- note-type-aware mapping
- sibling burying
- card-template-specific study modes
- richer card editing/browsing
- future export or re-import workflows

The principle for this MVP is:

> Decko may render a simplified card, but it must preserve the rich imported source note.

## Product principle

Decko should stay beautiful and opinionated, but import must be trustworthy.

A user should be able to import a real `.apkg` and know that Decko has preserved the original note fields, even if the current review card only uses a subset of them.

## Current architecture context

Decko already has:

- legacy `.apkg` import
- media extraction and disk-backed media storage
- imported deck persistence
- review state persistence
- FSRS scheduling
- furigana rendering
- two-sided review card UI

This MVP should build on that architecture, not replace it.

## Required data preservation model

Introduce a durable imported-source model. Exact names may vary, but the implementation should include equivalents of the following concepts.

### ImportedAnkiNote

Represents the original Anki note.

Suggested fields:

```dart
class ImportedAnkiNote {
  final String sourceNoteId;
  final String sourceGuid;
  final String sourceModelId;
  final String modelName;
  final String deckId;
  final List<ImportedAnkiField> fields;
  final List<String> tags;
}
```

### ImportedAnkiField

Represents one named Anki field.

Suggested fields:

```dart
class ImportedAnkiField {
  final String name;
  final int ordinal;
  final String rawValue;
  final String plainTextValue;
  final List<MediaReference> mediaReferences;
}
```

The implementation must preserve `rawValue`, because Anki fields may contain HTML, ruby-like markup, image tags, `[sound:...]`, styling, or information Decko does not yet understand.

### ImportedAnkiCardTemplate

Represents a card template from the Anki model.

Suggested fields:

```dart
class ImportedAnkiCardTemplate {
  final String sourceModelId;
  final int ordinal;
  final String name;
  final String questionTemplate;
  final String answerTemplate;
}
```

This is important because card-template names such as `Listening`, `Reading`, and `Production` are semantically meaningful.

### ImportedAnkiCardSource

Represents the relationship between an Anki card and its source note/template.

Suggested fields:

```dart
class ImportedAnkiCardSource {
  final String sourceCardId;
  final String sourceNoteId;
  final String sourceDeckId;
  final int templateOrdinal;
  final String? templateName;
  final String queueState;
  final int due;
  final int reps;
  final int lapses;
}
```

This should connect to the existing `ReviewCardState` / FSRS scheduling layer without resetting imported progress.

## Architecture rule

Do not force all Anki data into `LearningItem`.

Instead, the architecture should become:

```text
Anki .apkg
   ↓
Lossless imported source data
   - notes
   - named fields
   - templates
   - card sources
   - tags
   - media refs
   ↓
Decko mapping layer
   ↓
Decko review card / LearningItem abstraction
   ↓
Review UI
```

`LearningItem` can remain the clean Decko study abstraction.

The imported Anki source data should be stored alongside it, or linked by stable IDs, so future features can remap or inspect the original data without needing to re-import.

## Required behaviour

### 1. Preserve all named fields

When importing a note, Decko must preserve every Anki field by name and ordinal.

Unknown fields must not be dropped.

The following must be preserved:

- raw field value
- plain-text value where useful
- field name
- field order/ordinal
- detected media references

### 2. Preserve tags

Anki note tags must be preserved even if Decko does not yet use them in the UI.

Imported tags should be available from the preserved imported-source model.

### 3. Preserve model identity

Decko must preserve:

- model id
- model name
- field definitions
- card template names
- card template ordinals
- question template text
- answer template text

### 4. Preserve card-template identity

If a note generates multiple cards, Decko must preserve which Anki card came from which template.

For example, if a note creates:

- Listening
- Reading
- Production

Decko must not collapse those into one anonymous generic card without preserving the template identity.

It is acceptable for the current review UI to still render a simplified card, but the preserved source data must keep the distinction.

### 5. Preserve media references

Build on MVP_008.

Media files are already extracted and stored. This MVP must ensure field-level references are preserved as source metadata:

- `[sound:...]`
- `<img src="...">`
- raw image/audio field values
- any media refs discovered in unknown fields

### 6. Preserve imported progress

This MVP must not reset scheduling state.

The existing rules remain:

- Keep Anki progress means imported scheduling/progress is preserved.
- Start fresh means a new Decko review state is created intentionally.
- FSRS only updates state after a user grades a card.

### 7. Generate current Decko cards from preserved source data

The current review experience should continue working.

After import, Decko should still generate a usable review card using the current mapping logic, but that generated card should be derived from the preserved source data rather than being the only stored representation.

### 8. Add an import-inspection/debug affordance

Add a simple way to confirm that fields were preserved.

This can be one of:

- a developer/debug screen on deck detail
- an import preview expansion
- a simple “Source fields” view for one imported card/note
- test-only inspectable repository APIs

The UI does not need to be beautiful yet, but it must prove that rich fields are stored.

If a visible UI is created, keep it Decko-styled and avoid stock/utilitarian Material presentation.

## Non-goals

Do not implement full note-type-aware rendering yet.

Do not implement Study Options yet.

Do not implement Advanced Deck Option Profiles yet.

Do not implement `.anki21b` support unless it is already trivial.

Do not change FSRS scheduling maths.

Do not redesign the review screen.

Do not attempt full Anki template rendering.

Do not implement editing of imported fields.

Do not export back to Anki.

## Design constraints

Decko must remain beautiful.

Even if a debug/source-fields view is added, do not ship a raw stock-looking table unless it is hidden behind a developer/debug affordance.

Prefer clean cards, grouped sections, and readable labels.

## Suggested implementation path

1. Inspect current Anki import adapter and persistence model.
2. Add imported-source domain models.
3. Parse `col.models` to recover model names, field names, and card templates.
4. When reading notes, map split field values to named `ImportedAnkiField` entries.
5. Preserve note tags.
6. Link cards to note/template identity using card ordinals.
7. Persist the imported-source data with the deck.
8. Update existing mapping code to generate Decko cards from preserved source data.
9. Add tests using fixtures that include multiple named fields and multiple card templates.
10. Add a minimal inspect/debug affordance or repository-level test verification.

## Acceptance criteria

- [ ] Import preserves every Anki note field by name and ordinal.
- [ ] Unknown fields are not discarded.
- [ ] Raw field values are preserved.
- [ ] Plain-text values are available where useful.
- [ ] Note tags are preserved.
- [ ] Model id and model name are preserved.
- [ ] Field definitions from the Anki model are preserved.
- [ ] Card template names and ordinals are preserved.
- [ ] Question and answer template text are preserved.
- [ ] Multiple generated Anki cards from one note preserve their template identity.
- [ ] Media references inside all fields are preserved.
- [ ] Existing media rendering from MVP_008 still works.
- [ ] Existing FSRS scheduling from MVP_007 still works.
- [ ] Imported progress is not reset.
- [ ] Current review UI still works with imported decks.
- [ ] At least one fixture/test covers a note with fields like Reading, Audio, Sentence, Sentence-Kana, Sentence-English, Sentence Audio, Image_URI, Tags.
- [ ] At least one fixture/test covers a note with Listening / Reading / Production templates.
- [ ] There is a way to inspect or verify preserved source fields.
- [ ] `flutter analyze` passes.
- [ ] `flutter test` passes.

## Required tests

Add unit tests for:

- parsing model field names
- parsing card template names and ordinals
- mapping note field values to named fields
- preserving unknown fields
- preserving tags
- preserving media refs from all fields
- linking cards to source template identity

Add integration/widget tests where practical for:

- importing a fixture deck and confirming preserved source fields
- confirming review still opens after import
- confirming media still renders/plays after import

## Required documentation updates

Update:

- `docs/DECISIONS.md`
- `docs/ROADMAP.md`
- `docs/UI_REGISTRY.md` if any new visible source-field UI pattern is added
- `memory.md`

Add a decision along the lines of:

```text
DEC-014: Anki imports preserve lossless source note data before mapping to Decko cards
```

The decision should record:

- Decko should not discard unknown Anki fields.
- Decko’s clean review model is generated from preserved source data.
- Future note-type-aware mapping and deck options depend on this preserved source layer.

## Approval report required

When complete, return an approval report with:

1. Summary
2. Files changed
3. Imported-source model description
4. Data preserved from Anki
5. Mapping flow from source data to Decko review card
6. Tests added
7. Known limitations
8. Manual test checklist
9. Recommendation for the next MVP

## Likely next MVP

After this MVP, the next likely step is:

```text
MVP_010 — Note-Type-Aware Decko Card Mapping
```

That MVP should use the preserved source fields/templates to decide how Listening, Reading, Production, sentence, image, and audio cards should be rendered.

Only after that should Decko resume:

```text
Study Options and Deck Overrides
Advanced Deck Option Profiles
```