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

**Beautiful visual design is the product's core reason to exist** — explicitly
the opposite of AnkiDroid's utilitarian look. NEVER drop in stock/default
Material UI (e.g. a bare `AlertDialog`); always use Decko's polished components
(`DeckoConfirmDialog`, `DeckoSnackbar`, themed surfaces, DeckoSpacing/Radii) and
consider the interaction model, not just the content. A fix that looks like
generic Android/Anki must be redone.

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

### Added in MVP_003

- Review session screen (`features/review/review_session_screen.dart`) — three
  states from one screen: **reviewing** (a `Card X of N` progress header + bar,
  the `DeckoCard`, `Show answer`, then `RatingButtonRow`), **complete**
  (`SessionSummary`), and **empty** ("This deck has no cards yet." + Back to
  deck). Keeps the per-card theme switcher in the app bar.
- `SessionSummary` (`features/review/widgets/session_summary.dart`) — completion
  view: celebratory header, `Cards reviewed: N`, per-rating counts with the
  shared rating accent colours, and `Review again` / `Back to deck` actions.
- Empty-deck pattern: review never falls back to a sample card; an empty deck
  shows an explicit empty state (resolves the MVP_002 deferred note).

### Added in MVP_004

- Progress screen (`features/progress/progress_screen.dart`) — now data-driven
  via `ProgressRepository` (a `FutureBuilder<ProgressSnapshot>`): level card
  (XP + level + progress-to-next), stat cards (current streak, cards reviewed
  today), a "Your latest review" card with per-rating counts, and the
  Achievements badges whose earned state derives from the snapshot
  (First Review / Perfect Round / Three-Day Streak).
- No-progress empty state: rocket icon + "No progress yet" + "Complete your
  first review session to start building your Decko streak." Never shows fake
  numbers. Achievements remain visible (all locked).
- Persistence is invisible UI-wise but load-bearing: theme choice survives
  restart; figures come from stored progress, not constants. Storage sits
  behind `SettingsRepository` / `ProgressRepository` (DEC-009).

### Added in MVP_005

- Import screen (`features/import/import_screen.dart`) — a single screen with
  internal phases (idle → analysing → preview → importing → error). Idle lists a
  real "Import Anki deck (.apkg)" action plus CSV/JSON "Coming soon"; error
  shows a friendly "Couldn't import that deck" + Try again. Honest footer:
  "Decko imports a copy — it doesn't sync with Anki."
- `ImportPreviewPanel` (`features/import/widgets/`) — deck name, a stat list
  (cards found / new / reviewed / suspended / approx due / progress available),
  and the keep/start-fresh choice — or, when no progress exists, an honest
  warning + "Import as new".
