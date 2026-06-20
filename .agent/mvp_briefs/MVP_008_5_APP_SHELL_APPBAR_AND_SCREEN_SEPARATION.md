# MVP_008.5 — App Shell, AppBar, and Screen Separation

## Status

Ready for agent execution.

This is a short product/UI pause before MVP_009. Do not start the lossless Anki import work yet.

## Why this MVP exists

Decko has become functionally powerful very quickly: Anki import, media, FSRS, review state, progress, and deck deletion are now all present. The home/import experience is starting to feel crowded because too many actions and flows are competing in the same visual space.

Before deepening the data model with lossless Anki import, give Decko a clearer app shell and separate the main home experience from the import experience.

Decko's product promise is still:

> Import your deck. Study it beautifully.

This MVP is about making the app structure feel intentional, calm, and beautiful.

## Mission

Add a Decko-style app shell with a proper app bar and separate Home from Import so the app no longer feels like everything sits on one crowded page.

## Goals

### 1. Add a reusable Decko app shell

Create a reusable app-shell structure for normal app screens.

It should include:

- A Decko-branded app bar.
- A clear screen title.
- A small set of relevant actions.
- Consistent spacing and visual hierarchy.
- Beautiful Decko styling, not stock/utilitarian Material UI.

Possible files:

```text
lib/core/widgets/decko_app_shell.dart
lib/core/widgets/decko_app_bar.dart
```

Exact names are flexible if the implementation is clean.

### 2. Separate Home from Import

The deck library/home screen should not try to be both the landing screen and the import workflow.

Home should focus on:

- The user's decks.
- Study status / due cards.
- A calm primary action such as Import or Add deck.
- A small amount of progress/streak information if already available.

Import should become its own focused screen/flow.

The import screen should focus on:

- Choosing a file.
- Explaining supported formats.
- Showing import preview.
- Showing Keep progress / Start fresh choices where relevant.
- Showing media/progress warnings where relevant.

Do not crowd this into the home screen.

### 3. Rework home screen hierarchy

The home screen should answer:

```text
What can I study now?
What decks do I have?
How do I import another deck?
```

It should not answer every possible settings/import/progress question.

Make the visual hierarchy clearer:

- AppBar / title area.
- Primary study/deck section.
- Deck list.
- Import CTA.
- Secondary actions only where they make sense.

### 4. Rework import screen hierarchy

The import screen should answer:

```text
What can I import?
What happens when I import it?
What choices do I have before committing?
```

It should be visually separate from the home screen.

### 5. Preserve all existing behaviour

Do not break:

- `.apkg` import.
- media import/rendering.
- Keep progress / Start fresh.
- FSRS scheduling.
- due queue.
- deck deletion.
- furigana toggle.
- theme persistence.
- progress persistence.

This is a UI/app-structure MVP, not a data/import rewrite.

## Non-goals

Do not implement:

- Lossless Anki note import.
- Note-type-aware mapping.
- Study options.
- Advanced deck option profiles.
- Modern `.anki21b` support.
- New scheduling behaviour.
- New media extraction features.
- Authentication or cloud sync.

## Design requirements

Decko must not look like stock Material.

Use the existing design direction from MVP_008:

- Dark, calm study-first styling.
- Rounded cards.
- Clear hierarchy.
- Intentional icons.
- Beautiful empty states.
- DeckoConfirmDialog / DeckoSnackbar style where applicable.

If a stock `AppBar` is used internally, wrap/style it so it feels like Decko.

## Suggested navigation shape

Routes may already exist. Adjust cleanly if needed.

Suggested conceptual shape:

```text
/                 Home / Deck Library
/import           Import Deck
/deck/:deckId     Deck Detail
/deck/:deckId/review Review Session
/progress         Progress
/themes           Theme Gallery
```

Home should link to Import.
Import should return to Home or newly imported Deck Detail after successful import.

## Acceptance criteria

- [ ] App has a reusable Decko app shell/app bar pattern.
- [ ] Home screen and Import screen feel clearly separate.
- [ ] Home focuses on existing decks and study entry points.
- [ ] Import screen focuses on file import and preview/commit choices.
- [ ] Home is less crowded than before.
- [ ] Import CTA is still easy to find from Home.
- [ ] Successful import still leads to a sensible destination.
- [ ] Existing review/deck/detail/progress/theme flows still work.
- [ ] Existing import tests still pass or are updated to match the new UI.
- [ ] Add/adjust widget tests for Home → Import navigation.
- [ ] `flutter analyze` passes.
- [ ] `flutter test` passes.

## Tests to add or update

At minimum:

- Home renders without import workflow crowding the page.
- Home has an Import/Add deck action.
- Tapping Import opens the Import screen.
- Import screen has file/import-focused copy.
- Existing import preview/commit tests still pass.
- Existing deck library/detail/review tests still pass.

## Documentation updates

Update as appropriate:

```text
docs/UI_REGISTRY.md
memory.md
```

Only update `docs/DECISIONS.md` if a durable architectural decision is made.

Potential decision if useful:

```text
DEC-014: Decko uses a reusable app shell and separates Home from Import workflows.
```

Do not update `.agent/skills/` unless this MVP creates a reusable operating rule for future agents.

## Approval report required

When finished, report:

1. Summary.
2. Files changed.
3. Before/after app structure.
4. Screens affected.
5. Design decisions.
6. Behaviour intentionally preserved.
7. Tests run and result count.
8. Known limitations.
9. Recommendation for the next MVP.

## Next MVP after this

After this UI pause, return to:

```text
MVP_009 — Lossless Anki Note Import and Field Preservation
```

Do not rename or replace that work unless explicitly instructed.
