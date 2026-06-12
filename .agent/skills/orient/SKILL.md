---
name: orient
description: Cold-start a Decko session by reading the repository, understanding current state, and summarising it before action.
---

# Orient Skill

Orient mode is used when starting work in Decko, returning after time away, or handing the repository to a fresh coding agent.

## Core Rule

Read first. Summarise second. Act only after confirmation.

Do not modify files in orient mode.

## Step 1 — Identify Repository Context

Confirm the repository is `HelyeFab/Decko`.

## Step 2 — Read Core Project Truth

Read available files in this order:

```txt
README.md
memory.md
.agent/AGENT_OPERATING_SYSTEM.md
.agent/README.md
docs/iteration-1.md
docs/architecture.md
docs/agent-brief.md
docs/DECISIONS.md
docs/CODING_STANDARDS.md
docs/UI_REGISTRY.md
docs/ROADMAP.md
```

Do not fail because a file is missing. List missing important files in the final summary.

## Step 3 — Inspect Project Shape

Look for:

```txt
lib/
test/
android/
ios/
macos/
web/
pubspec.yaml
analysis_options.yaml
docs/
.agent/
```

## Step 4 — Identify Current Stage

Classify honestly:

- Documentation-only foundation
- Flutter scaffold exists but no feature implementation
- MVP shell exists
- Core domain model implemented
- UI prototype exists
- Production app in active development

## Step 5 — Summarise Orientation

Use:

```markdown
## Orientation Report

### Repository
[repo name]

### Current project stage
[stage]

### What exists
- [file/area]: [purpose]

### Source of truth
- [doc]: [what it governs]

### Current architecture direction
[short summary]

### Agent workflow in place
[which .agent skills exist]

### Missing or not yet created
- [missing file/area]

### Risks or ambiguities
- [risk]

### Recommended next step
[one concrete next action]
```

Then stop and ask whether the orientation is correct.
