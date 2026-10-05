# 15. The architecture this converges to

Chapters 1–14 teach a pattern: a few seats in tmux handing work to each other, with a cheap model
doing the bulk typing. That pattern works, and it is not where this ends.

This chapter describes the shape a long-lived setup converges into: a **seat model** with a swappable
brain, and a split between a local runtime and a cloud that holds the portfolio. It is written
generically — the ideas port to any orchestrator plus any cloud service you point at it.

## 15.1 The split, in one line

> **The orchestrator is the client and the runtime. The cloud holds the data for orchestration.**

- The cloud stores **agents, rigs (topology), tasks, contexts and the state the client reports**.
- The orchestrator **launches and supervises seats** on your machine.
- **Pull model**: the client initiates every exchange. The server never reaches into your machine.
  Remote commands are the one exception, and they are opt-in.

Why split it at all: the orchestrator is a *local* concern — processes, sockets, terminals, your
credentials — while the portfolio is a *shared* concern: who works on what, what is blocked, what
shipped. Conflating the two is what makes agent setups feel unmanageable once there is more than one
of them.

## 15.2 The physical layers

```
owner / principal session       <- the human's own agent session; the only thing they talk to
  |  send | launch | attach
  v
orchestrator daemon             <- a local process on a loopback port, with a local database
  |  creates and supervises
  v
terminal sessions               <- named <rig>-<seat>@<rig>  (e.g. my-team-go-dev@my-team)
  |
  v
runtime processes               <- whichever agent runtimes your orchestrator supports
```

The daemon's database is the durable half of all this: rig topology (`rigs`, `pods`, `nodes`),
`snapshots`, `sessions`, the work ledger (`queue_items`, `queue_transitions`) and usage samples. That
is *why* a seat can die and come back with its queue intact, and why "down" is a lifecycle state
rather than data loss — restoring from a snapshot lets each seat resume its own session file
([chapter 14.7](14-keeping-the-fleet-alive.md)).

It is also the forensic record: the daemon's `events` table is the authoritative timeline of anything
that happened to a seat, and it will out-explain any log file you keep
([chapter 12](12-troubleshooting.md)).

## 15.3 What a seat is: a position and an occupant

This distinction is the core of the model, and it is what lets you swap brains without losing work.

| Half | Durable? | What it is | Example |
|---|---|---|---|
| **Position** | yes | the key in the rig spec, plus its edges and permission policy | `my-team.go-dev` |
| **Occupant** | swappable | the runtime + model sitting in it right now | a cheap model, or an expensive one |

A seat's behaviour comes from its role files on disk, delivered to it as startup text. **The role file
is the unit of work**: an unguided seat flails, and a role written for one runtime's toolset handed to
a different runtime misroutes — it will look for tools that runtime does not have. Match the role to
the runtime, or expect a confused teammate.

## 15.4 Identity first

Whatever your orchestrator's equivalent of `whoami` is, run it before anything else, and re-run it
after any compaction, restart or restore. A startup overlay can be stale, and a seat that does not
know which position it occupies will do the wrong job confidently.

The same instinct as [chapter 14.1](14-keeping-the-fleet-alive.md): ask the thing that knows, not the
thing that remembers.

## 15.5 Rooms, seats and seat types

Three levels, and keeping them apart is the whole point:

| Level | What it is | Example |
|---|---|---|
| **Room** | the workspace that holds seats | `my-room` |
| **Seat** | a named position in that room — **the key is yours to choose** | `go-dev`, `web-dev`, `architect` |
| **Seat type** | the reusable behaviour that seat points at, pinned to a version | `developer`, `architect` |

**The seat key and the seat type are different things.** Two seats — `go-dev` and `web-dev` — can
point at the *same* seat type and differ only in their name, their role file and their queue. The key
is custom; the type is shared. That is what lets a project name its seats after its own work
(`go-dev`, `skills-dev`, `feedback-dev`) without inventing a new behavioural type for each one.

**Seat types are not a fixed list.** A well-built cloud ships a small *seed set* — a handful of
general roles like implementer, reviewer, planner, researcher, writer — and then treats the set as
yours:

