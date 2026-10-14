# 02. Seats and Worktree Isolation

The single biggest failure mode of multi-agent development teams is **git collision**: two agents editing files in the same working tree, clobbering each other's commits, or committing unstaged lines created by peers.

This system guarantees clean parallel execution by enforcing **one git worktree per seat**.

---

## Why Shared Checkouts Break Multi-Agent Teams

When multiple agents run in a single shared repository checkout:
1. `git add -A` or `git commit -a` from Seat A will accidentally commit partial edits made by Seat B.
2. An edit made by Seat A changes files on disk while Seat B is running tests, causing unexplainable test failures.
3. Commit authorship gets contaminated when one seat exports environment variables like `GIT_DIR` or `GIT_AUTHOR_NAME`.

---

## The Solution: Worktree Per Seat

Every active seat gets its own dedicated Git worktree and branch:

```
/home/user/project/              <- Shared root repo checkout (main branch, clean)
  ├── ~/.config/4genthub/rooms/my-team/
        ├── wt/lead/             <- Branch: my-team/lead
        ├── wt/architect/        <- Branch: my-team/architect
        ├── wt/fe-dev/           <- Branch: my-team/fe-dev
        └── wt/go-dev/           <- Branch: my-team/go-dev
```

### Key Rules Enforced by the Client

1. **Independent File Trees:**
   Each seat edits files only inside its own `wt/<seat>` directory. Edits are completely isolated until merged.
2. **Local Commit Discipline:**
   - Commit by explicit pathspec: `git commit -m "feat: description" -- <file1> <file2>`
   - Untracked files use intent-to-add: `git add -N -- <new_file>`
   - Never stage broadly (`git add .` or `git add -A` are rejected by git hooks).
3. **No Automatic Push:**
   Seats commit only to their local seat branches. Only the human owner or designated lead can approve pushing commits to remote repositories.
4. **Lead Merging:**
   The lead seat reviews code or delegates to the `reviewer` seat. Once approved, the lead merges the seat branch into the integration branch.

---

Next: [03 — The Durable Work Queue](03-the-durable-queue.md)
