# 01. Live Monitoring & The Watch View

When a team of 4 to 10 agents is executing concurrently, you cannot switch between 10 terminal windows to see what is happening.

The `watch` suite in `4genteam` provides real-time, read-only visibility into the entire fleet.

---

## 1. Monitoring Views

### A. The Merged Live Feed (`4genteam feed`)
Stream tool calls, agent reasoning, and outputs across all seats into a single terminal window:
```bash
4genteam feed --rig <rig-name> --detail
```
* **Real-time Color Coding:**
  - Blue: Read/Grep/Search tools
  - Yellow: Write/Edit tools
  - Green: Shell commands (`bash`, `eval`)
  - Magenta: MCP protocol tool invocations
  - Red: Blocked calls or tool errors
* **Word Wrapping:** Full tool commands and messages wrap cleanly with indentation.
* **Token Meters:** Displays current context tokens and distance to the next compaction threshold.

### B. Single-Seat Observation
Follow only one seat (e.g. the lead):
```bash
4genteam feed --rig <rig-name> --seat lead --detail
```

### C. The Multi-Pane Interactive Grid (`4genteam watch`)
Opens a tiled workspace using `herdr` showing:
- One pane per active seat
- A dedicated lead terminal window on top
- Direct input panels underneath each seat for operator intervention

```bash
4genteam watch --rig <rig-name>
```

---

## 2. Key Monitoring Flags

| Flag | Default | Description |
|---|---|---|
| `--detail` | `false` | Shows thinking/reasoning blocks, tool arguments, and replies |
| `--lines N` | `25` | Maximum lines shown per output block |
| `--width N` | `170/200` | Line wrapping width in terminal columns |
| `--back N` | `40` | Number of historical events to display on startup |

---

Next: [02 — Token Economy & Self-Compaction](02-self-compaction.md)
