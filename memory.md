# Decko Memory

## Last updated
2026-06-22

## Current stage
MVP_019 in review: Activity Ledger, XP, Streaks & Heatmap (DEC-028). A durable
local `ActivityEvent` ledger (file-backed JSON at <appSupport>/decko_activity/
events.json) records review + practice over time. Pure ActivityProgressCalculator
derives total/review/practice XP, XP today, cards/practice today, current+longest
streak (from active days), GitHub-style heatmap (84d), recent activity. Progress
screen REWRITTEN ledger-backed (heatmap + recent + review-vs-practice XP on the
level card; daily goal now activity-COUNT based = reviews+practice rounds, default
20). Review session + Bunburu/Listening record ActivityEvents (practiceOutcomeSink
writes BOTH snapshot + ledger). Legacy ProgressSnapshot PRESERVED + migrated ONCE
(idempotent, ActivityMigration in DeckoApp.initState) as legacy baseline events (XP
kept; streak reconstructed so it survives; legacy excluded from heatmap). Review/
FSRS/due/counters UNTOUCHED. 169 tests, analyze clean. NOT committed — awaiting
verification. NEXT: MVP_020 Auth & Firebase sync.

## Last completed (MVP_018 — Listening Challenge, DEC-027) committed ccf7733: SECOND registered
practice mode (`listening_challenge`), proving the MVP_017 platform. Word audio
(front) → pick meaning; sentence audio (example) → pick the matching sentence (or
translation when a deck has Sentence-English); reveal shows a meaning context.
`ListeningChallengeBuilder` (pure/local/deterministic) does availability +
distinct same-kind choice gen; surfaces via the registry in Deck Detail / Hub /
review manual actions (ONE new PracticeLauncher case, no other screen touched).
Manual + deck practice only (motivational XP; reviewPresentation=false, deferred).
FSRS/review untouched (DEC-027). Progress level card now shows combinedXp (review
+ practice). 159 tests, analyze clean, verified on iOS sim.

## Last completed (MVP_018 — Listening Challenge, DEC-027)
- Domain (`lib/domain/listening/`): ListeningChallengeRound/Session/Result +
  PromptKind/Source enums; pure `ListeningChallengeBuilder` (cardFor: word audio
  from item.front via soundRefIn → cleaned back; else sentence audio from
  item.example → Sentence-English/back; isCapable/deckIsCapable(>=4);
  roundForItem/roundsForDeck with 4 distinct choices — 1 correct + 3 distractors,
  random selection, graceful when <4 audio cards). Reuses sentence_text
  soundRefIn/cleanSentence.
- PracticeModeId.listeningChallenge ('listening_challenge'); registered in
  DeckoPracticeModeRegistry (manualLaunch true, reviewPresentation FALSE).
- PracticeLauncher: listening case (SYNC, no async service — local audio +
  existing text). launchCard now takes `Deck deck` (needs the deck for
  distractors) — review caller passes widget.deck.
- `features/listening/ListeningChallengeScreen`: play/replay button, 4 choice
  cards, feedback, next/finish, completion + XP pill, audio-unavailable state
  (MediaStore + audioplayers, autoplay per round). Reports PracticeOutcome
  (modeId listeningChallenge, 5 XP/correct). practiceModeIcon/practiceCardAction
  gained the listening case (headphones / "Listen & choose").
- Tests: listening_test.dart (7: availability, choice gen, registry) + 1 widget
  (full flow + practice-XP-not-review-state boundary). 159 total.
- DEFERRED: scheduler-routed listening review; richer prompt targets; typing.

## Last completed (MVP_017 — practice-mode platform — Bunburu is now the first
REGISTERED practice mode. `PracticeModeRegistry` (availableForCard/Deck,
manual/reviewPresentation modes) + `DeckoPracticeModeRegistry` (Bunburu);
Deck Detail / Practice Hub / Review discover modes via the registry (no
hard-coded games); `PracticeLauncher` maps mode→screen. `PracticeOutcome` seam →
motivational only: ProgressSnapshot.practiceXp + practiceCount (combinedXp counts
toward LEVEL; review metrics/totalCardsReviewed untouched). Manual practice never
mutates review state; scheduled review still grades through ReviewScheduler
(DEC-026). 150 tests, analyze clean. Committed.

