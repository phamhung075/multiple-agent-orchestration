# 3. Prerequisites

## Machine

| Need | Detail |
|---|---|
| OS | Linux or macOS. OpenRig upstream says native Windows is unsupported and WSL2 untested. **It worked on WSL2 Ubuntu** in this run, with the caveats in chapter 9. |
| Node.js | **22 or 24** (24.21.0 used). Node 20 is no longer supported. On Apple-silicon Macs use Node 22. |
| tmux | 3.x (`tmux -V`). Required by OpenRig. |
| git | For the project and the deepseek-offload submodule. |
| RAM | Each Claude Code seat is roughly 300–500 MB. A team of two seats plus a kernel, a browser and an editor fits in 16 GB, but the Linux out-of-memory killer was seen once on a 16 GB WSL2 limit. Give WSL2 at least 16 GB. |
| Disk | A few GB for npm packages, transcripts (a long seat transcript is tens of MB) and DeepSeek session logs (about 5–9 MB per job). |

### WSL2 memory limit (Windows side)

`C:\Users\<you>\.wslconfig`:

```ini
[wsl2]
memory=16GB
```

Then run `wsl --shutdown` from Windows and reopen the distro.

## Accounts

Use the accounts you already have. You do not need every provider.

| Runtime | Login | Check |
|---|---|---|
| Claude Code | `claude auth login` | `claude auth status` |
| Codex (optional) | `codex login` | `codex login status` |
| Antigravity `agy` (optional) | follow its own login | `agy --version` |
| DeepSeek (for workers) | an API key in the Harness environment (see chapter 6) | `dsh-offload.mjs doctor` |

OpenRig's kernel picks Claude-only, Codex-only, agy-only or a mixed variant from the runtimes it finds
logged in, so a missing unused provider is fine.

## Optional

| Need | When |
|---|---|
| Go 1.23+ | Only for the case study (chapter 22). |
| A Postgres you can reach from your machine | Only if your e2e tests need a database. |

## Install the basics (Ubuntu / WSL2)

```bash
sudo apt update && sudo apt install -y tmux git curl build-essential
# Node 24 via nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
exec $SHELL
nvm install 24
npm install -g @anthropic-ai/claude-code
claude auth login
```

## Check

Run the doctor script from this guide:

```bash
bash scripts/doctor.sh
```

It prints the version of every tool and marks missing ones. Fix every `MISSING` line that applies
to you before the next chapter.

Next: [chapter 4 — install OpenRig](04-install-openrig.md).
