# 05. Jev: Decisions and Task Gates

Seats should not stall on a choice they could get answered in seconds, and a task should not close because its author says it is done. **Jev** is the judge that answers both. It runs on the machine, through the same `4genteam` client as everything else: the cloud server judges nothing.

Two verbs call it. Both read `TYPESAFE_API_KEY` from `~/.config/4genthub/.env` and append every outcome to `~/.config/4genthub/jev_decisions.log`.

---

## 1. A decision is open: `4genteam decide`

A seat runs it **before** asking the lead or the owner.

```bash
4genteam decide --tier seat --summary "<5-8 word subject>" \
  --detail-file detail.txt --questions-file q.json
```

* `q.json` is an array of questions, each with options (`id`, `label`, at most 75 characters) and one marked `recommended`.
* Put the context in `--detail-file`, written with a quoted heredoc. Never pass it as `--detail "..."`: a double quote, a `$` or a newline in the text breaks the shell command, and the text after it runs as a command or lands in the log as garbage.
* Exit `0`: the tier decided, so act on the printed answer. Exit `5`: confidence was below the threshold, so the question goes one tier up.

### The ladder

| Tier | Who asks | If Jev is confident | If not |
|---|---|---|---|
| `seat` | a worker seat | the seat acts | escalates to `lead` |
| `lead` | the lead seat, repeating the call with `--tier lead` and what it verified | the lead acts | escalates to the owner |
| owner | the human, on the dashboard | answers | |

**Credentials and spend always go to the owner**, with no Jev call. More categories can be added with `DECISION_OWNER_ONLY_CATEGORIES`.

### Reading the confidence

A tier decides when Jev's confidence reaches `JEV_DECISION_THRESHOLD` (this stack runs `0.75`; the client default is `0.8`). The asker's own framing shapes the answer: a question that carries the asker's measurements and recommendation usually comes back confident, so a high number is agreement with the framing, not independent proof. Put the facts and the real alternatives in; leave the lean in the `recommended` flag only.

---

## 2. The work is finished: `4genteam complete`

A seat closes a task with this verb instead of marking it done by hand.

```bash
4genteam complete --task <task-id> --base <sha-before-your-work> \
  --summary "<what changed>" --test "<the test command>"
```

It collects the evidence (diff, commits, the test run), checks it deterministically (a passing test command is required, keep-out paths, diff size), puts the task's acceptance criteria to Jev, posts the evidence and then completes the task.

| Exit | Meaning |
|---|---|
| `0` | completed |
| `5` | completed, but the seat's test command failed |
| `6` | the gate refused: fix what the verdict names and run it again |

Exit `6` happens only with `VALIDATION_GATE_ENFORCEMENT=true`. Without it the gate runs in **shadow mode**: the verdict goes to stderr and the task closes anyway, so nothing is actually gated. A task with no acceptance criteria passes the deterministic checks alone, which the log records as "the task has no acceptance criteria".

---

## 3. Settings

All from `~/.config/4genthub/.env` or the environment; the client re-reads them on every call, so a change needs no rebuild or reseat.

| Variable | Default | Meaning |
|---|---|---|
| `TYPESAFE_API_KEY` | none, required | the Jev credential; never commit it |
| `JEV_DECISION_MODEL` | `jev-1.13.0` | the judge model |
| `JEV_DECISION_THRESHOLD` | `0.8` | confidence needed for a tier to decide |
| `VALIDATION_GATE_ENFORCEMENT` | unset (shadow) | `true` makes a reject or uncertain verdict stop `complete` |
| `JEV_DECISION_LOG_PATH` | `~/.config/4genthub/jev_decisions.log` | the append-only outcome log |

A seat environment that exports one of these wins over the file.

---

## 4. The log

Each line is one JSON object: `timestamp`, `kind` (`decision` or `gate`), `model`, `confidence_threshold`, `summary`, `detail`, and for a decision the `choices` with their confidence, the `tier` and the `outcome` (`decided`, `escalated-to-lead`, `escalated-to-owner`). It is the audit trail: read it to see which questions seats escalate and how often.

---

Next: [Recipes & Playbooks: Modern New Project Recipe](../04-reference-and-playbooks/new-project-recipe.md)