## Last completed (MVP_017 — practice-mode platform, DEC-026)
- Domain (`lib/domain/practice/`): PracticeMode (id/title/sub/desc/kind/
  manualLaunch/reviewPresentation), PracticeModeId (bunburuSentenceBuilder +
  storageKey), PracticeOutcome (+ toJson/fromJson) — Codex-authored models.
  Registry iface `lib/domain/repositories/practice_mode_registry.dart`;
  `lib/data/decko_practice_mode_registry.dart` (availability via
  SentenceBuilderMapper.looksCapable). In DeckoApp scope (practiceRegistryOf).
- Progress: ProgressSnapshot.practiceXp/practiceCount + recordingPractice(xp)
  (review fields untouched); combinedXp drives currentLevel/xpIntoLevel;
  totalCardsReviewed still review-XP-only. ProgressRepository.recordPracticeOutcome
  + migration-safe serialization.
- UI: `features/practice/` — PracticeHubScreen (Available now / From your decks,
  registry-driven), PracticeLauncher (mode→screen), PracticeModeTile (+ icon/
  action-label maps). Deck-detail `_PracticeModesSection`; review manual buttons
  via registry; SentenceBuilderScreen reports PracticeOutcome on completion (5 XP
  per correct sentence) + shows +XP pill. Old SentenceBuilderHubScreen deleted;
  Home "Practice" row → PracticeHubScreen (gamepad).
- Tests: practice_test.dart (7: registry availability, recordingPractice
  boundary, outcome json, recordPracticeOutcome persist) + 2 widget (manual
  practice records XP not review state; Home→hub). 150 total.
- DEFERRED: a 2nd game, richer per-mode outcomes, coming-soon placeholders (omitted).

## Last completed (MVP_016 — Bunburu sentence builder — a Decko-native sentence-unscramble
game from imported sentence fields. Japanese tokenised into WORD-level tiles
(with furigana) by the Bunburu kuromoji micro-service (POST /furigana; app key
in gitignored .env via --dart-define-from-file), cached per deck on disk. FOUR
surfaces: Home "Practice" hub, manual per-card ("Build this sentence"),
deck-detail tile, OPT-IN review presentation (global `sentenceBuilderReview`,
grades through the normal seam). Practice records nothing to review/progress —
FSRS untouched (DEC-025). Earlier in-house tokenisers (script-boundary, BudouX)
rejected; BudouX removed. Tokenizer client/models ported by Codex. 142 tests,
analyze clean, builds+runs on iOS sim with the .env key. User-verified live:
word tiles + furigana + sentence audio button + random deck-practice selection.
Committed. (Audio [sound:…] is also read from item.example, not just note fields.)

## Last completed (MVP_016 — Bunburu sentence builder, DEC-025)
- Tokenization via the Bunburu kuromoji micro-service (POST /furigana; key in
  gitignored .env via --dart-define-from-file) → word-level CubeTokens +
  furigana. Pipeline: SentenceBuilderMapper (SYNC sentence picker; [sound:] →
  audioRef incl. from item.example) → SentenceRoundService (ASYNC: per-deck
  FileSentenceTokenCache + batch tokenize, skip <2 tiles; random deck-practice
  selection). Tokenizer client + CubeToken/FuriganaSegment ported by Codex.
  (Earlier in-house tokenisers — script-boundary, BudouX — rejected & removed.)
- StudyOptions gained global `sentenceBuilderReview` (form toggle, in
  EffectiveStudyOptions). Review session async-loads the builder round
  (FutureBuilder + fallback to normal card), grading via the existing _rate →
  ReviewScheduler seam.
- UI: SentenceBuilderView (cube tiles + furigana ruby + audio button),
  SentenceBuilderScreen, SentenceBuilderLoader (spinner/error/empty),
  SentenceBuilderHubScreen. Four surfaces: Home "Practice" hub, manual per-card,
  deck-detail tile, opt-in review presentation.
- LAYOUT GOTCHA: SentenceBuilderView action buttons must avoid Row+Expanded
  (infinite-width in the review body) — stacked full-width; review builder area
  uses a ListView.
- Tests: 13 domain/service (fake SplitTokenizer + in-memory cache) + 4 widget.
  142 total. analyze clean; verified live on iOS sim.
- DEFERRED: builder audio autoplay, hearts/timed/daily modes, routing policy,
  per-deck flag, Decko-hosted tokenizer service, deck bulk pre-tokenize.

## Last completed (MVP_015 — progress polish & light gamification, DEC-024)
- Data: ProgressSnapshot gained monotonic `longestStreakDays` (migration-safe
  back-fill). Daily goal in SettingsRepository (default 20), exposed via
  DeckoApp.settingsOf. `lib/domain/achievement.dart`: pure achievementsFor
  (firstReview/dailyGoal/threeDayStreak/hundredCards), derived from snapshot.
