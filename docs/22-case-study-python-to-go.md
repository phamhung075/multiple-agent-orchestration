# 22. Case study: migrating a Python server to Go

What actually happened, in order, so you can repeat the pattern on your own project.

## The job

Port the Python server of `4genthub` (package `fastmcp`: FastAPI, SQLAlchemy, Keycloak, MCP/SSE and
WebSocket routes) to Go **for performance**, keeping the same architecture (DDD layers), the same
files, the same API and the same database schema. The Python server must keep working until the Go
one is proven.

## Step 1 — A team with no permission prompts

`rig.yaml` in the project (see [../templates/rig.yaml](../templates/rig.yaml)): an owner and a checker, both
`claude-code`, with `permission_policy: builtin:yolo`.

```bash
rig spec validate rig.yaml
rig up ~/.openrig/specs/4genthub-go/rig.yaml
ps -eo args | grep dangerously-skip-permissions     # both seats show the flag
```

## Step 2 — The brief

A migration brief was sent to the owner as a message (the owner then created its own queue task):

- Same architecture and files; one Go file per Python module under a new `agenthub_go/` directory.
- Same API and schema; do not touch the Python server; do not revert uncommitted user changes.
- Build a ledger first: `MIGRATION.md` with one row per module and a status.

## Step 3 — The ledger

The owner produced `MIGRATION.md`:

```
| Slice | Python module | Go file | Lines | Status |
|---|---|---|---|---|
| 0-shared/config | `config/auth_config.py` | `fastmcp/config/auth_config.go` | 56 | done |
| 0-shared/config | `client/client.py`       | `fastmcp/client/client.go`      | 697 | n/a (FastMCP client SDK; server-only Go runtime) |
| 1-domain        | `agent_management/domain/entities/agent_template.py` | `…/agent_template.go` | 260 | todo |
```

Slice order: `0 shared/config → 1 domain → 2 infrastructure/db → 3 application → 4 server routes/MCP →
5 auth → 6 websocket`. Framework-specific modules with no meaning in Go are marked `n/a` with a reason.
Progress is one command: `grep -c '| todo |' MIGRATION.md`.

## Step 4 — Make the team keep going

Problem: both seats stopped at the end of their turns; the owner waited on the checker and the
checker was idle.

Fixes (chapter 10): a **standing mission** with a stop condition in `CULTURE.md`, "owner never waits
for the checker", and two periodic reminders every 600 s.

## Step 5 — Put DeepSeek to work

The offload section was added to `CULTURE.md` and sent to both seats. The owner started waves
(`w5-20 … w5-34`, then `w6-01 …`) from one shared prompt (chapter 11), reviewed each job's diff and ran
`go build/vet/test`, then marked rows `done`. The checker reviewed slices on the queue.

Audit evidence we used to verify behavior (chapter 8):

```bash
node .agents/skills/deepseek-offload/scripts/dsh-offload.mjs list
grep -c '"name":"mcp__deepseek' ~/.claude/projects/<project>/<owner-session>.jsonl
```

## Step 6 — Testing

When all rows were `done`, the plan was e2e tests of the **Go server only**, using a test account kept
in a private file outside the repo (`~/.openrig/specs/<team>/e2e-account.env`, mode 600), with the
path (not the secret) written in `CULTURE.md`. Template: [../templates/e2e-account.env.example](../templates/e2e-account.env.example).

## Step 7 — Merge only when done

Rule in the culture: **no merge and no push until every row is `done` and e2e is green.** Stage only
the migration files, never the user's unrelated uncommitted changes. (Deployment is outside this guide.)

## What went wrong, and what it taught

| Event | Lesson |
|---|---|
| Seats idle, each waiting on the other | Remove the wait in the culture; add reminders |
| Machine restart killed the tmux server and every tmux seat | Restore with `rig up <rig> --existing`; keep durable state in files |
| Claude hit its usage limit | A second team on `agy` was created; only one team may edit the same files |
| Three rigs for one job | Stop the others' reminders; pick one owner for the code area |
| Day 2: two teams in one rig | Add a pod with `rig expand`; split work by bounded context in `TEAM_SPLIT.md` (chapter 10.6) |
| Day 2: seats written to use DeepSeek, zero jobs | Delegation must be the leader's default and checked by job count (chapters 11.0 and 11.7) |
| Day 2: every DeepSeek job failed, `Insufficient Balance` | Test the worker with a tiny job before blaming the seats; top up |
| `rig up <folder>` and `rig up rig.yaml --existing` failed | `rig up` takes a `.yaml`/`.rigbundle`, or a rig **name** with `--existing` |
| Seat said "No conversation found" on resume | The transcript was gone: `--fresh <seat>` (chapter 23) |
| A new culture section had no effect | Seats read it only at launch: message them |

## Reproduce on your project

1. Chapters 3–6: install.
2. Chapter 7: spec with owner + checker.
3. Ask the owner to build a **ledger** for your job.
4. Chapter 10: mission, stop condition, reminders.
5. Chapter 11: offload waves with the review gate.
6. Chapter 12: compaction rule.
7. Test, then merge when the ledger is clean.

Next: [chapter 23 — troubleshooting](23-troubleshooting.md).
