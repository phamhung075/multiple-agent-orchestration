# 02. Five-Minute Quickstart

Get a complete 2-agent engineering team (a Developer and a Reviewer) running in your repository in under 5 minutes.

## Step 1: Create a Team Definition

Create a directory (for example `~/teams/dev-team/`) holding a file named `team.json`. The room needs a slug and each seat needs a `seat_key` and a `runtime`:

```json
{
  "room": { "slug": "dev-team" },
  "seats": [
    { "seat_key": "dev",      "seat_type": "developer", "runtime": "claude-code", "model": "sonnet" },
    { "seat_key": "reviewer", "seat_type": "reviewer",  "runtime": "claude-code", "model": "sonnet" }
  ]
}
```

The `room.slug` is the room name used by every command below. Larger teams add `modules`, `links` and `seat_overlays` (see `scripts/team/4genthub-min/team.json` in the 4genthub repository for a five-seat example).

## Step 2: Launch the Team

```bash
4genteam up dev-team --team ~/teams/dev-team
```

`up` reads the definition from the local directory; it needs no cloud round trip. Check seat status:
```bash
4genteam ps dev-team --nodes
```
You will see both `dev` and `reviewer` running, ready to accept tasks.

## Step 3: Dispatch Your First Mission

Send a mission to the developer seat:

```bash
4genteam send --from owner dev-team dev 'Create a utility function in utils/math.js that calculates factorials with tests. Record a queue item when done.'
```

## Step 4: Watch the Work Live

To watch your team work in real time with live streaming tool calls and token meters:

```bash
4genteam feed --rig dev-team --detail
```

Or open the interactive multi-seat terminal grid:
```bash
4genteam watch --rig dev-team
```

## Step 5: Check the Work Queue

Inspect tasks and handoffs recorded by the seats:

```bash
4genteam room queue list dev-team
```

---

Next: [03 — Daily Operations Cheat Sheet](03-daily-operations.md)
