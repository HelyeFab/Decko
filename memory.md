# Decko Memory

## Last updated
2026-06-12

## Current stage
Documentation and agent-system foundation.

## Last completed
- Created initial product foundation docs.
- Added `.agent` operating system inspired by PlanPal.
- Added core skills: orient, architect, execute, review, decide, imprint, remember, recover.
- Added templates for memory, decisions, and review reports.
- Added first implementation prompt: `AGENT_001_FLUTTER_SCAFFOLD.md`.
- Added decision log, coding standards, UI registry, and roadmap.

## Files changed recently
- `.agent/README.md`: explains the Decko agent workflow folder.
- `.agent/AGENT_OPERATING_SYSTEM.md`: defines the operating loop.
- `.agent/skills/*/SKILL.md`: reusable agent modes.
- `.agent/templates/*`: handoff and reporting templates.
- `.agent/prompts/AGENT_001_FLUTTER_SCAFFOLD.md`: first coding-agent task.
- `docs/DECISIONS.md`: durable architecture decisions.
- `docs/CODING_STANDARDS.md`: Flutter and architecture standards.
- `docs/UI_REGISTRY.md`: initial design direction.
- `docs/ROADMAP.md`: staged product roadmap.

## Decisions to remember
- Decko Iteration 1 is local-first.
- Imported deck formats are adapters, not the internal model.
- Scheduling must be FSRS-ready from the start.
- App themes and card themes are separate systems.

## Next action
Run Agent 001: Flutter Scaffold and Product Shell.

## Blockers / open questions
- Need to scaffold the Flutter project in the repo.
- Need to choose initial persistence library later; not required for Agent 001.
