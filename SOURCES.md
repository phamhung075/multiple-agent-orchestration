# Sources

Every component this guide uses, where it comes from, and the version checked on the author's
machine (WSL2 Ubuntu, 2026-10-01). **Verified** = run locally; **upstream** = taken from the project's
own documentation.

## Core software

| Component | What it is | Source | Version checked |
|---|---|---|---|
| **OpenRig** (`rig`) | Orchestrator: teams of agent seats, durable queue, watchdogs, TUI | npm `@openrig/cli` · https://github.com/mvschwarz/openrig · https://openrig.dev | 0.6.3 (verified, linked from a local clone) |
| **Claude Code** | Anthropic coding agent CLI (runtime for seats) | npm `@anthropic-ai/claude-code` | 2.1.287 (verified) |
| **Antigravity CLI** (`agy`) | Google agent CLI, a second runtime OpenRig supports | installed at `~/.local/bin/agy` | 1.2.14 (verified) |
| **Gemini CLI** | Google Gemini coding CLI (optional) | npm `@google/gemini-cli` | 0.60.0 (verified) |
| **herdr** | Terminal workspace manager for agents; OpenRig's default terminal provider | `~/.local/bin/herdr` (`herdr update` self-updates) | 0.9.3 (verified) |
| **tmux** | Terminal multiplexer that holds most seats | distro package | 3.4 (verified) |
| **DeepSeek Harness** (`dsh`) | Agent runtime that runs the DeepSeek workers and a web GUI | npm `@deepseek-ai/dsh` · https://github.com/deepseek-ai/deepseek-harness | 0.1.7-rc.2, developer preview (verified from a source checkout) |
| **deepseek-offload** | MCP bridge + background runner that hands jobs to `dsh` | https://github.com/phamhung075/deepseek-offload | local clone (verified) |
| **Node.js** | Runtime for `rig`, `dsh` and the bridge | https://nodejs.org | v24.21.0 (verified); OpenRig needs 22 or 24 |
| **Go** | Target language of the case-study migration | https://go.dev | 1.23.5 (verified) |

## Upstream documents used

| Document | Location |
|---|---|
| OpenRig README (install, first run, what changes on your machine) | `openrig/README.md` |
| OpenRig getting started | `openrig/docs/reference/getting-started.md` |
| OpenRig permission policies (`yolo`, `standard`, `open`, `locked`) | `openrig/packages/daemon/policies/builtin/*.policy.md` |
| OpenRig shipped rig specs (starters, kernel) | `openrig/packages/daemon/specs/rigs/` |
| OpenRig compaction skill | `rig context get skills/claude-compaction-restore` |
| deepseek-offload README, INSTALL runbook and SKILL | `deepseek-offload/README.md`, `INSTALL.md`, `.agents/skills/deepseek-offload/SKILL.md` |
| DeepSeek Harness README, development guide, safety notice | `deepseek-harness/README.md`, `docs/development.md`, `SAFETY.md` |

Use `rig context list` and `rig context get <ref>` to read the version of the OpenRig skills that
matches your installed CLI.

## Local layout on the author's machine

| Path | Role |
|---|---|
| `~/__projects__/openrig` | OpenRig source clone (the global `rig` is linked to `packages/cli`) |
| `~/__projects__/deepseek-offload` | The bridge and runner |
| `~/__projects__/deepseek-harness` | DeepSeek Harness checkout |
| `~/__projects__/4genthub` | The project being migrated (case study) |
| `~/__projects__/4genthub/agenthub_go` | The Go port (module `agenthub`) |
| `~/.openrig/` | OpenRig instance state: database, config, logs, `specs/`, `workspace/` |
| `~/.openrig/specs/<team>/` | Team specs and the team's private files (never committed) |
| `~/.dsh/` | DeepSeek Harness home: `profiles/`, `sessions/`, `plugins/` |
| `~/.claude/projects/<project>/<session>.jsonl` | Claude Code transcripts (the evidence we used to audit seats) |
| `~/.wslconfig` (Windows side) | WSL2 memory limit |

## Project sources of the case study

| Item | Source |
|---|---|
| Python server (`fastmcp` package, FastAPI + SQLAlchemy + Keycloak), replaced by the Go port; the source of the case study | `4genthub/agenthub_main/src/fastmcp` |
| Go port | `4genthub/agenthub_go` (ledger: `MIGRATION.md`) |
| Team spec and culture | `4genthub/rig.yaml`, `4genthub/CULTURE.md` |
| Remote | `git@github.com:phamhung075/4genthub.git` |

## Where each idea in this guide comes from

| Idea | Origin |
|---|---|
| Rigs, seats, pods, queue, watchdog, `rig send/capture/up/down` | OpenRig docs and `--help` (verified) |
| `permission_policy: builtin:yolo` ⇒ `--dangerously-skip-permissions` | OpenRig policy files and README, confirmed with `ps` on running seats |
| Standing mission in `CULTURE.md`, compaction rule, offload rules | Written by the author during the case study (chapters 10–12) |
| Wave-based DeepSeek porting (`w5-*`, `w6-*`) | Observed in the owner seat's transcript and `dsh-offload.mjs list` |
| Troubleshooting entries | Each one was hit during the run (chapter 23) |
| Chapter 14: liveness probe, server-identity heartbeat, crash forensics | Diagnosed 2026-10-05 from `~/.openrig/openrig.sqlite`'s `events` table, the seats' session files and `dmesg`; `scripts/rig-watchdog.sh` verified locally (self-test, a live healthy fleet, and stopped/unknown rigs) |
| The omp "read-only seat" entry in chapter 23 | Measured 2026-10-05 on a relaunched `omp` seat: every `write`/`edit`/`bash` denied by the operator-approval path |
| Chapter 15: position vs occupant, rooms/seats/seat types, the cloud/client split | Read live from a cloud service's seat listing — where the seat **key** and the seat **type** are separate fields, so two seats can share one type — and from a backend that stores seat types as per-user records with their own versions. Described generically in the chapter; the specific endpoints are not reproducible from this guide |
| Chapter 18: the brain (rooms, seats, modules, overlays, the four-step flow) | **4genthub** (https://www.4genthub.com/), the cloud half this guide pairs with OpenRig. Feature and flow wording is taken from the project's own landing page (`agenthub-frontend/src/pages/LandingPage.tsx`), which was rewritten to claim only what ships. The runbook's checks and the rotation caveat come from chapters 14–15 of this guide |

## Not verified

- How to install `herdr` and `agy` from scratch: they were already installed. Use each project's
  own install instructions.
- Behavior of `rig send --raw … --wait-for-idle` as a self-compact trigger: written and sent to the
  seats, but not observed end to end.
- Auto permission mode (`rig seat set-permissions --mode auto`): requested, result not read back.
- Giving each rig its own tmux socket (`-S`/`-L`) so a server event costs one rig (chapters 9.8 and
  14.6): proposed from reading OpenRig's tmux adapter, **not implemented or tested here**. As of
  0.6.4 every rig shares the default socket.
- The **trigger** of the 2026-10-05 fleet loss: the mechanism is verified (the server went first; the
  panes took `SIGHUP` inside a 215 ms window), the trigger is still unattributed. Do not read chapter
  14 as a closed case.
