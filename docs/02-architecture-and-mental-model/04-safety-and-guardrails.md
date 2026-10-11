# 04. Safety, Guardrails & Git Guards

Autonomous AI development requires strict safety rails. The goal is to allow agents to write, test, and iterate on code rapidly while making it **physically impossible** for an agent to perform destructive, unrecoverable actions.

---

## 1. The Core Immutability Rules

Every seat operates under non-negotiable boundaries:
1. **Never Push:** Seats commit only to their local branches. `git push` and force pushes are blocked at the git hook level.
2. **Never Touch Production:** Deployment credentials and production keys are never mounted into agent environments.
3. **Clean Code First:** No backward-compatibility shims, no legacy workarounds, and no temporary hacks just to force tests to pass.
4. **Explicit Pathspec Commits:** Staging with `git add -A` or committing with `git commit -a` is prohibited to prevent accidental inclusion of unreviewed files.

---

## 2. Multi-Layer Guardrails

```
[ Layer 1: Prompt & System Roles ]
    - agent.yaml / guidance rules specifying permissions and boundaries
    - Inexpensive, but not 100% foolproof against hallucinations

[ Layer 2: Seat Policy / Runtime Deny Lists ]
    - Builtin policies (e.g. deny patterns for "git push*", "rm -rf /")
    - Refuses matching command prefixes

[ Layer 3: The Git Guard Hook (Chained Git Hooks) ]
    - Pre-commit & pre-push hooks installed by 4genteam
    - Validates author identity and directory location
    - Fails closed: refuses push attempts even if bypassed with flags
```

---

## 3. The Git Guard Contract

The Git Guard installed by `4genteam` acts as the definitive safety net:
- **Refuses Commits from Shared Checkout:** Ensures commits only happen inside the seat's assigned worktree (`wt/<seat>`).
- **Refuses Forged Authorship:** Ensures commit author matches the seat identity.
- **Scans for Secrets:** Issues warnings if API keys or credentials appear in the diff.
- **Fail-Closed Pre-Push Hook:** Blocks any outbound push attempt directly at the local git boundary.

---

Next: [Production Performance: 01 — Live Monitoring & The Watch View](../03-production-performance/01-live-monitoring-watch.md)
