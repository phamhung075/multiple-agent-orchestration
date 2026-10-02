# 8. Culture and the standing mission

A team that works for hours needs one place that says **what the job is** and **how to behave**.
That place is the culture file.

## 8.1 What `CULTURE.md` is

- A markdown file referenced from the spec (`culture_file: CULTURE.md`).
- **Read by each seat once, at launch.** A running seat does not notice later edits.
- Resumed seats keep their earlier conversation, so they only know a change if you tell them.

Template: [../templates/CULTURE.md](../templates/CULTURE.md).

## 8.2 What belongs in it

| Section | Content |
|---|---|
| Project | Repo path, language, where the code lives, what must not change |
| Standing mission | The job, in order, with a stop condition ("until no `todo` row remains") |
| Roles | What the owner does, what the checker does, who may merge |
| Ledger | The file that tracks progress (for example `MIGRATION.md`) and how to update it |
| Offload rules | When to use DeepSeek workers and how to review them (chapter 9) |
| Token rules | When to compact (chapter 10) |
| Test account | The **path** of a private env file, never the secret |
| Hard limits | No commits unless asked, no touching unrelated uncommitted files, no merge until done |

Keep it short and concrete. Every sentence should change what an agent does.

## 8.3 A good standing mission

```markdown
## Standing mission: finish agenthub_go/MIGRATION.md

Port every row marked `todo` in agenthub_go/MIGRATION.md to Go (same file layout, same behavior as
the Python original, which stays untouched), then mark it `done`. Work slice by slice in the listed
order. Owner: do not stop or wait for the checker; queue each finished slice for review and start the
next one. Checker: review queued slices promptly. Both: when you finish a turn, re-read
MIGRATION.md; if any `todo` remains, continue. Stop only when none remain or you need information
only the user can give.
```

Why it works: it gives a **ledger**, a **stop condition** and a rule that **removes the wait** between
owner and checker (the two seats were each waiting for the other).

## 8.4 After you edit the culture

1. Edit the file.
2. Send each running seat a short message naming the changed section:

```bash
M="CULTURE.md updated: new section 'Offloading to DeepSeek'. Re-read it and follow it."
rig send dev-owner@my-team "$M"
rig send dev-check@my-team "$M"
```

3. To prove they got it, search the transcript:

```bash
grep -c "Offloading to DeepSeek" ~/.claude/projects/<project>/<session-id>.jsonl
```

Seats that restart from scratch read the file again at launch.

## 8.5 Keeping the team going

Seats stop at the end of every turn. Combine three things:

| Tool | Solves |
|---|---|
| Standing mission + ledger | They know what to do next after any restart or compaction |
| Watchdog reminder every ~10 min | A seat left `idle` gets nudged |
| "Never wait for the other seat" rule | No two-seat deadlock |

When you are done, stop the reminders (`rig watchdog stop <jobId>`) or they keep firing.

## 8.6 Several teams on one code area

Two teams on the same files overwrite each other. In the first run three rigs were set up for the
same migration and had to be stopped. The second run kept two teams (a Claude pair and an `agy` pair)
in one rig as two pods, and split the work so they cannot collide.

**Split by bounded context, not by slice.** Rows in the same context share types and files, so a
split by slice makes one team wait on the other. Use the first path segment of the module (for
example `task_management` for team A, everything else for team B), across all slices. Write it down in
a file both teams read (see [../templates/TEAM_SPLIT.md](../templates/TEAM_SPLIT.md)):

- ownership table: team, seats, contexts, number of `todo` rows;
- each team edits only its own rows in the ledger, with a targeted edit after re-reading it;
- never edit the other team's files; shared files (`go.mod`, helpers) are add-only;
- checkers check only their own team's rows;
- the end-to-end test runs once, by one named seat, when both teams have no `todo` rows.

Put the same rules in `CULTURE.md` so a restored rig has them. Running seats read `CULTURE.md` only at
launch, so also tell them (chapter 8.4) and point them at the shared file.

**Do not copy permissions between culture files.** The old `agy` culture authorized a production
deploy; that did not carry over to the new combined rig. Authorizations are per rig and per user
decision: write them again deliberately or leave them out.

**Each owner leads workers.** See chapter 9.0: the owner is the team leader and the DeepSeek jobs are
its workers; the checker reviews the leader.

## 8.7 Check

- `culture_file` resolves (`rig spec preflight rig.yaml`).
- Your mission has a ledger and a stop condition.
- Each running seat's transcript contains your latest section title.

Next: [chapter 9 — DeepSeek offload workflow](09-deepseek-offload-workflow.md).
