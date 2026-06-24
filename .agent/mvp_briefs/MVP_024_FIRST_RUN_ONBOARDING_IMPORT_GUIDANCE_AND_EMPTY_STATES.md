# MVP_024 — First-Run Onboarding, Import Guidance & Empty States

## Status

Planned.

## Mission

Make Decko understandable, welcoming, and shippable for a new user who has never spoken to us before.

Decko already has a strong technical spine: Anki import, media, FSRS review, practice modes, activity tracking, auth, activity sync, matching-deck review-state sync, and sync-status UX. This MVP turns that power into a calm first-run experience.

A new user should immediately understand:

- what Decko is
- whether they need an Anki deck
- how import works
- what happens to existing Anki progress
- what syncs and what does not
- how to start studying even before importing a personal deck
- where to go next when the library is empty

## Product Promise

> Import your deck. Study it beautifully.

This MVP must reinforce that promise without overwhelming the user.

## Why this MVP matters

Decko is moving from feature-building into shippability.

The product is no longer missing its core engine. The main risk now is that a first-time user opens Decko and sees an empty or technical interface without understanding the value.

A shippable Decko needs a first-run path that feels:

- friendly
- beautiful
- safe
- honest about sync
- reassuring about progress preservation
- easy to act on

## Non-goals

This MVP must not change learning correctness.

Do **not** change:

- FSRS scheduling
- due queue logic
- sibling burying
- daily limits
- review-state merge rules
- synced review-state semantics
- imported card IDs
- deck fingerprint rules
- Anki parsing logic
- media extraction logic
- practice-mode scoring logic

This MVP is UX, onboarding, empty states, and guidance.

## Scope

### 1. First-run onboarding flow

Add a short, skippable onboarding flow shown only when the user first opens Decko.

It should explain Decko in a few calm screens:

1. **Import your deck**
   - Decko works with Anki `.apkg` decks.
   - Existing progress is detected when available.

2. **Study beautifully**
   - Review cards, media, furigana, and practice modes are presented in Decko’s own modern UI.

3. **Keep your progress safe**
   - Decko never silently resets imported progress.
   - Progress decisions are explicit.

4. **Sync across devices**
   - Decko syncs account/activity and review state for matching decks.
   - Decko does not currently sync deck files or media.
   - To continue on another device, import the same deck there.

The flow should be short enough to feel helpful, not like a tutorial wall.

### 2. Empty library state

Replace any plain empty library state with a beautiful Decko empty state.

It should include:

- friendly headline
- one-sentence explanation
- primary action: import Anki deck
- secondary action: try sample/demo deck if available in this MVP
- short reassurance about progress safety

Suggested copy:

> Your Decko library is empty.
>
> Import an Anki deck to start studying beautifully. If your deck contains progress, Decko will ask before keeping or resetting it.

Actions:

- Import deck
- Try sample deck

### 3. Import guidance screen polish

The import screen should clearly explain:

- supported format: `.apkg`
- modern Anki packages are supported from MVP_013
- progress-aware import choices
- media support
- diagnostics/report availability
- what to do if import fails

This must remain calm and user-facing. Avoid exposing raw technical language by default.

Technical details may remain available behind an existing diagnostics/report screen.

### 4. Sync explanation for new users

Add short user-facing sync guidance in onboarding and/or account/sync screen:

Decko syncs:

- account profile
- safe settings
- activity ledger / XP / streak / heatmap history
- review and FSRS state for matching local decks

Decko does not yet sync:

- `.apkg` deck files
- images/audio media files
- imported deck content

Important explanation:

> To continue the same deck on another device, import the same deck there. Decko will recognise it and offer to apply synced progress.

This explanation is essential for avoiding user confusion after MVP_022 and MVP_023.

### 5. Empty account/sync states

When the user is signed out, account/sync screens should explain what signing in enables:

- activity sync
- progress history sync
- review-state sync for matching decks
- safer cross-device continuity

When the user is signed in but has no imported decks, explain that sync is ready but there are no decks to match yet.

### 6. First successful import celebration

After a user imports their first deck, show a small success state that explains what just happened.

It should include:

- deck imported
- card count
- whether media was found
- whether progress was found/kept/reset/not present
- next action: start studying
- secondary action: view import report

