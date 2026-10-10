# 1. Introduction

## The problem

One AI coding agent in one terminal is useful. A large job (port 600 modules, refactor a monorepo,
review every endpoint) overwhelms it: its context fills up, it stops at the end of each turn, you
babysit it, and every token is billed at top-model prices.

## The idea

Treat agents like a small engineering team:

1. **A team (rig)** with named roles: an *owner* who builds, a *checker* who reviews independently.
2. **A durable queue** instead of chat. Work and verdicts are recorded as queue items, so they survive
   restarts, compaction and crashes.
3. **A culture file** that states the mission once. Agents re-read it after every restart.
4. **Cheap workers** (DeepSeek) do the bulk typing in parallel. The expensive model plans, reviews and
   fixes.
5. **Wake-ups** (watchdogs) so a team that stopped at the end of a turn is reminded to continue.

The picture at the top of the [README](../README.md) shows the same stack: LLMs at the left, the
agent layers in the middle (decision, planning, task execution), skill offload to DeepSeek at the
bottom left, and OpenRig + herdr as the tooling at the bottom right.

Chapter 2 shows the finished system on one page and the order to build it in.

## The components

| Layer | Component | Job |
|---|---|---|
| Orchestrator | **OpenRig** (`rig`, daemon on `127.0.0.1:7433`) | Starts teams from YAML, tracks seats, routes messages, keeps the queue and watchdogs |
| Terminals | **tmux** and **herdr** | Each seat is a real terminal session you can attach to |
| Runtimes | **Claude Code**, **agy** (Antigravity), Codex | The actual coding agents inside the seats |
| Workers | **DeepSeek Harness (`dsh`)** + **deepseek-offload** | Background jobs that draft code cheaply |
| Your project | A git repo | Where the team works |

## Vocabulary

| Term | Meaning |
|---|---|
| **Rig** | A team defined in a `rig.yaml` file. Example: `4genthub-go`. |
| **Pod** | A group of seats with one context domain (for example `dev`). |
| **Seat** | One agent position. Its address is `<member>@<rig>`, for example `dev-owner@4genthub-go`. |
| **Occupant** | The agent session currently sitting in the seat. It can be replaced without renaming the seat. |
| **Kernel** | OpenRig's own always-on rig (advisor, operator, queue worker, a shared terminal). Created by the daemon automatically. |
| **Queue item (qitem)** | A durable unit of work or verdict. `rig queue create/handoff/list`. |
| **Culture** | A markdown file read by every seat at launch. The team's standing instructions. |
| **Policy** | Permission posture of a rig or seat (`yolo`, `standard`, `open`, `locked`). |
| **Watchdog** | A scheduled job that sends a reminder to a seat every N seconds. |
| **Snapshot** | A saved copy of a rig's state used to restore it (`rig up <rig> --existing`). |
| **Offload / worker** | A DeepSeek background job started with `dsh-offload.mjs start`. |
| **Wave** | A batch of workers launched together (for example `w5-20` … `w5-34`). |
| **Ledger** | A file listing every task and its status (`MIGRATION.md`). The single source of truth for progress. |
| **Compaction** | Claude Code's `/compact`: summarize the context to free tokens. |

## Rules of thumb that make it work

1. **Files and queue, not chat.** If it matters after a restart, it is in a file or a queue item.
2. **One team per code area.** Two teams editing the same files overwrite each other.
3. **The expensive model reviews, the cheap model drafts.** A worker's "tests pass" is never trusted.
4. **The culture file is the source of truth, but a running seat reads it only at launch.** After
   editing it, send the seats a message (chapter 10).
5. **Never merge before the whole job is done and tested.**

## What it is not

- It is not magic. Agents stop, loop, or disagree. The system's value is that it recovers
  (queue, ledger, wake-ups, snapshots) and that you can see everything.
- It is not safe by default when you disable permission prompts. Read chapter 9 first.

## Check

You should be able to explain, in one sentence each: what a rig is, why work goes on a queue, and why
the culture file exists. Continue to [chapter 3](03-prerequisites.md).

Next: [chapter 2 — the blueprint](02-blueprint.md).
