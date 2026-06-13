# MVP_009 — Study Options and Deck Overrides

## Status

Planned.

## Mission

Add a simple, persistent study-options system that lets Decko combine global study defaults with deck-specific overrides, then apply the effective options to review sessions and media behaviour.

Decko now imports real Anki decks, preserves progress, has a due queue, uses FSRS scheduling, and is gaining media support. The next product step is giving the learner control over how each deck behaves without exposing the full complexity of Anki option groups yet.

The key product promise is:

> I can set how I usually study, then override those settings for a specific deck when that deck needs different behaviour.

## Context

Existing architecture already includes:

- Local-first storage.
- Imported decks persisted locally.
- Persistent per-card review state.
- FSRS scheduling behind the `ReviewScheduler` seam.
- Furigana preservation/rendering with a persisted toggle.
- Media import/rendering planned in MVP_008.
- Deck detail and review session flows.

MVP_009 should introduce a first-class options layer without changing FSRS maths.

## Core concept

Implement two levels of options:

```text
GlobalStudyOptions
        ↓
DeckStudyOptions overrides
        ↓
EffectiveStudyOptions used by review/media flows
```

Rules:

- Global options define the default behaviour for all decks.
- Deck options may override selected global options.
- If a deck option is unset, the global value is used.
- The review session should only consume `EffectiveStudyOptions`.
- FSRS scheduling calculations must remain isolated in the scheduler layer.

## Goals

### 1. Add domain models

Create simple, immutable domain models such as:

```dart
class StudyOptions {
  final int newCardsPerDay;
  final int reviewCardsPerDay;
  final int maxSessionCards;
  final AudioAutoplayMode audioAutoplayMode;
  final ImageDisplayMode imageDisplayMode;
  final FuriganaPreference furiganaPreference;
  final bool burySiblingsUntilTomorrow;
}
```

Suggested enums:

```dart
enum AudioAutoplayMode {
  off,
  beforeQuestion,
  afterReveal,
}

enum ImageDisplayMode {
  withQuestion,
  afterReveal,
}

enum FuriganaPreference {
  useGlobal,
  alwaysShow,
  alwaysHide,
}
```

The exact names may change, but keep the concepts explicit and testable.

### 2. Add repositories

Introduce a repository seam for options, for example:

```dart
abstract class StudyOptionsRepository {
  Future<StudyOptions> getGlobalOptions();
  Future<void> saveGlobalOptions(StudyOptions options);

  Future<DeckStudyOptions?> getDeckOptions(String deckId);
  Future<void> saveDeckOptions(String deckId, DeckStudyOptions options);

  Future<EffectiveStudyOptions> getEffectiveOptions(String deckId);
}
```

Persist options locally. Use the existing local persistence approach unless there is a clear reason not to.

### 3. Add global study defaults screen

Add a place where the user can configure global study defaults.

This can be reached from an existing settings/theme/progress area, or from a simple route if the app does not yet have a full settings page.

Minimum fields:

- New cards per day.
- Review cards per day.
- Maximum cards per session.
- Audio autoplay mode.
- Image display mode.
- Global furigana default.

### 4. Add deck-specific options screen

From deck detail, add a visible entry point such as:

```text
Deck options
```

The deck options screen should allow overriding the global defaults.

Keep the UI simple. A good first version is:

- Show the global value.
- Let the user choose “Use global” or “Override for this deck”.
- If overridden, let the user set the deck-specific value.

Minimum deck-specific overrides:

- New cards per day.
- Review cards per day.
- Maximum cards per session.
- Audio autoplay mode.
- Image display mode.
- Furigana preference.
- Bury siblings until tomorrow on/off.

### 5. Apply options to review queue creation

The due queue should respect:

- `newCardsPerDay`
- `reviewCardsPerDay`
- `maxSessionCards`

Expected behaviour:

- A very large imported deck should not dump thousands of cards into one session.
- If the deck has many due review cards, the review cap should limit the session.
- If the deck has many new cards, the new-card cap should limit how many new cards are introduced.
- The final session should not exceed `maxSessionCards`.

Be careful not to damage existing imported progress or FSRS scheduling state.

### 6. Apply options to media behaviour

If MVP_008 media support exists, apply:

- `audioAutoplayMode`
- `imageDisplayMode`

Expected behaviour:

- `off`: do not autoplay audio; show a manual play button where applicable.
- `beforeQuestion`: play prompt audio when the card appears.
- `afterReveal`: play answer/audio after the answer is revealed.
- `withQuestion`: show image on the question side if present.
- `afterReveal`: hide image until reveal if configured.

If MVP_008 is not merged yet, implement the options model/UI and leave media hooks clearly marked for integration.

### 7. Apply options to furigana behaviour

The existing furigana toggle is global. Preserve it.

MVP_009 should add deck-level control:

- Use global setting.
- Always show furigana for this deck.
- Always hide furigana for this deck.

Do not remove the existing global toggle.

### 8. Add tests

Add pure tests for:

- Global defaults.
- Deck override resolution.
- Effective options fallback logic.
- Queue limits for new/review/session max.
- Furigana preference resolution.

Add widget tests for:

- Opening deck options from deck detail.
- Changing a deck option and seeing it persist.
- Review session respecting a small max-session limit.

## Non-goals

Do not implement in MVP_009:

- Full Anki option-group parity.
- Custom FSRS weights UI.
- Desired retention tuning.
- Learning steps / relearning steps UI.
- Graduating/easy interval settings.
- Deck option groups shared across multiple decks.
- Cloud sync.
- Accounts.
- Modern `.anki21b` support.
- Import media extraction if MVP_008 has not already handled it.

## UX principles

Decko should not become intimidating.

Use human wording, not Anki jargon, wherever possible.

Prefer:

```text
New cards per day
Reviews per day
Maximum cards in one session
Play audio automatically
Show images before answering
Bury related cards until tomorrow
```

Avoid exposing advanced terms too early:

```text
Lapse interval
Learning steps
Graduating interval
FSRS parameters
Desired retention
```

## Suggested screens

### Global Study Options

Sections:

1. Daily study limits.
2. Media behaviour.
3. Reading aids.
4. Related-card behaviour.

### Deck Options

Header:

```text
Options for <deck name>
```

For each option:

```text
Use global default: <value>
Override for this deck
```

## Acceptance criteria

- [ ] A global study-options model exists.
- [ ] A deck-specific override model exists.
- [ ] Effective options are resolved from global + deck-specific values.
- [ ] Options persist across app restart.
- [ ] Deck detail has a clear “Deck options” entry point.
- [ ] User can configure global daily limits.
- [ ] User can configure deck-specific daily limits.
- [ ] Review sessions respect new-card, review-card, and max-session limits.
- [ ] User can configure audio autoplay behaviour.
- [ ] User can configure image display behaviour.
- [ ] User can configure deck-level furigana preference.
- [ ] Existing global furigana toggle still works.
- [ ] FSRS scheduling maths is unchanged.
- [ ] Imported progress is not reset.
- [ ] Existing import, review, delete-deck, and progress flows still work.
- [ ] `flutter analyze` passes.
- [ ] Tests cover option resolution and queue limiting.

## Approval report required

When complete, report:

1. Summary.
2. Files changed.
3. Options added.
4. Persistence strategy.
5. How global and deck-specific options combine.
6. How review queue limits are applied.
7. How media/furigana options are applied.
8. Tests added.
9. Known limitations.
10. Recommendation for the next MVP.

## Likely next MVP

MVP_010 should expand from simple deck overrides toward a more Anki-like options/profile system only after MVP_009 is stable.
