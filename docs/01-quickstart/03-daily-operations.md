# 03. Daily Operations Cheat Sheet

The essential commands to operate, monitor, and steer your agent team every day.

## 1. Starting, Restoring & Stopping Teams

| Goal | Command |
|---|---|
| **Start / Sync a team** | `4genteam up <rig-name> --team <dir>` (the directory holding `team.json`) |
| **Restore a stopped team** | `4genteam continue <rig-name>` |
| **Stop a team** | `4genteam room stop <rig-name>` (this room only) or `4genteam stop` (machine-wide: safeguards too) |
| **Room status, one line per seat** | `4genteam room status <rig-name>` |
| **List running nodes / seats** | `4genteam ps <rig-name> --nodes` |
| **Run diagnostics on fleet** | `4genteam doctor` |

## 2. Inspecting Live Work

| Goal | Command |
|---|---|
| **Merged live feed (all seats)** | `4genteam feed --rig <rig-name> --detail` |
| **Watch single seat feed** | `4genteam feed --rig <rig-name> --seat <seat-name> --detail` |
| **Full interactive grid** | `4genteam watch --rig <rig-name>` |
| **Capture recent pane output** | `4genteam capture agenthub--<rig>--<seat> --lines 30` (session names: `4genteam ps <rig> --nodes --json`) |

## 3. Communicating & Dispatching

| Goal | Command | Notes |
|---|---|---|
| **Send task to seat** | `4genteam send --from owner <rig> <seat> '<message>'` | Prefixes message with identity |
| **Send to a session name** | `4genteam send <rig>-<seat>@<rig> '<message>'` | The canonical name is translated to the runtime's session; use single quotes to avoid bash substitution |

> [!TIP]
> Always wrap messages in **single quotes** (`'...'`) so your local shell doesn't interpret backticks (`\``) or dollar signs (`$`) before sending.

## 4. Managing Work & The Queue

| Goal | Command |
|---|---|
| **List pending & active tasks** | `4genteam room queue list <rig-name> --active-only` |
| **View specific task detail** | `4genteam room queue show <rig-name> <qitem-id>` |
| **Check blocked items** | `4genteam room queue list <rig-name> --state blocked` |

## 5. Decisions & Closing Work

| Goal | Command |
|---|---|
| **Ask Jev before asking the lead or owner** | `4genteam decide --tier seat --summary '<subject>' --detail-file detail.txt --questions-file q.json` |
| **Close a task through the gate** | `4genteam complete --task <id> --base <sha> --summary '<what changed>' --test '<test command>'` |
| **Read what Jev decided** | `tail ~/.config/4genthub/jev_decisions.log` |

See [05 — Jev: Decisions and Task Gates](../03-production-performance/05-jev-decisions.md).

## 6. Maintenance & Token Compaction

| Goal | Command |
|---|---|
| **Run compaction supervisor** | `4genteam compact <rig-name>` |
| **Reseat / refresh skills** | `4genteam room reseat <rig-name> <seat-name>` |
| **Sync room specifications** | `4genteam sync rig <rig-name>` |

---

Next: [Architecture & Mental Model: 01 — How It Works](../02-architecture-and-mental-model/01-how-it-works.md)
