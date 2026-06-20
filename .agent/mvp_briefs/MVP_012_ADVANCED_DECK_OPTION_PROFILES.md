# MVP_012 — Advanced Deck Option Profiles

## Status

Planned, postponed until after MVP_011.

## Why this was renumbered

This brief was originally drafted as `MVP_010 — Advanced Deck Option Profiles`.

That sequence changed after Decko’s real Anki import work revealed two required foundations:

```text
MVP_009 — Lossless Anki Note Import and Field Preservation
MVP_010 — Note-Type-Aware Decko Card Mapping
MVP_011 — Study Options and Deck Overrides
MVP_012 — Advanced Deck Option Profiles
```

This brief now assumes MVP_011 has introduced simple global/deck study options.

## Mission

Expand Decko’s simple MVP_011 study-options system into a more Anki-like option profile system, while keeping the default user experience calm and understandable.

MVP_011 gives Decko global defaults plus deck-specific overrides. MVP_012 should introduce reusable option profiles for advanced users and imported Anki-style workflows.

The key product promise is:

> I can create a study profile once, reuse it across multiple decks, and optionally tune advanced scheduling/media behaviour without breaking Decko’s simpler defaults.

## Critical Anki-parity loose ends from MVP_011

MVP_011 intentionally shipped two honest limitations. Because Decko’s goal is to support a close Anki-compatible study experience, these must not be treated as cosmetic follow-ups:

1. **Daily limits are currently per-session caps.**
   - MVP_011 can cap new/review/session size, but reopening a session later the same day can grant a fresh allowance.
   - MVP_012 should either implement true daily accounting or explicitly mark it as the next blocking scheduler-parity item.
   - A true implementation should track cards studied today by deck/profile, reset at the correct day boundary, and make the remaining allowance visible or testable.

2. **Bury siblings is stored but not enforced.**
   - MVP_011 stores the preference, but the queue does not yet hide sibling cards from the same Anki note.
   - For Anki-like behaviour, effective options must drive queue filtering so related new/review cards are buried until tomorrow after one sibling is shown or reviewed.
   - Burying must never delete cards or reset FSRS state.

If MVP_012 cannot complete both of these, it must clearly report which one remains and why. Do not let these disappear behind profile-management UI.

## Context

This MVP assumes MVP_011 has shipped:

- `GlobalStudyOptions` or equivalent.
- Deck-specific overrides.
- Effective option resolution.
- Review queue limits.
- Media behaviour options.
- Furigana preferences.
- Persistent options storage.

MVP_012 should build on that system rather than replacing it.

## Core concept

Introduce reusable option profiles:

```text
Global defaults
        ↓
Option profile, optional
        ↓
Deck-specific overrides
        ↓
EffectiveStudyOptions
```

Decko should support:

- A default profile.
- User-created profiles.
- Assigning a profile to one or more decks.
- Deck-specific overrides on top of the assigned profile.

This is similar in spirit to Anki option groups, but the UI should remain more approachable.

## Goals

### 1. Add option profile domain model

Create a model such as:

