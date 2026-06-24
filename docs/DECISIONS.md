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
- A Decko-styled inspect screen (`ImportedSourceScreen`, reached from deck detail's "View imported source") proves the rich data is kept: note-type fields + templates, a per-template card breakdown, and a sample note's named fields, tags, and per-field media refs.

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

## DEC-019: Note-type-aware card mapping derived from the preserved source

Date: 2026-06-20
Status: Accepted

### Context

Import built one `LearningItem` per Anki card via a **positional** mapper that ignored the card template — so a note generating Listening / Reading / Production cards produced three lookalike Decko cards (the 3× inflation). MVP_009 preserved the templates + named fields; MVP_010 uses them so those cards become *different study activities*.

### Decision

- A pure `NoteTypeAwareCardMapper` (`lib/domain/import/`) consumes the preserved `ImportedAnkiSource` + one `ImportedAnkiCardSource` and returns a `CardMapping`: Decko content (front/back/reading/example) + a `ReviewCardMode` (`generic | listening | reading | production`) + an inspectable rationale (`matchedBy`, `frontFields`, `backFields`).
- **Template identity first** (templateName → mode), then **named field roles** (expression / reading / meaning / sentence / sentence-kana / sentence-english / sentence-audio / word-audio / image) resolved by name, most-specific first. Generic names (`Front`/`Back`/`Field N`) deliberately match nothing.
- **Per-mode composition:** Listening = audio-first front, word revealed on back; Reading = Japanese-text front; Production = English prompt front, Japanese hidden until flip. Each maps the source media to the right side.
- **Fallback:** when neither template nor fields give a useful signal, the mapping is `recognized: false` and the adapter keeps its existing positional content with `mode: generic`. Simple/demo decks are untouched.
- **Progress safety (the hard rule):** the `LearningItem.id` stays `anki-card-<cardId>` and imported progress is unchanged — only the *content arrangement* changes, so review state / FSRS are never reset.
- **UI:** `DeckoCard` shows a quiet small-caps mode eyebrow (no badge/pill); the imported-source inspect screen shows each template's mode + matched-by + front/back fields.

### Consequences

- Multi-template notes review as distinct cards; one source card still ↔ one Decko card.
- The mapper is heuristic and extensible (add template/field synonyms over time); it doesn't aim for full Anki template fidelity.
- Re-import is needed for already-imported decks to pick up modes (mapping runs at import time).
- Furigana display stays globally toggled (not hidden per-face); deferred refinement.

## DEC-020: Two-level study options (global defaults + per-deck overrides)

Date: 2026-06-20
Status: Accepted

### Context

Decko had no way to shape study behaviour: large imported decks dumped every due/new card into one session, and audio/image/furigana behaviour was fixed. Anki users expect a default they can override per deck.

### Decision

- **Domain (`lib/domain/study_options/`, framework-light):** `StudyOptions` (global defaults), `DeckStudyOptions` (all fields nullable = "use global", plus a deck-only `FuriganaPreference`), and `EffectiveStudyOptions.resolve(global, deck)` where a deck override wins per-field and unset fields fall back to global. Enums: `AudioAutoplayMode {off, beforeQuestion, afterReveal}`, `ImageDisplayMode {withQuestion, afterReveal}`, `FuriganaPreference {useGlobal, alwaysShow, alwaysHide}`.
- **Persistence:** `StudyOptionsRepository` + `SharedPrefsStudyOptionsRepository` — global under one key, each deck's overrides under a per-deck key (loaded on demand, removed with the deck). Exposed via `DeckoApp.studyOptionsOf`.
- **Queue caps (per-session):** `DueQueue.build` gains optional `maxNew` / `maxReview` / `maxSession`; the review session builds the limited queue from the deck's effective options. Caps only trim *which* cards enter a session — no card state changes, so imported progress / FSRS are untouched. "Per day" is currently enforced per session (no intra-day carryover) — a documented simplification.
- **Media + readings:** the review session autoplays the question/answer audio per `AudioAutoplayMode`; `DeckoCard.showFrontImage` hides the question-side image when `ImageDisplayMode.afterReveal`; furigana shows per `EffectiveStudyOptions.resolveShowFurigana(globalToggle)`, layering the deck preference over the preserved global toggle.
- **UI:** the Settings tab became a hub (Study defaults · Themes · global furigana); a `GlobalStudyOptionsScreen` and a per-deck `DeckOptionsScreen` (each row: "Using global: X" + Override) reached from a "Deck options" tile on deck detail. Human wording, not Anki jargon.

### Consequences

- Sessions are bounded; learners control new/review pace, audio, images, and readings globally or per deck; everything persists.
- FSRS maths and the global furigana toggle are unchanged.
- Daily limits are per-session for now (no daily-count rollover); deck option groups shared across decks are deferred to MVP_012.

## DEC-021: Study option profiles + true daily limits + sibling burying

Date: 2026-06-20
Status: Accepted

### Context

MVP_011 gave global defaults + per-deck overrides but shipped two honest gaps: daily limits were per-session (reopening granted a fresh allowance) and bury-siblings was stored but not enforced. MVP_012 adds reusable profiles and closes both parity gaps — without touching FSRS or card identity.

### Decision

- **Profiles:** `StudyOptionProfile {id, name, options, isDefault}` — a reusable `StudyOptions` set. A synthetic "Default" profile mirrors the global options; user profiles are stored as a JSON list. `DeckStudyOptions` gains `profileId`. Resolution order is **global/default → assigned profile → deck override** (`getEffectiveOptions`: base = profile options when assigned else global; then per-field deck override). A deleted/dangling `profileId` falls back to global. The repository protects the default profile from deletion.
- **True daily limits:** `DailyStudyCounts {day, newStudied, reviewStudied, studiedNoteIds}` per deck (`DailyStudyCountsRepository` + shared-prefs impl). The day boundary is the local calendar day (`year-month-day`); `forDay(today)` zeroes a stale record. The review session loads today's counts and caps the queue by **remaining = limit − studiedToday**, so a second same-day session keeps the reduced allowance and a new day resets it. Each grade records the card by its **pre-grade** kind (new vs review) and marks its note studied; counts persist on flush.
- **Sibling burying (enforced):** when enabled, `DueQueue.build` filters (never mutates) — it drops cards whose source note was studied earlier today (`studiedNotesToday`) and keeps only the first card per note this build (review → learning → new order, so a due review beats a new sibling). Note identity comes from `importedProgress.sourceNoteId` or the preserved source's card→note links; cards with no known note are never buried. Demo decks (no source) are a no-op.
- **Advanced (safe) options:** `NewCardOrder {deckOrder, random}` added, behind a collapsed "Advanced" section. Bury surfaced there too. **Deferred (documented blocker):** desired retention and maximum interval need FSRS-policy plumbing — not implemented to keep scheduler maths safe; import-aware profile suggestions also deferred.
- **UI:** Settings hub gains "Study profiles" (list/create/edit/delete; default edits via Study defaults). Deck options gains a profile selector; override baselines reflect the selected profile ("Inherited: X"). A shared `StudyOptionsForm` powers the global + profile editors.

### Consequences

- One source card still ↔ one Decko card; FSRS and imported progress are never reset (verified by an adversarial review) — options/limits/bury are pure queue filters + presentation.
- Daily limits are now genuinely daily and survive app restarts the same day.
- Known edge: bury "reserves" a note for a card that a later cap may drop, suppressing its new sibling for that build (Anki-consistent; revisit if finer parity is wanted). Finer-grained bury (separate new/review) and desired-retention/max-interval remain future work.

## DEC-022: Modern Anki package support + import diagnostics

Date: 2026-06-21
Status: Accepted

### Context

Decko could only read legacy uncompressed `.apkg` exports (`collection.anki21`/`.anki2`) and rejected the modern zstd format with a "re-export" message. Real users hit that wall, and import failures were vague (sometimes surfacing raw SQLite errors). MVP_013 makes import trustworthy across real-world Anki packages.

### Decision

- **Modern format is now actually imported.** A package's collection is detected (`AnkiPackageFormat`: `legacy2` / `legacy21` / `modern21b` / `unknown`). For `collection.anki21b` the bytes are zstd-decompressed and handed to the **existing** SQLite reader — the schema is identical, so lossless source, note-type mapping, and FSRS all work unchanged. `LearningItem.id = anki-card-<cardId>` is preserved.
- **zstd via an injected decoder.** `ZstdDecoder` (interface) + `ZstandardDecoder` (the native `zstandard` plugin). It's injectable so host `flutter test` uses a fake (the native plugin can't run in the Dart test VM); the app uses the real one. **This adds a CocoaPods requirement for iOS** (the plugin doesn't support SPM) — see consequences.
- **Modern media, best-effort.** Modern media payloads are zstd-compressed and indexed by a zstd-compressed `MediaEntries` protobuf. Decko decompresses the index, hand-parses just the `name` field (a ~50-line reader, no protobuf dependency), and decompresses each payload. Anything that fails degrades gracefully — text cards always stay studyable.
- **Structured diagnostics.** `ImportDiagnostics` (package format, collection file, decks/notes/cards/models/templates/media counts, warnings, blocking error) is produced during parse, surfaced in the import preview, and asserted in tests.
- **Specific failure states** replace vague/raw-SQLite messages: no collection found, undecodable modern format, corrupted/incomplete, and "expected Anki tables were missing". Non-blocking issues (missing manifest, manifest entries missing from the zip) become warnings, not errors.

### Consequences

- Modern `.apkg` exports import without asking users to toggle "Support older Anki versions".
- **CocoaPods is now required to build/run on iOS** (the `zstandard` plugin uses CocoaPods, not SPM). `flutter analyze`/`flutter test` are unaffected (host VM + fake decoder). Installing CocoaPods (`brew install cocoapods`) is a one-time dev-env step; on-device modern import is verified after that.
- No re-import is required for already-imported decks; their ids/state are unchanged. This MVP doesn't migrate existing decks.
- Media protobuf parsing is `name`-only and best-effort; exotic media-index variants degrade to "media unavailable" with a warning rather than failing the import.

## DEC-023: Import diagnostics are user-facing trust signals, not raw parser logs

Date: 2026-06-21
Status: Accepted

### Context

MVP_013 produced structured `ImportDiagnostics`, but the import UI still showed flat warning strings and a few raw fields. The next problem is trust: a user importing a real Anki deck needs to understand what Decko found, what imported cleanly, what was approximated, and whether the deck is safe to study — without parser noise.

### Decision

- **Severity + category + health.** Each finding is an `ImportDiagnostic { category, severity (info/warning/error), message, technicalDetail? }`. Categories are user-understandable (Package · Collection · Notes & fields · Templates · Media · Progress · Scheduling). Overall `ImportHealth` (healthy / usableWithWarnings / blocked) is **derived** from the findings' severities — not set by hand.
- **One reusable health UI.** `ImportHealthSummary` renders a status header (calm copy per state), a friendly metadata chip row (format described in plain language, note/card/template/media counts), grouped attention findings, and a collapsed **"Technical details"** disclosure (raw format/collection/per-finding detail). No enum names or SQLite wording in the primary view; technical detail only behind progressive disclosure.
- **Surfaces.** The summary appears in the import preview (above keep/fresh), in a calm post-import **result** state for imports with warnings (clean imports stay frictionless: snackbar → Home), and in an **Import report** screen reachable from deck detail. The report persists: diagnostics are stored on `DeckImportInfo` and serialized with the deck.
- **Blocking vs unsupported** stay as typed exceptions (`DeckImportException` / `UnsupportedPackageException`) surfaced in the import error state with a practical next step — distinct from the health-summary states.

### Consequences

- Import results are explainable and reassuring; warnings are grouped and humane, not alarming, and never hidden.
- Diagnostics travel with the deck (small JSON on `DeckImportInfo`), so the report is revisitable; decks imported before this show a "no report" state.
- Health derives from severity, so adding a finding automatically updates the summary — no separate status bookkeeping.

## DEC-024: Light gamification is derived from progress and must not drive scheduling

Date: 2026-06-21
Status: Accepted

### Context

After the Anki-parity and import-trust foundations, Decko needs to feel more motivating without ever distorting review correctness. MVP_015 adds a daily goal, streak polish, a completion celebration, and a small achievement set — all on top of the existing `ProgressSnapshot`.

### Decision

- **Gamification is a read-only presentation layer over recorded progress.** XP, streak, daily goal, celebration, and achievements derive from `ProgressSnapshot` (+ a motivational daily goal). Nothing here decides what is due, mutates per-card state, or touches FSRS / the due queue / daily counters / sibling burying.
- **Achievements are derived, not a separate economy.** A pure `achievementsFor(snapshot, dailyGoal)` returns earned/locked for a tiny starter set (First review, Daily goal, 3‑day streak, 100 cards). To keep streak/total achievements from un-earning, `ProgressSnapshot` gained a monotonic `longestStreakDays` (and total cards derives from XP). No new persistence beyond the existing snapshot, which back-fills `longestStreakDays` from `currentStreakDays` for old blobs (migration-safe).
- **The daily goal is motivational, not an Anki limit.** Stored in `SettingsRepository` (default 20, configurable via a Settings stepper); it changes only the progress UI and celebration, never how many cards are scheduled.
- **Celebration reads post-session state.** The review screen records the session, then loads the resulting snapshot + goal to show XP gained, daily-goal progress, and a streak acknowledgement in the summary — recording stays the single source; the summary just reflects it.

### Consequences

- Studying feels rewarding (goal ring, kinder streak, celebratory summary, badges) while review math is untouched — the safety constraints hold by construction.
- Adding an achievement is a pure-function change; no scheduler coupling, no stored badge state to migrate.
- Future game modes (e.g. Bunburu) can route outcomes through this same progress/achievement layer without becoming a scheduling dependency.

## DEC-025: Bunburu / Sentence Builder — practice and an opt-in review presentation, never a hidden scheduler

Date: 2026-06-21
Status: Accepted

### Context

MVP_016 brings the Bunburu sentence-unscramble concept into Decko as a sentence builder powered by imported sentence fields. It must feel native and close to the card, without ever distorting review correctness.

### Decision

- **Word-level tokenization via a service; a pure pipeline decoupled from review.** `SentenceBuilderMapper` (sync) picks the best sentence + translation + audio + reading from preserved Anki source fields (`Sentence` / `Sentence-Kana` / `Sentence-English` / `Sentence Audio`, falling back to `LearningItem.example`), after sanitising (`[sound:…]` / bracketed furigana / HTML stripped). Tokenization is done by the **Bunburu kuromoji micro-service** (the same service the standalone Bunburu app uses): `POST /furigana` returns proper word-level `CubeToken`s with per-token furigana. `SentenceRoundService` combines the picker + the tokenizer + a per-deck file cache to build `SentenceBuilderRound`s asynchronously; a card is "capable" only when it yields ≥2 tiles. None of this imports the Anki adapter, FSRS, the scheduler, or review-state storage.
  - **Why a service, not on-device:** real Japanese word segmentation needs a dictionary (kuromoji's IPADIC is ~15MB). Decko is local-first by *preference*, not mandate, so we reuse the existing service rather than bundle a dictionary. Results are cached per deck on disk (`FileSentenceTokenCache`), so after the first tokenize the builder is instant and works offline; the service is only hit for new/changed sentences. The app key lives in a gitignored `.env` (`--dart-define-from-file`), never in source; when unconfigured/offline the builder shows a clear "tokenizer unavailable" state.
  - An earlier in-house tokenizer (script-boundary heuristic, then BudouX phrase-level) was abandoned: neither produced acceptable word-level tiles. (BudouX dependency removed.)
- **Three entry paths, two result regimes.**
  - *Manual per-card* ("Build this sentence" on the revealed review card) and *deck practice* (a deck-detail tile) open a `SentenceBuilderScreen` that records **nothing** to review/progress repositories — practice cannot change FSRS state, due counts, imported progress, or burying. Its completion is a self-contained, motivational-only panel.
  - *Scheduler-routed review presentation* (opt-in via the global `sentenceBuilderReview` study option): a due card with a usable sentence is **presented** as a builder, but grading still flows through the existing Again/Hard/Good/Easy → `ReviewScheduler` write-back. The builder is the card's question/reveal; it creates no second scheduler path and no hidden review event.
- **The seam is presentation, not scheduling.** The scheduler still decides which card is due; the review screen decides how it's shown (flashcard / listening / reading / production / sentence builder). Grading is unchanged.

### Consequences

- Learners get sentence practice next to the card and as a deck activity, plus an optional "review my sentences as a builder" mode — all without risk to the spaced-repetition schedule.
- The safety boundary is enforced by construction: practice screens take no review dependencies; the review presentation reuses the one grading path. Tests assert the manual action's visibility, the practice loop, and that the routed review grades through the normal seam (progress recorded, session completes).
- **Four entry surfaces:** a Home "Practice" section → a `SentenceBuilderHubScreen` (lists sentence-capable decks); a manual "Build this sentence" action on the revealed review card; a deck-detail practice tile; and the opt-in `sentenceBuilderReview` review presentation. Async tokenization sits behind a calm loader (spinner / "tokenizer unavailable" retry / "no sentences"). Tiles render per-token furigana ruby.
- Deferred (documented): sentence-audio playback in the builder; hearts/timed/daily-challenge modes; a smarter policy for *when* to route a review to the builder; bulk pre-tokenizing a whole deck (rounds are capped per session); Decko hosting its own tokenizer service instead of reusing Bunburu's. The `sentenceBuilderReview` flag is global-only for now (no per-deck override).

## DEC-026: Practice modes are a registered platform; outcomes feed motivation, not review

Date: 2026-06-22
Status: Accepted

### Context

MVP_016 proved Decko can host a richer game (Bunburu) without breaking review. But it was a special case wired directly into Deck Detail, Review, and a Bunburu-specific hub. Before adding more games (Listening, Typing, Matching…), Decko needs a shared platform so a new game plugs in without editing unrelated screens.

### Decision

- **Practice modes are registered capabilities discovered per card and per deck.** A `PracticeMode` descriptor (id, title/subtitle/description, kind, `manualLaunch`, `reviewPresentation`) is registered in a `PracticeModeRegistry` (`availableForCard` / `availableForDeck` / `manualModesForCard` / `reviewPresentationModesForCard`). Bunburu is the first registered mode (`bunburu_sentence_builder`); availability derives from the existing sentence-capability check. Deck Detail, the Practice Hub, and Review ask the registry — they never hard-code a game. A single `PracticeLauncher` maps a mode → its screen (one new `case` per future game). UI keeps icons/action labels (id→icon, id→"Build this sentence") so the domain stays framework-light.
- **A lightweight outcome→motivation seam.** `PracticeOutcome` (mode, item/deck, timings, correct/incorrect, xp) is recorded via `ProgressRepository.recordPracticeOutcome`. This is **motivation only**: it adds `practiceXp` + a `practiceCount` to `ProgressSnapshot`. Practice XP counts toward **level** (`combinedXp = totalXp + practiceXp`) but is kept *separate* from review XP so review-derived metrics (`totalCardsReviewed`, the "100 cards" achievement) stay accurate.
- **The boundary is enforced, not just intended.** Manual/deck practice never mutates `ReviewCardState`, FSRS, due dates, daily counters, or sibling burying — by construction (practice screens take no review dependencies; the recorder touches only motivational fields). A scheduler-routed review presentation still submits its grade through the normal `ReviewScheduler` seam (the builder is only the card's presentation).

### Consequences

- Adding a future game = register a `PracticeMode` + add a `PracticeLauncher` case + a domain availability rule. No edits to Deck Detail / Review / Hub logic.
- Practice feels rewarding (XP, count, celebration) without distorting the spaced-repetition schedule or review stats.
- Tests assert card/deck availability and the manual-practice-vs-review boundary (practice records motivation XP; `cardsReviewedToday`/review state stay zero).
- Deferred: a real second game; per-mode richer outcomes/analytics; "coming soon" placeholders (intentionally omitted to avoid fake functionality).

## DEC-027: Listening Challenge is a registered practice mode powered by imported audio

Date: 2026-06-22
Status: Accepted

### Context

MVP_017 built a practice-mode platform (registry + launcher + outcome seam, DEC-026). MVP_018 adds the second real mode to prove the platform: a Listening Challenge that uses imported audio. It must slot in without editing Deck Detail / Review / the Hub.

### Decision

- **Listening Challenge (`listening_challenge`) is registered like any mode.** It appears wherever the registry is queried — Deck Detail "Practice modes", the Practice Hub, and a review card's manual actions — because those surfaces are already registry-driven. `PracticeLauncher` gains one `case`; no other screen changed.
- **Availability is audio-driven and pure.** A `ListeningChallengeBuilder` extracts a playable `[sound:…]` (word audio from the card `front`, else sentence audio from `example`) plus an answer (the card's `back` meaning, or `Sentence-English`). A card is capable if it has audio + an answer; a deck is capable with ≥4 such cards (enough for distractors). Round construction generates exactly four **distinct** choices (one correct + three distractors drawn from the deck, no duplicates), with a graceful "not enough audio" state otherwise. It's all local and deterministic given a `Random` — no tokenizer service.
- **Manual + deck practice only this MVP.** `reviewPresentation = false` (a scheduler-routed listening review is deferred). Manual/deck outcomes flow through the existing `PracticeOutcome` → motivational XP seam (5 XP per correct), and **never** mutate FSRS, review state, due dates, daily counters, or sibling burying. If a scheduled listening review is added later, it must grade through `ReviewScheduler` like every mode.
- Audio playback reuses the existing `MediaStore` + `audioplayers`; missing/unresolvable audio degrades to a friendly "audio unavailable — pick the meaning" state rather than blocking the round.

### Consequences

- The platform's claim holds: a second game = register a `PracticeMode` + a builder + one `PracticeLauncher` case + an availability rule. Deck Detail / Review / Hub were untouched.
- Tests cover availability (card/deck, with/without audio), choice generation (one correct, no duplicates, fallback), the manual-outcome boundary (XP recorded; review state stays zero), and the play→choose→feedback→complete flow.
- Deferred: scheduler-routed listening review; richer prompt targets (sentence-meaning vs matching-sentence); typing/transcription (a later MVP).

## DEC-028: An activity ledger separates motivational progress from review scheduling

Date: 2026-06-22
Status: Accepted

### Context

Through MVP_015–018 motivational progress lived in a single `ProgressSnapshot`
(XP, streak, today's count). That's a point-in-time summary — it can't answer
"what did I do over time?", power a heatmap, or split review vs practice. It also
risked entangling motivation with scheduling.

### Decision

Introduce a durable, local **activity ledger** as the source of truth for
motivation, kept strictly separate from review/FSRS state.

- **Two layers, clearly split.** `ReviewState`/`ReviewCardState` answer *when is
  this card due* (FSRS, due queue, Anki parity). `ActivityEvent`/the ledger
  answer *what did I do, earn, practise* (XP, streaks, heatmap, history).
  Recording an activity never decides card due state.
- **`ActivityEvent`** (id, occurredAt, `ActivitySource`, modeId, deck/item,
  `ActivityOutcome`, xpAwarded, duration, metadata) is appended on review-session
  completion and on Bunburu/Listening completion. Review XP and practice XP are
  distinguishable by `source`/`modeId`.
- **`ActivityLedgerRepository`** with a **file-backed** local store
  (`<appSupport>/decko_activity/events.json`) — chosen over `shared_preferences`
  because history grows. Designed to be sync-ready (future Firebase, MVP_020),
  but local-first defines the model; the cloud only mirrors it.
- **Derived, not stored.** `ActivityProgressCalculator` (pure) derives total /
  review / practice XP, XP today, cards reviewed today, practice rounds today,
  current + longest streak (from active days), the heatmap, and recent activity.
  Achievements derive from this. The daily goal is **activity-count based**
  (reviews + practice rounds today), unifying both without rescaling the user's
  existing "20".
- **Practice never mutates FSRS.** Manual/deck practice rewards motivation only.
  A future scheduled review presentation must still grade through
  `ReviewScheduler` and is recorded with `ActivitySource.scheduledPractice`.
- **Safe migration.** The legacy `ProgressSnapshot` is preserved and backfilled
  once (idempotent) into the ledger as legacy baseline events: XP is kept, and
  the prior streak is reconstructed (the learner genuinely studied those days) so
  it survives and can continue. No fake per-day heatmap detail is fabricated;
  legacy events are excluded from the heatmap.

### Consequences

- The Progress screen is now ledger-backed: a heatmap, recent activity, review
  vs practice XP, current/longest streak, daily goal, achievements.
- No FSRS / due queue / daily counter / sibling-burying / import semantics
  changed — review state still updates exactly as before; the ledger is additive.
- Tests cover event serialization, XP/streak/heatmap derivation, file
  persistence, and the migration (incl. idempotency).
- Sets up MVP_020 (Auth & Firebase sync) to mirror a clean local model.

## DEC-029: Local-first auth, and an activity-only cloud sync boundary

Date: 2026-06-22
Status: Accepted

### Context

MVP_019 made the activity ledger the local source of truth for motivation. To
support cross-device learning we need a cloud identity + sync — but imported Anki
progress and FSRS scheduling are high-risk correctness data that must not be put
at risk by sync. So the foundation has to be deliberately narrow.

### Decision

- **Firebase Auth provides identity; sync is opt-in and additive.** Decko stays
  fully usable signed-out and offline — Firebase init is guarded, and a
  `LocalOnlyAuthRepository` / `LocalOnlySyncRepository` are the safe defaults.
- **Two kinds of state, one synced.** Review/imported state (FSRS, due dates,
  imported progress, card ids, decks, media) is **not** synced in this MVP.
  Motivational state — profile, safe settings, and the MVP_019 activity ledger —
  **is**. Review correctness stays local until a dedicated, safety-designed
  review-sync MVP.
- **Everything is behind seams.** `AuthRepository` (+ `FirebaseAuthRepository`,
  anonymous / email-password / Google) and `SyncRepository` /
  `CloudActivityRepository` / `CloudUserRepository` (+ Firestore impls). Screens
  never touch Firebase; tests run entirely on in-memory fakes.
- **Activity sync is idempotent and non-destructive.** Events are keyed by their
  stable id (`/users/{uid}/activityEvents/{id}`), so re-uploading never
  duplicates progress; downloading merges cloud events the device lacks and
  **never deletes local-only events**. Conflicts favour additive merge.
- **Settings/profile are push-only this pass** (`/users/{uid}/settings/app`,
  `/profile/main`) — a safe cloud backup; cross-device settings *restore* is
  deferred so an older cloud value can't silently revert a local change.
- **Daily goal stays activity-count based** (DEC-028); only theme, furigana, and
  daily goal sync — never per-deck study options.

### Non-negotiables (unchanged)

- Cloud sync must never overwrite imported Anki progress or FSRS review state.
- `ReviewScheduler` remains the only path for due/review mutations.
- Syncing XP/streaks/history must not imply syncing card due dates.
- Local data wins over destructive cloud operations.

### Consequences

- Firestore rules scope each user to `/users/{uid}/**` only.
- Tests cover auth flows, sync idempotency/merge, the no-delete-local rule,
  settings mapping, the signed-out/offline path, and the account-screen states.
- Sets up MVP_021 (Typing Recall) or a dedicated review-state sync MVP — the
  latter only once its safety model is explicitly designed.

## DEC-029a: Decko now requires sign-in (auth gate) — supersedes DEC-029's "usable without an account"

Date: 2026-06-23
Status: Accepted (revises DEC-029)

### Context

DEC-029 made cloud sync opt-in and kept Decko fully usable signed-out/offline.
The product owner has since decided Decko should be an account-first app: every
user signs in before reaching the app, so there is always a cloud identity for
sync and a personalised home.

### Decision

- **A mandatory auth gate.** The GoRouter `redirect` sends any unauthenticated
  session to `/signin` (a branded `SignInScreen`); a signed-in session is
  redirected away from the gate to Home. `refreshListenable` is bound to the
  auth-state stream so the gate reacts immediately to sign-in/sign-out.
- **A real account is required — no guest.** Email/password or Google only; the
  anonymous "continue as guest" path was removed from the UI. (Firebase session
  persistence means the gate is only hit on first launch / after sign-out, so the
  app still works offline once signed in.)
- **Personalised Home.** A `SalutationHeader` greets the user by first name with
  their Google photo (initial / placeholder fallback) and a time-based greeting.

### Consequences

- This **supersedes** DEC-029's "fully usable without an account / offline"
  promise. Everything else in DEC-029 stands: only profile + safe settings +
  activity ledger sync; review/FSRS/imported state are never synced or mutated.
- First launch now needs network to sign in; subsequent launches are offline-OK.
- Tests: the harness signs in by default so app tests pass the gate; dedicated
  tests cover the gate (signed-out → SignInScreen) and the salutation.

## DEC-030: Typing Recall answer checking + review-state boundary

Date: 2026-06-23
Status: Accepted

### Context

MVP_021 adds Decko's third registered practice mode (`typing_recall`) — its first
productive-input mode (type the answer). Text input needs an answer-checking
layer that is forgiving enough for language learning but never silently accepts a
wrong answer, and it must not touch review/FSRS state.

### Decision

- **Registered like any mode.** `typing_recall` joins the `PracticeModeRegistry`;
  it surfaces in Deck Detail / Hub / review manual actions with one new
  `PracticeLauncher` case. Manual + deck practice only; **`reviewPresentation =
  false`** — scheduled-review typing is deferred because mapping typo/almost
  categories to FSRS grades is a real risk (DEC-030 defers it explicitly).
- **Two directions, mixed.** Per card the `TypingRecallBuilder` emits a *reading*
  round (show the expression → type the kana reading, only when the reading
  differs from the shown form) and/or a *meaning* round (→ type the English
  meaning; any comma/slash/semicolon-separated alternative is accepted). Sessions
  mix both. Pure + sync (no source load).
- **Explainable, conservative checking** (`TypingRecallChecker`), three buckets:
  - **correct** — matches an accepted answer after *safe* normalisation: trim,
    collapse spaces, katakana→hiragana, full-width→half-width, case-fold English,
    strip surrounding punctuation.
  - **almost** — not correct, but matches after dropping *all* spaces +
    punctuation, or is a single-character edit on an answer of length ≥ 4.
  - **incorrect** — otherwise. The expected answer is always revealed.
  We deliberately do **not** attempt full kana/kanji equivalence or romaji→kana;
  reading rounds expect kana input. The long-vowel mark ー is treated as
  meaningful (never stripped).
- **Motivation only.** Outcomes record a `PracticeOutcome` → activity ledger
  (XP: correct 5, almost 2, incorrect 0). Manual/deck typing **never** mutates
  FSRS, review-card state, due dates, daily counters, or sibling burying.

### Consequences

- The platform's claim holds again: a new mode = a builder + a registry entry +
  one launcher case + a screen. Deck Detail / Review / Hub untouched.
- Tests cover normalisation, correct/almost/incorrect classification, availability
  rules, deck-session generation, alternatives, the registry, and the screen flow.
- Deferred: scheduled-review typing (needs an explicit, tested grade mapping);
  romaji input; expression/sentence typing targets.

## DEC-031: Sync user review state, not deck content

Date: 2026-06-23
Status: Accepted

### Context

MVP_020 synced only motivational state (profile, settings, activity). To let a
learner continue on another device, Decko must sync per-card review/FSRS state —
but it must never sync deck packages/media, and never silently reset or regress a
card's progress (the project's oldest rule).

### Decision

- **Sync user state, not deck content.** Review/FSRS state syncs only for cards
  already present locally that can be *confidently matched*. Deck files, imported
  source notes, card templates, media, and `.apkg` packages are **never** synced.
- **Stable identity gates everything.** A deterministic `DeckFingerprint`
  (FNV-1a over sorted Anki card ids + note ids + counts + name; null for
  non-imported / non-`anki-card-…` decks) is the cloud key:
  `/users/{uid}/deckStates/{fingerprint}/cards/{itemId}`. The same `.apkg`
  imported on two devices produces the same fingerprint, order-independent.
  Cards match by the existing stable `LearningItem.id = anki-card-<cardId>`.
- **Push is automatic + additive; apply is explicit.** Reviewed cards push to
  the cloud after each session (incremental) and on manual "Sync now" — upload
  never touches local state. Applying cloud → local is **never automatic**: the
  deck-detail banner surfaces "synced progress available" and only a user tap
  writes it (honours "never silently reset FSRS").
- **Conflict-safe merge** (`ReviewStateMergePolicy`, pure): adopt cloud only when
  it is a strictly safe, newer continuation — newer `lastReviewedAt` AND
  monotonic (cloud `reps`/`lapses` never below local). A newer-but-regressing
  cloud state is a **conflict** (kept local, surfaced), never an overwrite.
  Unmatched cloud states are preserved-but-unapplied; unmatched local cards are
  left untouched. Cloud DTO (`SyncableReviewState`) is decoupled from local
  persistence.

### Consequences

- Cross-device "continue where you left off" works without trusting the cloud to
  define learning state. Firestore rules (`/users/{uid}/**`) already scope it.
- No FSRS math / due queue / daily limits / sibling burying changed.
- Tests cover fingerprint determinism + non-collision, DTO round-trip, every
  merge branch, and the service (push reviewed-only, apply matching-only, never
  overwrite advanced local, signed-out no-op).
- Deferred (MVP_023): richer conflict UX, recovery, pending/offline status. A
  full-deck push runs on manual sync (large decks are heavy) — incremental
  after-session push keeps the cloud current cheaply.

## DEC-032: Sync status visibility + explicit, plain-language review-state apply

Date: 2026-06-23
Status: Accepted

### Context

MVP_020/022 built the sync machinery; MVP_023 is about *trust*. Users need to see
what syncs, whether a deck is matched, whether progress is waiting, and what
"Apply synced progress" will (and won't) do — without ever fearing their study
progress could be overwritten silently.

### Decision

- **Derived, plain-language status — never new sync behaviour.** A pure
  `deriveDeckSyncState(...)` turns per-card merge tallies into a single headline:
  notImportedDeck / signedOut / notMatched / matchedUpToDate / localAhead /
  cloudAhead / conflict / offline. `ReviewStateSyncService.deckStatus(deck)`
  computes the tallies from the existing merge policy (Firebase fetch errors →
  offline). A pure `deriveGlobalSyncStatus(...)` maps auth + activity `SyncState`
  to a `GlobalSyncStatus`. Status reads never mutate review state.
- **Explicit apply, now explained.** The deck-detail banner only ever *offers*
  apply on `cloudAhead`; tapping opens a confirmation that states how many cards
  match, that only matching cards' review state changes, and that deck content /
  media / card text are untouched and newer-or-safer local progress is never
  overwritten. Conflicts surface a calm "Decko kept your local progress."
- **Calm offline + local-ahead messaging.** Offline reassures that studying still
  works and Decko will sync later; local-ahead simply notes this device is newer.

### Consequences

- Users can answer "am I synced / matched / cloud-ahead / local-ahead / in
  conflict / offline?" at a glance, per deck and globally.
- The MVP_020/022 sync boundary is unchanged: deck content / media / imported
  source are still never synced; no FSRS / scheduler / due-queue / daily-counter
  / sibling-burying behaviour changed.
- Deferred (later): true pending-upload tracking + a connectivity signal (offline
  is currently inferred from fetch failures).
