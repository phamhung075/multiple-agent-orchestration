# Sources & Architecture Components

Every component used in this orchestration stack, its role, upstream source, and documentation pointers.

## 1. Core Software

| Component | What it is | Source / Repo | Role in Fleet |
|---|---|---|---|
| **4genthub Client** (`4genteam`) | Unified CLI client for rooms, git worktrees, watch views, and supervisor | https://github.com/phamhung075/4genthub-client | Starts the stack, provisions worktrees, runs token compaction supervisor, formats live feeds |
| **OpenRig** (`rig`) | Background daemon: seat lifecycle, message transport, durable queue | https://github.com/mvschwarz/openrig · npm `@openrig/cli` | Manages terminal nodes, hosts the local queue database, routes inter-agent messages |
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
~/.openrig/
  ├── daemon.db                     # SQLite database: queue items, sessions, events
  ├── agenthub-seats/<room>/
        └── wt/<seat>/              # Isolated Git worktrees for each active seat
~/.config/4genthub/
  └── .env                          # API credentials (never committed to git)
~/.local/bin/
  ├── 4genteam                      # Unified fleet management binary
  ├── rig                           # OpenRig orchestrator CLI
  └── herdr                         # Workspace window manager
```

---

## 3. Upstream References

- **OpenRig Documentation:** https://openrig.dev
- **4genthub Platform:** https://www.4genthub.com
- **Anthropic Claude Code:** https://docs.anthropic.com/en/docs/agents-and-tools/claude-code
- **DeepSeek Platform:** https://platform.deepseek.com
