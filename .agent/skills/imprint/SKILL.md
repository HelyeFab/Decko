---
name: imprint
description: Preserve Decko UI consistency by recording reusable visual patterns after UI work changes the design language.
---

# Imprint Skill

Use imprint mode after UI work introduces or changes a reusable Decko visual pattern.

## Core Rule

If UI changes create a reusable pattern, record it in `docs/UI_REGISTRY.md`.

## What to Imprint

Record patterns for:

- app shell
- deck cards
- flashcard surfaces
- review buttons
- XP and streak feedback
- theme selector
- import flow states
- empty states
- error states
- typography and spacing
- card reveal animations

## What Not to Imprint

Do not record one-off implementation details.

Do not duplicate Flutter code unless it clarifies a reusable pattern.

## Imprint Format

```markdown
## Pattern: [Name]

### Used in
- [screen/component]

### Purpose
[What learner experience this pattern supports]

### Visual rules
- [colour/token]
- [spacing]
- [shape]
- [typography]

### Interaction rules
- [tap/reveal/animation/feedback]

### Accessibility notes
- [contrast, labels, tap targets]
```

## Standard

Decko should feel like one coherent app, not a set of unrelated screens.
