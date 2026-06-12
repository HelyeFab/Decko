---
name: decide
description: Record durable Decko decisions so future sessions do not reopen settled choices accidentally.
---

# Decide Skill

Use decide mode when a choice affects architecture, data model, imports, scheduling, theming, gamification, or UX language.

## Core Rule

Important decisions go in `docs/DECISIONS.md`.

Do not leave durable project truth only in chat.

## When to Record a Decision

Record a decision when it changes or confirms:

- Flutter architecture
- state management
- persistence
- import format strategy
- FSRS/scheduler approach
- theme system
- card rendering rules
- gamification rules
- naming of core domain concepts

## Decision Format

```markdown
## DEC-[number]: [Title]

Date: YYYY-MM-DD
Status: Accepted

### Context
[Why this decision is needed]

### Decision
[What we chose]

### Consequences
- [positive/negative consequence]

### Alternatives considered
- [alternative]: [why not chosen]
```

## Standard

A future agent should be able to understand why the choice exists without reading the original chat.
