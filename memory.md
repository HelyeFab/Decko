# Decko Memory

## Last updated
2026-06-12

## Current stage
MVP_003 complete: simple review session state built and verified. Awaiting approval.

## Last completed (MVP_003)
- Domain: `ReviewSession` (immutable, copyWith), `ReviewAnswer`, `ReviewSessionResult` (per-rating counts) — framework-light.
- Scheduler seam: `ReviewScheduler` interface + `SimpleReviewScheduler` (in-order queue, pure transitions, answeredAt injected). This realises the DEC-003 seam — recorded as DEC-008.
- Reworked review screen into a real session: renamed `review_placeholder_screen.dart` → `review_session_screen.dart` (`ReviewSessionScreen`, takes required Deck + injectable scheduler). Three states: reviewing (Card X of N + progress bar), complete (`SessionSummary`), empty ("This deck has no cards yet.").
- Empty deck no longer falls back to a sample card (closes the MVP_002 deferred note).
- Routing: `/deck/:deckId/review` → `ReviewSessionScreen`; orphan `/review` now redirects to home. "Back to deck" uses `context.go(/deck/:id)`.
- Tests: 4 pure scheduler unit tests (`test/review_session_test.dart`) + 7 widget tests incl. full loop, review-again, back-to-deck, empty-deck. All pass; analyze clean.

## Deferred notes (see docs/ROADMAP.md "Deferred Notes")
- Empty-deck handling: DONE in MVP_003 (review shows "This deck has no cards yet.").
- Still open: normalise Japanese readings to kana for real decks (demo data mixes kana/romaji).

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
- Review scheduler seam is `ReviewScheduler`; SimpleReviewScheduler now, FSRS later (DEC-008).

## What is still placeholder
- All deck data comes from `MockDecks`; no persistence (sessions reset on exit).
- Deck detail "Due today"/"Reviewed" are `—`; no scheduler/history.
- Review ratings only affect the current in-memory session — no due dates/intervals.
- Session results are not persisted; gamification (XP/streak) is still mock.
- Import remains "Coming soon" placeholders.
- Theme selection is in-memory only.

## Next action
Awaiting approval for the next MVP. Likely next per MVP_003 brief: JSON deck import adapter (DEC-002 path), OR persist local decks + theme, OR FSRS-ready review state. Do not start without approval.

## Blockers / open questions
- Persistence library still unchosen (needed around roadmap I1.6).
