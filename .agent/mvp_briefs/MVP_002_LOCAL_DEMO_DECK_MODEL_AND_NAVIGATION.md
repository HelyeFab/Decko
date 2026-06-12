# Decko MVP Agent Brief — MVP_002: Local Demo Deck Model and Navigation

## Mission

Turn Decko from a beautiful static product shell into a small local-first app flow with a real demo deck model, repository interface, deck tiles, and deck detail navigation.

This MVP is **not** about real file import, persistence, FSRS scheduling, or Anki compatibility yet.

The goal is to prove this flow:

```txt
Deck Library -> Demo Deck Tile -> Deck Detail -> Review Preview
```

Decko should now feel like it contains a real local deck, even though the data is still mock/demo data.

---

## Before coding

Read these files first:

```txt
.agent/README.md
.agent/AGENT_OPERATING_SYSTEM.md
.agent/skills/orient/SKILL.md
.agent/skills/architect/SKILL.md
.agent/skills/execute/SKILL.md
.agent/skills/review/SKILL.md
.agent/mvp_briefs/MVP_001_FLUTTER_PRODUCT_SHELL.md
docs/DECISIONS.md
docs/CODING_STANDARDS.md
docs/UI_REGISTRY.md
docs/ROADMAP.md
docs/import-progress.md
memory.md
```

Then return a short implementation plan before making changes.

---

# MVP_002 Scope

Build a local demo deck model and navigation layer.

The existing MVP_001 shell already has:

```txt
- Deck Library / Home
- Import Placeholder
- Review Preview
- Theme Gallery
- Progress Preview
- MockDecks demo data
- Deck and LearningItem domain models
- GoRouter navigation
```

MVP_002 should make the deck library render real local deck data and introduce a deck detail screen.

---

## 1. Add a deck repository abstraction

Create a small repository interface for reading local/demo decks.

Suggested location:

```txt
lib/domain/repositories/deck_repository.dart
```

Suggested shape:

```dart
abstract class DeckRepository {
  List<Deck> getDecks();
  Deck? getDeckById(String id);
}
```

Create a mock/local implementation backed by the existing demo data.

Suggested location:

```txt
lib/data/mock_deck_repository.dart
```

Do not add persistence yet.
Do not add Riverpod yet unless absolutely necessary.
Use the simplest dependency flow that keeps the code understandable.

---

## 2. Render real deck tiles in the deck library

Update the deck library so it displays deck tiles from the repository.

Each deck tile should show useful summary information, for example:

```txt
- deck title
- short description
- number of cards/items
- due today placeholder
- studied/reviewed placeholder
- source label such as Demo deck or Local deck
```

Keep the existing empty state as a fallback when the repository returns no decks.

The library should still include:

```txt
- Decko branding
- tagline: Import your deck. Study it beautifully.
- Import CTA
- Theme/progress navigation
- product promise tiles if they still fit cleanly
```

---

## 3. Add a deck detail screen

Create a new screen for a selected deck.

Suggested location:

```txt
lib/features/deck_detail/deck_detail_screen.dart
lib/features/deck_detail/widgets/
```

The deck detail screen should show:

```txt
- deck title
- description
- total cards/items
- sample cards/items
- placeholder progress summary
- primary CTA: Start review
- secondary information: Review modes coming soon
```

The detail screen should make it clear that this is still demo/local data.

---

## 4. Update navigation

Update routing so the flow becomes:

```txt
Deck Library
  -> tap demo deck tile
  -> Deck Detail
  -> Start review
  -> Review Preview
```

Also update `Explore demo deck` so it routes to the deck detail screen first, not directly to review.

Use the existing routing style unless there is a strong reason to change it.

Optional: if helpful, add named routes, but do not make this MVP bigger than needed.

---

## 5. Review preview should receive deck context if simple

If straightforward, allow the review preview to know which deck/item it is previewing.

For MVP_002, it is acceptable for the review screen to still use the existing sample card, but the preferred behaviour is:

```txt
Deck Detail -> Start review -> first item from selected demo deck
```

Do not build a real review queue yet.
Do not implement grading persistence.

---

## 6. Tests

Update or add widget tests covering:

```txt
- Deck library renders a demo deck tile
- tapping demo deck tile opens deck detail
- Explore demo deck opens deck detail
- Start review opens review preview
- Empty state still works if repository has no decks, if easy to test
```