- Progress screen: `_DailyGoalCard` ring (celebratory "reached!" state), kinder
  streak via `_StatCard.footnote`, `_AchievementsGrid`, level/latest kept.
- Completion: SessionSummary `_RewardChips` (XP gained / goal progress / streak);
  review session `_recordProgress` loads post snapshot+goal into the summary.
- Settings hub: `_DailyGoalControl` stepper (5–100, step 5).
- Tests: progress_gamification_test.dart (8) + 2 widget (progress celebrate,
  summary chips). 125 total.

## Last completed (MVP_014 — import diagnostics UX, DEC-023)
- ImportDiagnostics upgraded: ImportDiagnostic {category, severity, message,
  technicalDetail}, DiagnosticCategory/DiagnosticSeverity, derived ImportHealth
  (healthy/usableWithWarnings/blocked). Serialized; persisted on DeckImportInfo
  (via ImportedDeckStorage) so the report is revisitable.
- ImportHealthSummary (features/import/widgets): status header + plain-language
  metadata chips + grouped findings + collapsed "Technical details". Reused in
  the import preview, the post-import RESULT phase (warnings only; clean imports
  keep snackbar→Home), and ImportReportScreen (route /deck/:id/report, reached
  from an "Import report" tile on deck detail).
- Blocking/unsupported remain typed exceptions → import error state.
- Tests: health summary healthy/warning/blocking + technical expansion +
  deck-detail→report + reworked preview test. 115 total.
- NOTE: decks imported before MVP_014 have no stored diagnostics → "no report".

## Last completed (MVP_013 — import compatibility hardening, DEC-022)
- Modern collection: detect `collection.anki21b` → zstd-decompress (injectable
  `ZstdDecoder` + `ZstandardDecoder` native plugin) → existing SQLite reader
  (same schema). `LearningItem.id = anki-card-<cardId>` preserved; FSRS/progress
  untouched. `_parse` is now async.
- Modern media: zstd payloads + zstd `MediaEntries` protobuf index, hand-parsed
  (name only) in `lib/data/import/media_entries.dart`, best-effort + graceful.
- `ImportDiagnostics` (format/collection/counts/warnings/blockingError) in
  `lib/domain/import/`; surfaced in ImportPreviewPanel. Specific user errors
  (no collection, undecodable modern, corrupted, missing tables) — no raw SQLite.
- Adapter takes `AnkiApkgImportAdapter({zstd})`; tests inject identity/failing
  fakes. Fixtures gained a `modern` flag (collection.anki21b + protobuf media).
- Tests: 9 import-hardening (legacy diagnostics, modern import+format, modern
  media, undecodable→clear, no-collection, missing-tables, missing-manifest
  warning, unfamiliar fields, garbage) + 1 preview-diagnostics widget. 111 total.
- DEFERRED/NOTE: media protobuf is name-only best-effort; CocoaPods install
  pending for on-device verification.

## Last completed (MVP_012 — advanced deck option profiles, DEC-021)
- Profiles: `StudyOptionProfile {id,name,options,isDefault}` (synthetic default
  mirrors global); `DeckStudyOptions.profileId`; resolution global/default →
  profile → deck override; dangling profileId → global fallback; default
  protected from deletion. In study_options.dart + SharedPrefs repo.
- TRUE daily limits: `DailyStudyCounts` (day/new/review/studiedNoteIds) +
  `DailyStudyCountsRepository`/SharedPrefs + `DeckoApp.dailyCountsOf`. Review
  session caps by remaining = limit − studiedToday; grade records PRE-grade
  kind; persists on flush. Second same-day session keeps allowance; new day
  resets (local-day boundary).
- BURY siblings ENFORCED in `DueQueue.build` (filters only): drop notes studied
  earlier today + one card per note per build. Note id from
  importedProgress.sourceNoteId or preserved-source card→note map (review
  `_loadNoteMap`). Demo decks no-op.
- New-card order (deckOrder/random) behind a collapsed Advanced section.
- UI: Settings hub "Study profiles" (StudyProfilesScreen + ProfileEditorScreen);
  deck options profile selector + Advanced override; shared `StudyOptionsForm`.
- DEFERRED (documented): desired retention + max interval (FSRS plumbing);
  import-aware suggestions. Edge: bury reserves a note before caps.
- Tests: 13 pure (resolution, profile repo + delete fallback, daily limits 2nd
  session/reset, bury, new-card order) + 2 widget (daily counts honoured;
  profile assignment). 100 total. Adversarial subagent review: safety holds.

