# 6. Your first team

Goal: a two-seat team (owner + checker) working in one repository, launched from a spec file.

## 6.1 The fastest start: a shipped starter

OpenRig ships starters. For two Claude agents:

```bash
cd ~/my-repo
rig specs preview first-project-claude --kind rig
rig up first-project-claude --cwd . --plan      # preview only
rig up first-project-claude --cwd .
rig tui --shared
```

Other starters: `first-project` (two Codex), `first-project-mixed` (Claude owner + Codex checker).

## 6.2 Your own spec

Copy [../templates/rig.yaml](../templates/rig.yaml) next to your project and edit it.

```yaml
version: "0.2"
name: my-team
summary: >
  Two Claude Code seats: an owner who builds and a checker who reviews independently.

culture_file: CULTURE.md              # read by every seat at launch
permission_policy: builtin:yolo       # optional: Claude launches with --dangerously-skip-permissions

pods:
  - id: dev
    label: My project
    members:
      - id: owner
        agent_ref: "local:<relative path to>/agents/development/implementer"
        runtime: claude-code
        profile: default
        cwd: "."
      - id: check
        agent_ref: "local:<relative path to>/agents/development/qa"
        runtime: claude-code
        profile: default
        cwd: "."
    edges:
      - kind: delegates_to
        from: owner
        to: check

edges: []
```

Rules learned the hard way:

| Rule | Why |
|---|---|
| `agent_ref: "local:..."` must be a **relative** path | An absolute path is rejected: `local: ref must be a relative path` |
| The path is relative to the **spec file**, and may climb with `../` | Use `realpath --relative-to=. <agents-dir>` to compute it |
| `cwd` is the folder the agent works in | `"."` = the spec's folder; an absolute path also works |
| `culture_file` is relative to the spec | Put `CULTURE.md` beside `rig.yaml` |
| The shipped agent definitions live in `openrig/packages/daemon/specs/agents/` | `development/implementer`, `development/qa`, `orchestration`, `review`, … |

Validate before launching:

```bash
rig spec validate ./rig.yaml        # schema only
rig spec preflight ./rig.yaml       # agent refs, policy, readiness
rig policy current --spec ./rig.yaml
```

## 6.3 Permission policy in one table

| Spec line | Claude launch flag | Behavior |
|---|---|---|
| none | `--permission-mode acceptEdits` | Edits go through, other actions follow native rules and prompts |
| `permission_policy: builtin:yolo` | `--dangerously-skip-permissions` | No prompts at all. Read chapter 13 first |
| `permission_policy: none` | `acceptEdits` | Explicit "I chose the floor" |

A seat-level override beats the rig-level policy:
`rig seat set-permissions <seat> --mode floor|full_bypass|inherit|auto --reason "<text>"`
(applies to **future launches** only, and must be run from a seat, because it needs a seat identity).

## 6.4 Launch

```bash
rig up ./rig.yaml --plan            # preview
rig up ./rig.yaml                   # launch; prints the attach command
rig ps --nodes --rig my-team        # both seats should be run / idle
```

The argument to `rig up` is:

- a **`.yaml` spec** or a **`.rigbundle`** (new rig), or
- a **name** together with `--existing` (restore a stopped rig that already exists).

It is **not** a folder, and `rig up rig.yaml --existing` is wrong (it looks for a rig named "rig.yaml").

## 6.5 Give the first task

```bash
rig send dev-owner@my-team "Implement <one bounded change>. Create and claim a queue task for it, \
verify the behavior, then hand it to dev-check for an independent check of the exact diff."
rig queue list --destination dev-owner@my-team --limit 1000
```

`rig send` types into the seat's terminal (a message, not a record). The owner records the real work
on the queue. From your own shell you cannot `rig queue create`, because that needs a seat identity;
ask a seat to create the item.

## 6.6 Add a second team (pod) to a running rig

To run two teams on the same job (for example a Claude pair and an `agy` pair), add a pod to the
running rig instead of starting another rig. Seat names are `<pod>-<member>@<rig>`, so use a new pod
id; the same id as an existing pod collides.

```yaml
# agy-pod.yaml  (a pod fragment: the same fields as one entry under `pods:`)
id: agy
label: my-team-agy
members:
  - id: owner
    agent_ref: "local:../../../path/to/agents/implementer"
    runtime: agy
    profile: default
    cwd: "/home/me/my-repo"
  - id: check
    agent_ref: "local:../../../path/to/agents/qa"
    runtime: agy
    profile: default
    cwd: "/home/me/my-repo"
edges:
  - kind: delegates_to
    from: owner
    to: check
```

```bash
rig expand <rig-id> ./agy-pod.yaml --rig-root ~/.openrig/specs/my-team
rig ps --nodes --rig my-team           # four seats now
```

Things to know **(verified 2026-10-02)**:

- The new seats start **fresh**. Live seats cannot be moved between rigs, so "moving" a team means
  expanding the target rig, then `rig down` and `rig archive` the old one. Take `--snapshot` first.
- `rig expand` may print `timed out after 5000ms ... outcome is UNKNOWN`. The pod can still have been
  created: run `rig ps --nodes --rig <rig>` before retrying.
- The saved `rig.yaml` is **not** updated. Restoring from the spec will not bring the new pod back;
  add it to the spec too.
- Two teams on one repo need a split of the work (chapter 8.6) or they will overwrite each other.

## 6.7 Check

- `rig ps --nodes --rig my-team` shows `working` or `idle`, lifecycle `run`.
- `ps -eo args | grep dangerously-skip-permissions` shows the flag when you chose yolo.
- `rig capture dev-owner@my-team --lines 30` shows the agent's screen.

Next: [chapter 7 — daily use](07-daily-use-cheatsheet.md).
