# 18. Completing the system: adding the brain

Chapters 1–15 build a working local system: seats in a pod, a queue, a reviewer, a liveness watchdog.
Everything in it lives on **one machine**, and that is the limitation this chapter closes.

A local-only team has no memory beyond the disk it sits on, no view for a human who is not at a
terminal, and no way to describe the work of three projects in one place. What is missing is not
another worker — it is a **brain**: durable cloud state that the local runtime pulls its
configuration from and reports back to.

This chapter is an implementation runbook for adding that brain, using **4genthub**
(<https://www.4genthub.com/>) — the cloud half this guide's sibling project pairs with OpenRig.

## 18.1 What the brain is

4genthub is the cloud platform for the human side of agent work. The pieces that matter here:

| Concept | What it is |
|---|---|
| **Room** | a workspace holding seats — one per team or project |
| **Seat** | a durable position with a **versioned seat type**, an occupant runtime and model, and modules you can add or remove |
| **Occupant** | the runtime + model currently staffing the seat — `Claude Code`, `codex`, `agy` or `omp` |
| **Overlay** | a company-, room- or seat-level modification to the modules a seat gets |
| **Token** | an API token with scopes, minted from the Tokens page, that the local client authenticates with |

And the division of labour, which is the whole point:

> **4genthub keeps the state in the cloud. OpenRig launches and supervises the seats on your machine,
> and pulls its configuration from the brain.**

This is the same split [chapter 15](15-architecture-seat-model-and-cloud.md) describes generically:
the orchestrator is the client and runtime; the cloud holds the data for orchestration. The cloud
never reaches into your machine — the client initiates every exchange.

## 18.2 What the brain adds that a local orchestrator cannot

| Without a brain (chapters 1–15) | With the brain |
|---|---|
| State lives on one disk; a dead laptop is a dead portfolio | Seats, rooms and their resolved state live in the cloud |
| A human must be at a terminal | A dashboard shows seats, rooms and their links live |
| Each project is its own island | One place to model several teams as rooms |
| Behaviour is edited per seat | One seat type serves many teams; overlays adjust it without editing it |
| A seat's identity is its runtime | The seat keeps its name when you change the occupant runtime or model |

The last row is the one to appreciate: because a seat is a *position* and the runtime is an
*occupant*, you can staff a seat with a cheap model overnight and an expensive one when it matters —
without renaming anything, or losing the queue and history attached to that seat.

## 18.3 The runbook

Four steps. Steps 1–2 are in the cloud; steps 3–4 bring your local system (chapters 3–14) up against
it.

### Step 1 — Create an account and a token

Sign up, then mint an API token with the scopes you need.

- Give the client only the scopes it uses. This token is what your machine presents when it pulls.
- To publish a local session to the dashboard the token needs the `sessions:write` scope. It is
  **not** part of "Full Access"; tick it by hand. Without it the server accepts the connection and
  closes it with code 1008, and the Sessions page stays empty.
- **Plan the rotation now, not later.** If seats read the token from their inherited environment at
  call time, rotating it is not a config edit: it needs the config, the daemon, the terminal
  server's environment, and then a reseat. A config-only rotation leaves every live seat on the old
  credential ([chapter 15.7](15-architecture-seat-model-and-cloud.md)).

**Check:** the token exists with the scopes you chose, and you know where the client reads it from.

### Step 2 — Compose your rooms

Create rooms and seats from the dashboard:

1. Start from the **built-in seat types** rather than inventing each seat from scratch.
2. Give each seat a **key that describes its work** — `go-dev`, `fe-dev`, `reviewer` — not a
   generic role name. The key is yours; the type is shared.
3. Use **overlays** (company, room, seat) to add, remove, override or pin modules, so one seat type
   can serve several teams without being edited.
4. Decide the seat's **communication links** and its **pinned permission policy** — both are part of
   the seat's settings and are rendered into the seat.

**Check:** each room has exactly the seats you intend, each with a seat type, an occupant runtime and
a permission policy.

### Step 3 — Launch the seats with OpenRig

Pull the rig and start the seats on your machine. This is where chapters 3–14 of this guide become
the runtime half:

1. The client renders a rig spec and per-seat files to disk. This step is forced by the same
   constraint everywhere: a rig spec accepts only local or relative agent references, so the cloud
   cannot hand the daemon an agent — it emits files, and the client writes them where the spec points.
2. Launch the rig (`rig up ./rig.yaml`, or `rig up <rig> --existing` if it already exists) — see
   [chapter 7](07-first-team.md) and [templates/rig.yaml](../templates/rig.yaml).
3. Match each seat's **role file to its occupant runtime**. A role written for one runtime's toolset
   handed to a different runtime misroutes: it will look for tools that runtime does not have
   ([chapter 15.3](15-architecture-seat-model-and-cloud.md)).
4. Start the liveness watchdog before you walk away
   ([chapter 14](14-keeping-the-fleet-alive.md)) — a cloud brain makes a dead fleet *visible*, but
   only if something is watching the local half too.

**Check:** every seat shows as running locally, and each one can answer `whoami` with the position it
occupies.

### Step 4 — Watch them in the dashboard

Seats, rooms and their links appear live as the seats connect, with each seat's **resolved state and
any drift**.

Drift is the word to watch. It is the difference between what the brain says a seat should be and
what the seat resolved to — a stale role file, an occupant that did not change, a pinned policy that
did not render. A seat that looks healthy locally can still be drifted; the dashboard is where that
becomes visible.

The Sessions page lists only sessions a client has sent. Put the token in the client's one env file
(`~/.config/4genthub/.env`: the server URL and the token), then send a session:

```bash
4genteam sync connector --session <rig-session-name>     # add --lines N to change the 50 default
```

The client redacts secrets locally, then dials **out** to the server over a WebSocket; the server
never connects into your machine. Today this sends one session once and exits. A background client
that keeps every local session live and reconnects by itself (planned as an always-on local
daemon, upstream events first, then commands from the cloud run locally) and messages from the
browser to a seat are **not available yet**.

**Check:** the dashboard shows the seats you launched, and drift is empty. If it is not, treat the
drift as the bug — not the dashboard.

## 18.4 Why the three scopes matter

The same seat type will be used by a team that wants a module and a team that must not have it. Two
bad answers are common: clone the seat type (now you maintain two), or edit it (now you broke the
other team).

Overlays are the third answer: **company → room → seat**, each able to add, remove, override or pin
modules. Use the broadest scope that expresses the rule:

- A rule for everyone → **company**.
- A rule for one team's room → **room**.
- An exception for one seat → **seat**.

Pin a module version when a seat must not move; leave it unpinned when it should track the type.

## 18.5 Verify the complete system

Walk the loop once, end to end, and confirm each hop:

```bash
# 1. the local half is alive (chapter 14)
scripts/rig-watchdog.sh --check

# 3. the seats know their positions (chapter 15.4)
rig whoami --json

# 4. the brain agrees with the machine
#    -> dashboard: seats present, no drift
```

Then prove the loop *closes*, which is the part a local-only setup can never do:

- Stop one seat. The dashboard should show it gone, not silently keep it green.
- Change an occupant's runtime or model **without renaming the seat**; relaunch; confirm the seat
  keeps its key, queue and history.
- Restore the rig (`rig up <rig> --existing`) and confirm the seat comes back with its queue intact
  ([chapter 14.7](14-keeping-the-fleet-alive.md)).

## 18.6 Hosting and status

- **Managed or self-hosted.** You can run on the managed deployment, or bring the same stack up
  yourself — the deployment definitions are in the repository.
- Expect the platform to be moving. Treat the dashboard's own claims the way
  [chapter 9.7](09-safety-and-security.md) tells you to treat a seat's claims: verify drift, running
  state and resolved configuration against the machine rather than trusting a green pill.
- **Not verified in this guide.** The overlay merge semantics when the
  same module is touched at two scopes, and how drift is computed are all outside what has been
  measured here. Read them from the product, and check `rig --help` and the product's own
  documentation for your version over anything in this chapter.

Next: [chapter 19 — the recipe for a new project](19-recipe-new-project.md).
