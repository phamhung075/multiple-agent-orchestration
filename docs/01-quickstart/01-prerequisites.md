# 01. Prerequisites

Before running your first AI dev team, ensure your machine has the necessary baseline tools installed and authenticated.

## 1. Supported Systems

- **Linux** (Ubuntu 22.04+ or Debian 12 recommended)
- **macOS** (Apple Silicon or Intel)
- **Windows via WSL2** (Ubuntu under WSL2 works identically to native Linux)

## 2. Core Toolchain

You need three fundamental system utilities:

| Tool | Purpose | Install Command |
|---|---|---|
| **Node.js 20+** | Runs OpenRig orchestrator and TypeScript tools | `nvm install 20` or via system package manager |
| **Go 1.22+** | Builds and runs the `4genteam` client | `sudo apt install golang` or from `go.dev` |
| **tmux & herdr** | Terminal multiplexers for seat workspaces | `sudo apt install tmux` |

### Installing `herdr`
`herdr` provides structured, multi-pane workspaces and terminal windowing for live observation:
```bash
# If installed via npm or GitHub release:
npm install -g herdr
```

## 3. The Orchestrator: OpenRig (`rig`)

OpenRig is the background daemon that manages seats, executes queue handoffs, and routes inter-agent messages.

```bash
npm install -g @openrig/cli
rig setup --dry-run
rig setup
```

Verify that the OpenRig daemon is running:
```bash
rig ps
```
*If the daemon is not running:* start it with `rig daemon start`.

## 4. The Unified Client: `4genteam`

The `4genthub` client (`4genteam`) controls room synchronization, seat worktrees, token monitoring, automated compaction, and live watch feeds.

Install `4genteam` into your local binary path:
```bash
# From the agenthub_client repository:
go build -o ~/.local/bin/4genteam ./cmd/4genteam
```
Verify installation:
```bash
4genteam --help
```

## 5. Agent Model Credentials & Runtimes

Each seat is powered by an agent runtime. Authenticate the runtimes you intend to use:

- **Claude Code:**
  ```bash
  claude auth login
  ```
- **Gemini / Antigravity (`agy`):**
  Ensure your `GEMINI_API_KEY` or Google Cloud credentials are configured.
- **DeepSeek (for cheap worker offloading):**
  Store your API key securely in `~/.config/4genthub/.env` or `~/.env`:
  ```bash
  DEEPSEEK_API_KEY=your_key_here
  ```

---

Next: [02 — Launch your first 2-seat team in 5 minutes](02-five-minute-team.md)
