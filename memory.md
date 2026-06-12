# Decko Memory

## Last updated
2026-06-12

## Current stage
MVP_001 complete: Flutter product shell built and verified.

## Last completed
- Scaffolded the Flutter app in-repo (`flutter create`, org dev.fabiani, name decko, platforms ios/android/macos).
- Added `go_router`; deferred Riverpod (see DEC-006).
- Built domain layer: `Deck`, `LearningItem`, `ReviewRating` (framework-light).
- Built centralised theme system: 3 app themes (Soft Study default, Decko Light, Decko Dark) and 3 card themes (Minimal / Detailed / Game) via `ThemeRegistry`; live in-memory switching through `ThemeController`.
- Built 5 screens: Deck Library (home), Import placeholder, Review preview, Theme gallery, Progress preview.
- Added reusable widgets: `DeckoCard`, `RatingButtonRow`, `EmptyLibraryCard`, `PromiseTile`, `SectionHeader`, `AchievementBadge`.
- Verified: `flutter analyze` clean; 3 widget tests pass (branding/CTAs, review reveal + ratings, all sub-screens open).
- Imprinted UI patterns into `docs/UI_REGISTRY.md`; recorded DEC-006.

## Files changed recently
- `pubspec.yaml`: description + `go_router` dependency.
- `lib/main.dart`, `lib/app/*` (decko_app, decko_router, theme/*).
- `lib/core/*` (constants + widgets).
- `lib/domain/*`, `lib/data/mock_decks.dart`.
- `lib/features/{deck_library,import,review,themes,progress}/*`.
- `test/widget_test.dart`: Decko smoke tests.
- `docs/DECISIONS.md` (DEC-006), `docs/UI_REGISTRY.md` (imprint).

## Decisions to remember
- Decko Iteration 1 is local-first.
- Imported deck formats are adapters, not the internal model.
- Scheduling must be FSRS-ready from the start.
- App themes and card themes are separate systems.
- GoRouter now; Riverpod deferred until real state exists (DEC-006).

## What is still placeholder
- Import buttons are "Coming soon" — no real .apkg/CSV/JSON parsing.
- Review ratings show a snackbar and reset; no scheduling yet.
- Theme selection is preview-only (in-memory, not persisted).
- Progress values (XP 120, streak 3, reviewed 18, level 2) are mock data.

## Next action
Awaiting approval. Recommended next: MVP_002 — local demo deck model + navigation (deck library lists real `Deck`s from a repository, deck detail screen, demo deck wired through). Do not start without approval.

## Blockers / open questions
- Persistence library still unchosen (not needed until I1.6).