## Last completed (MVP_011 — study options & deck overrides, DEC-020)
- Domain (`lib/domain/study_options/`): `StudyOptions` (global), `DeckStudyOptions`
  (nullable overrides + deck-only `FuriganaPreference`), `EffectiveStudyOptions.
  resolve(global, deck)` (deck wins per-field, else global). Enums
  AudioAutoplayMode/ImageDisplayMode/FuriganaPreference.
- `StudyOptionsRepository` + `SharedPrefsStudyOptionsRepository` (global key +
  per-deck key; deleted with deck). `DeckoApp.studyOptionsOf`.
- `DueQueue.build` gained optional maxNew/maxReview/maxSession; review session
  builds the capped queue from effective options. Caps only trim which cards
  enter a session — state/FSRS untouched. "Per day" = per session for now.
- Review session: autoplay per AudioAutoplayMode (own AudioPlayer, parses
  front/back [sound:]); `DeckoCard.showFrontImage` hides question image when
  ImageDisplayMode.afterReveal; furigana via resolveShowFurigana(globalToggle).
- UI: Settings tab → `SettingsHubScreen` (Study defaults · Themes · furigana);
  theme gallery moved to /settings/themes. `GlobalStudyOptionsScreen`
  (/settings/study) + `DeckOptionsScreen` (/deck/:id/options) from a "Deck
  options" tile on deck detail. Reusable controls in
  features/settings/widgets/option_controls.dart.
- Tests: 11 pure (resolution, furigana, serialization, queue caps) + 2 widget
  (open+persist deck override; review respects max-session). 85 total.

## Last completed (MVP_010 — note-type-aware card mapping, DEC-019)
- `NoteTypeAwareCardMapper` (`lib/domain/import/`, pure): ImportedAnkiSource +
  one ImportedAnkiCardSource → `CardMapping` (front/back/reading/example +
  `ReviewCardMode` {generic,listening,reading,production} + inspect rationale
  matchedBy/frontFields/backFields). Template identity first, then named field
  roles (expression/reading/meaning/sentence/sentence-kana/-english/-audio/
  word-audio/image). Generic Front/Back/Field names match nothing →
  recognized:false → adapter keeps positional content (simple/demo decks
  untouched).
- Per mode: Listening = audio-first front (word on back); Reading = JP-text
  front; Production = English prompt, JP hidden until flip.
- `ReviewCardMode` (`lib/domain/review_card_mode.dart`) + `LearningItem.mode`
  (default generic). `DeckoCard` shows a quiet small-caps mode eyebrow (no
  badge). Inspect screen gained a "Card mapping" section (mode chip + matched-by
  + front/back fields per template).
- SAFETY (held): `LearningItem.id` stays `anki-card-<cardId>`, imported progress
  unchanged — only content arrangement changes, review state/FSRS never reset.
- Mapping runs at IMPORT time → RE-IMPORT already-imported decks to get modes.
- Tests: 8 pure mapper + 2 adapter integration (3-template → 3 distinct modes;
  simple deck stays generic) + 2 DeckoCard widget (listening eyebrow; production
  hides JP until flip). 72 total.
- Brief renamed on disk to MVP_010_NOTE_TYPE_AWARE_DECKO_CARD_MAPPING.md.

## Last completed (MVP_009 — lossless Anki source, DEC-016)
- Import now preserves the FULL Anki source before deriving the simplified
  Decko study card. Domain: `ImportedAnkiSource` (models, notes, cardSources)
  in `lib/domain/import/source/`; `ImportedAnkiNote`/`ImportedAnkiField`
  (name, ordinal, rawValue, plainTextValue, mediaReferences),
  `ImportedAnkiModel` (fieldNames + templates), `ImportedAnkiCardTemplate`
  (ordinal, name, q/a), `ImportedAnkiCardSource` (card→note→template link).
- Persistence: `ImportedSourceStore` interface + `FileImportedSourceStore`
  (one JSON file per deck under app-support; off shared_preferences for size).
  Wired through DeckImportAdapter → DeckoApp.sourceOf → import screen; deck
  delete removes the stored source.
