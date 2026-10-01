# 13. Safety and security

Agents that run without permission prompts are powerful and can do real damage. Set the limits
before you start the team.

## 13.1 Permission postures

| Posture | Launch | When |
|---|---|---|
| Floor (default) | `--permission-mode acceptEdits` | Normal supervised work |
| Standard / Open / Locked | config policies (`rig policy …`) | Tune what asks, what is allowed, what is denied |
| `builtin:yolo` | `--dangerously-skip-permissions` | A trusted repo, a task you can undo, a machine without secrets you fear for |
| `auto` mode | `rig seat set-permissions <seat> --mode auto` (future launches) | Claude's own auto-approval; depends on your account; **not verified end to end** here |

Facts:

- YOLO is **off by default**. You must select it.
- The flag does not remove managed restrictions or give access beyond your account's.
- A seat-level setting beats the rig-level policy. Changing it does **not** affect running seats; it
  applies at the next launch.
- To go back: `rig policy apply none --spec rig.yaml`, and `rig seat set-permissions <seat> --mode inherit`.

## 13.2 Blast radius checklist (before yolo)

- The repo has a clean or backed-up state. Uncommitted work you care about is committed or stashed,
  or the team is told in `CULTURE.md` never to touch it.
- The machine has no production credentials in reach. Prefer a throwaway database and a test account.
- No secrets in the repo, in prompts, in queue items, or in `CULTURE.md`.
- Remote git credentials: the team is told **not to push** until the job is done.

## 13.3 Secrets

| Do | Don't |
|---|---|
| Keep test credentials in a private file with mode 600 outside the repo (`~/.openrig/specs/<team>/e2e-account.env`) | Paste a password into `CULTURE.md`, a prompt or a queue item |
| Put the **path** to the file in the culture | Commit the file |
| Tell seats to read it at test time only | Let a DeepSeek worker see it |
| Rotate any password that ever landed in a committed file | Assume deleting the file removes it from git history |

Real example from the run: a password appeared in a committed session-log file in the repo history.
Deleting later does not remove it; rotate it.

Template: [../templates/e2e-account.env.example](../templates/e2e-account.env.example).

## 13.4 Rules for the culture file (copy these)

```markdown
- Never stage or revert files you did not change. The repo may hold unrelated uncommitted work.
- Do not commit unless asked. Do not merge or push until the job is done and tested.
- Never copy credentials into the repo, logs, commits, queue items or DeepSeek prompts.
- DeepSeek workers write only under <new dir> and never run git writes.
```

## 13.5 What the tools themselves change

- OpenRig writes trust settings and activity hooks into `~/.claude.json` and the workspace
  `.claude/settings.local.json`, and a block in `~/.tmux.conf`.
- deepseek-offload adds `.mcp.json` entries; its jobs default to `--permission allow` (unattended).
  Use `--permission reject` for read-only or untrusted work.
- The DeepSeek Harness is a developer preview: read its `SAFETY.md`.
- Anything a seat is allowed to run, it can run on a loop. Do not leave an unattended yolo team on a
  repo you cannot restore.

## 13.6 Stopping everything

```bash
rig down <rig> --snapshot             # stop a team, keep its state
rig watchdog list                     # then: rig watchdog stop <jobId> for each reminder
node .agents/skills/deepseek-offload/scripts/dsh-offload.mjs list     # cancel running jobs:
node .agents/skills/deepseek-offload/scripts/dsh-offload.mjs cancel <jobId>
```

## 13.7 Review before you trust

- The checker seat verifies the exact diff and runs the build.
- You read the ledger and `git diff --stat` before any merge.
- Audit claims with evidence: transcripts (`~/.claude/projects/…`), `dsh-offload.mjs list`,
  `rig ps`, not with what a seat says about itself.

You have finished the guide. Return to the [README](../README.md) for the index.