| Want to | Your cloud needs |
|---|---|
| Load the shipped set | a "seed the defaults" operation, per account |
| Create your own | per-user seat-type records, unique on user + slug |
| Change one safely | **versioned** types: publishing a new version sets default runtime and module
  references, and each seat pins the version it uses |

That last row is the one worth insisting on. Because a type is a versioned record rather than a
constant, you can evolve "developer" for new seats while an in-flight seat stays pinned to the older
behaviour — and a migration never has to freeze the whole team.

What you should *not* build is a large fixed library of per-agent templates. If a seat's behaviour
needs to change, that belongs in its type version or its role file, not in a lookup table that
duplicates both.

Rules that follow:

- Never assume a seat has a capability another seat type has; read the seat's rendered files first.
- If you need something your seat lacks, **route the work** to a seat that has it, or repoint the
  seat at a different type version.
- Do not build a config-injection proxy between seats. Each seat should receive its own role file at
  launch and reach shared tools itself.

## 15.6 How work moves

```
owner → lead seat → dev seats → reviewer → lead → owner approves
```

The ledger carries an owner and a state per item: `pending`, `claimed`, `handed-off`, `blocked`,
`done`. Two rules make it safe when several seats share one working tree:

- Seats **commit locally, stage by explicit path, and never push**.
- **A reviewer is the gate**, so "done" means a second seat verified it — not that a seat said so.

The owner approves every push. If a push deploys production, make that rule absolute rather than a
default; it is the one action that is expensive to take back.

## 15.7 Where the two halves meet

Only through client-side scripts that hold a cloud token. They pull seat and room definitions from the
cloud, **render the rig spec and seat files to disk**, and push back what the client observed (seat
status, sessions, usage).

The rendering step is usually forced by a constraint worth knowing: rig specs tend to accept only
local or relative agent references, so the cloud cannot hand the daemon an agent directly — it emits
files and the client writes them where the spec points.

One consequence to plan for: **if seats read the token from their inherited environment at call time,
rotating it is not a config change.** It needs the config, the daemon, the terminal server's
environment, and then a reseat. A config-only rotation leaves every live seat on the old credential.

## 15.8 A real rig, in full

[../templates/rig-omp-10-seats.yaml](../templates/rig-omp-10-seats.yaml) is a ten-seat team: one
runtime, one model, one pod, a lead with `delegates_to` and `escalates_to` edges to nine specialists,
and `collaborates_with` edges between peers. Copy it, change the seat keys, and point the agent
references at your own role directories.

Note what is *not* in it: no cloud, no credentials, no prompts. The spec describes **positions**. The
behaviour lives in the role files, and the work lives in the ledger.

## 15.9 What this changes about chapters 1–11

Read these as corrections, not footnotes:

| Earlier chapters | What a long-lived setup does instead | Why it changed |
|---|---|---|
| A cheap model reached through an **MCP offload** the seats call as a tool | The cheap model as a **runtime occupant** — a peer seat with its own role file | An offload job is fire-and-forget; a seat holds context, takes a queue item and can be reviewed like anyone else |
| Owner + checker, fanning out to workers | A **pod of ~10 seats** with an explicit lead and reviewer | Coordination moves into the topology (edges) instead of into prompts |
| A **config-injection proxy** because only the principal session has tool access | Every seat receives its own role file and reaches shared tools itself | The proxy was a workaround for a limitation that no longer exists |
| A large **template library** to look agents up | **Versioned seat types** you own, plus a seat key you choose | Templates duplicated what the role file should say once |
| Seats named from a fixed list of roles | **Seat keys are yours** (`go-dev`, `skills-dev`) pointing at a shared type | The seat name should describe its work, not its place in a taxonomy |
| Scale by adding seats | Scale by **swapping occupants** — keep the position, change the brain | Positions carry the queue, the edges and the history; a new occupant inherits all of it |

## 15.10 Not verified

- Your orchestrator's internal reconciliation logic, and how it computes a resolved spec hash — you
  generally have only its CLI behaviour and its database.
- The cloud's rendering step depends on the client scripts you actually run; read them rather than
  assuming the shape above.
- Whether an occupant swap preserves an in-flight turn. It is usually documented as switching runtime
  and model; assume it wants a turn boundary until you have measured it.

Next: [chapter 16 — completing the system](16-completing-the-system-the-brain.md).
