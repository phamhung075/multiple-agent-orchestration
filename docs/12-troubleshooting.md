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
→ `rig down <rig> --snapshot`, then `rig up <rig> --existing`. Try the `rig up` on its own first,
though: after a whole-fleet loss on 2026-10-05 it succeeded directly, with no `rig down`.

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
shows both. → Refer to rigs by id. `rig archive <rigId>` hides a record and keeps its data (reverse with
`rig unarchive`); `rig down <rig> --delete` removes it for good.

### The UI shows `Startup failed ... Cannot establish managed input target <seat>`
Usually a stale failed record on an old rig, not a live launch: `curl -s http://127.0.0.1:7433/api/ps`
shows `status: stopped` and the seats show `startupStatus: failed`, `startupCompletedAt: null`. →
`rig archive <rigId>`, or restore it on purpose.

### `rig expand` times out (`outcome is UNKNOWN`)
The daemon did not answer within 5 seconds, but the pod may exist. → `rig ps --nodes --rig <rig>`
before retrying.

## Seats

### Seat is `idle` after `rig send`
The message sits unsubmitted in the input box. → `tmux send-keys -t '<seat>' Enter`.

### Seat is `needs-input`, reason `selection_prompt`
A permission prompt or picker is waiting. `rig capture <seat> --lines 30` shows it. Approve plain
"Yes" for read-only commands you understand. Avoid "don't ask again" unless you mean it. Seats on
`builtin:yolo` do not show these.

### A seat can read but cannot write, edit or run bash (omp runtime)
Symptom: `agentActivity` alternates `running (read)` with `needs_input`, reason `permission_prompt`,
on every `write`/`edit`/`bash`; the seat itself reports it "cannot run git here". It is half working
and looks busy.
Cause **(verified 2026-10-05)**: for the `omp` runtime, `rig seat set-permissions` is refused
("Per-seat permission mode is unsupported for runtime 'omp'"), and a **fresh launch does not apply
the declared `permission_policy`** — the policy columns stay NULL and are load-bearing. Relaunching
the seat, even owner-authorized, does **not** fix it: every tool call was still denied by the
operator-approval path afterwards.
→ Do not burn a relaunch on it. Check the columns on the seat record, treat the NULLs as the cause,
and either grant at a layer the runtime honours or move that seat's writable rows to a seat that can
write. The seat's own report is honest — believe it over the `running` state.

### `No conversation found with session ID …` after a restore
The Claude transcript for that session no longer exists, so `claude --resume` fails and the seat sits
at a bare shell. → `rig up <rig> --existing --fresh <logical-seat-id>`. History is lost, the seat
re-reads its culture. Check what is on disk with `ls ~/.claude/projects/<project>/`.

### Lifecycle `att` with reason `no_runtime_hook`
The session is alive but OpenRig has not received its activity hook yet. Often a seat whose launch
failed. Check `rig capture <seat>`.

### `Harness launch failed: Failed to send launch command`
The pane was not ready or the terminal died. → `rig down <rig>`, then `rig up <rig> --existing`.

### `rig send` refuses an `agy` seat: "shows a bare sh shell"
The `agy` runtime runs as `bash → sh → agy`, so the send guard sees `sh` in the foreground and thinks
the runtime is gone **(verified 2026-10-02; looks like a false positive)**. Confirm first:
`rig capture <seat>` shows the agy screen and `pstree -p $(tmux list-panes -t <seat> -F '#{pane_pid}')`
shows `agy`. Then type into the pane yourself:
`tmux send-keys -t <seat> -l "<text>"; sleep 1; tmux send-keys -t <seat> Enter`. If agy is really not
running, relaunch the seat instead.

### A message was sent but the seat does nothing with it
Look at the screen. `agy` shows `Press up to edit queued messages`: the message waits until its current
turn ends, which can be a long time. Claude Code loses track of it if the seat is mid-compaction. →
Wait for a turn boundary, or interrupt (Escape) and resend a short, imperative instruction.

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
→ `rig up <rig> --existing`. On 2026-10-05 this reported `fully_restored` with all ten seats
`resumed` on their own session files, with **no `rig down` first**; reach for
`rig down <rig> --snapshot` only if you get the HTTP 409 refusal above.

**Mechanism (verified 2026-10-05).** Every seat's exit record read `{"reason":"sighup","kind":"signal"}`
and eight of them landed inside a 215 ms window: the **server** went first, each pane's pty master
closed, and the kernel hung up the pane's process group. `exit-empty on` then exited the already
emptied server cleanly, which is why the socket was left stale. The tidy exit is the epilogue, not
the cause.

**Cause still unattributed.** The leading candidate is an unlogged signal to the server process.
Ruled out, with reasons worth reusing: the **daemon** (`session.stopped` has exactly one writer and a
deliberate close does log it — a seat stopped 53 s earlier proved the row exists); **OpenRig's tests**
(every `kill-server` in the tree passes a private socket `-S`; production code only uses
`kill-session -t <name>`); the **OOM killer** (it killed other processes at other times, and there is
no kernel event at the death second).

**Reasoning trap.** A missing `dmesg` line does **not** mean "no kill": `SIGTERM`, `SIGKILL` and
`SIGHUP` to a user process leave no kernel record at all. Absence of evidence is only evidence when
the mechanism would necessarily have left a trace. See [chapter 14](14-keeping-the-fleet-alive.md)
for the probe that catches this in 60 s instead of 2 m 16 s, and `~/.openrig/openrig.sqlite`'s
`events` table (UTC) for the authoritative timeline.

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
Nothing told them to, or they were told and did not act. → Add the offload section to `CULTURE.md`,
message the seats, then **count jobs**: `node $R list | grep job-$(date -u +%Y%m%d)`. Zero means no
delegation, whatever the seats said (chapters 8–9).

### Every DeepSeek job ends `error`, result says `Insufficient Balance`
The DeepSeek account is out of credit. `doctor` can still pass. → Run
`node $R start "Reply with the single word OK." --read-only --json`; `error` means top up, `done` means
credit is back. Until then seats should port directly and report once, not retry in a loop.

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
scripts/rig-watchdog.sh --check   # expectation vs reality, one line per rig
rig ps --nodes --rig <rig>        # activity and reason per seat
rig capture <seat> --lines 40     # what is on screen?
tail -30 ~/.openrig/daemon.log    # what did the daemon say?
dmesg | grep -i oom | tail        # was it memory?  (a CLEAN dmesg does not rule out
                                  #  a signal — SIGTERM/SIGHUP leave no kernel record)
```

Ask the two questions in order, and never let one answer for the other: **what does the daemon
believe** (`rig ps`, its cache) versus **what is actually alive** (`tmux ls`, the ground truth). When
they disagree, the ground truth wins and every other tool will mislead you in the same direction
(chapter 14.1).

`rig context get help` prints the help guide for your installed version.

Next: [chapter 13 — safety and security](13-safety-and-security.md).
