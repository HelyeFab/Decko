# MVP_010 — Note-Type-Aware Decko Card Mapping

## Status

Planned. This is the current next MVP after MVP_009.

## Mission

Use the lossless Anki source preserved in MVP_009 to generate distinct Decko study cards for different Anki card templates, instead of flattening all cards from a note into lookalike generic cards.

The key product promise is:

> Decko understands what each imported Anki card is trying to train — listening, reading, production, recognition, or another template-specific mode — and presents it beautifully without losing the original source data.

## Why this matters now

MVP_009 preserved the full imported Anki source:

- note models
- named fields
- raw field values
- tags
- card template names
- card template ordinals
- question/answer template text
- generated card sources

That solved the data-loss problem, but the review card mapping is still not smart enough.

Known issue from MVP_009:

```text
A 3-template Anki note can still produce 3 lookalike Decko study cards.
```

For example, a Japanese note may generate:

```text
Listening
Reading
Production
```

Those are not the same learning activity. Decko must stop treating them as anonymous duplicates.

## Product principle

Decko should preserve Anki’s serious deck structure while presenting it through Decko’s cleaner, more beautiful review experience.

This MVP should not make Decko look like Anki. It should make Decko smarter about what Anki imported.

## Current architecture context

Decko already has:

- lossless imported Anki source data from MVP_009
- `ImportedAnkiSource`, notes, fields, models, templates, and card sources
- media import and disk-backed media storage
- two-sided flip card UI
- audio/image rendering
- furigana rendering
- persistent per-card review state
- FSRS scheduling behind the scheduler seam
- due queue and review sessions

MVP_010 should consume the preserved source model. It should not re-parse `.apkg` in the review layer.

## Core concept

Introduce a mapping layer that turns preserved Anki source cards into Decko review-card presentations.

```text
ImportedAnkiSource
   ↓
Card template + named fields + media refs
   ↓
NoteTypeAwareCardMapper
   ↓
DeckoReviewCardPresentation / LearningItem fields
   ↓
Beautiful Review UI
```

Exact class names may vary, but the architectural separation matters:

```text
Import preserves source data.
Mapping decides how to study it.
Review UI renders the mapped presentation.
Scheduler remains separate.
```

## Goals

### 1. Add a note-type-aware card mapping layer

Create a dedicated mapper/service, for example:

```dart
class NoteTypeAwareCardMapper {
  DeckoCardPresentation map({
    required ImportedAnkiSource source,
    required ImportedAnkiCardSource cardSource,
  });
}
```

The mapper should have access to:

- the note
- named fields
- template name
- template ordinal
- question template
- answer template
- media references
- tags where useful

It should produce a stable Decko-facing presentation object or mapped `LearningItem` data.

### 2. Preserve one Decko review card per Anki card source

If Anki generated three cards from one note, Decko should preserve three reviewable cards, but they should no longer look identical.

For example:

```text
Anki note
  ├─ Listening card → Decko listening presentation
  ├─ Reading card   → Decko reading presentation
  └─ Production card → Decko production presentation
```

Do not collapse them into one card.

Do not inflate them into duplicates with identical front/back content.

### 3. Use template identity first

Mapping should prefer template identity when available.

Useful signals:

- `templateName`
- `templateOrdinal`
- `questionTemplate`
- `answerTemplate`
- model name
- named fields

Template names such as these should be recognised when present:

```text
Listening
Reading
Production
Recognition
Recall
Sentence
Audio
```

The mapper should be heuristic and extensible. It does not need perfect support for every Anki model.

### 4. Use named fields instead of positional guessing where possible

MVP_009 preserved fields such as:

```text
Reading
Audio
Sentence
Sentence-Kana
Sentence-English
Sentence Audio
Image_URI
Tags
```

MVP_010 should use those names before falling back to field order.

Example field roles:

```text
word / expression / front / vocab → target expression
reading / kana → reading aid
meaning / gloss / english → meaning
sentence / example → Japanese example sentence
sentence-kana → sentence reading aid
sentence-english → example translation
sentence audio → example audio
image_uri / image → image reference
```

Keep fallback behaviour for older/simple decks.

### 5. Create distinct mappings for common Japanese card types

At minimum, support three template behaviours where the source data makes them identifiable.

#### Listening

Likely intent:

```text
Hear Japanese → recall/recognise meaning and reading.
```

Suggested presentation:

- Front prioritises audio.
- Text may be hidden or secondary if source/template indicates audio-first.
- Image can appear if present.
- Back shows expression, reading, meaning, and example.
- Sentence audio can be available on the back or example area.

#### Reading

Likely intent:

```text
See Japanese → recall reading and meaning.
```

