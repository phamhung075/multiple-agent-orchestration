# 3. Install OpenRig

OpenRig provides the `rig` command and a background daemon (`127.0.0.1:7433`).

## 3.1 Install

```bash
npm install -g @openrig/cli          # published package
rig --version                        # (verified) 0.6.3
rig setup --dry-run                  # preview what setup will change
```

With Bun instead: `bun add -g @openrig/cli` (Node.js 22+ is still needed to run it).

If you work from a source clone (the author's setup), link the CLI package:

```bash
git clone https://github.com/mvschwarz/openrig.git ~/__projects__/openrig
cd ~/__projects__/openrig && npm install
# the global `rig` then points at packages/cli
```

> Source builds can sit in a half-merged state. If `rig` fails to run or `git status` shows `UU`
> conflicts, use the published package instead.

## 3.2 What setup changes on your machine

From the OpenRig README (upstream), summarized:

| When | Change |
|---|---|
| `npm install -g` | CLI and bundled components under your npm prefix |
| `rig setup` | May install missing tools; writes an OpenRig block in `~/.tmux.conf` (mouse, scrollback) |
| Daemon start | Creates `~/.openrig/` (database, config, plugins, skills); seeds the `openrig-skills` skill |
| Seat launch | Creates tmux sessions, sets identity variables (`OPENRIG_*`), writes Claude workspace trust to `~/.claude.json` and activity hooks to the workspace `.claude/settings.local.json` |

Read the full table in the upstream README before running it on a machine you care about.

```bash
rig setup                            # apply
```

When asked "Allow your agents to run OpenRig commands without repeated permission prompts?" the
recommended answer is Yes. It lets seats call `rig` without a prompt each time. It is separate from
the broad bypass in chapter 13.

## 3.3 Start the daemon and the kernel

```bash
rig daemon start                     # starts the daemon, verifies the kernel
rig ps                               # lists rigs; the kernel appears automatically
rig tui                              # terminal UI (rig tui --shared attaches to the shared one)
```

On first start the daemon creates the **kernel** rig from the shipped variant that matches your
logged-in runtimes (`rig-claude-only.yaml`, `rig-codex-only.yaml`, `rig-agy-only.yaml` or the mixed one).

## 3.4 Check

```bash
rig --version
rig ps                    # shows "kernel" with 4 seats
rig ps --nodes --rig kernel
rig config                # resolved configuration with sources
```

Expected: the kernel has `advisor-lead`, `operator-agent`, `operator-human`, `queue-worker`.
`operator-human` is a plain terminal showing `rig tui`.

## 3.5 Useful files

| Path | Content |
|---|---|
| `~/.openrig/daemon.log` | Daemon log (look here for HTTP 500 errors) |
| `~/.openrig/openrig.sqlite` | Rigs, seats, queue, snapshots |
| `~/.openrig/config.json` | Your config overrides (`rig config set <key> <value>`) |
| `~/.openrig/specs/` | A good place for your team specs |
| `~/.openrig/workspace/` | Default workspace for kernel seats |

## 3.6 Getting help

```bash
rig --help
rig <command> --help
rig context get help          # help guide for your installed version
rig context list              # shipped skills and context packs
```

Next: [chapter 4 — DeepSeek](04-install-deepseek.md).