- Deck detail provenance — imported decks show an `IMPORTED` label and a
  provenance card ("Imported from Anki · Progress: kept / started fresh / no
  scheduling data found"). Demo decks unchanged (`DEMO DECK`).
- Deck tiles label source as `Imported` vs `Demo deck`; imported decks list
  first. The library now rebuilds via a `ListenableBuilder` over the `DeckStore`
  so imports appear immediately and after restart hydration.
- Honesty rule: no screen claims AnkiWeb sync or full Anki compatibility; copy
  uses "first import support", "some complex decks may not import perfectly".

### Added in MVP_006

- Review is now a **due queue**: the session walks only due + new cards
  (`Card X of N` reflects the queue, not the whole deck). Grading writes back
  persistent `ReviewCardState` and the due count moves.
- **All-caught-up** state (`review_session_screen.dart`): when nothing is due,
  a check icon + "All caught up." / "No cards are due right now." + Back to deck
  (distinct from the zero-cards "This deck has no cards yet." state). No sample
  fallback.
- Deck detail **Due today / Reviewed are live** (read from `ReviewStateRepository`
  via a FutureBuilder): they decrement after review and survive restart.
- `DeckoSnackbar` (added MVP_005) is the standard confirmation toast.
- **Swipe-left to delete** an imported deck in the library (`Dismissible`, end-to-start,
  errorContainer background + trash icon, AlertDialog confirm). Demo decks are not
  deletable. Deleting also clears the deck's review state. Original Anki file untouched.
- **Furigana** (`core/widgets/furigana_text.dart`) — `FuriganaText` renders
  `漢字[かな]` bracket notation as ruby (reading above kanji); with readings off it
  renders plain base text. Used for card front + example and the deck-detail
  sample rows (base-only there). A furigana on/off **toggle** (translate icon)
  sits in the review app bar, persisted (`FuriganaController` + settings); default on.
- **Example emphasis** — `DeckoCard` renders the example sentence large (titleLarge,
  furigana) with the translation muted beneath; the meaning/answer is secondary.
  The sentence is the focal point of a vocab card (DEC-012).

### Added in MVP_008

- **Media in cards** — `DeckoFieldContent` (`core/widgets/`) renders a card field
  that mixes text (furigana via `FuriganaText`), `[sound:…]` audio (a filled-tonal
  **play button**, `audioplayers`), and `<img>` images (`Image.file`, max-height
  220, rounded). Parsed by `parseAnkiContent` (`core/content/anki_content.dart`).
  `DeckoCard` uses it for front / back / example and takes a `deckId` to resolve
  media via the `MediaStore`.
- **Missing media** — audio shows a disabled muted-volume button ("Audio
  unavailable"); images show a broken-image placeholder. Never crashes.
- **Import preview** now lists Audio references / Image references / Media files
  when the package has media.
- Media is per-deck on disk (`FileMediaStore`), deleted with the deck (DEC-014).
- Deck-detail sample rows strip media markers for a clean one-line preview.
- **Card is a true two-sided flip card** (`DeckoCard`): a clean **front** (word +
  word-audio only, centered prompt) that **3D-flips** (rotateY, ~460ms) on tap /
  "Show answer" to a **distinct back** (reading, meaning prominent, image, and the
  example box with sentence + sentence-audio). The word is NOT repeated on the
  back — it's the other side, not a taller front. Tap the card to flip.
- **`DeckoConfirmDialog`** (`core/widgets/`) — the on-brand replacement for stock
  `AlertDialog`: rounded surface, icon medallion, full-width confirm + text
  cancel; `destructive` flag colours it with the error scheme. Use for all
  confirmations (deck delete uses it).
- **Icons** — all icons are Font Awesome free (`FaIcon` + `FontAwesomeIcons.*`,
  typed `FaIconData`); fixed-size icon containers set `alignment: Alignment.center`
  (FA glyphs aren't auto-padded like Material icons). New icons follow suit (DEC-015).
- Reusable-component note: a **floating bottom nav bar** is a proposed future
  direction (rounded, elevated, active-tab-labelled) — would need a
  `StatefulShellRoute` refactor; tracked in ROADMAP Deferred Notes, not built.

### Added in MVP_008.5 (app shell + Home/Import separation, DEC-017)

- **`DeckoAppBar`** (`core/widgets/decko_app_bar.dart`) — the shared app-bar
  pattern. `DeckoAppBar.wordmark(actions:)` stamps the Decko wordmark (Home);
  `DeckoAppBar(title:, actions:)` shows a screen title (sub-screens). Flat
  (`scrolledUnderElevation: 0`, no surface tint) so chrome stays calm. Adopted by
  Home, Import, Deck Detail, Progress, and Themes. Use it instead of a bare
  `AppBar`.
- **`StudyRibbon`** (`features/deck_library/widgets/study_ribbon.dart`) — Home's
  hero and signature element: a **stacked-flashcard** band (offset card edges
  peeking behind a gradient face) naming the **resume deck** (most cards waiting)
  and its ready count, with a pill **Study** button. Softens to a quiet
  "all caught up" surface when nothing is due. The one bold element on Home;
  everything around it stays quiet.
- **`DeckRow`** (`features/deck_library/widgets/deck_row.dart`) — the compact deck
  shelf row: icon, name, `N cards · Imported/Demo`, and a live **to-study badge**
  (filled primary pill when cards wait, a quiet check when caught up). Replaces the
  large `DeckTile` on Home. Imported rows remain swipe-to-delete via `Dismissible`
  + `DeckoConfirmDialog`.
- **`DottedOutline`** (in `deck_library_screen.dart`) — a rounded dashed border
  (`CustomPainter`) used for the calm "Import a deck" ghost row at the foot of the
  shelf.
- **Home hierarchy** — ribbon → "Your decks" shelf → dashed Import row. Live
  per-deck counts come from `DueQueue.build` over persisted review state and
  refresh when returning from a session. The product **promise grid lives only in
  Home's empty state** now, never crowding a populated Home.

### Added in MVP_008.5b (floating bottom nav, DEC-018)

- **`DeckoBottomNav`** (`core/widgets/decko_bottom_nav.dart`) — the floating
  primary navigation: a rounded, elevated bar that hovers with a margin (never
  stock edge-to-edge `NavigationBar`). The **active** destination expands into a
  labelled primary pill; the rest are quiet `onSurfaceVariant` icons. Takes
  `items` / `currentIndex` / `onSelect`; every item has a tooltip + selected
  semantics. Default tabs: Home (`house`), Import (`fileImport`), Progress
  (`chartLine`), Settings (`gear`).
- **`DeckoShell`** (`app/decko_shell.dart`) — hosts a `StatefulNavigationShell`
  (the four-branch `StatefulShellRoute.indexedStack`) as the body with
  `DeckoBottomNav` as the `bottomNavigationBar`. Re-tapping the active tab pops
  that branch to its root. **Deck detail** lives inside the Home branch (bar stays,
  Back → Home); the **review session** is pushed on the root navigator so it plays
  full-screen over the bar.
- Home's app-bar action icons were removed (those destinations are now tabs); the
  Home Import affordances switch to the Import tab via `context.go`.

### Added in MVP_009 (imported-source inspector, DEC-016)

- **`ImportedSourceScreen`** (`features/imported_source/`) — a Decko-styled view of
  the preserved Anki source (not a raw debug table). Reached from a "View imported
  source" tile on deck detail (imported decks only), route `/deck/:id/source`.
  Sections: a primary-container **summary** (notes · note types · cards), a
  **note-types** card per model (field chips + numbered card-template chips), a
  **cards-by-template** breakdown (count chips, proving Listening/Reading/Production
  stay distinct), and a **sample note** card listing each field's name → plain value
  with small audio/image media pips, plus tag chips. Falls back to a friendly
  "No preserved source" empty state for pre-feature/demo decks.
- Reuses the shelf-card idiom (rounded `cardColor` + `outlineVariant` border),
  `SectionHeader`, and pill chips — no new primitives.

### Added in MVP_010 (note-type-aware cards, DEC-019)

- **Mode eyebrow** — `DeckoCard` shows a quiet small-caps eyebrow
  (`LISTENING` / `READING` / `PRODUCTION`) on both faces when
  `LearningItem.mode != generic`. Deliberately understated: muted
  `onSurfaceVariant`, letter-spaced `labelSmall`, **no badge or pill** — guides
  without making Decko feel like Anki's chrome. Nothing renders for `generic`.
- **Card-mapping inspect** — the imported-source screen gained a "Card mapping"
  section: one card per template showing the mapped Decko mode (a small
  secondary-container chip), the `Matched by …` rationale, and the FRONT / BACK
  source field lists — so import decisions are explainable.
- Per-mode front emphasis (audio-first listening, Japanese-text reading,
  English-prompt production) is driven by content arrangement from the
  `NoteTypeAwareCardMapper`, not new card widgets — the two-sided flip card is
  unchanged.

### Added in MVP_011 (study options, DEC-020)

- **Settings hub** — the Settings tab is now `SettingsHubScreen`: tiles for
  "Study defaults" and "Themes" (theme gallery moved to `/settings/themes`) plus
  the global furigana switch. Tile pattern = icon medallion + title + subtitle +
  chevron on a rounded `cardColor` surface.
- **Option controls** (`features/settings/widgets/option_controls.dart`),
  reusable across the global and deck screens:
  - `SettingsSection` — small-caps section label (+ optional subtitle) over a
    rounded surface of divider-separated rows.
  - `StepperRow` — label + round −/＋ buttons + value (integer options).
  - `ChoiceRow<T>` — label over a wrap of single-select pill chips (enums).
  - `SwitchRow` — label (+ subtitle) with a trailing `Switch`.
- **Deck-options override pattern** — each deck option shows a `SwitchRow`
  ("Using global: X" when off); flipping it on reveals the control set to the
  current global value. Furigana uses a 3-way `ChoiceRow` (Use global / Always
  show / Always hide). Reached from a "Deck options" tile on deck detail.
- The deck-detail action tiles (Deck options, View imported source) share one
  `_DeckActionTile` row idiom.

### Added in MVP_012 (option profiles, DEC-021)

- **`StudyOptionsForm`** (`features/settings/widgets/study_options_form.dart`) —
  the shared editable options form (daily limits · media · collapsed **Advanced
  scheduling** with new-card order + bury). Reused by the global "Study defaults"
  screen and the profile editor, so there's one options form, not three.
- **Advanced disclosure** — a small-caps "ADVANCED SCHEDULING" row that expands
  to reveal advanced controls (progressive disclosure; defaults stay simple).
- **Study profiles** — Settings hub gains a "Study profiles" tile →
  `StudyProfilesScreen` (list with a Default badge; "New profile" → editor). A
  user profile opens `ProfileEditorScreen` (rename `TextField` + `StudyOptionsForm`
  + destructive delete via `DeckoConfirmDialog`); the Default profile opens the
  global Study defaults instead.
- **Deck profile assignment** — Deck options gains a "Study profile" `ChoiceRow`
  at the top; override baselines read "Inherited: X" from the selected profile
  (not just global), and an Advanced section adds the new-card-order override.
- No new primitives — everything reuses `SettingsSection` / `StepperRow` /
  `ChoiceRow` / `SwitchRow` from MVP_011.

### Added in MVP_014 (import diagnostics UX, DEC-023)

- **`ImportHealthSummary`** (`features/import/widgets/import_health_summary.dart`) —
  the reusable import "health" panel. A coloured status header (✓ healthy in
  `primaryContainer` / ⚠ usable in `tertiaryContainer` / ✕ blocked in
  `errorContainer`) with calm copy, a `Wrap` of plain-language metadata chips
  (format described in words, note/card/template/media counts), grouped attention
  findings (category eyebrow + severity-coloured rows), and a collapsed
  **"Technical details"** disclosure. No enum/SQLite wording in the primary view.
  Used by the import preview, the post-import result, and the import report.
- **Import flow states** — the import screen gained a calm **result** phase
  (`_ResultPanel`) shown only for imports with warnings (clean imports keep the
  snackbar→Home flow). Blocking/unsupported stay in the existing error state with
  a practical next step.
- **`ImportReportScreen`** (`features/import/`) — the saved report, reached from a
  "Import report" `_DeckActionTile` on deck detail (imported decks with stored
  diagnostics). Reuses `ImportHealthSummary`.
- Severity colours: error → `error`, warning → `tertiary`, info →
  `onSurfaceVariant` (a reusable convention for finding rows).

### Conventions

- Buttons use the themed `FilledButton`/`OutlinedButton` (min height 56) for
  comfortable mobile tap targets.
- Icon-only buttons carry tooltips; badges/rating buttons carry `Semantics`
  labels.
- Sub-screens are pushed over the deck library so back returns to the hub.

### Added in MVP_015 (progress polish & light gamification, DEC-024)

- **Daily-goal card** (`features/progress/progress_screen.dart` `_DailyGoalCard`)
  — a circular progress ring (`CircularProgressIndicator`, rounded cap) with the
  count in the centre, flipping to a celebratory `primaryContainer` "Daily goal
  reached!" state with a check. Motivational only; never a scheduling limit.
- **Kinder streak stat** — `_StatCard` gained an optional `footnote` line
  (primary-coloured) used for encouraging streak status ("Counted today" /
  "Study today to keep it" / "Study today to start one").
- **Achievements grid** (`_AchievementsGrid`) — a `Wrap` of the existing
  `AchievementBadge` (earned/locked) driven by the pure `achievementsFor`
  (domain `achievement.dart`); icons mapped per achievement.
- **Session reward chips** (`features/review/widgets/session_summary.dart`
  `_RewardChips`) — pill chips for XP gained, daily-goal progress (highlighted
  when reached), and streak, under the completion header. Optional fields, so the
  summary degrades gracefully before progress is recorded.
- **Daily-goal stepper** (`features/settings/settings_hub_screen.dart`
  `_DailyGoalControl`) — a −/value/+ row in the Settings hub (5–100, step 5),
  persisted to `SettingsRepository`.

### Added in MVP_016 (Bunburu sentence builder, DEC-025)

- **`SentenceBuilderView`** (`features/sentence_builder/widgets/`) — the
  interactive surface: a build row (slots) above a shuffled bank of soft "cube"
  token chips (`Material`+`InkWell`, rounded, subtle shadow; filled =
  `primaryContainer`). Check / Show-answer actions, a gentle shake on a wrong
  check, and a coloured reveal block (correct = `primaryContainer`, revealed =
  `tertiaryContainer`) showing the full sentence + translation + optional audio.
  Presentation-only; the host owns the post-resolve action via `onResolved`.
  Note: avoid `Row`+`Expanded` for its action buttons — stacked full-width
  buttons keep it robust under loose/unbounded width (it renders inside both a
  `ListView` and the review body).
- **`SentenceBuilderScreen`** (`features/sentence_builder/`) — drives a session
  (single manual round or deck practice) and ends on a calm MVP_015-style
  "Practice complete" panel ("your review schedule is unchanged"). Records
  nothing to review/progress.
- **`SentenceBuilderHubScreen`** (`features/sentence_builder/`) — a practice hub
  listing sentence-capable decks (deck tiles with `cubesStacked` + play), reached
  from a Home "Practice" section. Tapping a deck loads its source, builds rounds,
  and opens `SentenceBuilderScreen`. Warm "No sentences yet" empty state.
- **Entry points** — a Home "Practice" section with a `primaryContainer`
  **Sentence builder** row → the hub (shown when any deck likely has sentences);
  a "Build this sentence" `TextButton` in the review card's revealed area
  (manual); a `cubesStacked` "Sentence builder" deck-detail tile (deck practice);
  and the opt-in review presentation, which reuses `SentenceBuilderView` inside
  the review body and keeps the normal grade buttons.

### Added in MVP_017 (practice-mode platform, DEC-026)

- **`PracticeModeTile`** (`features/practice/widgets/practice_mode_tile.dart`) —
  the canonical practice-mode row (icon medallion + title + subtitle + play),
  with an `accent` variant for Hub heroes. UI-side `practiceModeIcon(id)` and
  `practiceCardAction(id)` map a mode to its icon / in-review action label, so
  the domain stays framework-light. Used by the Hub, Deck Detail, and Review.
- **`PracticeHubScreen`** (`features/practice/`) — the registry-driven hub
  ("Available now" mode tiles → a deck picker; "From your decks" deck rows that
  launch their mode), replacing the Bunburu-specific hub. Reached from the Home
  "Practice" section (now labelled generically, `gamepad` icon).
- **Deck Detail "Practice modes"** — a `_PracticeModesSection` lists
  `registry.availableForDeck(deck)` as `PracticeModeTile`s; hidden when none.
- **Review manual actions** — the revealed card renders one button per
  `registry.manualModesForCard(item)` (Bunburu → "Build this sentence"); the
  opt-in review presentation is gated by `registry.reviewPresentationModesForCard`.
- **`PracticeLauncher`** (`features/practice/practice_launcher.dart`) — the one
  place mapping a `PracticeMode` → its screen (`launchDeck` / `launchCard`); a
  future game is one new `case`.
- Practice completion shows a `+N XP` pill (motivational; review schedule
  unchanged).

### Added in MVP_021 (Typing Recall, DEC-030)

- **`TypingRecallScreen`** (`features/typing/`) — a `primaryContainer` prompt
  card (instruction label + the large word), a focused text field (autofocus),
  a Check button, then a colour-coded feedback panel — correct (green
  `solidCircleCheck`), almost (amber `circleHalfStroke`), incorrect (error
  `circleXmark`) — that always reveals `Answer: …` + the explanation, with
  Next/Finish and a keyboard-icon completion + `+XP` pill. Kind, never shaming.
- Registered via the platform — `keyboard` icon + "Type this" card action added
  to the `practiceModeIcon` / `practiceCardAction` maps; surfaces in the Hub,
  Deck Detail, and review manual actions with no screen-specific code.

### Added in MVP_020 (Account & sync, DEC-029)

- **`AccountScreen`** (`features/account/`, route `/settings/account`) — branded
  identity + sync, never stock Firebase UI. Signed-out: a `primaryContainer`
  hero, email/password fields, Sign in / Create account, an "or" divider,
  Continue with Google, an anonymous option, and the local-only promise. Signed
  in: a profile card, a live sync-status card (`StreamBuilder<SyncState>` with
  status icon + "Sync now"), a "What syncs / stays local" card, and Sign out.
- **Settings hub** gains an **Account & sync** tile (`cloudArrowUp`) at the top.
- Errors surface inline + via `DeckoSnackbar`; all friendly, never raw Firebase.

### Added in MVP_019 (Activity ledger & heatmap, DEC-028)

- **`ActivityHeatmap`** (`features/progress/widgets/`) — a GitHub-style XP grid:
  the recent days laid out as week columns of seven rounded cells, intensity by XP
  (`surfaceContainerHighest` → `primary` in five buckets), today ringed, a
  Less→More legend, horizontally scrollable (newest on the right). Card surface.
- **`RecentActivityList`** (`features/progress/widgets/`) — a bordered card of
  recent ledger rows: mode icon (review `layerGroup` / Bunburu `cubesStacked` /
  listening `headphones`), a label ("Reviewed N cards" / "Sentence builder" /
  "Listening challenge"), relative time, and a `+N XP` trailing pill.
- **Progress screen** is now ledger-backed: daily-goal ring + level card (now
  with a "Review X · Practice Y" XP breakdown) + streak / XP-today stat cards +
  heatmap + recent activity + achievements. The old per-session "latest review"
  card was replaced by recent activity.

### Added in MVP_018 (Listening Challenge, DEC-027)

- **`ListeningChallengeScreen`** (`features/listening/`) — a big circular
  play/replay button (`volumeHigh`; `volumeXmark` when audio is unavailable),
  four `_ChoiceCard`s, immediate correct/incorrect feedback (correct =
  `primaryContainer`+check, wrong-selected = `errorContainer`+x, others muted),
  the revealed prompt word/sentence, next/finish, and a headphones completion
  panel with a `+N XP` pill. Reuses `MediaStore` + `audioplayers` (autoplay per
  round). No new media layer.
- Registered via the platform — `headphones` icon + "Listen & choose" card
  action added to the `practiceModeIcon` / `practiceCardAction` maps; it surfaces
  in the Practice Hub, Deck Detail "Practice modes", and review manual actions
  with no screen-specific code.

## Accessibility Baseline

All Decko UI work should consider:

- readable contrast
- large enough tap targets
- text scaling
- screen reader labels for icon-only buttons
- motion that does not block comprehension

## Imprint Rule

When a reusable visual pattern is created, update this file using the imprint skill.
