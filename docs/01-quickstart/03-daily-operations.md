# 03. Daily Operations Cheat Sheet

The essential commands to operate, monitor, and steer your agent team every day.

## 1. Starting, Restoring & Stopping Teams

| Goal | Command |
|---|---|
| **Start / Sync a team** | `4genteam up <rig-name>` or `rig up ./rig.yaml` |
| **Restore a stopped team** | `rig up <rig-name> --existing` |
| **Stop a team (with snapshot)** | `rig down <rig-name> --snapshot` |
| **List running nodes / seats** | `rig ps --nodes --rig <rig-name>` |
| **Run diagnostics on fleet** | `4genteam doctor` |

## 2. Inspecting Live Work

| Goal | Command |
|---|---|
| **Merged live feed (all seats)** | `4genteam feed --rig <rig-name> --detail` |
| **Watch single seat feed** | `4genteam feed --rig <rig-name> --seat <seat-name> --detail` |
| **Full interactive grid** | `4genteam watch --rig <rig-name>` |
| **Capture recent pane output** | `rig capture <rig>-<seat>@<rig> --lines 30` |

## 3. Communicating & Dispatching

| Goal | Command | Notes |
|---|---|---|
| **Send task to seat** | `4genteam send --from owner <rig> <seat> '<message>'` | Prefixes message with identity |
| **Direct rig message** | `rig send <rig>-<seat>@<rig> '<message>'` | Use single quotes to avoid bash substitution |

> [!TIP]
> Always wrap messages in **single quotes** (`'...'`) so your local shell doesn't interpret backticks (`\``) or dollar signs (`$`) before sending.

## 4. Managing Work & The Queue

| Goal | Command |
|---|---|
| **List pending & active tasks** | `rig queue list` |
| **View specific task detail** | `rig queue show <qitem-id>` |
| **Check blocked / parked items** | `rig queue list --filter state=blocked` |

## 5. Maintenance & Token Compaction

| Goal | Command |
|---|---|
| **Run compaction supervisor** | `4genteam compact <rig-name>` |
| **Reseat / refresh skills** | `4genteam seat reseat <rig-name> --seat <seat-name>` |
| **Sync room specifications** | `4genteam sync rig <rig-name>` |

---

Next: [Architecture & Mental Model: 01 — How It Works](../02-architecture-and-mental-model/01-how-it-works.md)
