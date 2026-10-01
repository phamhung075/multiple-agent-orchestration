# 5. Terminals and runtimes

A seat is a real terminal session running an agent CLI. OpenRig supports two kinds of terminal
holders and several runtimes. Knowing which one a seat uses explains most "why can't I see it?"
questions.

## 5.1 tmux

- Seats of runtime `claude-code` (and `codex`) run in **tmux** sessions named `<seat>@<rig>`.
- Attach: `tmux attach -t dev-owner@4genthub-go`. Detach: `Ctrl-b` then `d`.
- List: `tmux ls`.
- All seats share **one tmux server**. If that server dies, every tmux seat dies with it
  (chapter 12). Seats in herdr are not affected.

## 5.2 herdr

- **herdr** is a persistent terminal workspace manager. OpenRig's default terminal provider.
- `agy` seats in this run lived in herdr panes (the `herdr server` process), not tmux.
- OpenRig can open seats as tiles in herdr:

```bash
rig terminal status           # provider availability and liveness
rig terminal views            # saved views, and rigs you can open as derived views
rig terminal open <view>      # open every live agent in the view as a tile
```

If tiles do not open, the message says why, for example `tmux session … is not alive`.

Other herdr commands: `herdr` (attach), `herdr status`, `herdr update`, `herdr server stop`,
`herdr workspace …`, `herdr pane …`.

## 5.3 Runtimes

| Runtime | In a spec | Notes |
|---|---|---|
| Claude Code | `runtime: claude-code` | Default flag `--permission-mode acceptEdits`; full bypass with `permission_policy: builtin:yolo` |
| Antigravity | `runtime: agy` | Supported by OpenRig builds that include the agy adapter (shipped specs `kernel-agy`, `first-project-agy`) |
| Codex | `runtime: codex` | Sandbox `workspace-write` by default; `danger-full-access` with yolo |
| Terminal | `runtime: terminal`, `agent_ref: builtin:terminal` | A plain shell (the kernel's `operator-human`) |

Check which runtimes the machine can launch:

```bash
claude auth status
codex login status
agy --version
```

A runtime mix per team is allowed: for example Claude owner + Codex checker (`first-project-mixed`).

## 5.4 Seat status words

`rig ps --nodes --rig <name>` shows two useful columns.

| LIFECYCLE | Meaning |
|---|---|
| `run` | Session alive and managed |
| `att` | Attached (alive but with attention flags, for example no runtime hook yet) |
| `rec` | Recoverable: not running, can be restored |
| `det` | Detached: the terminal went away |

| ACTIVITY | Meaning |
|---|---|
| `working` | The agent is acting |
| `idle` | Finished its turn, waiting for input |
| `needs-input` | Blocked on a prompt (permission, selection) |

## 5.5 Seeing what a seat is doing

```bash
rig capture <seat>@<rig> --lines 40     # read the screen
tmux attach -t <seat>@<rig>             # watch live (tmux seats)
rig tui --shared                        # shared dashboard
```

Never poll `rig capture` in a loop. Use queue handoffs and watchdogs (chapter 10).

Next: [chapter 6 — your first team](06-first-team.md).
