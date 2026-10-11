# Multiple-Agent Orchestration

> **Run an autonomous, self-improving team of AI coding agents on your own machine, on any project.**

Agents work concurrently in isolated Git worktrees, hand off tasks through a durable queue, offload bulk boilerplate to cheap models, and monitor token usage via automated compaction.

---

## ⚡ 5-Minute Quickstart

### 1. Install Tooling
```bash
# 1. Orchestrator
npm install -g @openrig/cli
rig setup --dry-run && rig setup

# 2. Unified Client
# (Build from agenthub_client repo into your PATH)
go build -o ~/.local/bin/4genteam agenthub_client/cmd/4genteam
```

### 2. Define Your Team (`rig.yaml`)
In any project repository:
```yaml
version: "openrig/v1"
rig: "dev-team"

nodes:
  - name: dev
    runtime: claude-code
    model: claude-3-7-sonnet
    cwd: "."

  - name: reviewer
    runtime: claude-code
    model: claude-3-7-sonnet
    cwd: "."
```

### 3. Launch and Watch
```bash
# Start the team & provision worktrees
4genteam up dev-team

# Send a mission
4genteam send --from owner dev-team dev 'Write a factorial utility with tests. Record a queue item when done.'

# Stream live tool execution with word-wrapped output & token meters
4genteam feed --rig dev-team --detail
```

---

## 🏗️ Architecture: The 3-Tier Model

```
[ Tier 1: Cloud Brain ]
   4genthub (Web UI & MCP Server)
      - Tasks, boards, roles, portfolio, and cost telemetry
             ▲
             │ Outbound HTTPS only (Zero Inbound Ports)
             │
[ Tier 2: Machine Client ]
   4genteam (Unified CLI & Background Services)
      - Provisions isolated git worktrees per seat (wt/<seat>)
      - Runs token compaction supervisor and live terminal feeds
             │
             ▼ Local Sockets
[ Tier 3: Local Orchestrator ]
   OpenRig Daemon + Runtimes (Claude Code, agy, omp, dsh)
      - Supervises agent sessions in tmux / herdr panes
      - Keeps persistent queue items (qitems) and routes messages
```

---

## 📚 Documentation Map

The documentation is organized into four clear stages:

### [1. Getting Started](docs/01-quickstart/01-prerequisites.md)
* [01. Prerequisites](docs/01-quickstart/01-prerequisites.md) — Node, Go, OpenRig, and runtime authentication.
* [02. Five-Minute Team](docs/01-quickstart/02-five-minute-team.md) — Up and running with a 2-seat team.
* [03. Daily Operations](docs/01-quickstart/03-daily-operations.md) — Common commands cheat sheet (`up`, `send`, `watch`, `compact`).

### [2. Core Concepts & Mental Model](docs/02-architecture-and-mental-model/01-how-it-works.md)
* [01. How It Works](docs/02-architecture-and-mental-model/01-how-it-works.md) — The 3-tier split and zero-inbound security.
* [02. Seats & Worktree Isolation](docs/02-architecture-and-mental-model/02-seats-and-worktrees.md) — Why seats never share a git working tree.
* [03. The Durable Work Queue](docs/02-architecture-and-mental-model/03-the-durable-queue.md) — Task lifecycles and handoffs that survive crashes.
* [04. Safety & Guardrails](docs/02-architecture-and-mental-model/04-safety-and-guardrails.md) — The Git Guard contract and push bans.

### [3. Production Performance](docs/03-production-performance/01-live-monitoring-watch.md)
* [01. Live Monitoring & Watch](docs/03-production-performance/01-live-monitoring-watch.md) — Real-time terminal feeds and multi-pane grids.
* [02. Self-Compaction](docs/03-production-performance/02-self-compaction.md) — Automated context supervisor preventing context blowups.
* [03. Cheap Worker Offload](docs/03-production-performance/03-deepseek-offload.md) — DeepSeek background workers and off-peak gates.
* [04. Self-Improving Team](docs/03-production-performance/04-self-improving-team.md) — The seat friction loop and the Autonomy Charter.

### [4. Playbooks & Reference](docs/04-reference-and-playbooks/new-project-recipe.md)
* [New Project Recipe](docs/04-reference-and-playbooks/new-project-recipe.md) — End-to-end checklist for adding the stack to any project.
* [Troubleshooting Catalog](docs/04-reference-and-playbooks/troubleshooting-catalog.md) — Symptom $\rightarrow$ Cause $\rightarrow$ Resolution table.

---

## 🔒 Safety & Rules of Thumb

1. **Worktrees over Shared Checkouts:** Never allow multiple agents to write in the same folder. Each seat operates in `wt/<seat>`.
2. **Queue over Ephemeral Chat:** If work or context must survive restarts, store it as a queue item or markdown doc.
3. **Expensive Plans, Cheap Drafts:** Use top-tier models (Claude Sonnet, Opus) for planning and review; offload bulk boilerplate to cheap models (DeepSeek).
4. **Humans Push, Agents Commit:** Agents commit locally with pathspecs. Only human operators approve pushes to remote branches.
