# MVP_010 — Advanced Deck Option Profiles

## Status

Planned.

## Mission

Expand Decko’s simple MVP_009 study-options system into a more Anki-like option profile system, while keeping the default user experience calm and understandable.

MVP_009 gives Decko global defaults plus deck-specific overrides. MVP_010 should introduce reusable option profiles for advanced users and imported Anki-style workflows.

The key product promise is:

> I can create a study profile once, reuse it across multiple decks, and optionally tune advanced scheduling/media behaviour without breaking Decko’s simpler defaults.

## Context

This MVP assumes MVP_009 has shipped:

- `GlobalStudyOptions` or equivalent.
- Deck-specific overrides.
- Effective option resolution.
- Review queue limits.
- Media behaviour options.
- Furigana preferences.
- Persistent options storage.

MVP_010 should build on that system rather than replacing it.

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

MVP_010 may introduce advanced scheduling controls, but they must be hidden behind an “Advanced” section.

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

### 6. Improve sibling burying semantics

If the imported Anki data can identify siblings or note relationships, improve burying behaviour.

Expected behaviour:

- If a card from a note is reviewed today, sibling cards from the same note may be buried until tomorrow when burying is enabled.
- Burying should be controlled by effective options.
- Burying must not delete or permanently hide cards.
- Due counts should reflect buried cards clearly if possible.

If sibling identity is not reliable yet, record that limitation and keep the UI honest.

### 7. Add import-aware profile suggestions

When importing a deck, Decko may suggest an option profile based on media/card characteristics.

Examples:

- Deck contains many `[sound:]` references → suggest “Audio-first”.
- Deck contains many images → suggest “Image-first”.
- Very large imported deck → suggest a conservative daily limit.

This should be a suggestion only, not automatic behaviour that surprises the user.

### 8. Keep simple mode simple

Decko should still feel approachable.

The default user path should remain:

```text
Import deck → Study → Progress
```

Advanced profiles should be available for users who want them, not forced on everyone.

## Non-goals

Do not implement in MVP_010:

- Full Anki option-group parity.
- Raw FSRS weight editor.
- Cloud sync of profiles.
- Account-level profile sharing.
- Marketplace/community profile presets.
- Modern `.anki21b` import.
- Media extraction, if MVP_008 did not already handle it.
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
- [ ] Existing MVP_009 options continue to work.
- [ ] Advanced scheduling settings are optional and do not break FSRS.
- [ ] Desired retention and maximum interval, if implemented, are tested.
- [ ] Sibling burying behaviour is tested if implemented.
- [ ] Imported progress is not reset.
- [ ] Existing deck import, media, review, and progress flows still work.
- [ ] `flutter analyze` passes.
- [ ] Tests cover profile resolution and deck assignment.

## Approval report required

When complete, report:

1. Summary.
2. Files changed.
3. Profile model and repository design.
4. Effective option resolution order.
5. UI added.
6. Advanced settings included or deferred.
7. Sibling burying behaviour.
8. Tests added.
9. Known limitations.
10. Recommendation for next MVP.

## Likely next MVP

After MVP_010, good candidates are:

- Modern `.anki21b` import support.
- Smarter note-type-aware field mapping.
- Floating bottom navigation and broader UX polish.
- Review history and analytics.