Suggested presentation:

- Front prioritises the written expression or sentence.
- Audio remains available but not necessarily dominant.
- Back shows reading, meaning, and example/translation.

#### Production

Likely intent:

```text
See English/meaning prompt → produce Japanese.
```

Suggested presentation:

- Front prioritises English meaning or sentence translation.
- Japanese expression/reading should be hidden until reveal.
- Back shows Japanese expression, reading, example, audio, and image where useful.

These are design directions, not rigid UI requirements. The mapper must make these cards semantically different.

### 6. Keep Decko’s two-sided flip card working

The review card UI should continue to use the polished two-sided card from MVP_008.

This MVP may add metadata to the presentation such as:

```dart
enum ReviewCardMode {
  generic,
  listening,
  reading,
  production,
}
```

or a similar structure.

The UI can use that mode for labels, layout, or audio emphasis, but must remain beautiful and uncluttered.

### 7. Keep media behaviour intact

MVP_008 media support must continue to work:

- word audio
- sentence audio
- images
- missing-media fallback
- disk-backed media lookup
- delete deck → delete media

MVP_010 should improve placement, not regress playback/rendering.

### 8. Keep scheduling untouched

Do not change FSRS maths.

Do not reset imported progress.

Do not change review state identity unless required to correctly associate one review card with one source Anki card.

If card IDs or mapping IDs need migration, document it carefully and test that imported progress is not silently reset.

### 9. Add source-aware inspection/helpful debug info

The existing imported-source inspect screen should remain useful.

Consider adding or improving visibility of:

- template name
- mapped Decko mode
- fields used for front
- fields used for back
- media used

This can be dev/debug-only or a simple inspect section. Do not overbuild a full card editor in this MVP.

## Non-goals

Do not implement in MVP_010:

- Study options / deck overrides.
- Advanced option profiles.
- Full Anki template renderer.
- Full HTML/CSS template fidelity.
- Card editing.
- Modern `.anki21b` support.
- AnkiWeb sync.
- FSRS parameter UI.
- New practice modes beyond mapping imported templates.
- A large navigation redesign.

## UX principles

Decko should make imported card types understandable without becoming technical.

Prefer gentle labels such as:

```text
Listening
Reading
Production
```

or:

```text
Listen
Read
Recall
```

Avoid exposing raw Anki internals in the main review UI unless the user opens an inspect/source view.

The review card should still feel like Decko: calm, visual, spaced, and intentional.

## Acceptance criteria

- [ ] A dedicated note-type-aware mapping layer exists.
- [ ] Mapping consumes `ImportedAnkiSource` / preserved source models from MVP_009.
- [ ] Mapping uses template name/ordinal where available.
- [ ] Mapping uses named fields before positional fallback.
- [ ] Listening / Reading / Production templates map to distinct Decko presentations when present.
- [ ] Multi-template notes no longer produce indistinguishable review cards.
- [ ] One source Anki card still corresponds to one reviewable Decko card.
- [ ] Existing simple/demo decks still review correctly.
- [ ] Existing media rendering still works.
- [ ] Existing furigana rendering still works.
- [ ] Imported progress is not silently reset.
- [ ] FSRS scheduling behaviour is unchanged.
- [ ] Imported-source inspect/debug affordance remains available.
- [ ] Tests cover named-field mapping.
- [ ] Tests cover Listening / Reading / Production distinction.
- [ ] Tests cover fallback behaviour for simple decks.
- [ ] `flutter analyze` passes.

## Suggested tests

Add pure tests for:

- A note with Listening / Reading / Production templates produces three distinct presentations.
- Listening card front prioritises audio.
- Reading card front prioritises Japanese text.
- Production card front prioritises English/meaning prompt.
- Sentence audio is not confused with word audio.
- Image fields remain associated with the correct presentation.
- Unknown templates fall back to generic mapping.

Add widget tests for:

- Reviewing a Listening card shows a distinct listening-style front.
- Reviewing a Production card does not reveal the Japanese answer before flip.
- The imported-source view can show template/mapping information if implemented.

## Approval report required

When complete, report:

1. Summary.
2. Files changed.
3. Mapping architecture.
4. Supported template/card modes.
5. How named fields are resolved.
6. Media/audio/image behaviour.
7. Scheduling/progress safety.
8. Tests added.
9. Known limitations.
10. Recommendation for the next MVP.

## Likely next MVP

After MVP_010, return to learner control:

```text
MVP_011 — Study Options and Deck Overrides
MVP_012 — Advanced Deck Option Profiles
```

Deck options should come after this MVP because options such as audio-first, image-first, card limits, and bury siblings depend on Decko understanding what each imported card is.