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
* **A glyph and colour per kind of tool**, so the feed reads by shape:

  | Glyph | Kind | Colour |
  |---|---|---|
  | `◉` | read, ls | blue |
  | `⌕` | grep, find, glob, search | cyan |
  | `✎` | write, edit | yellow |
  | `❯` | shell (`bash`, `eval`) | green |
  | `⌁` | web search, fetch, browser | blue |
  | `⇉` | delegate, todo | violet |
  | `?` | ask | orange |
  | `⬡` | MCP tool, shown as `mcp <server_tool>` | magenta |
  | `→` | anything else | white |

* **Purpose first, argument below.** A call's head carries the purpose the seat stated for it (dim italic); the command, path or request follows on the lines below, with no `key=` noise. Results are headed by the tool that answered (`← bash`), and errors are red (`✗ bash`).
* **Runtime events in orange.** What the runtime injects into a seat itself is marked apart from the seat's own work: `HOOK <name>` for a reminder or notice (system tags removed, three lines at most), `RULE` for an injected rule, `EXIT` for the end of a session. A call the seat's own policy refused is a white-on-red `BLOCKED`.
* **Word Wrapping:** Full tool commands and messages wrap cleanly with indentation.
* **Token Meters:** Every line carries the context percentage, so the meter never scrolls out of view.

### B. Single-Seat Observation
Follow only one seat (e.g. the lead):
```bash
4genteam feed --rig <rig-name> --seat lead --detail
```

### C. The Multi-Pane Interactive Grid (`4genteam watch`)
Opens a tiled workspace using `herdr` showing:
- One pane per active seat, titled with the seat, its model and a context bar:
  `== lead | deepseek-flash ==  ███████████████░ 91% 137k/150k to compact`
  (the title is renamed as the reading moves, at most every 5 seconds, so the stream itself carries no header line)
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

A running pane keeps the binary it started with: after updating `4genteam`, run `4genteam watch --rig <rig-name>` again to rebuild the panes.

Next: [02 — Token Economy & Self-Compaction](02-self-compaction.md)
