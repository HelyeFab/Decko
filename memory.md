# Decko Memory

## Last updated
2026-06-12

## Current stage
MVP_002 complete and APPROVED (2026-06-12): local demo deck model + navigation.

## Deferred notes (see docs/ROADMAP.md "Deferred Notes")
- Empty deck (zero items) should later show "This deck has no cards yet." instead of the current sample-card fallback in review.
- Normalise Japanese readings to kana for real decks (demo data mixes kana/romaji).

## Last completed (MVP_002)
- Added `DeckRepository` interface (`lib/domain/repositories/deck_repository.dart`) and `MockDeckRepository` backed by `MockDecks`.
- Expanded `MockDecks` to two demo decks (Japanese Starter Deck, Travel Phrases); friendlier titles.
- Deck library now renders `DeckTile`s from the repository; MVP_001 empty-state kept as a fallback (injectable empty repo proves it).
- New deck detail screen (`features/deck_detail/`) with placeholder progress summary, sampled cards, "Start review", "Review modes coming soon".
- Routing: `/deck/:deckId` and `/deck/:deckId/review`; route builders resolve the deck via `DeckoApp.repositoryOf` (DEC-007); unknown id → "deck not found". "Explore demo deck" now opens deck detail, not review directly.
- Review screen accepts an optional `Deck` and previews its first card (falls back to sample); app bar shows the deck name.
- Repository exposed through the app scope (renamed `_ThemeScope` → `_DeckoScope`, added `DeckoApp.repositoryOf`); `DeckoApp` takes an injectable `deckRepository`.
- 5 widget tests cover the full flow incl. empty fallback; `flutter analyze` clean.

## Earlier (MVP_001)
- Flutter shell scaffolded (org dev.fabiani); go_router added, Riverpod deferred (DEC-006).
- 5 screens, domain models, centralised theme system (3 app + 3 card themes), reusable widgets.
- Fixed home promise-grid overflow (aspect ratio 1.0 + maxLines/Flexible).

## Decisions to remember
- Local-first Iteration 1 (DEC-001).
- Import formats are adapters, not the internal model (DEC-002).
- FSRS-ready model from the start; SimpleScheduler behind interface later (DEC-003).
- App themes vs card themes are separate (DEC-004).
- Never silently reset imported progress; progress-aware import (DEC-005; see docs/import-progress.md).
- GoRouter now, Riverpod deferred (DEC-006).
- Decks read via DeckRepository, resolved by id in routes (DEC-007).

## What is still placeholder
- All deck data comes from `MockDecks`; no persistence.
- Deck detail "Due today"/"Reviewed" are `—`; no scheduler/history.
- "Start review" previews the first card only — no real review queue.
- Ratings show a snackbar; no scheduling/state update.
- Import remains "Coming soon" placeholders.
- Theme selection is in-memory only.

## Next action
Awaiting approval for the next MVP. Brief present: none yet beyond MVP_002. Likely next: MVP_003 (JSON deck import) or MVP_004 (simple review session state). Do not start without approval.

## Blockers / open questions
- Persistence library still unchosen (needed around roadmap I1.6).
