# Decko Decisions

This file records durable product and architecture decisions.

## DEC-001: Decko is local-first for Iteration 1

Date: 2026-06-12
Status: Accepted

### Context

Iteration 1 needs to prove the core review experience before accounts, cloud sync, payments, or collaboration are introduced.

### Decision

Decko Iteration 1 is local-first. Imported decks, review state, themes, XP, streaks, and session history should work without login.

### Consequences

- Faster MVP implementation.
- Easier offline support.
- No backend required for first agent work.
- Future sync must be designed as an additional layer, not baked into the UI.

### Alternatives considered

- Start with cloud sync: rejected because it would delay the core product experience.

## DEC-002: Imported deck formats are adapters, not the internal model

Date: 2026-06-12
Status: Accepted

### Context

Decko should support imported decks, including Anki-style decks long term, but imported structures should not control the app architecture.

### Decision

Use import adapters that translate external files into Decko domain objects: Deck, LearningItem, ReviewCard, and ReviewEvent.

### Consequences

- JSON/CSV fixtures can unblock early development.
- APKG support can arrive later without rewriting the app.
- The rest of the app stays independent from external deck internals.

### Alternatives considered

- Make APKG the internal model: rejected because it would make UI, scheduling, and gamification dependent on an external format.

## DEC-003: Scheduling must be FSRS-ready from the start

Date: 2026-06-12
Status: Accepted

### Context

Decko wants modern spaced repetition without forcing the first build to implement full FSRS immediately.

### Decision

The data model should include FSRS-compatible fields, but the first implementation may use a SimpleSchedulerService behind the same SchedulerService interface.

### Consequences

- The MVP can be tested quickly.
- FSRS can replace the simple scheduler later.
- Review UI remains independent from scheduling details.

### Alternatives considered

- Implement full FSRS before any UI: rejected because it would delay product validation.

## DEC-004: App themes and card themes are separate systems

Date: 2026-06-12
Status: Accepted

### Context

Decko differentiates itself through beautiful UI and card experiences.

### Decision

Separate AppThemeConfig from CardThemeConfig.

### Consequences

- Users can mix app shell themes with flashcard presentation themes.
- Card rendering can evolve independently from app navigation.
- UI consistency must be tracked in `docs/UI_REGISTRY.md`.

## DEC-005: Decko must never silently reset imported progress

Date: 2026-06-12
Status: Accepted

### Context

Existing deck users may have hundreds or thousands of cards with meaningful study history. For them, the deck content is not enough: due dates, intervals, review state, suspended cards, reps, lapses, and review history are part of the value of the deck.

If Decko imports a deck and treats all cards as new without warning, the user loses trust immediately.

### Decision

Decko must distinguish between clean import and progress-aware import.

When scheduling/progress information exists, the user must be offered a clear choice:

- keep existing progress
- start fresh

When scheduling/progress information does not exist or cannot be read, Decko must clearly warn that the deck will be imported as new.

### Consequences

- APKG import must eventually inspect both content and scheduling/progress data.
- Import UX must include a pre-confirmation summary.
- The domain model needs an import progress mapping layer, not only card content import.
- A progress-aware import MVP is required before Decko can confidently target serious existing Anki users.

### Alternatives considered

- Always start imported decks as new: rejected because it would make Decko unsafe for users with existing progress.
- Try to perfectly reproduce external scheduler state immediately: rejected for early MVPs because preserving practical progress is more important than exact scheduler compatibility.

### Related docs

- `docs/import-progress.md`

## DEC-006: GoRouter now, Riverpod deferred until there is real state

Date: 2026-06-12
Status: Accepted

### Context

`docs/CODING_STANDARDS.md` names Riverpod + GoRouter as the preferred stack, but the MVP_001 brief lists "complex state management" and "large dependencies" as non-goals. MVP_001 is a static product shell with no real domain state.

### Decision

