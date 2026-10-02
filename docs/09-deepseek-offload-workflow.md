# 9. The DeepSeek offload workflow

The pattern that moved most of the typing off the expensive model: **waves of background workers,
reviewed by the owner and the checker.**

```
 owner (Claude)                         DeepSeek workers (dsh)             checker (Claude)
 ──────────────                         ──────────────────────             ────────────────
 pick N todo modules ──write prompts──▶  w6-01 … w6-09 run in parallel
 launch wave (--detach)                  each writes only new files
 review wave w5 (diff vs source, build)◀─ report (≤300 words)
 fix, mark ledger rows done ───────────────── queue handoff ─────────────▶ review slice
 launch next wave                                                          verdict on the queue
```

## 9.0 The ladder: owner leads, workers do

Each team is a ladder. The **owner** is the team leader; the **DeepSeek jobs** are its workers; the
**checker** reviews the leader's integrated output. The owner plans a slice, splits it into
self-contained module jobs, starts them all (`--detach`), reviews each result against the source while
the rest run, then queues the slice to the checker. Writing code by hand is for design-heavy modules,
for a job that failed the build twice, or when the workers are unavailable. Delegation is the default
for mechanical work, not an option the seat may skip.

Stating this once in `CULTURE.md` was **not enough** (2026-10-02): seats busy in a long turn, or in the
middle of a compaction, never acted on it. What worked better: an imperative message naming the exact
command and the exact rows ("start one detached job per module for the next 5–8 todo rows, report the
job ids"), plus checking that jobs exist (9.7).



| | In-session subagent | DeepSeek job |
|---|---|---|
| Cost to the calling seat | Its tokens count in your context | You pay only for the prompt and the short report |
| Parallelism | A few | Many (the case study ran 4 at a time, 9 prompts per wave) |
| Memory of your conversation | Can inherit it | None: the prompt must be self-contained |
| Good for | Quick questions | Bulk mechanical work with a build/test check |

Rule of thumb from the skill: if the work produces more intermediate text than final text, offload it.

## 9.2 What to offload, what to keep

| Offload | Keep in the expensive model |
|---|---|
| Mechanical ports of self-contained modules | Design decisions, anything needing the conversation's context |
| Repo-wide audits, greps, "find every place X" | Git operations, merges, pushes |
| Reading long logs or test output | Secrets, credentials, production access |
| Drafting docs, translations | The review and the final "done" decision |

## 9.3 The shared prompt (`common.md`)

Write one file with the hard rules, then append the module list per job. A real example shape
([../templates/dsh-prompt-common.md](../templates/dsh-prompt-common.md)):

```markdown
You are porting Python modules of <project> to Go, as a drafting worker. Work in <repo path>.

HARD RULES
- Write ONLY under <new dir>/. Never edit existing files. Never edit the ledger, go.mod or go.sum.
- No git commands that write, no commit, no push. Never read or print .env files, tokens or credentials.
- Same behavior as the Python, keep quirks (including bugs), one .go file per .py module.
- Reuse existing Go code (helpers listed here: ...); do not duplicate it.
- If a module is framework-specific with no meaning in the target, write nothing and say why.
- Add focused tests with expectations taken from reading the source.
- Finish by running: gofmt -l . && go build ./... && go vet ./... && go test ./<your pkgs>/...
  Report ONLY what you ran and observed: files created, behavior you could not port, anything
  unverified. Under 300 words.

YOUR MODULES:
```

Then one file per job: `scratch/dsh-prompts/w6-01.md` = `common.md` + a list of modules.

## 9.4 Launch a wave

```bash
R=.agents/skills/deepseek-offload/scripts/dsh-offload.mjs
P=scratch/dsh-prompts
for n in 01 02 03 04; do
  node $R start "$(cat $P/w6-$n.md)" --cwd "$PWD" --label w6-$n --detach
done
node $R list              # watch states: running → done
```

Keep a wave running while you review the previous one.

## 9.5 Following and steering

```bash
node $R status <jobId>
node .agents/skills/deepseek-offload/scripts/session-tail.mjs <jobId> --watch
node $R update <jobId> "Also skip modules that already exist."
node $R cancel <jobId>
node $R result <jobId>
```

The web GUI at `http://127.0.0.1:3080` lists the session under your project folder but **cannot show
a running job**. Do not prompt a job's row in the GUI.

## 9.6 The review gate (non-negotiable)

A worker's report is a draft. Before a ledger row is marked `done`:

1. Read the diff against the source module.
2. Run the build, vet and tests yourself (`gofmt -l . && go build ./... && go vet ./... && go test ...`).
3. Fix what is wrong (the expensive model, not another job, unless it is mechanical).
4. A job that fails the build twice is finished by hand.
5. The checker reviews every slice independently and records a verdict on the queue.

Never trust "tests pass" from a worker. Never put credentials or production details in a prompt.

## 9.7 Pitfalls we hit

| Symptom | Cause | Fix |
|---|---|---|
| Seats had DeepSeek attached but never used it | Nothing told them to | Add the offload section to `CULTURE.md` **and** message the seats (chapter 8) |
| Told to delegate, still no jobs | Message sat in the seat's queue behind a long turn, or was lost in a compaction | Look for jobs, not words: `node $R list \| grep job-$(date -u +%Y%m%d)`; resend an imperative, specific order (9.0) |
| Every job ends `error` in seconds, `Insufficient Balance` | The DeepSeek account has no credit | Top up, then prove it with a tiny job: `node $R start "Reply OK" --read-only --json` must end `done`. Tell seats not to retry in a loop |
| Count of `mcp__deepseek__*` calls is 0 but jobs exist | The owner used the runner from Bash, not the MCP tool | Count Bash calls to `dsh-offload.mjs`, and `node $R list` |
| Two jobs wrote the same file | Overlapping module lists | One module or one small group per job; skip files that already exist |
| Job edited unrelated files | The prompt did not forbid it | Keep the "write only under X" rule; the checker's diff review catches it |
| A worker failed to build | Missing helper | Tell it which helpers to reuse; finish by hand after two failures |

## 9.8 Cost control

- `node $R window` shows DeepSeek's peak and off-peak pricing; `start --defer-to-off-peak` schedules
  batch work at the cheaper time.
- Model choice: `deepseek-flash` (default) or `deepseek-v4-pro` via `install.sh --model`.

## 9.9 Check

You can launch a wave of three jobs, see them `done` in `node $R list`, and mark one row `done` only
after you read its diff and ran the build.

Next: [chapter 10 — token economy](10-token-economy-and-compaction.md).
