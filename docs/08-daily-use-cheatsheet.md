# 8. Daily use — the cheat sheet

All commands were used in the real run. `<seat>` means `member@rig`, for example `dev-owner@4genthub-go`.

## Look

| Goal | Command |
|---|---|
| All rigs | `rig ps` |
| Seats of one rig | `rig ps --nodes --rig <rig>` |
| Everything | `rig ps --full` or `rig ps --nodes -A` |
| Stopped rigs | `rig ps --filter status=stopped` |
| A seat's screen | `rig capture <seat> --lines 40` |
| Attach live (tmux seats) | `tmux attach -t <seat>` (detach `Ctrl-b d`) |
| Dashboard | `rig tui` or `rig tui --shared` |
| A seat's identity (from outside) | `rig whoami --session <seat> --json` |
| Config | `rig config`, `rig config --with-source`, `rig config get <key>` |
| Daemon log | `tail -f ~/.openrig/daemon.log` |
| Is the fleet actually **alive**? | `scripts/rig-watchdog.sh --check` — asks tmux, not the daemon ([chapter 14](14-keeping-the-fleet-alive.md)) |

## Open herdr and the GUIs

| Goal | Command |
|---|---|
| Open herdr (launch or attach to the persistent session) | `herdr` |
| herdr server and client status | `herdr status` |
| A named herdr session | `herdr --session <name>` |
| Seats as herdr tiles | `rig terminal status` → `rig terminal views` → `rig terminal open <view>` (run from inside herdr or any terminal) |
| Stop the herdr server (closes its panes) | `herdr server stop` |
| OpenRig web GUI | `rig ui open` (opens the default browser; needs the daemon, port 7433 by default: `rig daemon status`) |
| OpenRig terminal dashboard | `rig tui` |
| DeepSeek Harness web GUI | `npx @deepseek-ai/dsh web` → http://127.0.0.1:3080 |
| The brain's dashboard — rooms, seats, resolved state, drift | https://www.4genthub.com/ ([chapter 18](18-completing-the-system-the-brain.md)) |

The OpenRig web UI is served by the daemon on its port and is **off by default**: opening
`http://127.0.0.1:7433` returns "The OpenRig web UI is off". Turn it on once:

```bash
rig config set ui.enabled true
rig daemon stop && rig daemon start
rig ui open
```

herdr and the daemon are separate processes; `rig daemon status` shows whether the daemon is up.
On WSL, if no browser window opens, browse to `http://127.0.0.1:7433` from Windows. See [chapter 5](05-terminals-and-runtimes.md)
for herdr and [chapter 6](06-install-deepseek.md) for the DeepSeek GUI.

The brain's dashboard is the only view here that shows **drift** — where a seat's resolved state
differs from what it was configured to be. A seat can be running locally and still be drifted, so
this is the one thing the local tools cannot tell you ([chapter 18.3](18-completing-the-system-the-brain.md)).

## Talk and give work

| Goal | Command |
|---|---|
| Message one seat | `rig send <seat> "text"` |
| Message one seat, signed (4genthub client) | `4genteam send --from lead <rig> <seat> "text"` |
| Restart live seats when each is quiet (4genthub client) | `4genteam seat reseat <rig> --seat a --seat b` |
| Message a pod or rig | `rig send --pod dev "text"` · `rig send --rig <rig> "text"` |
| Raw keystrokes (no envelope) | `rig send --raw <seat> "/compact"` |
| Wait for idle first | `rig send <seat> "text" --wait-for-idle 600` |
| Verify delivery | `rig send <seat> "text" --verify` |
| Durable work (from a **seat** shell) | `rig queue create --destination <seat> --body-file task.md --summary "..."` |
| Hand off with evidence | `rig queue handoff …` (see `rig queue handoff --help`) |
| What is owed to me | `rig queue list --owned --limit 1000` |
| Submit a pending input | `tmux send-keys -t '<seat>' Enter` |

> A message sent to a busy seat can sit unsubmitted in its input box. If the seat stays `idle`
> after a `rig send`, press Enter in its pane.

## Start, stop, restore

| Goal | Command |
|---|---|
| New rig from a spec | `rig up ./rig.yaml` |
| Restore an existing rig | `rig up <rig> --existing` |
| Restore, some seats fresh | `rig up <rig> --existing --fresh <seat-logical-id> …` (for example `dev.owner`) |
| Preview | add `--plan` |
| Stop (and snapshot) | `rig down <rig> --snapshot` |
| Stop and delete the record | `rig down <rig> --delete` |
| Start the daemon | `rig daemon start` |
| Daemon down after a reboot, restore chosen rigs | `rig start --rigs <name> …` (headless; plain `rig start` needs a TTY) |
| Restore everything that was running | `rig start --last` (or `--all` for every restorable snapshot) |
| Hide a rig, keep all data | `rig archive <rigId>` / `rig unarchive <rigId>` / `rig ps --include-archived` |

Restoring a rig that still has live sessions can fail with HTTP 409, and the daemon often believes
sessions are alive when they are not. Try `rig up <rig> --existing` first — after a whole-fleet loss
it has succeeded directly — and fall back to `rig down <rig> --snapshot` if it refuses
([chapter 23](23-troubleshooting.md)).

## Wake-ups (watchdogs)

```bash
rig watchdog register --spec wake-owner.yaml --policy periodic-reminder \
    --target-session dev-owner@my-team --interval-seconds 600 --registered-by human@host
rig watchdog list
rig watchdog status <jobId>
rig watchdog stop <jobId>
```

`wake-owner.yaml` is in [../templates/wake-reminder.yaml](../templates/wake-reminder.yaml).

## Permissions

```bash
rig policy current --spec rig.yaml
rig policy apply yolo --spec rig.yaml        # or: none
rig seat set-permissions <seat> --mode auto --reason "why"     # run from a seat
```

## DeepSeek workers

```bash
R=.agents/skills/deepseek-offload/scripts/dsh-offload.mjs
node $R doctor
node $R start "$(cat scratch/dsh-prompts/w1-01.md)" --cwd "$PWD" --label w1-01 --detach
node $R list                 # states of recent jobs
node $R status <jobId>
node $R result <jobId>
node $R update <jobId> "extra instruction"
node $R cancel <jobId>
node .agents/skills/deepseek-offload/scripts/session-tail.mjs <jobId> --watch
```

> A cheap model can also be staffed as a **seat** — an occupant of a position, with its own role file
> — instead of being called as a tool. It then holds context, takes a queue item, and can be reviewed
> like any other seat. [Chapter 15.9](15-architecture-seat-model-and-cloud.md) explains when that
> replaced this pattern and why.

## Where to find evidence

| Question | Look at |
|---|---|
| Did the seat actually run a command? | `~/.claude/projects/<project>/<session-id>.jsonl` (tool calls) |
| Is the seat using DeepSeek? | `node $R list`; `~/.dsh/sessions/<project>/` |
| Why did a request fail? | `~/.openrig/daemon.log` |
| What is the migration status? | `grep -c '| todo |' MIGRATION.md` or `bash scripts/status.sh` |

## One-screen status

```bash
bash scripts/status.sh ~/my-repo/agenthub_go/MIGRATION.md
```

Next: [chapter 9 — safety and security](09-safety-and-security.md).