Keep existing MVP_001 tests passing.

---

# Explicit non-goals

Do **not** implement these yet:

```txt
Real .apkg parsing
CSV/JSON import
Progress-aware import
Anki scheduling import
AnkiWeb sync
AnkiConnect
AnkiDroid integration
Real FSRS algorithm
Review queue generation
Persistent local database
Cloud sync
Authentication
Payments
AI card generation
Complex state management
```

Mock/demo data is still fine.

---

# Technical preferences

- Keep the app local-first.
- Keep domain models framework-light.
- Keep repository interfaces small.
- Prefer simple constructor injection or a lightweight inherited/provider pattern already used by the app.
- Avoid large dependencies.
- Keep UI responsive on phone-sized screens.
- Use accessible tap targets and readable text.
- Preserve the separation between app themes and card themes.
- Preserve the product rule that Decko must not falsely claim real deck import or progress preservation yet.

---

# Visual direction

The deck library and deck detail screen should continue the MVP_001 visual language:

```txt
soft background
rounded cards
clear typography
warm spacing
friendly CTAs
polished but not childish
```

The deck tile should feel inviting, not like a database row.

Possible tile copy examples:

```txt
Japanese Starter Deck
12 cards
Demo deck
Ready to review
```

or:

```txt
Minna-style Japanese Basics
A tiny sample deck for testing Decko's review experience.
```

---

# What to return for approval

Before finalising, return this approval report:

## 1. Summary

Briefly explain what was built.

## 2. Files changed

List every created or changed file.

Use this format:

```txt
Created:
- lib/domain/repositories/deck_repository.dart
- lib/data/mock_deck_repository.dart
- lib/features/deck_detail/deck_detail_screen.dart

Changed:
- lib/features/deck_library/deck_library_screen.dart
- lib/app/decko_router.dart
- test/widget_test.dart
```

## 3. Screens / flows included

List the screens and flows now available:

```txt
- Deck Library renders demo deck tile
- Demo deck tile opens deck detail
- Explore demo deck opens deck detail
- Deck detail opens review preview
```

## 4. Design decisions

Explain any decisions made around:

```txt
repository structure
data flow
navigation route shape
how selected deck context is passed
how mock data is handled
```

## 5. Dependencies added

List any dependencies added to `pubspec.yaml`.

If no dependencies were added, say:

```txt
No external dependencies added.
```

## 6. How to run

Provide exact commands:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## 7. Known limitations

Clearly state what is still fake/placeholder.

For example:

```txt
- Deck data still comes from MockDecks.
- Deck detail progress values are placeholders.
- Start review does not create a real review session yet.
- Ratings do not update card state.
- Import remains placeholder only.
```

## 8. Manual test checklist

Return a checklist we can use:

```txt
[ ] App launches successfully
[ ] Deck library shows Decko branding
[ ] Deck library shows at least one demo deck tile
[ ] Import CTA still opens import placeholder
[ ] Explore demo deck opens deck detail
[ ] Tapping a deck tile opens deck detail
[ ] Deck detail shows deck title, description, card count, and sample items
[ ] Start review opens review preview
[ ] Review preview still shows reveal + grading buttons
[ ] Theme gallery still works
[ ] Progress preview still works
[ ] Existing widget tests pass
```

## 9. Recommendation for next MVP

Suggest the next smallest implementation step.

Expected next step is probably one of:

```txt
MVP_003: JSON deck import
MVP_004: Simple review session state
MVP_005: FSRS-ready scheduler interface
MVP_006: Progress-aware Anki import investigation spike
```

Do not start the next MVP without approval.

---

# Acceptance criteria

MVP_002 is complete when:

```txt
[ ] DeckRepository abstraction exists.
[ ] Mock/local repository returns at least one demo deck.
[ ] Deck library renders actual deck tiles from repository data.
[ ] Empty state remains available as a fallback.
[ ] Deck detail screen exists.
[ ] Tapping a deck opens deck detail.
[ ] Explore demo deck opens deck detail.
[ ] Start review opens review preview.
[ ] Existing MVP_001 screens still work.
[ ] No real import is claimed or implemented.
[ ] No persistence is introduced yet.
[ ] Tests are updated and passing.
[ ] Agent returns the approval report above.
```
