# AGENT 001 — Flutter Scaffold and Product Shell

## Mode

Start with `orient`, then use `architect`, then wait for confirmation before `execute`.

## Objective

Create the first Flutter scaffold for Decko and implement a beautiful, non-functional product shell that can support future deck import, review, themes, and gamification work.

## Required Reading

Before planning, read:

```txt
README.md
memory.md if it exists
.agent/AGENT_OPERATING_SYSTEM.md
.agent/skills/orient/SKILL.md
.agent/skills/architect/SKILL.md
docs/iteration-1.md
docs/architecture.md
docs/DECISIONS.md
docs/CODING_STANDARDS.md
docs/UI_REGISTRY.md
docs/ROADMAP.md
```

## Scope

Build only the scaffold and shell.

Expected areas:

```txt
pubspec.yaml
lib/main.dart
lib/app/
lib/features/deck_library/
lib/features/import/
lib/features/review/
lib/features/themes/
lib/features/gamification/
test/
```

## First Implementation Target

The first app should open and show:

- Decko branded home/deck library screen
- empty state for no imported decks
- import call-to-action button without full import implementation
- visible theme direction using initial theme tokens
- navigation placeholders for review, themes, and progress if useful

## Out of Scope

Do not implement yet:

- APKG parsing
- cloud sync
- login
- payments
- full FSRS algorithm
- full persistence
- AI generation

## Architecture Requirements

- Keep app shell separate from feature screens.
- Add routing in a dedicated app/router file if GoRouter is introduced.
- Centralise theme tokens.
- Do not hardcode business logic in widgets.
- Use placeholder repositories only if needed.

## Acceptance Criteria

- App launches locally with Flutter.
- Decko branding is visible.
- Empty deck library state is polished.
- Import CTA exists but clearly remains a placeholder.
- Theme foundation exists in code.
- No scope creep beyond scaffold/shell.
- Documentation is updated if implementation changes assumptions.

## Completion

After execution, run review mode and update `memory.md` with the exact next recommended step.
