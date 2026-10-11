# 01. How It Works: The 3-Tier Split

A robust multi-agent orchestration architecture avoids running everything in a tangled local loop. It cleanly splits into three distinct tiers:

```
[ Tier 1: Cloud Brain ]
   4genthub (Web UI & MCP Server)
      - Tasks, boards, roles, portfolio, and cost telemetry
      - Never runs models directly; acts as shared record of truth
             ▲
             │ Dials OUT (Outbound HTTPS only)
             │
[ Tier 2: Machine Client ]
   4genteam (Unified CLI & Background Services)
      - Starts and syncs rigs
      - Delivers skills and enforces isolated git worktrees
      - Runs token compaction supervisor and live terminal feeds
             │
             ▼ Local Unix Sockets / HTTP
[ Tier 3: Local Orchestrator ]
   OpenRig Daemon + Runtimes (Claude, agy, omp, dsh)
      - Supervises seat processes in isolated tmux/herdr panes
      - Delivers persistent queue items and inter-seat messaging
```

---

## The Three Core Principles

### 1. Zero Inbound Ports
The orchestrator on your local machine **only makes outbound connections** to the cloud brain. No public IPs, no open ports, and no external entity can execute unauthorized code on your machine.

### 2. Position vs. Occupant
A **Seat** is an engineering role (e.g. `lead`, `architect`, `go-dev`, `reviewer`) with:
- Dedicated worktree and branch
- Assigned task queue
- Persistent memory and guidelines

An **Occupant** is the AI model running in that seat (e.g., Claude 3.7 Sonnet, DeepSeek Flash, Gemini Pro).
You can swap an expensive model for a cheap model without renaming the seat, losing queue history, or altering git branches.

### 3. Queue and Files Over Ephemeral Chat
Agent chat logs are ephemeral and blow up context limits. In this system:
- **Tasks and handoffs** live in durable queue items (`qitems`) or 4genthub board tasks.
- **Architectural rulings and guidelines** live in markdown documentation files on disk.
- When an agent crashes, restarts, or compacts, its mission is immediately restored from disk and queue state.

---

Next: [02 — Seats and Worktree Isolation](02-seats-and-worktrees.md)
