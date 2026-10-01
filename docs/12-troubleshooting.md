# 12. Troubleshooting

Every entry below happened during the real run. Format: **symptom → cause → fix**.

## Starting rigs

### `Up failed: Unable to determine source type for '<folder>'` (HTTP 400)
`rig up` was given a folder. It needs a `.yaml` rig spec or `.rigbundle`.
→ `rig up ./rig.yaml`.

### `Up failed: unknown error (HTTP 500)` after `rig up rig.yaml --existing`
`--existing` means "the argument is a rig **name**". It looked for a rig called `rig.yaml`.
→ New rig: `rig up rig.yaml`. Existing, stopped rig: `rig up <rig-name> --existing`.

### `Rig … has live sessions. Stop the rig with 'rig down' before restoring` (HTTP 409)
Restoring needs the rig stopped. Often the daemon believes sessions are alive after a crash.
→ `rig down <rig> --snapshot`, then `rig up <rig> --existing`.

### `local: ref must be a relative path`
A spec used `agent_ref: "local:/abs/path"`.
→ Use a path relative to the spec file: `realpath --relative-to=<spec dir> <agents dir>`.

### `Daemon not running`
After a reboot or crash. → `rig daemon start`, then restore the rigs you need.

### `rig queue create` says `Sender identity … required` or `--source is required`
From a plain shell there is no seat identity.
→ Run it from a seat, or `rig send` the seat a message asking it to create the item.
The same applies to `rig seat set-permissions`.

### Two records with the same rig name
A failed or repeated `rig up` can leave a stopped record and a new one. `rig ps --filter status=stopped`
shows both. → Use `rig down <rig> --delete` on the broken one, or refer to rigs by id.

## Seats

### Seat is `idle` after `rig send`
The message sits unsubmitted in the input box. → `tmux send-keys -t '<seat>' Enter`.

### Seat is `needs-input`, reason `selection_prompt`
A permission prompt or picker is waiting. `rig capture <seat> --lines 30` shows it. Approve plain
"Yes" for read-only commands you understand. Avoid "don't ask again" unless you mean it. Seats on
`builtin:yolo` do not show these.

### `No conversation found with session ID …` after a restore
The Claude transcript for that session no longer exists, so `claude --resume` fails and the seat sits
at a bare shell. → `rig up <rig> --existing --fresh <logical-seat-id>`. History is lost, the seat
re-reads its culture. Check what is on disk with `ls ~/.claude/projects/<project>/`.

### Lifecycle `att` with reason `no_runtime_hook`
The session is alive but OpenRig has not received its activity hook yet. Often a seat whose launch
failed. Check `rig capture <seat>`.

### `Harness launch failed: Failed to send launch command`
The pane was not ready or the terminal died. → `rig down <rig>`, then `rig up <rig> --existing`.

### Two seats waiting on each other
Add to the culture: "owner never waits for the checker; queue the slice and start the next one", and
register reminders (chapter 8).

### A seat does not follow a new rule
It reads `CULTURE.md` only at launch. → Message it (chapter 8). Verify with
`grep -c "<section title>" ~/.claude/projects/<project>/<session>.jsonl`.

## The machine

### Every tmux seat died at once
The tmux server stopped. `tmux ls` says `no server running`; `rig ps` can still claim `run` for
minutes (stale). Seats in **herdr** are unaffected.
→ `rig down <rig>` then `rig up <rig> --existing` for each rig. Cause was not identified in the
case study. Checked and ruled out: the Linux OOM killer (it killed Firefox processes, not tmux) and
OpenRig's own tests (they use isolated sockets).

### `rig terminal open` says `tmux session … is not alive`
Same as above for tmux seats. Restore them.

### Memory pressure on WSL2
`dmesg | grep -i 'Out of memory'` shows OOM kills. Raise `memory=` in `.wslconfig` (chapter 2), close
heavy tools (language servers, browsers), and avoid running many seats plus builds at once.

### Daemon log shows `SIGTERM … shutting down`
Something stopped the daemon (another session, a script, a restart). After it restarts, rigs show
stale states for a minute. Wait, re-run `rig ps`, then restore what is stopped.

## DeepSeek

### Seats have the DeepSeek MCP attached but never call it
Nothing told them to. → Add the offload section to `CULTURE.md` and message the seats (chapters 8–9).

### `dsh-offload.mjs doctor` reports a model-name error
The `acp` profile pins a model your provider route does not accept. →
`.agents/deepseek-offload/install.sh --model deepseek-flash` (or `deepseek-v4-pro`).

### Jobs run but the GUI shows nothing live
Expected for a released GUI. → `session-tail.mjs <jobId> --watch`. See chapter 9.

### Job output is wrong or edited unrelated files
Treat it as a draft: review the diff, run the build, fix by hand. Tighten the prompt's hard rules.

## Source repo problems

### `git status` shows `UU` and `<<<<<<<` markers in a tool's own source
Somebody is mid-merge. Do not resolve it for them. Use the published package (`npm i -g @openrig/cli`)
if you need a working `rig` meanwhile.

### Two teams edited the same files
Stop one team (`rig down <rig>`), stop its reminders (`rig watchdog stop <id>`), and let the other own
the area. Check `git status` and the ledger.

## Quick triage order

```bash
rig daemon start || true          # is the daemon up?
rig ps                            # what does OpenRig think?
tmux ls ; pgrep -a herdr          # what is really alive?
rig ps --nodes --rig <rig>        # activity and reason per seat
rig capture <seat> --lines 40     # what is on screen?
tail -30 ~/.openrig/daemon.log    # what did the daemon say?
dmesg | grep -i oom | tail        # was it memory?
```

`rig context get help` prints the help guide for your installed version.

Next: [chapter 13 — safety and security](13-safety-and-security.md).