```dart
class StudyOptionProfile {
  final String id;
  final String name;
  final StudyOptions options;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

Also add deck assignment metadata, for example:

```dart
class DeckStudyOptions {
  final String deckId;
  final String? profileId;
  final StudyOptionsOverride overrides;
}
```

Exact names may vary. Preserve the core idea:

```text
Profile gives reusable settings.
Deck override customises only this deck.
```

### 2. Add profile repository operations

Extend the options repository or create a dedicated profile repository.

Minimum operations:

- List profiles.
- Get profile by id.
- Create profile.
- Rename profile.
- Update profile options.
- Delete profile safely.
- Assign profile to deck.
- Unassign profile from deck.
- Resolve effective options for deck.

Deletion rule:

- Do not delete the default profile.
- If a profile used by decks is deleted, affected decks should fall back to global/default options, or the user should be asked to reassign them.

### 3. Add profile-management UI

Add a simple profile-management screen.

Minimum features:

- See existing profiles.
- Create a new profile.
- Rename a profile.
- Edit a profile’s options.
- See which decks use a profile, if practical.

The UI should not feel like a database admin panel.

Suggested wording:

```text
Study profiles
Use one set of study settings across several decks.
```

### 4. Add deck profile assignment UI

From Deck Options, allow the user to choose:

```text
Study profile:
- Default
- Intensive Japanese
- Audio-first listening
- Light daily review
```

Then allow deck-specific overrides below the selected profile.

The screen should clearly show:

```text
Profile value: 20 new cards/day
Deck override: 10 new cards/day
```

### 5. Add advanced but optional scheduling controls

MVP_012 may introduce advanced scheduling controls, but they must be hidden behind an “Advanced” section.

Possible advanced options:

- Desired retention.
- Maximum interval.
- New card insertion order.
- Bury related new cards.
- Bury related review cards.
- Enable/disable sibling burying.

Be careful:

- Do not expose raw FSRS weights in this MVP unless there is already a safe internal representation and tests.
- Do not allow settings that make scheduling nonsensical.
- Defaults should remain safe.

Recommended v1 advanced scheduling scope:

```text
Desired retention
Maximum interval
Bury related cards until tomorrow
New-card order: in deck order / random
```

Avoid raw FSRS weights for now.

### 6. Implement or explicitly advance sibling burying semantics

Because MVP_011 only stores bury-siblings without enforcing it, MVP_012 should treat this as Anki-parity work.

Expected behaviour:

- If a card from a note is studied today, sibling cards from the same note may be buried until tomorrow when burying is enabled.
- Sibling identity should come from the preserved Anki source where available: note id / card source / imported source links.
- Burying should be controlled by effective options.
- Burying must not delete or permanently hide cards.
- Burying must not reset FSRS state.
- Due counts should reflect buried cards clearly if possible.

If sibling identity is not reliable yet, record that limitation and keep the UI honest.

### 7. Implement or explicitly advance true daily limits

Because MVP_011 limits are per-session, MVP_012 should either make them true daily limits or create a dedicated next-MVP blocker.

Expected behaviour:

- Track new/review counts already consumed today.
- Reopening a session on the same day should not reset the allowance.
- The day boundary should be deterministic and testable.
- Counts should be per deck or per effective profile, whichever matches the final option-resolution model.
- Tests should cover starting a second session on the same day and after the next-day reset.

This is required for Anki-like study control. Do not describe daily limits as complete until this exists.

### 8. Add import-aware profile suggestions

When importing a deck, Decko may suggest an option profile based on media/card characteristics.

Examples:

- Deck contains many `[sound:]` references → suggest “Audio-first”.
- Deck contains many images → suggest “Image-first”.
- Very large imported deck → suggest a conservative daily limit.

This should be a suggestion only, not automatic behaviour that surprises the user.

### 9. Keep simple mode simple

Decko should still feel approachable.

The default user path should remain:

```text
Import deck → Study → Progress
```

Advanced profiles should be available for users who want them, not forced on everyone.

## Non-goals

Do not implement in MVP_012:

- Full Anki option-group parity.
- Raw FSRS weight editor.
- Cloud sync of profiles.
- Account-level profile sharing.
- Marketplace/community profile presets.
- Modern `.anki21b` import.
- Major navigation redesign.

## UX principles

Decko should avoid becoming visually or cognitively overwhelming.

Use progressive disclosure:

```text
Basic options visible by default.
Advanced scheduling collapsed by default.
Dangerous or confusing controls deferred.
```

Prefer wording like:

```text
Study profile
Daily limits
Audio behaviour
Images
Advanced scheduling
Related cards
```

Avoid making the user learn Anki terminology unless necessary.

## Acceptance criteria

- [ ] A reusable study option profile model exists.
- [ ] Profiles persist locally.
- [ ] At least one default profile exists.
- [ ] User can create a profile.
- [ ] User can rename a profile.
- [ ] User can edit a profile’s options.
- [ ] User can assign a profile to a deck.
- [ ] Deck-specific overrides still work on top of the assigned profile.
- [ ] Effective options resolve in the correct order: global/default → profile → deck override.
- [ ] Review sessions use effective options exactly as before.
- [ ] Existing MVP_011 options continue to work.
- [ ] Advanced scheduling settings are optional and do not break FSRS.
- [ ] Desired retention and maximum interval, if implemented, are tested.
- [ ] Sibling burying behaviour is implemented or explicitly deferred with a blocking follow-up.
- [ ] If sibling burying is implemented, sibling cards from the same imported note are hidden until tomorrow when burying is enabled.
- [ ] True daily limits are implemented or explicitly deferred with a blocking follow-up.
- [ ] If true daily limits are implemented, a second same-day session does not reset the allowance.
- [ ] Imported progress is not reset.
- [ ] Existing deck import, media, review, and progress flows still work.
- [ ] `flutter analyze` passes.
- [ ] Tests cover profile resolution and deck assignment.
- [ ] Tests cover true daily limits and/or the documented deferred blocker.
- [ ] Tests cover sibling burying and/or the documented deferred blocker.

## Approval report required

When complete, report:

1. Summary.
2. Files changed.
3. Profile model and repository design.
4. Effective option resolution order.
5. UI added.
6. Advanced settings included or deferred.
7. Sibling burying behaviour.
8. True daily limit behaviour.
9. Tests added.
10. Known limitations.
11. Recommendation for next MVP.

## Likely next MVP

After MVP_012, good candidates are:

- Modern `.anki21b` import support.
- Floating bottom navigation and broader UX polish.
- Review history and analytics.
