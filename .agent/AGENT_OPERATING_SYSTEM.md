# Decko Agent Operating System

Version: 0.1
Status: Draft

## Purpose

This document defines how coding agents should work on Decko.

Decko should be built through a repeatable workflow that preserves context, prevents scope drift, protects architectural decisions, and keeps the product coherent over time.

## Core Principle

Chat is the workshop.

GitHub is the source of truth.

Important project knowledge must be saved in the repository, not left only in conversation history.

## Source of Truth

Authoritative locations:

```txt
README.md
memory.md
docs/
.agent/
```

Durable Decko knowledge belongs in `docs/`.

Current handoff state belongs in root `memory.md`.

Reusable agent behaviour belongs in `.agent/`.

## Working Loop

```txt
orient / remember restore
  -> architect
  -> decide when durable choices are made
  -> execute
  -> imprint if UI changed
  -> review
  -> remember save
```

If something breaks, use `recover`.

## Agent Modes

- Orient: understand the repository before acting.
- Remember: restore or save session continuity through `memory.md`.
- Architect: decide what should be built before implementation begins.
- Decide: record important choices in `docs/DECISIONS.md`.
- Execute: build from an approved blueprint.
- Imprint: preserve UI consistency in `docs/UI_REGISTRY.md`.
- Review: check whether a change is correct before moving on.
- Recover: diagnose failures before attempting fixes.

## Decko Product Boundaries

Important current docs:

```txt
docs/iteration-1.md
docs/architecture.md
docs/agent-brief.md
docs/DECISIONS.md
docs/CODING_STANDARDS.md
docs/UI_REGISTRY.md
```

Read relevant product docs before building features.

## Quality Gate

A feature is not done when it compiles.

A feature is done when it is correct enough to build on.

Before moving on, verify:

- it matches the approved plan
- it respects the domain model
- it does not expand scope silently
- it has basic error handling
- it has empty and loading states if UI is involved
- it respects Flutter accessibility basics
- it updates docs where needed

## Session Start Protocol

1. Read `memory.md` if it exists.
2. Read relevant docs.
3. Summarise current state.
4. Ask for confirmation before proceeding.

## Session End Protocol

1. Save durable knowledge to docs if needed.
2. Save current handoff state to `memory.md`.
3. Summarise changed files.
4. State the exact next action.

## Rule

Do not rely on chat alone. Rely on workflow, documentation, and small verified steps.
