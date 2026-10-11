# Production Playbook: Adding Multi-Agent Orchestration to Any Project

Follow this step-by-step recipe to set up an autonomous, high-performance agent team on any Git repository.

---

## Phase 1: Machine Preparation (One-Time Setup)

1. Verify system dependencies:
   ```bash
   node -v    # Must be v20+
   go version # Must be 1.22+
   tmux -V    # tmux installed
   ```
2. Verify OpenRig is active:
   ```bash
   rig ps
   ```
3. Ensure `4genteam` client is in your `$PATH`:
   ```bash
   4genteam doctor
   ```

---

## Phase 2: Project Rig Specification

In the root of your target repository (`~/my-repo`), create a team specification `rig.yaml`:

```yaml
version: "openrig/v1"
rig: "my-team"

nodes:
  - name: lead
    runtime: claude-code
    model: claude-3-7-sonnet
    cwd: "."
    policy: standard

  - name: dev
    runtime: claude-code
    model: claude-3-7-sonnet
    cwd: "."
    policy: standard

  - name: reviewer
    runtime: claude-code
    model: claude-3-7-sonnet
    cwd: "."
    policy: standard
```

---

## Phase 3: Provision Worktrees & Safety Rails

Run `4genteam` to provision isolated git worktrees for each seat:

```bash
4genteam sync rig my-team
```

This ensures:
- Seat `dev` operates in `.openrig/agenthub-seats/my-team/wt/dev` on branch `my-team/dev`.
- Seat `reviewer` operates in its own isolated worktree.
- The shared repository checkout on `main` remains pristine.
- Git Guard hooks are installed to prevent unauthorized pushes and broad staging.

---

## Phase 4: Launch the Fleet

Start the team, background compaction supervisor, and watchdog in one step:

```bash
4genteam up my-team
```

Check node health:
```bash
rig ps --nodes --rig my-team
```

---

## Phase 5: Kick Off the Team

Dispatch the first objective to the lead seat:

```bash
4genteam send --from owner my-team lead 'Read README.md, define the first milestone tasks on the queue, and assign the first slice to dev.'
```

---

## Phase 6: Live Observation

Open the live feed:
```bash
4genteam feed --rig my-team --detail
```

Or open the full interactive grid view:
```bash
4genteam watch --rig my-team
```

---

Next: [Troubleshooting Catalog](troubleshooting-catalog.md)
