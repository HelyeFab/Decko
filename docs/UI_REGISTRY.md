# Decko UI Registry

Status: Draft

This file records reusable UI patterns so Decko remains visually coherent as features are added.

## Design Direction

Decko should feel:

- modern
- warm
- mobile-first
- playful but not childish
- more beautiful than a utility flashcard database
- focused during review sessions

## Theme Layers

Decko has two visual layers:

```txt
AppThemeConfig  -> app shell, navigation, surfaces, buttons
CardThemeConfig -> flashcard presentation, reveal style, content layout
```

## Initial App Themes

### Light

Clean default theme.

### Focus Dark

Low-light review experience.

### Soft Study

Warm, friendly, modern study aesthetic.

## Initial Card Themes

### Minimal

Large prompt, minimal chrome, high focus.

### Detailed

Prompt plus metadata, tags, hint, notes, and example areas.

### Game Card

More playful card treatment for challenge rounds and XP feedback.

## Core Patterns To Define During Implementation

The first UI agent should define and then imprint:

- deck library card
- import empty state
- review card surface
- answer reveal state
- rating button row
- XP session summary
- theme selector preview

## Accessibility Baseline

All Decko UI work should consider:

- readable contrast
- large enough tap targets
- text scaling
- screen reader labels for icon-only buttons
- motion that does not block comprehension

## Imprint Rule

When a reusable visual pattern is created, update this file using the imprint skill.
