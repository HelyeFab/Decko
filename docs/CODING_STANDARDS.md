# Decko Coding Standards

Status: Draft

## Stack Direction

Decko is a Flutter app.

Preferred first stack:

- Flutter stable
- Riverpod for state management
- GoRouter for navigation
- Local persistence later through Drift, Isar, or Hive
- Adapter-based import layer
- SchedulerService interface for review scheduling

## Architecture Rules

### 1. Keep domain logic out of UI

Widgets should render state and dispatch actions.

Widgets should not directly calculate:

- due dates
- FSRS scheduling values
- XP
- streaks
- achievements
- import parsing

### 2. Use feature folders for UI workflows

Suggested folders:

```txt
lib/
  app/
  core/
  domain/
  data/
  features/
```

Feature folders may contain screens, controllers, and feature-specific widgets.

### 3. Keep domain models framework-light

Domain models should avoid Flutter UI imports.

### 4. Use interfaces for replaceable systems

Use interfaces for:

- deck import
- scheduling
- persistence repositories
- theme registry
- achievement rules

### 5. Avoid premature backend work

Iteration 1 is local-first. Do not introduce accounts, cloud sync, or remote APIs unless explicitly approved.

## Naming Rules

Use documented product language:

- Deck
- LearningItem
- ReviewCard
- ReviewEvent
- ReviewRating
- ReviewMode
- AppThemeConfig
- CardThemeConfig

Avoid vague names such as `Thing`, `Data`, `Item2`, or `CardData` when a domain name exists.

## Flutter UI Rules

- Prefer small reusable widgets.
- Use theme tokens rather than hardcoded colours where possible.
- Add empty states for empty deck library and empty review queue.
- Add error states for failed imports.
- Keep tap targets comfortable for mobile use.
- Consider text scale and accessibility labels.

## Testing Direction

Initial tests should focus on pure logic:

- import adapter output
- scheduler behaviour
- XP/streak calculations
- review queue filtering
- theme registry defaults

UI tests can come after the first shell is stable.

## Documentation Rule

If implementation changes a durable rule, update the relevant doc.
