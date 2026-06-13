# Decko Memory

## Last updated
2026-06-12

## Current stage
MVP_008 complete: Anki media import + rendering (audio + images). Awaiting approval.

## Last completed (MVP_008)
- Deps: path_provider, audioplayers (DEC-014).
- `MediaStore` interface + `FileMediaStore` (app support dir /decko_media/<deckId>/<file>; injectable baseDir for tests). Exposed via DeckoApp.mediaOf.
- Importer: reads package `media` map, extracts every payload to MediaStore under original name (single decode; one file at a time); preview reports mediaFiles/audioRefs/imageRefs.
- Field cleaning now PRESERVES `[sound:x]` and normalised `<img src="x">` (+ furigana); media in separate note fields gathered onto the front. Fixed example-fallback bug (required `_hasJapanese` so it won't pick id fields like `item:435851`).
- `core/content/anki_content.dart`: parseAnkiContent → text/audio/image segments; stripMedia, mediaMarkers, counts. `DeckoFieldContent` renders them (FuriganaText / AudioButton via audioplayers / Image.file). DeckoCard takes deckId, uses DeckoFieldContent for front/back/example.
- Swipe-delete also deletes the deck's media. SampleItemRow strips media.
- Verified on real "+ Images" deck: 999 cards, 597 media, front gets audio+image markers, no junk example.
- Follow-ups (post-test): (1) card layout — meaning now prominent (headlineSmall), example in a labelled tinted box (`_ExampleSection`) so word-meaning and sentence don't blur; (2) ALL icons → Font Awesome free (`font_awesome_flutter`, FaIcon/FaIconData) DEC-015; centered fixed-size icon containers (deck tile, badge) with `alignment: Alignment.center`. 54 tests, analyze clean.
- Known nuance: Core 2k Optimized has an 11-field note with a pitch-accent SVG in the reading field; mapping survives via collapseRepeat but SVG-derived readings could occasionally be imperfect (not addressed).

## Earlier (MVP_007)
- `ReviewSchedulingPolicy` is now an INTERFACE; `FsrsSchedulingPolicy` (lib/data/) is a pure-Dart FSRS-5 impl with default weights (no dependency). Injected into the review screen (default FSRS); UI has no scheduling maths (DEC-013).
- `ReviewCardState` gained nullable `stability`/`difficulty`/`schedulerVersion` (safe migration; serialized in SharedPrefsReviewStateRepository).
- Imported/legacy cards: scheduler only runs on grade, so un-reviewed cards keep imported due dates; first grade seeds S/D from interval/ease/lapses — never reset (DEC-005).
- Verified numbers: new Good=3d, Easy=16d; repeated Good 3→11→35→101→269d. 46 tests (FSRS policy tests + existing); analyze clean.
- Old fixed policy (now/1d/3d/7d) removed; review_state_test rewritten for FSRS (relative assertions).

## Earlier (MVP_006)
- `ReviewCardState` (+ ReviewQueueState enum) persistent per-card state; `fromLearningItem` maps imported Anki progress.
- `ReviewStateRepository` + `SharedPrefsReviewStateRepository` (per-deck JSON blob, key `decko.reviewState.<deckId>`).
- Pure `DueQueue.build` (due review → due learning → new; suspended/future excluded) and pure, TEMPORARY `ReviewSchedulingPolicy` (Again→now/relearning, Hard→+1d, Good→+3d, Easy→+7d) — NOT FSRS (DEC-011).
- Review screen rewritten: loads states → builds due queue → walks it; grading applies policy, updates in-memory (due moves live), flushes changed states on session exit (complete/back/dispose). "All caught up." empty-queue state.
- Import seeds review state on commit (keep vs fresh). Deck detail Due/Reviewed now read from ReviewStateRepository (FutureBuilder) — decrement after review, survive restart.
- DeckoApp exposes `reviewStateOf`; injectable. 38 tests (new review_state_test.dart: policy, queue ordering, state mapping, repo round-trip; widget tests: due-decrement, all-caught-up, suspended-excluded). analyze clean.
- Floating bottom-nav requested during testing → ROADMAP Deferred Notes (needs StatefulShellRoute; its own MVP).
- Real-deck field-mapping fix: parse furigana (`<ruby>`/`漢字[よみ]`) → kanji + separate reading (single-word only); split rich Back blob into meaning + example, drop `[sound:]`/id junk/front-duplicate lines. Verified against real Kuchiguse Tier 2 .apkg. RE-IMPORT to apply.
- Added swipe-left-to-delete for imported decks (Dismissible + confirm dialog; also resets that deck's review state). DeckStore.removeImportedDeck. Demo decks not deletable.
- Furigana (DEC-012): importer now PRESERVES furigana as bracket notation `漢字[かな]` (was stripped). `FuriganaText` renders ruby; toggle (translate icon in review app bar) persisted via FuriganaController+settings (default on). Example sentence emphasised (titleLarge) with translation muted. Demo Japanese deck updated to use furigana brackets. SampleItemRow uses FuriganaText (base-only). RE-IMPORT real decks to get furigana.
- Fix: deck detail now refreshes Due/Reviewed on RETURN from review (was stale unless you went out to the library). Deck detail is StatefulWidget; "Start review" awaits the push then reloads. Review screen flushes state and pops via `_leave` (PopScope intercepts app-bar/system back so mid-session stop also flushes before the detail re-reads). 39 tests (added mid-session-back test).

## Earlier (MVP_005)
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
- Persistent per-card ReviewCardState + due queue + write-back (DEC-011).
- Furigana preserved as 漢字[かな], toggleable ruby (DEC-012).
- Scheduling: FSRS-5 policy, pure Dart, default weights, behind the seam (DEC-013).

## What is still placeholder
- FSRS uses DEFAULT weights (no per-user training) and no intra-day learning steps — FSRS-style, not Anki parity.
- Modern zstd `.anki21b` not supported (legacy export only).
- Import ignores media (image/audio) and templates; multi-deck packages collapse; field mapping heuristic.
- Demo deck content still from `MockDecks` (but their review state now persists once studied).
- Review-state storage = per-deck JSON blob in shared_preferences (flush on session exit); large libraries want a DB later.

## Now persisted
- Selected app theme; progress snapshot (MVP_004).
- Imported decks incl. cards + provenance (MVP_005).
- Per-card review state incl. FSRS stability/difficulty (MVP_006/007); due decrements & survives restart.

## Next action
Awaiting approval. Per MVP_007 brief, next candidates (MVP_008): media import (audio/images), modern .anki21b support, or floating bottom-nav UI (StatefulShellRoute). Do not start without approval.

## Blockers / open questions
- Real-.apkg testing needs the user (export with "Support older Anki versions"; simctl can't drive the picker).
- Per-grade write cost on very large decks mitigated by flush-on-exit; revisit with a DB if it bites.
