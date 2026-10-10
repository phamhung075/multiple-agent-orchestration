# Multiple-Agent Orchestration

How to run a team of AI coding agents on your own machine, on any project. The agents work in
parallel, hand work to each other through a queue that survives restarts, and can be staffed with a
cheap or an expensive model without renaming anything.

The guide builds one system from five tools:

| Tool | Job |
|---|---|
| **OpenRig** (`rig`) | Starts the team from a YAML file, keeps the queue, routes messages |
| **herdr and tmux** | The terminals the agents run in, and one window that shows all of them |
| **deepseek-offload** | Lets an agent give bulk typing to a cheap model in the background |
| **Self-compaction** | A supervisor that shrinks each agent's context before it fills up |
| **4genthub client** (`4genteam`) | One binary that starts the stack and talks to the cloud |

A sixth part is optional: **4genthub**, a cloud service that keeps rooms, seats and tasks outside
your disk and shows them in a browser.

![Overview: LLMs, agents, skill offload, DeepSeek Harness, OpenRig + herdr](demo.jpg)

It was written from a real run. A team of agents ported a production Python server to Go while a
person watched and steered. The commands were checked on one WSL2 machine.

## Where to start

- **You want it working today:** read [chapter 2](docs/02-blueprint.md), then follow the
  [recipe in chapter 19](docs/19-recipe-new-project.md). It points into the other chapters when you
  need the detail.
- **You want to understand it first:** read the chapters in order. The order is the build order.

## The chapters, in build order

### Part 1. Understand and prepare

| # | Chapter | You will learn |
|---|---|---|
| 1 | [Introduction](docs/01-introduction.md) | The problem, the idea and the vocabulary: rig, seat, pod, queue, offload |
| 2 | [The blueprint](docs/02-blueprint.md) | The finished system on one page, how the parts connect, and the build order |
| 3 | [Prerequisites](docs/03-prerequisites.md) | The machine, accounts and versions you need first |

### Part 2. Install the tools

| # | Chapter | You will learn |
|---|---|---|
| 4 | [Install OpenRig](docs/04-install-openrig.md) | Install `rig` and start the daemon |
| 5 | [Terminals and runtimes](docs/05-terminals-and-runtimes.md) | tmux, herdr, Claude Code and agy, and why a seat may not be where you look |
| 6 | [Install the DeepSeek workers](docs/06-install-deepseek.md) | The DeepSeek Harness and deepseek-offload |

### Part 3. Run a first team

| # | Chapter | You will learn |
|---|---|---|
| 7 | [Your first team](docs/07-first-team.md) | Write a `rig.yaml` and launch two seats |
| 8 | [Daily-use cheat sheet](docs/08-daily-use-cheatsheet.md) | The commands you use every day |
| 9 | [Safety and security](docs/09-safety-and-security.md) | Permissions, secrets and blast radius. Read before the team runs alone |

### Part 4. Make it run for hours

| # | Chapter | You will learn |
|---|---|---|
| 10 | [Culture and the standing mission](docs/10-culture-and-standing-mission.md) | A mission file that survives restarts |
| 11 | [The DeepSeek offload workflow](docs/11-deepseek-offload-workflow.md) | Waves of cheap workers, reviewed before they are accepted |
| 12 | [Token economy and compaction](docs/12-token-economy-and-compaction.md) | Spend fewer tokens, and what to restore after a compaction |
| 13 | [The compaction supervisor](docs/13-self-compaction-supervisor.md) | Compact seats automatically and check that it worked |
| 14 | [Keeping the fleet alive](docs/14-keeping-the-fleet-alive.md) | Notice a dead fleet and recover in a minute |

### Part 5. Scale it and make it reusable

| # | Chapter | You will learn |
|---|---|---|
| 15 | [The seat model and the cloud split](docs/15-architecture-seat-model-and-cloud.md) | Position versus occupant, seat types you own, what runs where |
| 16 | [A standalone client for any project](docs/16-a-standalone-client-for-any-project.md) | Why the client lives outside every project, one credential, one skills tree |
| 17 | [Bootstrapping a new room](docs/17-room-bootstrap-traps.md) | The four traps of a new room and the client that removes them |
| 18 | [Adding the cloud brain](docs/18-completing-the-system-the-brain.md) | Runbook for 4genthub: rooms, seats, tokens, the dashboard |
| 19 | [The recipe for a new project](docs/19-recipe-new-project.md) | The whole system on a new project, step by step, with a check for each step |

### Part 6. Work as a team in one repository

| # | Chapter | You will learn |
|---|---|---|
| 20 | [Working agreements](docs/20-working-agreements-shared-repo.md) | Pathspec commits, one changelog file per change, small docs, batched doc commits |
| 21 | [An A/B room for seat instructions](docs/21-ab-room-for-guide-variants.md) | Test a change to the seats' instructions beside the real team |

### Reference

| # | Chapter | You will learn |
|---|---|---|
| 22 | [Case study: Python to Go](docs/22-case-study-python-to-go.md) | The real migration, step by step |
| 23 | [Troubleshooting](docs/23-troubleshooting.md) | Every problem we hit, with cause and fix |
| – | [SOURCES.md](SOURCES.md) | Every source, repo, package and path this guide relies on |

Chapters 15 to 21 describe the system after months of use. Section 15.9 lists what changed compared
with the simple form taught in chapters 7 to 12, so the early chapters do not mislead you.

## Ready-to-copy files

- [templates/](templates/): `rig.yaml` (two seats), `rig-omp-10-seats.yaml` (a real ten-seat pod),
  `CULTURE.md`, `TEAM_SPLIT.md`, a watchdog reminder, a DeepSeek prompt, an e2e account example and a
  migration ledger
- [scripts/](scripts/): `doctor.sh` (check the machine), `status.sh` (one-screen status of teams and
  migration) and `rig-watchdog.sh` (catch and restore a rig whose seats have vanished)

## The five-minute version

```bash
npm install -g @openrig/cli          # 1. the orchestrator
rig setup --dry-run && rig setup     # 2. prepare the machine
claude auth login                    # 3. log in to the runtime you use
cd ~/my-repo
rig up ./rig.yaml                    # 4. start a team (see templates/rig.yaml)
rig send dev-owner@my-team "Do <one bounded task>. Track it on the queue."
rig ps --nodes --rig my-team         # 5. watch it work
```

After that, follow the [recipe](docs/19-recipe-new-project.md) to add the cheap workers, automatic
compaction, the watchdog and the client.

## Honesty notes

- Commands marked **(verified)** were run on the author's machine. Anything marked **(not verified)**
  comes from upstream docs only. When a tool changes, trust `rig --help` over this text.
- OpenRig 0.6.3 and the DeepSeek Harness (`0.1.7-rc.2`, developer preview) change quickly.
- The brain in chapter 18 is **4genthub** (<https://www.4genthub.com/>), the cloud half this guide
  pairs with OpenRig. Its wording is taken from its own landing page, which was rewritten to claim
  only what ships; the platform is still moving, so trust it over this text.
- No credentials are stored in this guide. [templates/e2e-account.env.example](templates/e2e-account.env.example)
  shows the shape only.
