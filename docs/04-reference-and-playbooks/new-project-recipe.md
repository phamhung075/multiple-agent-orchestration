# Production Playbook: Adding Multi-Agent Orchestration to Any Project

Follow this step-by-step recipe to set up an autonomous, high-performance agent team on any Git repository.

---

## Phase 1: Machine Preparation (One-Time Setup)

1. Verify system dependencies:
   ```bash
   go version # Must be 1.22+
   tmux -V    # tmux installed
   ```
2. Ensure `4genteam` client is in your `$PATH`:
   ```bash
   4genteam doctor
   ```

---

## Phase 2: Team Definition

Create a directory (for example `~/teams/my-team/`) with a `team.json`:

```json
{
  "room": { "slug": "my-team", "cwd": "~/my-repo" },
  "seats": [
    { "seat_key": "lead",     "seat_type": "lead",      "runtime": "claude-code", "model": "sonnet" },
    { "seat_key": "dev",      "seat_type": "developer", "runtime": "claude-code", "model": "sonnet" },
    { "seat_key": "reviewer", "seat_type": "reviewer",  "runtime": "claude-code", "model": "sonnet" }
  ]
}
```

---

## Phase 3: Worktrees & Safety Rails

Run `4genteam` to provision isolated git worktrees for each seat:

```bash
4genteam sync rig my-team
```

This ensures:
- Seat `dev` operates in `~/.config/4genthub/rooms/my-team/wt/dev` on branch `my-team/dev`.
- Seat `reviewer` operates in its own isolated worktree.
- The shared repository checkout on `main` remains pristine.
- Git Guard hooks are installed to prevent unauthorized pushes and broad staging.

---

## Phase 4: Launch the Fleet

Start the team, background compaction supervisor, and watchdog in one step:

```bash
4genteam up my-team --team ~/teams/my-team
```

Check node health:
```bash
4genteam ps my-team --nodes
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
