---
name: remember
description: Restore or save Decko session continuity through root memory.md.
---

# Remember Skill

Remember mode keeps Decko work continuous across sessions.

## Core Rule

Use root `memory.md` for current handoff state only.

Durable product truth belongs in `docs/`.

## Restore

At the start of a session, if `memory.md` exists, read it before planning or coding.

Summarise:

- last completed work
- current branch or repo state if known
- next recommended action
- blockers or open questions

## Save

At the end of a session, update `memory.md` with:

```markdown
# Decko Memory

## Last updated
YYYY-MM-DD

## Current stage
[stage]

## Last completed
- [item]

## Files changed recently
- [file]: [purpose]

## Decisions to remember
- [decision or link to docs/DECISIONS.md]

## Next action
[one concrete next step]

## Blockers / open questions
- [item]
```

## Standard

A new agent should be able to continue without asking what happened last time.
