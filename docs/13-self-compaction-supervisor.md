# 13. A supervisor that compacts the seats for you

Chapter 12 asks each seat to schedule its own `/compact`. In a long run that rule fails quietly:
seats forget it, a seat that is mid-task cannot act on it, and a seat that never finishes a turn
never compacts. The fix is to move the job out of the seats into **one supervisor process per
room**. The seats stay unaware; the supervisor watches and acts.

## 13.1 What the supervisor does

Each pass, for every seat in the room it supervises:

1. **Read the context size** of the seat's live session (the token count of its newest model
   request, taken from the session transcript or the runtime's own usage report).
2. **Compare it with a safe point.** Below it, do nothing.
3. **Wait for quiet.** Above the safe point, wait until the seat has produced no output for a short
   period (seconds, not minutes). Compacting in the middle of a tool call loses the call.
4. **Send `/compact`** to the seat's terminal, with a fixed instruction that says what to keep.
5. **Witness it.** Read the context size again. Count the compaction as done only when the size
   dropped; log both numbers. A `/compact` that was typed but did not shrink anything is a failure
   to report, not a success.
6. **Tell the seat to resume.** A compacted seat is idle. Send one short message that tells it to
   re-read its identity and its durable notes and continue.

```
2026-.. lead: quiet 26s at 162k, sent /compact
2026-.. lead: /compact WITNESSED (162k -> 31k)
2026-.. lead: told to resume
```

## 13.2 Two thresholds, not one

| Threshold | Meaning | Behaviour |
|---|---|---|
| **Safe point** (example: 150k tokens) | Compaction is cheap and loses little | Compact at the next quiet moment |
| **Hard ceiling** (example: 300k tokens) | The seat is about to degrade or hit a limit | Compact without waiting for a long quiet period |

Pick numbers from your model's window, not from this table. The safe point should leave room for a
whole task; the ceiling should sit well below the window so a compaction request itself still fits.
The reason to have both: the safe point keeps the average context small, which is where the savings
are, and the ceiling is the net for a seat that never goes quiet.

## 13.3 Rules that keep it safe

- **Only compact seats that are idle-ish.** Never during a build, a test run or a pending offload.
- **One supervisor per room, one writer per seat.** Two supervisors sending `/compact` to the same
  seat produce a double compaction and a confused resume.
- **The resume message is the only instruction the supervisor sends.** It points at files the seat
  owns (its guide, its notes). It does not carry task content, because the supervisor does not know
  the task.
- **Durable state first.** The scheme only works if each seat keeps its working state in files
  (a ledger, a "Next" note, queue items). Compaction removes the conversation, not the files.
- **Log every action** with the before and after numbers. A supervisor you cannot audit will be
  switched off the first time it surprises someone.

## 13.4 Running several rooms

Each room gets its own supervisor process, started with the room's name. They do not share state, so
a second room (for instance an experiment room, chapter 21) never needs the first to be stopped.
Check the processes and their logs:

```bash
pgrep -af 'compact.*--rig'          # one line per supervised room
tail -n 5 logs/compact-<room>.log   # the last actions, with before/after sizes
```

A room whose log shows only the "supervising" line is not broken: its seats have not reached the
safe point yet.

## 13.5 Runtimes without a usable size

The supervisor needs a context number. A runtime that does not report one (or reports it in a form
you cannot read) cannot be supervised this way; give those seats the chapter 12 rule instead, and
keep the sessions short. Do not guess a size from elapsed time.

## 13.6 Check

- The log shows `WITNESSED` lines with a drop, not just `sent`.
- No seat's context stays above the hard ceiling for more than one pass.
- After a compaction the seat's first action is to re-read its identity and notes.

Next: [chapter 14 — keeping the fleet alive](14-keeping-the-fleet-alive.md).
