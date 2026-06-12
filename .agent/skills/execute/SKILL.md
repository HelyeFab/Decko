---
name: execute
description: Build only from an approved blueprint. Stay in scope, work in small steps, preserve architecture, and stop when assumptions become invalid.
---

# Execute Skill

Execute mode turns an approved blueprint into implementation.

Use it only after architect mode has produced a blueprint and the user has explicitly confirmed it.

## Core Rule

Build the agreed blueprint.

Do not silently redesign the feature.

Do not expand scope because something seems convenient.

If the blueprint becomes invalid, stop and ask.

## Step 1 — Confirm the Approved Blueprint

If no blueprint exists, stop and run architect mode first.

## Step 2 — Read Relevant Project Truth

Read only files needed for the task.

Common sources:

```txt
README.md
memory.md
.agent/AGENT_OPERATING_SYSTEM.md
docs/iteration-1.md
docs/architecture.md
docs/DECISIONS.md
docs/CODING_STANDARDS.md
docs/UI_REGISTRY.md
```

Also read files directly affected by the blueprint.

## Step 3 — Create an Execution Checklist

Before editing, produce a short checklist matching the blueprint.

## Step 4 — Implement in Small Steps

For each step:

- change only required files
- preserve existing patterns
- keep naming consistent
- avoid broad rewrites
- avoid speculative future infrastructure
- run relevant checks where possible

## Step 5 — Respect Decko Architecture Boundaries

- Review screens must not calculate scheduling directly.
- UI widgets must not own persistence logic.
- Import adapters must translate external files into Decko domain objects.
- Anki/APKG-specific structures must not leak across the app.
- Gamification should derive from review events.
- Theme tokens should be centralised, not scattered through widgets.

## Step 6 — Stop on Invalid Assumptions

Stop if:

- required files do not exist
- current architecture differs from blueprint
- dependency is missing
- data model does not support the feature
- task requires out-of-scope infrastructure

## Step 7 — Finish With a Change Summary

```markdown
## Execution Complete — [Feature Name]

### Files changed
- [file]: [what changed]

### What was implemented
- [item]

### What was not implemented
- [out-of-scope item]

### Checks performed
- [check]

### Next recommended step
[Usually imprint/review/remember]
```

## Standard

Execute mode should feel controlled.
