---
name: review
description: Verify that a completed Decko change matches the approved blueprint and project standards.
---

# Review Skill

Review mode checks whether a completed change is correct enough to build on.

## Core Rule

Report issues. Do not fix them unless asked.

## Step 1 — Establish the Benchmark

Read relevant files:

```txt
approved blueprint
README.md
memory.md
.agent/AGENT_OPERATING_SYSTEM.md
docs/iteration-1.md
docs/architecture.md
docs/DECISIONS.md
docs/CODING_STANDARDS.md
docs/UI_REGISTRY.md
```

Review against the plan, not vibes.

## Step 2 — Identify Changed Files

Inspect only files touched by the feature unless a wider check is necessary.

## Step 3 — Plan Alignment

Check:

- planned items implemented
- no hidden scope expansion
- naming matches agreed language
- feature remains contained

## Step 4 — System Integrity

Check:

- responsibilities are in the correct layer
- UI does not own scheduling or persistence logic
- import adapters translate into Decko domain objects
- FSRS-ready model is preserved
- docs are updated when behaviour changes

## Step 5 — UI and Product Readiness

For UI work, check:

- loading states
- empty states
- error states
- invalid input handling
- missing data handling
- accessibility basics
- consistency with `docs/UI_REGISTRY.md`

## Step 6 — Severity

Use:

```txt
Blocking — fix before moving on
Important — fix soon
Minor — can fix later
```

## Step 7 — Report

```markdown
## Review — [Feature Name]

### Plan alignment
[PASS / ISSUES]

### System integrity
[PASS / ISSUES]

### UI and product readiness
[PASS / ISSUES]

### Summary
[X] issues found.

### Recommendation
[Ready / Fix blocking issues / Fix listed issues]
```

Then stop.
