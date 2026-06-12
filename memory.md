# Decko Memory

## Last updated
2026-06-12

## Current stage
MVP_004 complete: local persistence + real progress snapshot. Awaiting approval.

## Last completed (MVP_004)
- Added `shared_preferences` (2nd dep after go_router); justified in DEC-009.
- `ProgressSnapshot` domain model with pure `recordingSession(result, now)` (XP +10/card, level = xp~/100+1, same-day accumulation, streak +1 consecutive / reset on gap).
- New seams: `SettingsRepository` + `ProgressRepository` with `SharedPrefs*` impls (progress stored as one JSON blob; clock injectable).
- `ThemeController` now persists the selected theme and hydrates it on startup (`DeckoApp.initState` calls `load()`); theme survives restart.
- Review screen records the `ReviewSessionResult` once on completion via `DeckoApp.progressOf`.
- Progress screen rewritten (renamed progress_placeholder_screen.dart → progress_screen.dart, `ProgressScreen`): `FutureBuilder<ProgressSnapshot>`, real XP/level/streak/today, "Your latest review" card, achievements derived from snapshot, warm no-progress empty state.
- `DeckoApp` now injects deck + settings + progress repositories (defaults to SharedPrefs); exposed via scope (`themeOf`/`repositoryOf`/`progressOf`).
- Tests: 9 unit (incl. 5 ProgressSnapshot) + 7 widget (incl. theme-persist-across-restart, progress-recorded, empty-progress) = 16 total. analyze clean. Verified empty-progress on simulator; shared_preferences registers on iOS.

## Earlier (MVP_003)
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
- Local persistence via shared_preferences behind SettingsRepository/ProgressRepository (DEC-009).

## What is still placeholder
- Deck data still comes from `MockDecks` — decks themselves are NOT persisted (only theme + progress snapshot are).
- Deck detail "Due today"/"Reviewed" are `—`; no scheduler/due dates yet.
- Review ratings feed XP/streak but compute no intervals/scheduling.
- Progress is a single local snapshot, not full review history.
- Import remains "Coming soon" placeholders.

## Now persisted (MVP_004)
- Selected app theme (survives restart).
- Progress snapshot: totalXp, streak, cardsReviewedToday, lastReviewedAt, lastSessionResult.

## Next action
Awaiting approval for the next MVP. Per MVP_004 brief, candidates: JSON deck import (MVP_005, DEC-002 path), basic due-queue/review state, or first real gamification badges. Do not start without approval.

## Blockers / open questions
- Full deck persistence still uses mock data; a real DB (Drift/Isar/Hive) is the I1.6 step when decks/review history need persisting.
