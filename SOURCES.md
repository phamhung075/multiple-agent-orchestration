# Sources & Architecture Components

Every component used in this orchestration stack, its role, upstream source, and documentation pointers.

## 1. Core Software

| Component | What it is | Source / Repo | Role in Fleet |
|---|---|---|---|
| **4genthub Client** (`4genteam`) | Unified CLI client for rooms, git worktrees, watch views, and supervisor | https://github.com/phamhung075/4genthub-client | Starts the stack, provisions worktrees, runs token compaction supervisor, formats live feeds |
| **Jev** (judge model `jev-1.13.0`) | Decision and task-gate judge, called from the client with `TYPESAFE_API_KEY` | TypeSafe API (`TYPESAFE_BASE_URL`) | Answers `4genteam decide` and gates `4genteam complete`; every outcome is logged locally |
| **agenthub-runtime** | Local Rust engine, built and installed with the client | https://github.com/phamhung075/4genthub-client (`rust/agenthub-runtime`) | Seat lifecycle in headless PTYs, per-room durable queue, message transport, context tracking and forced compaction |
| **4genthub** | Cloud platform & web workspace (optional) | https://www.4genthub.com/ | Portfolio management, shared boards, task tracking, and token cost telemetry |
| **Claude Code** | Anthropic agent CLI runtime | npm `@anthropic-ai/claude-code` | High-capability reasoning, architecture planning, and gate reviews |
| **Antigravity CLI** (`agy`) / Gemini | Google coding agent CLI runtime | Local binary / `@google/gemini-cli` | Agent runtime for seats |
| **DeepSeek Harness** (`dsh`) | Agent runtime for bulk code generation | npm `@deepseek-ai/dsh` | Fast, low-cost parallel code generation |
| **deepseek-offload** | MCP bridge and background runner for `dsh` | https://github.com/phamhung075/deepseek-offload | Background task offloading with peak/off-peak price gates |
| **herdr** | Terminal workspace manager | https://github.com/herdr/herdr | Multi-pane grid windowing for live observation |
| **tmux** | Terminal multiplexer | System package (`apt install tmux`) | Process container for agent terminal sessions |

---

## 2. Directory Layout & State Stores

```
~/.config/4genthub/
  ├── rooms/<room>/
  │     ├── spec.json               # the room as the runtime started it
  │     ├── queue.sqlite            # the room's durable queue and its transitions
  │     ├── seats/ logs/ run/       # seat state, logs, per-seat runtime state
  │     └── wt/<seat>/              # Isolated Git worktrees for each active seat
  ├── .env                          # API credentials and Jev settings (never committed to git)
  └── jev_decisions.log             # Append-only log of every Jev decision and gate outcome
~/.local/bin/
  ├── 4genteam                      # Unified fleet management binary
  └── herdr                         # Workspace window manager
```

---

## 3. Upstream References

- **4genthub Platform:** https://www.4genthub.com
- **Anthropic Claude Code:** https://docs.anthropic.com/en/docs/agents-and-tools/claude-code
- **DeepSeek Platform:** https://platform.deepseek.com