Add `go_router` for navigation now (it matches the standards and the roadmap's "basic routing"). Defer `flutter_riverpod` until a later MVP introduces genuine state (review sessions, persistence). For MVP_001, the only mutable UI state — the selected app theme — is driven by a lightweight `ThemeController` (`ValueNotifier`) exposed via an `InheritedWidget`.

### Consequences

- Smaller dependency surface for the first build.
- Navigation is structured correctly from day one.
- Riverpod can be introduced in MVP_004+ without reworking routing.
- The theme controller is a deliberate stop-gap; it will likely become a Riverpod provider later.

### Alternatives considered

- Add Riverpod now: rejected as premature for a shell with no real state.
- Zero dependencies (Navigator only): rejected because it diverges from the documented stack and would need rework as routing grows.

## DEC-007: Decks are read through a DeckRepository, resolved by id in routes

Date: 2026-06-12
Status: Accepted

### Context

MVP_002 makes the library render real local decks and adds a deck detail screen. The UI needs a source of decks and a way to carry the selected deck into detail/review, without persistence or Riverpod yet.

### Decision

Introduce a small `DeckRepository` interface (`getDecks()`, `getDeckById(id)`) with a `MockDeckRepository` backed by `MockDecks`. The repository is provided through the existing app-scope `InheritedWidget` (`DeckoApp.repositoryOf`), the same mechanism used for the theme controller. Deck context flows through the URL: routes are `/deck/:deckId` and `/deck/:deckId/review`, and route builders resolve the `Deck` from the repository by id (falling back to a "deck not found" screen).

### Consequences

- Screens depend on an interface, not concrete data — a persistent repo can replace the mock later with no UI change.
- Navigation is URL-driven and link/deep-link friendly; no `Deck` objects passed via router `extra`.
- The repository is injectable, so tests can supply an empty repo to exercise the empty state.
- A non-existent deck id is handled explicitly rather than crashing.

### Alternatives considered

- Pass the `Deck` object via GoRouter `extra`: rejected because it breaks on refresh/deep-link and couples navigation to in-memory objects.
- Constructor-inject the repository into each screen: rejected because GoRouter builders make that awkward; the existing scope pattern is simpler and consistent.

## DEC-008: The review scheduler seam is `ReviewScheduler`

Date: 2026-06-12
Status: Accepted

### Context

DEC-003 said scheduling must be FSRS-ready behind an interface and tentatively named it "SchedulerService". MVP_003 implements the first real review-session layer and needs to fix that name and shape.

### Decision

The seam is `ReviewScheduler` (`lib/domain/repositories/review_scheduler.dart`) with `createSession` / `answerCurrentCard` / `completeSession`. MVP_003 ships `SimpleReviewScheduler` (in-order queue, tally counts, no intervals/due dates/persistence). Implementations are pure: transitions return a new immutable `ReviewSession`, and `answeredAt` is passed in rather than read from the clock, so sessions are deterministic and unit-testable. The review screen depends only on this interface and holds session state in local `State` (no Riverpod). The scheduler is an injectable constructor parameter (defaulting to `const SimpleReviewScheduler()`).

### Consequences

- This is the concrete realisation of the DEC-003 seam; a future `FsrsReviewScheduler` implements the same interface with no review-UI change.
- Session logic is testable in pure Dart (no widget pumping).
- Naming supersedes the tentative "SchedulerService" wording in DEC-003.

### Alternatives considered

- Keep the "SchedulerService" name: rejected — `ReviewScheduler` reads better alongside `ReviewSession`/`ReviewAnswer` and matches the MVP_003 brief.
- Put scheduling state in a Riverpod provider now: rejected as premature; local `State` is enough for a single-screen session.

## DEC-009: Local persistence uses shared_preferences behind repository seams

Date: 2026-06-12
Status: Accepted

### Context

MVP_004 needs to remember a little state across launches — the selected app theme and a small progress snapshot (XP, streak, today's count, last session result). Full deck persistence and a real database are deferred to roadmap I1.6.

### Decision

Use `shared_preferences` as the storage backend, hidden behind two small async repository interfaces: `SettingsRepository` and `ProgressRepository` (in `lib/domain/repositories/`), with `SharedPrefs*` implementations in `lib/data/`. The progress snapshot is stored as a single JSON blob. The XP/streak/"today" maths lives in a pure `ProgressSnapshot.recordingSession(result, now)` method (time injected), so it is deterministic and unit-testable; the repository just loads → applies → saves. Repositories are injectable via `DeckoApp` (defaulting to the `SharedPrefs*` impls) and exposed through the app scope, matching the DEC-007 pattern.

### Consequences

- Theme choice and progress survive restart with no DB or migrations.
- UI depends on interfaces, so a Drift/Isar/Hive backend can replace the `SharedPrefs*` impls later without touching screens (the I1.6 step).
- Progress logic is fully unit-testable without storage or Flutter.
- `shared_preferences` is the 2nd dependency (after go_router); justified by being the lightest fit for tiny key/value + a small snapshot.

### Alternatives considered

- Drift/Isar/Hive now: rejected as over-engineered for theme + one snapshot; reserved for full deck/review-history persistence (I1.6).
- Store progress as separate prefs keys: rejected — a single JSON blob keeps the snapshot atomic and easy to evolve.
- Compute progress inside the repository: rejected — keeping the maths in a pure domain method makes it testable and storage-agnostic.

## DEC-010: Anki import — legacy .apkg only, behind an adapter, decks in a DeckStore

Date: 2026-06-12
Status: Accepted

### Context

MVP_005 starts the import system: a real `.apkg` import that honours the progress-aware product rule (DEC-005 / docs/import-progress.md). `.apkg` is a zip containing an SQLite collection; modern Anki exports it zstd-compressed (`collection.anki21b`), which Dart can't easily decode.

### Decision

- **Format scope:** support the *uncompressed* `collection.anki2` / `collection.anki21` (Anki's "Support older Anki versions" export). Detect zstd `collection.anki21b` and reject it with a clear, actionable message. Modern-format decoding is a future MVP.
- **Seam:** a `DeckImportAdapter` (`AnkiApkgImportAdapter`) does all parsing — unzip (`archive`) → read the collection (`sqlite3` + `sqlite3_flutter_libs`) → map notes/cards to Decko `Deck`/`LearningItem`s. The UI never parses packages. All failures surface as a `DeckImportException` so the UI can always show a friendly message and never crashes.
- **Progress:** detect whether scheduling/progress exists; offer Keep / Start-fresh; preserve practical imported state (`ImportedCardProgress`, labelled imported-Anki, not native FSRS) when kept, or import as new otherwise. Provenance (`DeckImportInfo`) is shown on deck detail.
- **Persistence:** imported decks are stored as a JSON blob in `shared_preferences` (the MVP_004 pattern, "intentionally small"), fronted by an in-memory `DeckStore` (a `ChangeNotifier` implementing `DeckRepository`) so the synchronous repository/router resolution keeps working and the library refreshes on import/hydration. Demo decks remain; imported decks list first.

### Consequences

- A real personal deck can be imported and survives restart, without a database.
- `sqlite3` (not `sqflite`) makes the parser unit-testable on the host; tests build a synthetic `.apkg` rather than committing a binary.
- Field mapping (field0→front, field1→back, field2→example) and multi-deck collapsing are intentionally simple and isolated, ready to improve in a follow-up.
- Many/large imported decks will eventually need a file or DB store; the `ImportedDeckStorage` seam localises that change.

### Alternatives considered

- Decode modern zstd `.anki21b` now: deferred — no mature Dart zstd, would need native FFI with iOS/Android risk; legacy export covers the slice.
- `sqflite` for reading the collection: rejected — it can't run in host unit tests; `sqlite3` can.
- A real DB (Drift/Isar) for imported decks now: rejected as premature for a first vertical slice.

## DEC-011: Persistent per-card review state + temporary scheduling policy

Date: 2026-06-12
Status: Accepted

### Context

After MVP_005, reviewing a card changed nothing persistent — imported "Due today" never decremented because there was no per-card scheduling state being written back. We need a real due-queue and write-back without committing to FSRS yet.

### Decision

- **State:** a framework-light `ReviewCardState` (queueState, dueAt, reps, lapses, intervalDays, easeFactor, lastReviewedAt, sourceSystem), persisted behind a `ReviewStateRepository` (a per-deck JSON blob in `shared_preferences`, `SharedPrefsReviewStateRepository`).
- **Init:** on import, every item gets a `ReviewCardState` — Keep-progress maps imported Anki progress (suspended stays suspended, excluded from the queue); Start-fresh/unavailable start new. Demo decks initialise lazily as new on first review. DEC-005 stays binding (nothing silently reset).
- **Queue:** pure `DueQueue.build` — non-suspended cards that are due (review/learning) then new cards, deterministic order. Drives the review session.
- **Write-back:** a pure, explicitly **temporary** `ReviewSchedulingPolicy` (Again→relearning/now, Hard→+1d, Good→+3d, Easy→+7d) advances state on each grade. **NOT FSRS** — it exists so write-back works; a real FSRS scheduler replaces this one class.
- **Persistence timing:** the review screen updates state in memory per grade (due count moves live) and **flushes the changed states once when leaving the session** (complete / back / dispose), to avoid rewriting a large deck's whole blob on every tap.
- **Counts:** deck detail Due today / Reviewed read from the repository (live, decrement after review, survive restart).

### Consequences

- Imported decks become usable day-to-day: due decrements and persists.
- Pure policy + queue + state are unit-testable; FSRS-ready (same fields/seam, DEC-003/008).
- Per-deck blob rewrite is the known cost; flush-on-exit keeps it off the per-grade path. Very large libraries will eventually want a real DB (the repository seam localises that change).

### Alternatives considered

- Persist per grade: rejected — rewriting a 17k-card blob per tap would jank; flush-on-exit is enough for correctness.
- Bake scheduling into FSRS now: rejected — out of scope; the temporary policy unblocks write-back without the complexity.
- One global states blob: rejected — per-deck keys keep reads/writes scoped to the deck in play.

## DEC-012: Furigana preserved as bracket notation, rendered as toggleable ruby

Date: 2026-06-12
Status: Accepted

### Context

Real Japanese decks carry furigana (`<ruby>漢字<rt>かな</rt></ruby>`). The first importer stripped tags, mashing kanji+reading ("会社かいしゃ"). Learners want furigana shown — and the option to hide it.

### Decision

- **Storage format:** the importer converts ruby to Anki **bracket notation** `漢字[かな]` and keeps it inline in `front`/`example`. This is a compact, parseable representation that survives JSON persistence; no model change beyond keeping the markup in the existing strings.
- **Rendering:** a `FuriganaText` widget parses `漢字[かな]` and renders the reading as ruby above the kanji; with readings off it renders plain base text. Plain (non-Japanese) strings pass through unchanged.
- **Toggle:** a `showFurigana` preference persisted via `SettingsRepository`, exposed app-wide through a `FuriganaController` (`ValueNotifier`, in the app scope), toggled from the review app bar. Defaults on.
- **Emphasis:** the example sentence is rendered prominently (large, furigana) with the translation muted beneath — the sentence is the most useful part of a vocab card.

### Consequences

- Real decks render correctly (kanji + ruby), and learners can hide readings to self-test.
- Field mapping still falls back to a separate kana `reading` field for note types that split it out; that line also respects the toggle.
- Furigana only renders where the source provided it; decks without ruby show plain text.

### Alternatives considered

- Store kanji and readings as structured pairs on the model: rejected — bracket notation is simpler, human-readable, and round-trips through the existing string fields.
- Drop readings entirely: rejected — loses the core value of a Japanese deck.

## DEC-013: Scheduling uses an FSRS-5 policy (pure Dart, default weights)

Date: 2026-06-12
Status: Accepted

### Context

MVP_006 shipped a deliberately temporary fixed-interval policy (Again=now / Hard=1d / Good=3d / Easy=7d). It made write-back work but isn't credible scheduling. The seam (`ReviewSchedulingPolicy` → persisted `ReviewCardState`) was built to allow swapping it.

### Decision

- Turn `ReviewSchedulingPolicy` into an **interface** and implement `FsrsSchedulingPolicy` — a faithful **FSRS-5** memory model (stability + difficulty) with the **published default weights**, written in **pure Dart** (no dependency). It is FSRS-*style*, not a per-user trained optimiser, and omits intra-day learning steps. Interval = days until the card drops to the target retention (0.9), ≥ 1.
- `ReviewCardState` gains nullable `stability`, `difficulty`, `schedulerVersion`. Nullable = safe migration: imported and pre-FSRS persisted states load unchanged.
- The policy is injected into the review screen (default `FsrsSchedulingPolicy`); the UI contains no scheduling maths.
- **Imported progress is preserved:** the scheduler only runs when a card is graded, so un-reviewed cards keep their imported due dates. On a card's first FSRS grade, missing `stability`/`difficulty` are seeded conservatively from existing interval/ease/lapses — never reset to new (DEC-005 honoured).

### Consequences

- Real spaced repetition: new Good ≈ 3d, Easy ≈ 16d; repeated Good grows 3→11→35→101→269d; difficulty adapts per rating.
- Closes the temporary-scheduler gap from DEC-011 / the roadmap.
- A future MVP can train per-deck FSRS weights or add learning steps behind the same interface.

### Alternatives considered

- Pull a pub `fsrs` package: rejected — the FSRS-5 core is ~60 lines; pure Dart keeps it dependency-free, fully testable, and version-stable.
- Keep the fixed policy: rejected — not credible scheduling; the seam existed precisely to replace it.
- Convert Anki scheduler params exactly: rejected — out of scope; conservative seeding preserves practical progress without claiming parity.

## DEC-014: Anki media imported to local files, rendered by a field-content parser

Date: 2026-06-13
Status: Accepted

### Context

Real `.apkg` decks contain audio (`[sound:x]`) and images (`<img src="x">`); legacy packages ship a `media` JSON map plus numbered payload files. Decko previously stripped these references, making audio/image decks feel broken.

### Decision

- **Extraction:** during import, read the package `media` map and copy each payload to a `MediaStore` under its original filename, keyed by deck id (single zip decode; saved one file at a time so big decks don't balloon memory).
- **Storage:** `MediaStore` interface + `FileMediaStore` — files live under `<appSupport>/decko_media/<deckId>/`, never in `shared_preferences`. Per-deck folders avoid collisions and make deletion a recursive remove; injectable base dir for tests.
- **Content preservation:** field cleaning now **keeps** `[sound:x]` and normalised `<img src="x">` (alongside furigana). Media that lives in separate note fields is gathered and attached to the front so it renders.
- **Rendering:** a small `parseAnkiContent` splits a field into text / audio / image segments; `DeckoFieldContent` renders text via `FuriganaText`, audio as a play button (`audioplayers`), and images via `Image.file`. **No full HTML renderer.** Missing media → friendly placeholder / disabled button.
- **Deps:** `path_provider` (storage location) and `audioplayers` (local playback). Images need none.
- **Lifecycle:** deleting an imported deck also deletes its media. Import preview reports media/audio/image counts. FSRS, review state, and progress are unchanged.

### Consequences

- Audio/image decks import and play/render; everything survives restart and is removed on delete.
- "Import all media" means very large decks (hundreds of MB) are slower and use more disk — a noted limitation.
- Media placement is heuristic (orphan media → front); good enough for the common note types, refinable later.

### Alternatives considered

- Full HTML/CSS/template rendering: rejected — far beyond scope; a targeted segment parser covers Decko's media patterns.
- Store media in `shared_preferences` / a DB: rejected — blobs belong on the filesystem.
- Cap media by size: offered but rejected for this slice — completeness preferred; revisit if huge decks bite.

## DEC-015: Iconography uses Font Awesome free, via FaIcon/FaIconData

Date: 2026-06-13
Status: Accepted

### Context

The app used Material `Icons`. The product owner wants a consistent Font Awesome look.

### Decision

All app icons use **`font_awesome_flutter`** (free tier) rendered with `FaIcon`; icon constants are `FontAwesomeIcons.*` (typed `FaIconData`, not `IconData`). Widgets that take an icon parameter declare it `FaIconData`. Fixed-size decorative icon containers must set `alignment: Alignment.center` — FA glyphs lack the built-in padding Material icons have, so they otherwise sit off-centre.

### Consequences

- One coherent icon style; new icons should be `FontAwesomeIcons.*` + `FaIcon`.
- `FaIconData` ≠ `IconData`, so icon params/lists use `FaIconData`.
- Centre fixed-size icon chips/badges explicitly.

## DEC-016: Lossless Anki source preserved alongside each imported deck

Date: 2026-06-20
Status: Accepted

### Context

Decko's importer is positional/template-blind: it maps Anki fields by index and collapses a note's multiple card templates (e.g. Listening/Reading/Production) into identical Decko cards. Before we can render note-type-aware cards (MVP_010), the full Anki source must survive import — named fields with raw + plain values, tags, model/field/template definitions, and card→note→template links — not just the simplified study card.

### Decision

- A framework-light domain model (`ImportedAnkiSource`: models, notes with named `ImportedAnkiField`s + tags, and `ImportedAnkiCardSource` links) captures the lossless source.
- During import the adapter parses `col.models`, names each note field by ordinal, records per-field media references, and links each card to its template ordinal.
- Persistence is a JSON file **per deck** under `<appSupport>/decko_source/<deckId>.json` via an `ImportedSourceStore` interface (`FileImportedSourceStore`) — kept off `shared_preferences` because the source can be several MB for a large deck; loaded on demand, removed when the deck is deleted.
- The simplified study card is still derived as before; the source sits beside it. No rendering, scheduling, or review changes.

### Consequences

- Note-type-aware rendering (MVP_010) has the data it needs without re-importing.
- Larger on-disk footprint per imported deck (one JSON blob); acceptable and isolated to local app-support storage.
- Inspect UI for the preserved source is still pending (the remaining slice of MVP_009).

## DEC-017: Reusable app shell, and Home separated from the Import workflow

Date: 2026-06-20
Status: Accepted

### Context

Home (the deck library) had grown into a single crowded page — branding, decks, import CTAs, and a marketing "Why you'll love Decko" promise grid all competed for the same space — and every screen hand-rolled its own `AppBar`. Decko's promise ("Import your deck. Study it beautifully.") asks for a calmer, more intentional structure.

### Decision

- **Shared chrome:** `DeckoAppBar` (a `PreferredSizeWidget`) gives one app-bar pattern — a `wordmark` register for Home and a `title` register for sub-screens — adopted across Home, Import, Deck Detail, Progress, and Themes so chrome never drifts back to stock Material.
- **Home = study-first (Direction A):** the hero is the next study action — a `StudyRibbon` with a stacked-flashcard motif naming the resume deck (the one with the most cards waiting) and its ready count, softening to a calm "all caught up" state when nothing is due. Below it a compact deck shelf (`DeckRow`) with live per-deck "to study" badges, then a quiet dashed Import row. Live counts come from `DueQueue.build` over persisted review state and refresh on return from a session.
- **Import = its own screen:** the pick → preview → keep/fresh flow stays on `/import`; Home only links to it. The product promise grid now lives **only** in Home's empty state.

### Consequences

- Home answers "what can I study, what decks do I have, how do I import" and nothing more; a learner with decks sees decks, not a brochure.
- One app-bar/shell pattern to evolve; new screens reuse `DeckoAppBar`.
- The resume deck and badges depend on review state, so Home does a small per-deck state read on load (and on return from study).

## DEC-018: Floating bottom nav over a StatefulShellRoute (Home/Import/Progress/Settings)

Date: 2026-06-20
Status: Accepted

### Context

Primary destinations were reached from app-bar action icons on Home, which doesn't scale and buries Import/Progress/Settings. The product owner asked for a floating nav bar carrying Home, Import, Progress, and Settings (the theme gallery).

### Decision

- **Navigation:** a `StatefulShellRoute.indexedStack` with four branches (`/`, `/import`, `/progress`, `/settings`) behind `DeckoShell`, so each tab keeps its own navigation stack and the bar persists. Tab switches use `navigationShell.goBranch` (re-tapping the active tab pops it to root).
- **Full-screen routes:** **deck detail** is a sub-route of the Home branch (keeps the bar; Back returns to Home), while the **review session** is pushed on the **root** navigator (`parentNavigatorKey`) so study plays full-screen without the bar.
- **The bar:** `DeckoBottomNav` — a rounded, elevated, *floating* bar (margin + shadow), never the stock edge-to-edge `NavigationBar`. The active destination expands into a labelled primary pill; the others stay quiet icons. Every item has a tooltip/semantics label.
- **Settings tab** currently hosts the existing theme gallery (renamed destination, same screen); Import is now a first-class tab and resets to idle after a successful import (it persists in the shell). Home's app-bar action icons were removed; its Import ghost row now switches to the Import tab.

### Consequences

- Import/Progress/Settings are always one tap away; tab state survives switching.
- Deck detail shows the bar (a content screen within Home); only review is immersive.
- Going forward, new top-level destinations are added as shell branches; transient/full-screen flows attach to the root navigator.
