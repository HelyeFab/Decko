# Decko Store-Readiness MVP Roadmap

This roadmap records the agreed path from the current Decko product state toward a store-ready release.

It deliberately keeps **MVP_024** as the onboarding/import-guidance work already in progress, and shifts the previously discussed matching game to **MVP_025**.

## Current locked sequence

```text
MVP_024 — First-Run Onboarding, Import Guidance & Empty States
MVP_025 — Match Mode / Vocabulary Pairing Game
```

## Product principle

Decko is no longer just proving that the core architecture works. The remaining work is about making Decko safe, understandable, polished, and trustworthy for people who were not part of the build process.

A store-ready Decko should let a new user:

```text
Install Decko
Understand what Decko does
Import or try a deck
Study beautifully
Practise with optional game modes
See progress
Sign in
Sync activity and review state safely
Continue on another device when the same deck is present
Recover from errors without fearing data loss
```

## Phase 1 — Complete the core product experience

### MVP_024 — First-Run Onboarding, Import Guidance & Empty States

Status: in progress.

Goal:

```text
A new user opens Decko and understands what to do.
```

Scope:

```text
- first-run onboarding
- beautiful empty states
- import guidance
- honest sync explanation
- signed-out / no-deck sync states
- first successful import celebration
- optional sample/demo deck if included
- local onboarding-complete flag
```

Boundary:

```text
This is a shippability/product-understanding MVP.
It must not change FSRS, the due queue, review-state sync semantics, import preservation, or deck/media sync boundaries.
```

### MVP_025 — Match Mode / Vocabulary Pairing Game

Goal:

```text
Add a fast, playful matching game using the PracticeModeRegistry.
```

Initial round types:

```text
- Japanese expression -> English meaning
- English meaning -> Japanese expression
- expression -> reading
- reading -> expression
```

Rules:

```text
- manual practice only
- earns practice XP/activity events
- does not mutate FSRS/review state
- no scheduler changes
- no due queue changes
```

Suggested decision record:

```text
DEC-034 — Match Mode Is Manual Practice, Not Review Scheduling
```

### MVP_026 — Import Recovery, Duplicate Import & Re-import Polish

Goal:

```text
Make import feel safe even when things go wrong.
```

Scope:

```text
- duplicate deck detection
- re-import same deck UX
- replace / keep both / cancel choices
- failed import recovery
- partial media failure messaging
- low-storage handling
- import cancellation safety
- import history/report access
```

Key principle:

```text
Never lose or overwrite review progress during import/re-import.
```

### MVP_027 — Demo Deck / Starter Content

Goal:

```text
Allow users to experience Decko immediately without needing an Anki file.
```

Scope:

```text
- small built-in sample deck
- beautiful card examples
- audio/media examples if practical
- sample review
- sample practice modes
- clear label: Demo content
```

Rationale:

```text
Store users may install Decko before knowing how to export an .apkg file.
Decko should still be immediately understandable and delightful.
```

## Phase 2 — Make it safe and reliable enough for beta

### MVP_028 — Settings, Account Data Control & Support Info

Goal:

```text
Give users clear control over their app, account, sync, and local data.
```

Scope:

```text
- account page
- sign out
- delete local data
- explain what is local vs synced
- export debug/support info
- app version/build info
- privacy/support links
- sync settings
- daily goal
- card display settings
- deck option profiles access
```

### MVP_029 — Error Reporting, Crash Safety & Debug Export

Goal:

```text
When something fails, Decko should fail safely and explain itself.
```

Scope:

```text
- friendly error screens
- import failure debug export
- sync failure debug export
- copy diagnostic info
- optional Crashlytics/Sentry integration
- clear non-scary wording
- no raw stack traces shown to normal users
```

Key principle:

```text
Errors should never make the user wonder whether their learning progress is gone.
```

### MVP_030 — Large Deck Performance Pass

Goal:

```text
Make Decko reliable with real-world Anki decks.
```

Test targets:

```text
- 10k cards
- 20k cards
- 50k cards if realistic
- large media folders
- many review states
- many activity events
- app cold start after import
- review screen smoothness
- sync performance with large review-state sets
```

Possible work:

```text
- pagination
- lazy loading
- deck indexing
- media loading optimization
- import progress indicators
- storage size reporting
```

### MVP_031 — Offline / Reconnect Hardening

Goal:

```text
Decko should remain useful offline and sync safely later.
```

Scope:

```text
- offline study
- offline practice
- pending activity sync
- pending review-state sync
- reconnect handling
- sync retry queue
- conflict-safe messaging
- no duplicate XP/activity events
```

Beta readiness milestone:

```text
After MVP_031, Decko should be private-beta ready.
```

## Phase 3 — Store release preparation

### MVP_032 — Legal, Privacy & Data Deletion Flow

Goal:

```text
Make Decko legally and ethically ready for accounts and cloud sync.
```

Scope:

```text
- Privacy Policy
- Terms of Use
- account deletion explanation
- data deletion request path
- what data is stored locally
- what data is synced
- what is never uploaded
- contact/support email
```

### MVP_033 — App Identity, Icon, Splash & Store Assets

Goal:

```text
Make Decko feel like a real product before users even open it.
```

Scope:

```text
- final app icon
- splash screen
- app name/branding check
- screenshots
- store description
- short description
- feature graphic / promo image
- onboarding screenshots
- privacy labels
```

### MVP_034 — Beta Release Packaging

Goal:

```text
Prepare Decko for TestFlight / closed testing.
```

Scope:

```text
- versioning
- build numbers
- release notes
- Firebase environment separation
- production vs dev config
- TestFlight build
- Android internal testing if relevant
- tester instructions
```

### MVP_035 — Beta Feedback Loop

Goal:

```text
Turn real user feedback into controlled fixes.
```

Scope:

```text
- feedback form
- send diagnostic report flow
- known issues page
- beta tester onboarding
- crash review routine
- issue triage labels
- release checklist
```

### MVP_036 — Public Store Release Candidate

Goal:

```text
Decko is ready for public submission.
```

Acceptance criteria:

```text
- core flows tested
- import/review/sync stable
- onboarding clear
- privacy/legal complete
- store assets complete
- no known data-loss bugs
- no blocker crashes
- beta feedback addressed
```

Store readiness milestone:

```text
After MVP_036, Decko should be store-submission ready.
```

## Full recommended sequence

```text
MVP_024 — First-Run Onboarding, Import Guidance & Empty States
MVP_025 — Match Mode / Vocabulary Pairing Game
MVP_026 — Import Recovery, Duplicate Import & Re-import Polish
MVP_027 — Demo Deck / Starter Content
MVP_028 — Settings, Account Data Control & Support Info
MVP_029 — Error Reporting, Crash Safety & Debug Export
MVP_030 — Large Deck Performance Pass
MVP_031 — Offline / Reconnect Hardening
MVP_032 — Legal, Privacy & Data Deletion Flow
MVP_033 — App Identity, Icon, Splash & Store Assets
MVP_034 — Beta Release Packaging
MVP_035 — Beta Feedback Loop
MVP_036 — Public Store Release Candidate
```

## Summary

Decko has already proven the core spine:

```text
Import Anki deck
Preserve fields/media/progress
Study with FSRS
Use beautiful review UI
Use extra practice modes
Track activity/progress
Sign in
Sync activity
Sync review state for matching decks
Understand sync status
```

The remaining work is about turning that spine into a product that is safe, understandable, polished, supportable, and ready for real users.
