# 14. Keeping the fleet alive

Chapters 8–10 make a team run for hours without you. They watch **work**: the queue, the ledger,
reminders, the token budget. None of them watches whether the team still **exists**.

That is a real gap, and it bit a production run twice. On 2026-10-05 the tmux server holding all ten
seats died at 22:44:02 and nothing noticed until a human looked. This chapter is how to stop that.

## 14.1 The blind spot: every layer asks the daemon

When you ask "is my team up?", every tool you would naturally reach for reads the daemon's **cached
lifecycle**, not the machine:

| You ask | It actually answers | 2026-10-05 |
|---|---|---|
| `rig ps` | the daemon's intent — what it launched and believes | said `10 running` while all ten were gone |
| `rig crash-cart` | daemon-down only (it is the daemon-DOWN verdict) | said `{"state":"up"}` — correct, and useless here |
| `rig ps --nodes` activity | the daemon's view of a pane | still showed seats `working` |
| `startup reconcile` | runs **once, at daemon start** — never again | had run hours earlier |

So a total fleet loss is invisible to the toolkit. In the case study a human noticed 2 minutes 16
seconds later. **Nothing you would think to run tells you the truth, because they all ask the same
witness.**

The fix is one idea: **ask tmux directly, and compare it to what the daemon claims.**

## 14.2 The probe: expectation vs. reality

```bash
# what the daemon believes is running
rig ps --nodes --rig <rig> --json | python3 -c '
import json,sys; rows=json.load(sys.stdin)
print(sum(1 for r in rows if r.get("lifecycleState")=="running"))'

# what is actually there (a dead server yields 0, not an error)
tmux ls -F '#{session_name}' | grep -c '@<rig>$'
```

`expected > 0` with `live == 0` is the crash shape. Two details that matter:

- **Debounce.** Require **two consecutive misses** before acting. One bad poll happens during a
  legitimate launch or restore, and a watchdog that "heals" a rig mid-restore makes things worse.
- **Never act when the daemon expects nothing.** `expected == 0` means a deliberate stop. A
  watchdog that restarts rigs you meant to stop is worse than no watchdog.

Ready to run: [../scripts/rig-watchdog.sh](../scripts/rig-watchdog.sh) — one-shot check, or a loop
that restores a rig whose seats vanish. It uses `~/.openrig/bin/rig-continue.sh` if you have one, so
the team is re-briefed as well as relaunched; otherwise it falls back to `rig up <rig> --existing`.

## 14.3 Silence is not success

The first version of that watchdog logged only when something was wrong. That is a trap: **a
watchdog that died is indistinguishable from a watchful one.** If the only evidence of health is the
absence of complaints, you have replaced one silent failure with another.

So a healthy fleet must still say something, on a schedule:

```
2026-10-05T22:57:54+02:00 my-team: heartbeat — alive, daemon expects 10, tmux has 10, no misses
```

Pick the interval by what a failure costs: every 15 minutes is enough when the fallback is a human
reading a log. Make the heartbeat cheap — one line, no prompts, no tokens.

## 14.4 Timestamp the transition, don't reconstruct it

After the crash we could prove *when* the seats died (session-file mtimes) but not *when the server
changed*, so the trigger stayed a matter of inference. One command closes that:

```bash
tmux display-message -p '#{pid} #{start_time}'      # the server's identity
```

Record it each poll. When it differs from last time, log a timestamped line. Identity is pid **plus**
start time, so a recycled pid cannot masquerade as the same server. The next incident then has a
transition record instead of a reconstruction.

## 14.5 What killed the fleet — and what did not

Worth reading as a **reasoning** lesson, because the obvious suspects were all wrong.

**Mechanism (verified).** Every seat's exit record read `{"reason":"sighup","kind":"signal"}`, and
eight of them landed inside a 215 ms window. A hangup delivered to every pane in one instant is tmux
tearing panes down *because the server went*. So the server died first, each pane's pty master
closed, and the kernel hung up the pane's process group. `exit-empty on` then exited the already
emptied server cleanly — which is why the socket was left stale and `tmux ls` said
`no server running`. **The server is the trigger; the tidy exit is the epilogue.**

**Trigger (still unattributed).** No cause was established in the repo or the kernel log. The
leading candidate is an unlogged signal to the server process.

**Ruled out, with the reasoning:**

| Suspect | Why it is out |
|---|---|
| The daemon | `session.stopped` has exactly **one** writer, and a deliberate close *does* log it — a seat stopped 53 s earlier proved the row exists. Nine silent deaths were not the daemon. |
| OpenRig's own tests | Every `kill-server` in the tree passes a private socket (`-S`); production code only uses `kill-session -t <name>`. No suite ran that night. |
| The OOM killer | It killed other processes (browsers, vitest) at other times. Nothing kernel-level at the death second. |

**The reasoning trap to avoid.** A missing `dmesg` line does **not** mean "no kill". `SIGTERM`,
`SIGKILL` and `SIGHUP` sent to a user process leave no kernel record at all. Absence of evidence is
only evidence when the mechanism would necessarily have left a trace — and for a user-space signal,
it would not.

**Where the timeline actually lives** (more reliable than any log file):

```bash
python3 -c "import sqlite3;c=sqlite3.connect('$HOME/.openrig/openrig.sqlite');
[print(r) for r in c.execute(\"select created_at,type,node_id from events
 where created_at>='2026-10-05 20:40' and created_at<='2026-10-05 20:47' order by seq\")]"
```

`events` is UTC; `dmesg` and `ls` are local. Mixing them silently shifts everything by your offset.

## 14.6 Blast radius: every rig shares one server

The daemon passes no `-S`/`-L` socket selector on any of its tmux calls, so **all rigs share the
default tmux server**. One event that empties it ends the fleet for *every* team on the machine, not
just the one that caused it.

- If your seats run under **herdr** instead, they are unaffected by a tmux server death (chapter 12).
- Giving each rig its own socket (`tmux -S`/`-L` per rig) would make a server-scale event cost one
  rig. That is an upstream OpenRig change, not a config knob — until then, treat one machine's tmux
  server as shared fate for every team on it.

## 14.7 Recovery that works

```bash
rig up <rig> --existing        # restore from snapshot; each seat resumes its own session
```

It reported `fully_restored` with all ten seats `resumed` on their own session files — **no
`rig down` first**. Reach for `rig down <rig> --snapshot` only if you get the HTTP 409 "has live
sessions" refusal (chapter 12).

Why it is cheap: a seat's *position* (rig spec, edges, policy) and its *conversation* (session file)
both live on disk, so nothing has to be reconstructed. What you lose is the elapsed time, not the
work — which is exactly why the detection gap in 14.1 is the expensive part.

## 14.8 Check

```bash
scripts/rig-watchdog.sh --self-test          # the decision rule, on fixtures
scripts/rig-watchdog.sh --check              # report every rig with a brief; changes nothing
tail -3 ~/.openrig/logs/rig-watchdog.log     # is the heartbeat current?
```

- Silence in the log for longer than the heartbeat interval means the **watchdog** is down, not that
  the fleet is fine. Restart it.
- A client-side watchdog does not survive a reboot (and systemd user services are often offline on
  WSL). The durable home for this idea is an orchestrator-level liveness policy — OpenRig has a
  watchdog policy engine, but no liveness policy in it as of 0.6.4. Until then, start the script
  again after each boot.

Next: [chapter 15 — the architecture we actually run](15-architecture-seat-model-and-cloud.md).
