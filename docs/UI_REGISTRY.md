# Decko UI Registry

Status: Draft

This file records reusable UI patterns so Decko remains visually coherent as features are added.

## Design Direction

Decko should feel:

- modern
- warm
- mobile-first
- playful but not childish
- more beautiful than a utility flashcard database
- focused during review sessions

## Theme Layers

Decko has two visual layers:

```txt
AppThemeConfig  -> app shell, navigation, surfaces, buttons
CardThemeConfig -> flashcard presentation, reveal style, content layout
```

## Initial App Themes

### Light

Clean default theme.

### Focus Dark

Low-light review experience.

### Soft Study

Warm, friendly, modern study aesthetic.

## Initial Card Themes

### Minimal

Large prompt, minimal chrome, high focus.

### Detailed

Prompt plus metadata, tags, hint, notes, and example areas.

### Game Card

More playful card treatment for challenge rounds and XP feedback.

## Core Patterns To Define During Implementation

The first UI agent should define and then imprint:

- deck library card
- import empty state
- review card surface
- answer reveal state
- rating button row
- XP session summary
- theme selector preview

## Imprinted Patterns (MVP_001)

The product shell established these reusable patterns. Reuse them rather than
re-inventing equivalents.

### Design tokens

- `core/constants/decko_spacing.dart` — `DeckoSpacing` (xs…xxxl, pagePadding) and
  `DeckoRadii` (sm/md/lg/pill). Use these instead of magic numbers.
- `app/theme/theme_registry.dart` — the single source of truth for all app and
  card themes. Every `ThemeData` is built by one `_build` helper so shape,
  buttons, cards and chips stay consistent. Add new themes here.

### Reusable widgets

- `DeckoCard` (`core/widgets/decko_card.dart`) — the flashcard surface. Renders a
  `LearningItem` in any `CardThemeStyle` (minimal / detailed / game) with a
  `revealed` flag. Shared by the review screen and the theme gallery.
- `RatingButtonRow` (`features/review/widgets/rating_button_row.dart`) — the
  Again / Hard / Good / Easy grading row. Presentational only; reports a
  `ReviewRating` upward and never schedules.
- `EmptyLibraryCard` (`features/deck_library/widgets/empty_library_card.dart`) —
  the empty-state pattern (icon tile + title + body + primary/secondary CTA).
- `PromiseTile`, `SectionHeader`, `AchievementBadge` (`core/widgets/`) — feature
  preview tile, section title+subtitle, and badge with earned/locked states.
- App theme selector + colour-swatch cluster live in the theme gallery
  (`features/themes/theme_gallery_screen.dart`).

### Added in MVP_002

- `DeckTile` (`features/deck_library/widgets/deck_tile.dart`) — inviting deck
  summary card: icon, title, `DEMO DECK` source label, description, and meta
  chips (card count, "Ready to review"). Tappable, with a trailing chevron.
  Reuse for any deck list; it deliberately reads like a card, not a table row.
- Deck detail screen (`features/deck_detail/`) — `DEMO DECK` label, title +
  description, a three-up placeholder progress summary (`Total / Due today /
  Reviewed`, the latter two shown as `—` until a scheduler exists), a sampled
  `Cards` list via `SampleItemRow`, a primary `Start review` CTA and a
  "Review modes coming soon" note.
- The empty-state card remains the fallback when the repository returns no
  decks; the populated library leads with a `Your decks` section.

### Conventions

- Buttons use the themed `FilledButton`/`OutlinedButton` (min height 56) for
  comfortable mobile tap targets.
- Icon-only buttons carry tooltips; badges/rating buttons carry `Semantics`
  labels.
- Sub-screens are pushed over the deck library so back returns to the hub.

## Accessibility Baseline

All Decko UI work should consider:

- readable contrast
- large enough tap targets
- text scaling
- screen reader labels for icon-only buttons
- motion that does not block comprehension

## Imprint Rule

When a reusable visual pattern is created, update this file using the imprint skill.
