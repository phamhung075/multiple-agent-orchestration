# 04. The Self-Improving Friction Loop

How do agents report workflow pain points, refine their own tools, and evolve without requiring constant human intervention?

The **Seat Friction Loop** keeps the human out of the micro-loop: the human defines high-level intent and approves irreversible actions, while the lead and architect continually detect, triage, and eliminate operational friction.

---

## 1. The Autonomous Improvement Cycle

```
[ Agent encounters friction (missing tool, slow step, awkward rule) ]
    │
    ▼
[ 1. Friction Report ]
    Seat issues a structured report:
    `4genteam feedback --layer <layer> --text "<symptom, cost, suggested fix>"`
    And flags a task on the queue tagged `friction`.
    │
    ▼
[ 2. Lead Triage ]
    Lead dedupes reports, calculates Cost × Frequency, and designates one fix owner.
    │
    ▼
[ 3. Architect Analysis & Ruling ]
    Architect analyzes the cluster and produces a clean design ruling:
    tool modification, skill update, or constraint change.
    │
    ▼
[ 4. Development & Verification ]
    go-dev or fe-dev implements the change in a local worktree.
    Reviewer measures before-and-after to prove friction was reduced.
    │
    ▼
[ 5. Loop Closed ]
    Fix lands in `share/` or `rooms/` skills; reporting seat notified.
```

---

## 2. Autonomy Boundaries (The Charter)

The **Autonomy Charter** clearly divides responsibilities:

| Domain | Decided Autonomously by Lead & Architect | Reserved for Human Owner |
|---|---|---|
| **Task Ordering & Scheduling** | ✅ Autonomous | ❌ |
| **Seat Assignments & Roles** | ✅ Autonomous | ❌ |
| **Local Merges & Branches** | ✅ Autonomous | ❌ |
| **Skill & Tool Refinements** | ✅ Autonomous | ❌ |
| **Git Push to Remote** | ❌ Blocked | ✅ Owner Decision |
| **Production Deployments** | ❌ Blocked | ✅ Owner Decision |
| **Irreversible Deletions** | ❌ Blocked | ✅ Owner Decision |
| **Governance / Charter Edits** | ❌ Blocked | ✅ Owner Decision |

When the lead needs a decision from the owner, it presents a concise, 3-bullet digest:
`Decision Needed · Options · Recommendation · Deadline`.

---

Next: [05 — Jev: Decisions and Task Gates](05-jev-decisions.md)
