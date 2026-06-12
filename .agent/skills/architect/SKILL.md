---
name: architect
description: Think before building. Read project truth, align language, surface implementation-changing decisions, and produce a confirmed blueprint before code is written.
---

# Architect Skill

Architect mode stops the agent from rushing into implementation before the work is clear.

Use it before building meaningful Flutter features, data models, import flows, schedulers, UI systems, themes, or gamification logic.

## Core Rule

Do not write production code in architect mode.

Do not modify files unless the user explicitly asks for the blueprint to be saved.

## Step 1 — Read Project Truth First

Read relevant files in this order when available:

```txt
memory.md
README.md
.agent/AGENT_OPERATING_SYSTEM.md
docs/iteration-1.md
docs/architecture.md
docs/agent-brief.md
docs/DECISIONS.md
docs/CODING_STANDARDS.md
docs/UI_REGISTRY.md
```

## Step 2 — Restate the Task Briefly

```txt
I understand we are planning [feature/change].
The goal is [goal].
The likely affected areas are [areas].
```

## Step 3 — Align on Language

Identify 3 to 5 implementation-changing terms.

Decko examples:

- Deck
- LearningItem
- ReviewCard
- ReviewEvent
- App theme
- Card theme
- FSRS-ready
- Imported deck
- Practice mode

Do not continue with the blueprint until key language is aligned or already documented.

## Step 4 — Surface Only Implementation-Changing Decisions

Ask only decisions that materially change what gets built.

For each decision:

```txt
Decision: [decision]
My recommendation: [recommendation]
Why: [reason]
```

## Step 5 — Produce the Blueprint

```markdown
## Implementation Blueprint — [Feature Name]

### What we are building
[One clear paragraph]

### Language agreed
- [Term]: [definition]

### Decisions made
- [Decision]: [chosen approach and reason]

### Files likely affected
- [file or directory]

### Data model impact
[None / describe impact]

### UI impact
[None / describe impact]

### Scheduling impact
[None / describe impact]

### Gamification impact
[None / describe impact]

### Implementation steps
1. [step]
2. [step]

### Assumptions
- [assumption]

### Out of scope
- [what we are deliberately not doing]
```

## Step 6 — Wait for Confirmation

After presenting the blueprint, stop.

Do not begin execution until the user explicitly confirms.

## Standard

A good blueprint makes execution almost boring.
