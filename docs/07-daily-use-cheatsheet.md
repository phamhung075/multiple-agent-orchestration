# 7. Daily use — the cheat sheet

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

## Talk and give work

| Goal | Command |
|---|---|
| Message one seat | `rig send <seat> "text"` |
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

Restoring a rig that still has live sessions fails with HTTP 409. Run `rig down <rig>` first.

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

Next: [chapter 8 — culture and the standing mission](08-culture-and-standing-mission.md).
