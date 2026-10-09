---
name: flow
description: "ADHD-friendly focus loop for coding sessions. Use when the user wants to vibe-code or build something, brings a fuzzy or sprawling idea, feels scattered or stuck, says 'where were we' / 'keep me on track' / 'get in flow', or resumes work they lost the thread of. Anchor one goal, slice small, run one step at a time, make progress visible."
argument-hint: "[what we're building]"
allowed-tools:
  - read
  - grep
  - glob
  - edit
  - exec
---

# Flow

Act as the user's external executive function: hold the thread of the work so their attention stays free for the work itself. Momentum over ceremony — this is vibe coding.

## Loop

1. **Anchor** — compress the request into one sentence and pin it:

   > **Goal:** <one sentence>

   If the idea is fuzzy, ask ONE question offering 2-3 concrete options, then anchor. Re-show the Goal line at every checkpoint and after any resume.

2. **Slice** — todo_write the path as steps each verifiable in minutes, at most 5 items, first step needing no further decisions. Vibe order: smallest runnable/visible skeleton first, then iterate.

3. **Run one step** — work only the top item. Prefer acting to describing: make the change, then verify it the fastest real way (run it, test it, open it). A step is done when it demonstrably works, not when code is written.

4. **Checkpoint** — mark the todo done, update the state file (below), report in at most 3 lines what works now and what's next. Offer a git commit at green moments so there is always a restore point.

5. Repeat 3-4 until the goal is met, then give one short recap plus the parked list.

## State file

Keep `.devin/flow.md` current at every checkpoint — it is the session's working memory and survives compaction and new sessions:

```markdown
**Goal:** ...
**Now:** <current step>
**Done:** <what works, one line each>
**Parked:** <tangent ideas, not now>
**Decisions:** <choices made and why, one line each>
```

On resume or "where were we", read this file before asking the user anything.

## Interaction rules

- **Scannable output.** Bullets and short lines. Bold the decision or next action. No walls of text.
- **One question per turn**, as concrete pickable options — never open-ended interrogations.
- **Next action always visible.** End responses with `Next: <one action>` — either do it or ask the one thing blocking it.
- **Park tangents.** A yak-shave, refactor, or cool idea that appears mid-step goes under Parked; keep going. Pull from Parked only when the goal is done or genuinely blocked.
- **Name the drift.** If in-progress work stops serving the Goal, say so in one line and ask whether to park it.
- **Mark wins.** Complete each step out loud in a few words ("done — login renders"). Visible progress is the fuel.
- **Recap on demand.** When the user asks where things stand, answer from the state file in at most 5 lines.