This should reuse existing import diagnostics/health work from MVP_014.

### 7. Optional sample/demo deck

If feasible in this MVP, include a small built-in sample deck so users can try Decko before importing.

The sample deck should:

- be clearly labelled as sample/demo
- not pretend to be imported Anki content
- support review and at least one practice mode if possible
- be deletable or ignorable

If sample deck implementation becomes too large, it may be deferred to MVP_025, but the empty state should still reserve a clean design slot for it.

## UX principles

- beautiful, not stock Material
- reassuring, not technical
- concise, not tutorial-heavy
- honest about sync boundaries
- no scary wording around user progress
- every empty state should offer a clear next action

## Required user-facing messages

Decko must clearly communicate these ideas somewhere in the MVP:

### Progress safety

> Decko never silently resets imported progress.

### Sync boundary

> Decko syncs your study progress for matching decks, but not deck files or media yet.

### Cross-device continuity

> To continue on another device, import the same deck there and Decko will offer to apply synced progress.

### Empty library

> Import an Anki deck to begin, or try a sample deck to see how Decko feels.

## Data / persistence

Add a minimal onboarding-complete flag to local settings.

Suggested setting:

```dart
hasCompletedFirstRunOnboarding: bool
```

It should be local-first and safe. Do not tie onboarding completion to auth.

If a user signs out, onboarding should not necessarily reset.

## Routes / surfaces

Likely affected surfaces:

- app startup/root routing
- deck library / home screen
- import screen
- import result screen
- account/sync screen
- settings/help area if present

Potential new route:

```text
/onboarding
```

Potential reusable widgets:

```text
OnboardingScreen
OnboardingPage
EmptyLibraryState
ImportGuidanceCard
SyncExplainerCard
FirstImportSuccessPanel
```

## Acceptance criteria

- [ ] First-run onboarding appears for new local installs.
- [ ] Onboarding is skippable.
- [ ] Onboarding completion is persisted locally.
- [ ] Empty library state is beautiful and action-oriented.
- [ ] Empty library state links to import.
- [ ] Import screen explains supported deck format and progress safety.
- [ ] Sync explanation clearly states what syncs and what does not.
- [ ] Account/sync empty states are clear for signed-out and no-deck states.
- [ ] First successful import has a clear success/next-step state.
- [ ] Existing imported decks and review state are untouched.
- [ ] No FSRS, scheduler, due queue, daily limit, or sibling burying logic changes.
- [ ] No deck/media cloud sync added.
- [ ] Existing tests remain green.
- [ ] New widget/domain tests cover onboarding flag and empty states.
- [ ] `flutter analyze` passes.

## Suggested tests

### Unit tests

- onboarding completion flag defaults to false
- onboarding completion persists true
- sign-out does not reset onboarding flag

### Widget tests

- first-run onboarding renders
- skip onboarding reaches library
- complete onboarding reaches library
- empty library shows import action
- empty library shows sample-deck action only if implemented
- signed-out sync explanation renders
- signed-in/no-deck sync explanation renders
- import guidance mentions progress safety

### Regression tests

- imported deck IDs unchanged
- imported review state unchanged
- synced review-state DTOs unchanged
- review queue output unchanged

## Documentation updates

Update:

- `docs/ROADMAP.md`
- `docs/UI_REGISTRY.md`
- `docs/DECISIONS.md`
- `memory.md`

Decision record suggestion:

```text
DEC-033 — First-Run Onboarding and Honest Sync Boundaries
```

Core decision:

> Decko explains import, progress safety, and sync boundaries during first-run and empty states. Onboarding may guide users, but it must not change import, scheduler, FSRS, or sync semantics.

## Agent instructions

Follow the `.agent` operating system:

```text
orient -> architect -> decide -> execute -> imprint -> review -> remember
```

Use existing Decko UI patterns. Do not introduce stock/default Material-looking onboarding cards.

Update `.agent/skills/` only if this MVP changes how future agents should operate.

## Definition of done

MVP_024 is done when a brand-new user can open Decko, understand what it does, understand how import and sync work, and take a clear first action without reading our internal roadmap or prior conversations.

The finished experience should make Decko feel closer to a shippable product, not just a technically powerful prototype.
