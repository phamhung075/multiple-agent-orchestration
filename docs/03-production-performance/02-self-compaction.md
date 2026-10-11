# 02. Token Economy & Self-Compaction

Large context windows degrade reasoning quality and incur exponential token costs. Allowing agents to run until they hit 200k+ tokens causes hallucinations and stalling.

This system maintains lean, high-performance sessions using an **Automated Compaction Supervisor**.

---

## 1. The Token Compaction Limits

The supervisor monitors context usage against three configurable tiers:

| Tier | Default Limit | Action |
|---|---|---|
| **Soft Limit** | 150,000 tokens | Compaction triggers when the seat completes its current job turn |
| **Warning Limit** | 250,000 tokens | Feed displays amber warnings; urges seat to complete turn |
| **Hard Limit** | 300,000 tokens | Immediate pause; compacts as soon as command returns |

---

## 2. Running the Compaction Supervisor

Start the supervisor alongside your team:

```bash
4genteam compact <rig-name>
```

### The Compaction Protocol

The supervisor runs outside the seats and performs these automated steps:
1. **Reads context metrics** directly from the agent session logs.
2. **Waits for quiet:** Ensures the seat is not mid-execution or editing a file.
3. **Issues `/compact`:** Triggers the runtime's native summary compaction.
4. **Verifies token drop:** Checks that context tokens dropped (e.g. from 160k down to 25k).
5. **Re-anchors the seat:** Re-injects the current queue item and active mission pointer so the agent resumes work immediately with a clean context.

---

Next: [03 — Cheap Worker Offload & DeepSeek](03-deepseek-offload.md)
