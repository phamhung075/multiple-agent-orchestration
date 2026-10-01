# 10. Token economy and compaction

Long jobs burn tokens in three ways: a bloated context, idle loops, and using the top model for
mechanical work. This chapter covers all three.

## 10.1 Spend less

| Lever | How | Chapter |
|---|---|---|
| Offload bulk work | DeepSeek waves | 9 |
| Keep the context small | Compact after each finished task | below |
| No polling | Queue handoffs and watchdogs, not `rig capture` loops | 7, 8 |
| Right-size reviews | The checker reviews slices, not every line of a worker's chatter | 9 |
| Off-peak batches | `dsh-offload.mjs start --defer-to-off-peak` | 9 |
| One team per area | Two teams re-doing the same work double the cost | 8 |

When a provider limit is hit, a seat stops. The team resumes when the limit resets if reminders are
registered (chapter 8), and your ledger tells it where to continue.

## 10.2 Compact your own context after each task

Claude Code's `/compact` summarizes the conversation. A seat cannot act inside its own finished turn,
so it schedules the command to arrive **after** the turn ends.

Rule written into `CULTURE.md` (see [../templates/CULTURE.md](../templates/CULTURE.md)):

1. Record state durably first: ledger rows, the queue handoff or verdict, and a short **Next** note
   at the bottom of the ledger (what you were doing, the last command, the next step).
2. As the last action of the turn, schedule a background compact to your own session:

```bash
ME=$(rig whoami --json | python3 -c "import json,sys;print(json.load(sys.stdin)['identity']['sessionName'])")
nohup rig send --raw "$ME" \
  "/compact Keep: the mission in CULTURE.md, the ledger state, open queue items. After compacting: run rig whoami --json, re-read CULTURE.md and the Next note, then continue with the next todo." \
  --wait-for-idle 600 >/dev/null 2>&1 &
```

3. After compaction, restore from the durable files before doing real work.

Limits: skip it when the task was trivial or the context is small; never compact during a build or
test, with an offload job pending, or with a half-written queue item; never compact another seat.

> **Not verified end to end.** `--wait-for-idle` is documented as "wait until the target is
> explicitly idle before sending". Confirm on your version that `/compact` lands after the turn and
> not in the middle of it.

### Built-in alternative

OpenRig has a threshold-based setting:

```bash
rig config get policies.claude_compaction.enabled        # false by default
rig config get policies.claude_compaction.threshold_percent   # 80
```

Enabling it makes OpenRig drive compaction by context size for **all** Claude seats. Read the
skill first: `rig context get skills/claude-compaction-restore`.

## 10.3 After a compaction or restart: restore from files

The skill `claude-compaction-restore` has two protocols: "If You Are About To Compact" (write the
restore map) and "If You Just Compacted" (rebuild the working model). The minimum:

```bash
rig whoami --json                    # who am I
# re-read CULTURE.md and the Next note in the ledger
rig queue list --owned --limit 1000  # what is owed to me
```

## 10.4 Reminders that do not waste tokens

A reminder every 10 minutes costs one short prompt per seat. Use a message that points to the
ledger, not a long instruction:

```yaml
policy: periodic-reminder
target:
  session: dev-owner@my-team
message: "Keep going on the mission in CULTURE.md: re-read MIGRATION.md, and if any todo remains, port the next slice. Do not wait for the other seat."
```

Stop them when the job is finished: `rig watchdog stop <jobId>`.

## 10.5 Check

- `grep -c '/compact' ~/.claude/projects/<project>/<session>.jsonl` shows compactions after tasks.
- `rig watchdog list` shows only the reminders you want.

Next: [chapter 11 — the real case study](11-case-study-python-to-go.md).
