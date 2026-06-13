# MVP_008 — Anki Media Import and Rendering

## Status

Proposed next MVP.

## Mission

Make imported Anki decks feel complete by preserving and rendering media from legacy `.apkg` imports.

Decko already imports real cards, preserves progress, supports furigana, persists review state, and schedules with FSRS. The next major usability gap is media: many real Anki decks contain audio, images, or both. At the moment these references are dropped or rendered as plain text, which makes audio/image-heavy decks feel broken.

The goal of this MVP is to support a practical vertical slice of Anki media import and playback/rendering while keeping the scheduler, review state, and FSRS behaviour unchanged.

## Product promise

After this MVP, a learner should be able to import a legacy `.apkg` deck containing common Anki media references and study cards where:

- `[sound:filename.mp3]` becomes a playable audio control.
- `<img src="filename.png">` or equivalent image references render as images.
- Imported media is stored locally and survives app restart.
- Missing media does not crash review; Decko shows a graceful warning.

## Before coding, read

The agent must read:

- `.agent/README.md`
- `.agent/AGENT_OPERATING_SYSTEM.md`
- `.agent/skills/orient/SKILL.md`
- `.agent/skills/architect/SKILL.md`
- `.agent/skills/execute/SKILL.md`
- `.agent/skills/review/SKILL.md`
- `docs/DECISIONS.md`
- `docs/ROADMAP.md`
- `docs/UI_REGISTRY.md`
- `docs/import-progress.md`
- `memory.md`

Then return a short implementation plan before changing code.

## Current context

Decko currently has:

- real legacy `.apkg` import via `AnkiApkgImportAdapter`;
- imported decks persisted locally;
- persistent per-card review state;
- due queues and review write-back;
- FSRS-5 scheduling behind the existing scheduler seam;
- furigana preservation/rendering;
- imported-deck deletion;
- graceful bad-file handling.

Known gap: media is currently ignored or dropped. Many of Emmanuel's real decks include `[sound:]` references, so this MVP should prioritise audio before more exotic media handling.

## Scope

### 1. Extract media from legacy `.apkg`

During `.apkg` import, detect and extract the Anki media bundle.

Legacy `.apkg` packages usually contain:

- a SQLite collection database;
- a `media` mapping file;
- numbered media payload files.

Implement media extraction for the legacy package format already supported by Decko.

The importer should:

- read the package media mapping;
- copy referenced media files into Decko-controlled local storage;
- preserve original media filenames or create a deterministic mapping;
- associate imported media with the imported deck;
- avoid filename collisions between decks;
- fail gracefully if media metadata is missing or malformed.

### 2. Store media locally

Add a small media storage layer, for example:

```text
MediaStore / MediaRepository
```

It should support:

```text
saveMedia(deckId, originalFileName, bytes)
resolveMedia(deckId, originalFileName)
deleteMediaForDeck(deckId)
```

Use app-local storage appropriate for Flutter. Do not store media blobs in `shared_preferences`.

Keep the API behind an interface so storage can later move to a more robust database/file manager if needed.

### 3. Preserve media references in card content

Do not destroy media references during field mapping.

The importer should keep enough information for the review UI to recognise:

```text
[sound:example.mp3]
<img src="example.png">
<img src='example.jpg'>
```

If current content cleaning strips these markers, adjust the cleaning/parsing so useful media references survive.

### 4. Render images in review cards

The review UI should render image references as actual images where possible.

Minimum acceptable support:

- common image extensions: `.png`, `.jpg`, `.jpeg`, `.gif`, `.webp` where Flutter supports them;
- images on the front or back of a card;
- constrained sizing so large images do not overflow;
- graceful placeholder for missing/unreadable image files.

Do not build a full HTML renderer unless absolutely necessary. Prefer a small Anki-field-content parser/component that handles the media patterns Decko supports.

### 5. Play `[sound:]` audio

Add support for `[sound:filename]` references.

Minimum behaviour:

- show an audio/play button where `[sound:...]` appears;
- play the local media file when tapped;
- support common Anki audio such as `.mp3`, `.m4a`, `.wav`, `.ogg` if the chosen Flutter audio package supports them;
- show a friendly unavailable state if playback cannot start.

Audio should not autoplay in this MVP unless the implementation is trivial and non-disruptive. Manual play is enough.

### 6. Delete media with imported deck

When a user deletes an imported deck, Decko should also delete media files associated with that deck.

This must be tied into the existing swipe-left delete flow.

### 7. Import preview should mention media

Update import preview to show media awareness, for example:

```text
Media files found: 142
Audio references: 89
Image references: 12
```

Exact counts can be approximate if counting references precisely would overcomplicate the MVP, but the user should have confidence that Decko detected media.

### 8. Tests

Add unit/widget tests covering:

- parsing `[sound:...]` references;
- parsing image references;
- resolving media paths through the media repository/store;
- importer handles package media mapping;
- missing media renders gracefully;
- deleting an imported deck clears associated media;
- existing FSRS scheduler tests still pass;
- existing import/progress/review tests still pass.

## Non-goals

Do not implement:

- modern `.anki21b` / zstd support;
- AnkiWeb sync;
- full HTML/CSS Anki template rendering;
- JavaScript/card-template execution;
- full media sync or cloud storage;
- speech recognition or TTS generation;
- FSRS changes;
- scheduling changes;
- account/cloud features.

## Technical guidance

Keep this MVP narrow and practical.

Prefer:

```text
AnkiFieldContentParser
MediaReference
MediaRenderer
AudioButton
MediaRepository
```

rather than a large HTML rendering system.

The review UI should remain readable and accessible. Media should enhance the card, not break layout.

The FSRS scheduler and review-state write-back must remain unchanged except where tests require dependency wiring updates.

## Acceptance criteria

- [ ] Legacy `.apkg` import extracts media files where present.
- [ ] Imported media is stored locally outside `shared_preferences`.
- [ ] `[sound:...]` references show a play/audio control.
- [ ] Image references render as images in review cards.
- [ ] Missing media shows a friendly placeholder or warning.
- [ ] Imported deck deletion removes associated media.
- [ ] Import preview reports media presence/counts.
- [ ] Existing imported progress behaviour still works.
- [ ] FSRS scheduling behaviour is unchanged.
- [ ] Tests cover parser, media storage, rendering, deletion, and regression flows.
- [ ] `flutter analyze` is clean.
- [ ] `flutter test` passes.

## Manual test checklist

Use at least one real `.apkg` deck containing `[sound:]` references.

- [ ] Import a legacy `.apkg` deck with audio.
- [ ] Preview reports that media was found.
- [ ] Imported deck appears in the library.
- [ ] Review card shows an audio control.
- [ ] Tapping audio plays the imported sound.
- [ ] Reopen the app; audio still works.
- [ ] Import a deck/card with an image.
- [ ] Image renders without overflow.
- [ ] Missing media does not crash review.
- [ ] Delete imported deck.
- [ ] Associated media is removed.
- [ ] Existing due queue and FSRS intervals still behave correctly.

## Approval report required

When finished, return:

1. Summary
2. Files changed
3. Media formats supported
4. Import behaviour
5. Rendering/playback behaviour
6. Storage decisions
7. Dependencies added
8. How to run
9. Known limitations
10. Manual test checklist
11. Recommendation for next MVP

## Likely next MVP after this

After media import, the best candidates are:

```text
MVP_009 — Modern .anki21b Import Support
MVP_009 — Smarter Note-Type-Aware Field Mapping
MVP_009 — Floating Bottom Navigation UI Polish
```

The next choice should depend on testing with real decks after media support lands.