- Adapter parses `col.models` (field names + templates by ordinal), names note
  fields, records per-field media refs, links cards to template ordinals; saves
  source on import. The review card is still derived by the existing positional
  mapping (NOT yet note-type-aware — that's MVP_010).
- Inspect UI: `ImportedSourceScreen` (`features/imported_source/`), reached from
  a "View imported source" tile on deck detail (imported only), route
  `/deck/:id/source`. Decko-styled: summary, note-type field/template chips,
  cards-by-template breakdown, sample note's fields + tags + media pips. Empty
  state for pre-feature/demo decks.
- Tests: rich `_buildSourceApkg` fixture (named fields, multi-template models,
  capturing store) → field name/ordinal/raw, tags, per-field media refs, model +
  Listening/Reading/Production template identity, card→template linking; widget
  test inspects preserved source from deck detail.
- KNOWN: a 3-template note still yields 3 lookalike study cards (the 3× / 17987
  inflation). Fixing it is MVP_010, which consumes this preserved source.

## Earlier (MVP_008.5 — app shell, study-first Home, floating nav; DEC-017/018)
- `DeckoAppBar` (`core/widgets/`): one app-bar pattern — `.wordmark` on Home,
  titled on sub-screens; adopted across Home/Import/Deck Detail/Progress/Settings.
- Home reworked to "study ribbon" (Direction A): `StudyRibbon` hero (stacked-
  flashcard motif naming the resume deck + ready count, "all caught up" when
  none due) + compact `DeckRow` shelf with live per-deck to-study badges
  (`DueQueue` over review state, refreshed on return) + dashed Import row. The
  marketing promise grid now lives ONLY in the empty state.
- Floating bottom nav: `DeckoBottomNav` (rounded, elevated, content-hugging
  active pill flush with the bar) over a `StatefulShellRoute.indexedStack` —
  Home/Import/Progress/Settings(theme gallery). Deck detail sits in the Home
  branch (bar stays, Back→Home); review session is pushed full-screen on the
  root navigator. Import resets to idle after a successful import.

## Earlier (MVP_008)
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
- Anki media imported to local files, rendered by a field-content parser (DEC-014).
- Iconography uses Font Awesome free, via FaIcon/FaIconData (DEC-015).
- Anki imports preserve a lossless source note layer before mapping to Decko cards (DEC-016).
- Reusable app shell (DeckoAppBar) + Home separated from the Import workflow (DEC-017).
- Floating bottom nav over a StatefulShellRoute (Home/Import/Progress/Settings) (DEC-018).
- Note-type-aware card mapping from the preserved source; positional fallback (DEC-019).
- Two-level study options (global + per-deck overrides → effective); per-session caps (DEC-020).
- Study option profiles (global→profile→deck), TRUE daily limits, enforced sibling burying (DEC-021).
- Modern .anki21b (zstd) import + ImportDiagnostics + specific failure messages; CocoaPods now needed for iOS (DEC-022).
- Import diagnostics are user-facing trust signals (severity/health + ImportHealthSummary + persisted report), not parser logs (DEC-023).

## What is still placeholder
- FSRS uses DEFAULT weights (no per-user training) and no intra-day learning steps — FSRS-style, not Anki parity.
- Modern zstd `.anki21b` not supported (legacy export only).
- Note-type-aware mapping (MVP_010) now makes Listening/Reading/Production cards
  distinct, BUT it's heuristic (template/field-name synonyms; add more over time)
  and furigana is still globally toggled, not hidden per-face. RE-IMPORT decks to
  apply. Positional fallback handles simple/demo decks.
- Demo deck content still from `MockDecks` (but their review state now persists once studied).
- Review-state storage = per-deck JSON blob in shared_preferences (flush on session exit); large libraries want a DB later.

## Now persisted
- Selected app theme; progress snapshot (MVP_004).
- Imported decks incl. cards + provenance (MVP_005).
- Per-card review state incl. FSRS stability/difficulty (MVP_006/007); due decrements & survives restart.
- Extracted media on disk per deck (MVP_008); lossless Anki source JSON per deck (MVP_009).

## Next action
No brief queued. Per MVP_016 follow-ups: richer Bunburu modes (hearts, timed,
daily challenge), builder sentence-audio playback, a smarter policy for WHEN to
route a review to the builder, a game-mode hub, or other practice modes. Smaller
ROADMAP follow-ups: full media-protobuf parsing, desired retention + max interval
(FSRS plumbing), import-aware profile suggestions, per-deck sentenceBuilderReview,
morphological tokenisation.

## Blockers / open questions
- Real-.apkg testing needs the user (export with "Support older Anki versions"; simctl can't drive the picker).
- Per-grade write cost on very large decks mitigated by flush-on-exit; revisit with a DB if it bites.
- Sentence builder needs the Bunburu tokenizer service: teammates need their own gitignored `.env` (BUNBURU_API_URL + BUNBURU_APP_KEY) and must run `--dart-define-from-file=.env`; offline → clean "tokenizer unavailable" state.
