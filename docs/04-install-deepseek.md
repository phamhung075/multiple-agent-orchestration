# 4. Install the DeepSeek workers

Two pieces:

1. **DeepSeek Harness (`dsh`)** — the agent runtime that talks to the DeepSeek API and has a web GUI.
2. **deepseek-offload** — a small package that lets your Claude/agy seats start `dsh` jobs in the
   background, either through an MCP tool or a shell script.

```
Claude seat ──MCP or Bash──▶ deepseek-offload ──ACP──▶ dsh --profile acp ──▶ DeepSeek API
                                    │
                                    └── files the finished session in the dsh web GUI (http://127.0.0.1:3080)
```

## 4.1 DeepSeek Harness

Upstream says it is a **developer preview with compatibility-breaking changes**. Read its `SAFETY.md`.

Run from npm:

```bash
npx @deepseek-ai/dsh web          # web UI at http://127.0.0.1:3080
```

Or from a source checkout:

```bash
git clone https://github.com/deepseek-ai/deepseek-harness.git ~/__projects__/deepseek-harness
cd ~/__projects__/deepseek-harness
pnpm install
pnpm run build
pnpm dsh web
```

The author runs `pnpm dsh web` from the checkout. The deepseek-offload installer finds the checkout
at `~/deepseek-harness`, `~/projects/deepseek-harness`, `~/src/deepseek-harness` or
`~/__projects__/deepseek-harness`, or you pass `--dsh-root`.

### API key

The Harness needs a DeepSeek API key. Its development guide documents `DEEPSEEK_API_KEY`; on the author's machine the key was **not** in the shell environment, so it is configured in the Harness itself. Whichever way you do it, confirm with `dsh-offload.mjs doctor` (4.3). Environment-variable form:

```bash
export DEEPSEEK_API_KEY=sk-...          # put it in your shell profile or a private env file
```

Never commit it. `DEEPSEEK_BASE_URL` is optional.

### Harness home

`DSH_HOME` (default `~/.dsh`) holds `profiles/`, `plugins/` and `sessions/`. The bridge and the web GUI
must share it, or the sessions never show up in the GUI.

## 4.2 deepseek-offload in your project

Run from the project that will own the jobs:

```bash
cd ~/my-project
git submodule add https://github.com/phamhung075/deepseek-offload.git .agents/deepseek-offload
git submodule update --init .agents/deepseek-offload
.agents/deepseek-offload/install.sh --dry-run --with-mcp-config     # read the plan
.agents/deepseek-offload/install.sh --with-mcp-config               # apply
```

The installer is idempotent. It:

| Step | Result |
|---|---|
| Harness profiles | Creates `$DSH_HOME/profiles/{acp,web}` if missing |
| `acp` profile | Pins the delegation model (`deepseek-flash` by default) and its model catalog |
| Workspace plugin | Copies `dsh-workspace-attach` into `$DSH_HOME/plugins` so jobs are filed under the project folder in the GUI |
| Project `.agents/` | Links the bridge (`.agents/mcp-deepseek/server.cjs`), the plugin and the skill |
| MCP entries | `--with-mcp-config` adds a `deepseek` server to `.mcp.json` (Claude Code) and `.agents/mcp_config.json` (Gemini/Antigravity) |
| Verify | Runs `doctor` |

Useful flags: `--model NAME`, `--permission allow|reject`, `--dsh-root DIR`, `--dsh-home DIR`,
`--with-vision-subagent`, `--no-project-links`, `--uninstall`.

> `--permission allow` (the default) means delegated jobs run unattended and auto-accept every
> permission prompt. Use `--permission reject` for read-only or untrusted work.

## 4.3 Check

```bash
R=.agents/skills/deepseek-offload/scripts/dsh-offload.mjs
node $R doctor                                   # model pin, plugin liveness, GUI URL
node $R start "List the files in this folder and reply with the count." --label smoke --detach
node $R list                                     # job states
node $R result <jobId>                           # the final report
node $R window                                   # DeepSeek peak/off-peak pricing window
```

You should see the job go `running` then `done`, and a session appear in the web GUI under your
project folder. A released GUI cannot stream a running job; follow it with:

```bash
node .agents/skills/deepseek-offload/scripts/session-tail.mjs <jobId> --watch
```

Other runner commands: `wait`, `update <jobId> "<new info>"` (steer a running job), `cancel`,
`sessions`, `sync-workspace`, and `start --defer-to-off-peak` (wait for cheaper pricing).

## 4.4 What the project gains

After install the project has `.mcp.json` with a `deepseek` entry. Claude seats started in that
folder get four MCP tools: `deepseek_agent`, `deepseek_list_sessions`, `deepseek_update_session`,
`deepseek_mcp_servers`. The bridge's git write guard refuses commits and pushes from jobs by default.

Next: [chapter 5 — terminals and runtimes](05-terminals-and-runtimes.md).
