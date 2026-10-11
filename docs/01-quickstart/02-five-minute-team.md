# 02. Five-Minute Quickstart

Get a complete 2-agent engineering team (a Developer and a Reviewer) running in your repository in under 5 minutes.

## Step 1: Create a Simple Rig Specification

In your project repository (e.g. `~/my-project`), create a file named `rig.yaml`:

```yaml
version: "openrig/v1"
rig: "dev-team"

nodes:
  - name: dev
    runtime: claude-code
    model: claude-3-7-sonnet
    cwd: "."
    policy: standard

  - name: reviewer
    runtime: claude-code
    model: claude-3-7-sonnet
    cwd: "."
    policy: standard
```

## Step 2: Launch the Team

Use `rig` to start the team:

```bash
rig up ./rig.yaml
```

Check seat status:
```bash
rig ps --nodes --rig dev-team
```
You will see both `dev` and `reviewer` running and idle, ready to accept tasks.

## Step 3: Dispatch Your First Mission

Send a structured mission to the developer seat:

```bash
rig send dev-team-dev@dev-team "Create a utility function in utils/math.js that calculates factorials with tests. Record a queue item when done."
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
rig queue list
```

---

Next: [03 — Daily Operations Cheat Sheet](03-daily-operations.md)
