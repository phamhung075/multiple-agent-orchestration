# Troubleshooting Catalog

A quick reference guide for common issues, symptoms, and their direct resolutions.

---

## 1. Team & Node Launch Issues

### Symptom: `cannot load team definition from <dir>`
- **Cause:** `--team` must name the directory that holds `team.json`, and that file needs a `room.slug` and a `seat_key` on every seat.
- **Fix:** `4genteam up <rig> --team <dir>` with a valid `<dir>/team.json`.

### Symptom: `up` exits 2 and names seats that are not running
- **Cause:** The runtime daemon started but a seat would not run.
- **Fix:** Read the daemon log path printed with the error, then `4genteam room status <rig>`; restart one seat with `4genteam room reseat <rig> <seat>`.

### Symptom: Seat shows `runtime_error` or missing API key
- **Cause:** The seat's environment is missing API keys.
- **Fix:** Check `~/.config/4genthub/.env` or inspect `4genteam capture agenthub--<rig>--<seat> --lines 20` to see the exact startup error.

---

## 2. Communication & Queue Issues

### Symptom: Seat remains `idle` after receiving a message
- **Cause:** In rare cases with raw tmux sessions, text remains in the terminal buffer without submitting an Enter key.
- **Fix:** Send the enter key: `tmux send-keys -t '<session-name>' Enter`.

### Symptom: Unsigned message warning / `Delivered without sender identity`
- **Cause:** a message was sent from an unmanaged shell rather than from a seat session.
- **Fix:** Use `4genteam send --from owner <rig> <seat> '<message>'` which injects standard attribution headers.

---

## 3. Worktree & Git Issues

### Symptom: Commit rejected with `Refused commit from shared checkout`
- **Cause:** The Git Guard detected that an agent attempted to commit directly in the root repository checkout instead of its assigned worktree.
- **Fix:** Run `4genteam sync rig <rig>` to repair worktree assignments, and ensure the agent executes commands within `wt/<seat>`.

### Symptom: `git push` blocked with exit code 1
- **Cause:** Intended behavior. The Git Guard pre-push hook prevents autonomous agents from pushing to remotes.
- **Fix:** Review local commits on the seat branch and have the human operator perform the push.
