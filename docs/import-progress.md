# Progress-Aware Deck Import

Decko must treat user progress as part of the value of an imported deck.

For serious spaced-repetition users, the cards are not the only asset. The memory state is also part of the deck: which cards are new, which are learning, which are mature, which are due, which are suspended, and how much review history already exists.

## Product rule

Decko must never silently reset imported progress.

When a deck includes scheduling or review state, Decko should clearly offer the user a choice:

- keep existing progress
- start fresh

When a deck does not include scheduling or review state, Decko should clearly explain that only the card content can be imported.

## Import modes

### Clean import

Use this when the user wants a fresh copy of a deck or when the source file contains no scheduling information.

Result:

- all supported notes/cards are imported
- review cards start as new
- no previous due dates, intervals, or history are preserved

### Progress import

Use this when the source deck includes scheduling information and the user chooses to preserve it.

Result:

- reviewed cards remain reviewed
- due cards remain due
- future cards remain scheduled in the future
- new cards remain new
- suspended cards remain suspended where supported
- reps, lapses, interval, ease, and last-reviewed data are preserved where available

## Import summary UX

Before confirming a progress-aware import, Decko should show a summary similar to:

```txt
This deck includes existing progress.

Cards found: 1,000
Cards with progress: 500
New cards: 500
Due today: 34
Suspended: 12
Review history available: Yes

How would you like to import?

[ Keep my progress ]
[ Start fresh ]
```

If progress is missing:

```txt
This deck does not include scheduling information.
Decko can import the cards, but they will start as new.
```

## Data to preserve where available

For each imported card, preserve as much of the following as the source format exposes:

- source card id
- source note id
- source deck id/name
- source card state: new, learning, review, relearning
- due date or due position
- interval
- ease factor
- review count/reps
- lapse count
- last reviewed date
- review history rows
- suspended/buried state
- flags/tags where useful

## Internal mapping principle

Decko should not store imported progress as a permanent Anki-shaped object.

External progress should be translated into Decko's neutral domain model:

```txt
Imported card progress
  -> ReviewState
  -> ReviewEvent history where available
  -> Scheduler-ready fields
```

This keeps the app independent from any one external deck format.

## FSRS migration principle

Decko should support three migration cases:

1. no progress available -> start new
2. legacy scheduler progress available -> preserve practical due state and initialise scheduler fields as best as possible
3. FSRS-like history available -> use history/state to initialise FSRS-compatible fields where possible

The first progress-aware implementation does not need perfect FSRS reconstruction. It must preserve the user's practical progress first:

- what is due now
- what is not due yet
- what has been studied
- what is new
- what is suspended

## Acceptance criteria for progress-aware import

```txt
[ ] Detect whether imported deck includes scheduling/progress information.
[ ] Show an import summary before confirmation.
[ ] Offer Keep progress and Start fresh when progress exists.
[ ] Warn clearly when progress cannot be imported.
[ ] Preserve reviewed/new/learning/relearning state where available.
[ ] Preserve due dates or due positions where available.
[ ] Preserve reps, lapses, intervals, and ease where available.
[ ] Preserve suspended state where available.
[ ] Never reset user progress silently.
[ ] Record the import source and whether progress was preserved.
```
