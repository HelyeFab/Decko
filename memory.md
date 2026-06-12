# Decko Memory

## Last updated
2026-06-12

## Current stage
MVP_005 complete: progress-aware Anki .apkg import (legacy format). Awaiting approval.

## Last completed (MVP_005)
- Added deps: file_picker, archive, sqlite3 + sqlite3_flutter_libs (DEC-010).
- Import domain (`lib/domain/import/`): DeckImportAdapter + exceptions, DeckImportPreview, ImportedCardProgress + ImportedCardState, DeckImportInfo (provenance + ImportProgressMode). Extended Deck (importInfo) and LearningItem (importedProgress).
- `AnkiApkgImportAdapter` (`lib/data/import/`): unzip → read collection.anki2/.anki21 via sqlite3 → map notes/cards → counts + per-card progress. Rejects zstd .anki21b with a clear message; ALL failures → DeckImportException (never crashes).
- Persistence: imported decks as JSON in shared_preferences (`ImportedDeckStorage`), fronted by `DeckStore` (ChangeNotifier implements DeckRepository) wrapping the demo repo; hydrates at startup, adds on import. Library uses ListenableBuilder over the store; imported decks list first.
- Import UI: phase-machine `ImportScreen` (idle→analysing→preview→importing→error) + `ImportPreviewPanel` (keep/start-fresh or honest no-progress warning). Deck detail shows provenance; tiles label Imported vs Demo.
- DeckoApp now exposes `deckStoreOf`; repositoryOf returns the DeckStore.
- Tests: import_test.dart builds a SYNTHETIC .apkg (sqlite3+archive) and tests parse/keep/fresh/no-progress/zstd-reject/garbage + storage round-trip; widget_test adds 2 ImportPreviewPanel tests. 25 tests total, analyze clean.
- Follow-up fixes after real-deck testing (Core 2k/6k, 17987 cards imported OK):
  - file picker: iOS greyed out .apkg with FileType.custom; switched to FileType.any + validate `.apkg` in code.
  - reusable `DeckoSnackbar` (core/widgets) replaces the raw import SnackBar.
  - deck detail Due today / Reviewed now computed from imported progress (were hardcoded `—`).
  - field mapping made content-aware: kana field → reading, sentence → example, dedupe repeated tokens (fixed "さん さん" doubling). RE-IMPORT needed to apply to already-imported decks.
- Open from MVP_005 testing (see ROADMAP Deferred Notes): scheduler write-back so Due decrements after review (NEXT MVP candidate); media (image/audio) import; modern .anki21b; note-type-aware field mapping.
- Real-deck import verified manually on simulator; modern-format/large decks still need broader testing.

## Earlier (MVP_004)
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
- Anki import: legacy .apkg only, behind DeckImportAdapter, decks in a DeckStore (DEC-010).

## What is still placeholder
- Demo deck data still comes from `MockDecks`; imported decks ARE persisted now.
- Modern zstd `.anki21b` not supported (legacy export only) — deferred.
- Imported progress is stored/labelled but does NOT drive scheduling yet.
- Deck detail "Due today"/"Reviewed" are `—`; no scheduler/due dates.
- Import handles a practical subset: ignores media, templates, model fidelity; multi-deck packages collapse into one; field mapping is field0/1/2.

## Now persisted
- Selected app theme; progress snapshot (MVP_004).
- Imported decks incl. cards + per-card imported progress + provenance (MVP_005).

## Next action
Awaiting approval. Per MVP_005 brief, candidates: MVP_006 import field-mapping/compatibility improvements, basic due-queue from imported progress, JSON/CSV adapter, or review history/full progress storage. Pick after testing real personal decks. Do not start without approval.

## Blockers / open questions
- Needs manual test with a REAL .apkg (export with "Support older Anki versions"); not doable here (no file, simctl can't drive the picker).
- Modern .anki21b (zstd) decoding is the likely first compatibility gap users hit.
