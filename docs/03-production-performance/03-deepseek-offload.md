# 03. Cheap Worker Offload & DeepSeek

The most cost-effective way to run an agent fleet is the **Split-Model Architecture**:

- **Expensive models (Claude 3.7 Sonnet, Opus, GPT-4o)** do architecture, planning, code review, and debugging.
- **Cheap models (DeepSeek-V3 / DeepSeek-Coder)** do bulk boilerplate creation, module porting, and repetitive test writing.

---

## 1. The Offload Workflow

Rather than having the lead seat spend thousands of expensive tokens writing hundreds of lines of boilerplate code:

```
[ Lead / Dev Seat (High-Tier Model) ]
    │ Plans task & creates self-contained prompt
    ▼
[ DeepSeek Harness / Background Worker ]
    │ Executes in isolated background job
    ▼
[ Reviewer Seat (High-Tier Model) ]
    │ Verifies diff & runs automated tests
    │ APPROVE -> Merged to seat branch
    │ REJECT  -> Reworked with feedback
```

---

## 2. Off-Peak Hours & Pricing Gates

DeepSeek offers discounted rates during off-peak hours (half price). 
The `4genteam` client includes an automatic **Off-Peak Gate**:

```bash
4genteam offpeak check
```

When the off-peak gate is enabled:
- Bulk offload batches run during the discounted window.
- Urgent tasks can bypass the gate using `--force-peak`.

---

Next: [04 — The Self-Improving Friction Loop](04-self-improving-team.md)
