---
name: recover
description: Diagnose broken Decko work before attempting fixes.
---

# Recover Skill

Use recover mode when the app fails to build, tests fail, imports break, state becomes inconsistent, or a previous implementation appears confused.

## Core Rule

Diagnose before patching.

Do not keep applying random fixes.

## Step 1 — State the Failure

Describe:

- what failed
- where it failed
- exact error if available
- recent changes that may have caused it

## Step 2 — Classify the Failure

Use one of:

- environment/setup
- dependency/version
- Flutter build
- routing/state management
- persistence
- import parsing
- scheduling logic
- UI/runtime
- test expectation
- documentation mismatch

## Step 3 — Inspect Relevant Truth

Read relevant docs and affected files before changing code.

## Step 4 — Propose Recovery Plan

```markdown
## Recovery Plan — [Failure]

### Diagnosis
[best current explanation]

### Evidence
- [error/file/output]

### Proposed fix
1. [step]
2. [step]

### Risk
[what could go wrong]
```

## Step 5 — Fix Small

Apply the smallest fix that addresses the diagnosis.

## Standard

Recovery should increase understanding, not just silence an error.
