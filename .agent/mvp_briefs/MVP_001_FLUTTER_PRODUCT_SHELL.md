# Decko MVP Agent Brief — MVP_001: Flutter Product Shell

## Mission

Create the first working Flutter scaffold for **Decko**, a modern flashcard app focused on imported decks, beautiful themes, card UI, FSRS-ready review architecture, and gamification.

This MVP is **not** about building the full flashcard engine yet.

The goal is to create a polished app foundation that proves the Decko direction:

> Import your deck. Study it beautifully.

---

## Before coding

Read these files first:

```txt
.agent/README.md
.agent/AGENT_OPERATING_SYSTEM.md
.agent/skills/orient/SKILL.md
.agent/skills/architect/SKILL.md
.agent/skills/execute/SKILL.md
.agent/skills/review/SKILL.md
docs/DECISIONS.md
docs/CODING_STANDARDS.md
docs/UI_REGISTRY.md
docs/ROADMAP.md
memory.md
```

Then return a short implementation plan before making changes.

---

# MVP_001 Scope

Build a **beautiful Flutter product shell** for Decko.

The app should include:

## 1. App scaffold

Create a clean Flutter project structure.

Recommended structure:

```txt
lib/
  main.dart
  app/
    decko_app.dart
    decko_theme.dart
    decko_router.dart
  core/
    constants/
    widgets/
  features/
    deck_library/
      deck_library_screen.dart
      widgets/
    import/
      import_placeholder_screen.dart
    review/
      review_placeholder_screen.dart
    themes/
      theme_gallery_screen.dart
    progress/
      progress_placeholder_screen.dart
```

Use simple, maintainable Flutter. Do not over-engineer.

---

## 2. Decko home / deck library screen

Create a polished main screen that communicates the product clearly.

It should include:

- Decko logo text or wordmark
- Tagline: `Import your deck. Study it beautifully.`
- Empty-state card for users with no decks yet
- Primary CTA: `Import a deck`
- Secondary CTA: `Explore demo deck`
- Small preview of the app promise:
  - FSRS-ready reviews
  - Beautiful card themes
  - XP and streaks
  - Multiple study modes

The screen should feel modern, warm, and app-like — not like a database.

---

## 3. Import placeholder flow

Create an import placeholder screen.

It should explain that Decko will support imported decks.

For MVP_001, it does **not** need to parse real files.

The screen should include placeholder options:

```txt
Import .apkg deck
Import CSV
Import JSON
```

Each option can show a disabled or “Coming soon” state.

Important: do not implement real APKG import yet.

---

## 4. Review placeholder screen

Create a beautiful review preview screen.

It should show a sample flashcard with front/back styling.

Example content:

```txt
Front: 食べる
Reading: たべる
Back: to eat
Example: 毎日ご飯を食べます。
```

Include placeholder review buttons:

```txt
Again
Hard
Good
Easy
```

This prepares the UI for FSRS-style grading, but does not need to implement FSRS yet.

---

## 5. Theme foundation

Create an app theme system with at least three named themes:

```txt
Decko Light
Decko Dark
Soft Study
```

The actual app can default to `Soft Study`.

Create a simple theme gallery screen where users can preview these themes.

Do not add permanent persistence yet unless very easy.

---

## 6. Card theme foundation

Create at least three card theme preview components:

```txt
Minimal Card
Detailed Card
Game Card
```

They should show the same sample flashcard content in different visual styles.

This is important: Decko must separate **app themes** from **card themes**.

---

## 7. Gamification preview

Create a progress placeholder screen showing:

```txt
XP: 120
Current streak: 3 days
Cards reviewed today: 18
Level: 2
```

Also show 2–3 achievement badge placeholders:

```txt
First Review
Perfect Round
Three Day Streak
```

No real logic needed yet. This is a product shell only.

---

# Explicit non-goals

Do **not** implement these yet:

```txt
Real APKG parsing
AnkiWeb sync
AnkiConnect
AnkiDroid integration
Real FSRS algorithm
Cloud sync
Authentication
Payments
AI card generation
Full database persistence
Complex state management
```

Use mock/demo data where needed.

---

# Technical preferences

Use Flutter best practices.

For MVP_001:

- Keep the app simple.
- Prefer clear widgets over clever abstractions.
- Avoid large dependencies unless necessary.
- Make UI responsive enough for mobile.
- Keep styling centralised.
- Use British English in user-facing copy where relevant.
- Use accessible contrast and readable text sizes.
- Avoid tiny tap targets.

If adding dependencies, explain why.

---

# Visual direction

Decko should feel:

```txt
modern
warm
beautiful
mobile-first
friendly
motivating
less cold than Anki
more personal than a database
```

Avoid:

```txt
clinical UI
generic Material demo look
overly childish gamification
cluttered screens
too many colours
```

A good first visual direction:

```txt
soft background
rounded cards
clear typography
subtle gradients if appropriate
large friendly buttons
clean spacing
simple badges
```

---

# What to return for approval

Before finalising, return this approval report:

## 1. Summary

Briefly explain what was built.

## 2. Files changed

List every created or changed file.

Use this format:

```txt
Created:
- lib/main.dart
- lib/app/decko_app.dart
- ...

Changed:
- README.md
```

## 3. Screens included

List the screens now available:

```txt
- Deck Library / Home
- Import Placeholder
- Review Preview
- Theme Gallery
- Progress Preview
```

## 4. Design decisions

Explain any design choices made, especially:

```txt
theme structure
navigation structure
mock data structure
widget organisation
```

## 5. Dependencies added

List any dependencies added to `pubspec.yaml`.

If no dependencies were added, say:

```txt
No external dependencies added.
```

## 6. How to run

Provide exact commands:

```bash
flutter pub get
flutter run
```

Also include any platform notes.

## 7. Known limitations

Clearly state what is still fake/placeholder.

For example:

```txt
- Import buttons are placeholders.
- Review buttons do not yet update scheduling.
- Theme selection is preview-only.
- Progress values are mock data.
```

## 8. Manual test checklist

Return a checklist we can use:

```txt
[ ] App launches successfully
[ ] Home screen displays Decko branding
[ ] Import CTA opens import placeholder screen
[ ] Demo deck CTA opens review preview or sample deck flow
[ ] Review screen shows sample card
[ ] Again / Hard / Good / Easy buttons are visible
[ ] Theme gallery shows app and card theme previews
[ ] Progress screen shows XP, streak, and badges
[ ] UI looks acceptable on a phone-sized screen
```

## 9. Recommendation for next MVP

Suggest the next smallest implementation step.

Expected next step is probably one of:

```txt
MVP_002: Local demo deck model and navigation
MVP_003: JSON deck import
MVP_004: Simple review session state
MVP_005: FSRS-ready scheduler interface
```

Do not start the next MVP without approval.

---

# Acceptance criteria

MVP_001 is complete when:

```txt
[ ] The Flutter app runs.
[ ] Decko branding is visible.
[ ] There is a polished home/deck library screen.
[ ] There is an import placeholder screen.
[ ] There is a review preview screen with grading buttons.
[ ] There is a theme gallery with app/card theme previews.
[ ] There is a progress/gamification preview screen.
[ ] The app does not claim to support real Anki import yet.
[ ] The architecture leaves room for deck import, FSRS, themes, and gamification.
[ ] The agent returns the approval report above.
```
