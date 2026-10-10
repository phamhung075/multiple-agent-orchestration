# 19. An A/B room: choosing seat instructions by quality per cost

You will be tempted to improve every seat's instructions at once: "answer tersely", "verify before
you stop", a different house style. Do not roll a change out to the whole fleet on a hunch. Run it
as an experiment in a **second room, beside** the one doing real work, and measure quality per cost.

## 19.1 The design

One room, one lead, and one worker seat per **arm**. Every worker uses the same seat type, the same
model, the same base guide and the same policy. The arms differ by **exactly one extra instruction
module**:

| Arm | Extra module | Hypothesis |
|---|---|---|
| control | none | the baseline |
| terse | "fewest words that keep the facts; report what changed, the evidence, what is open" | fewer output tokens, same quality |
| verify-first | "name the smallest change and the one check that proves it; run the check; stop when it passes" | fewer wasted edits, same cost |

Because the base guide, model and policy are identical, a difference in the results can only come
from the module. That is the whole point; resist adding a second variable to an arm.

In the room definition each arm is a seat whose overlay lists the shared modules plus its own:

```
control : [base guide, policy]
terse   : [base guide, policy, terse module]
verify  : [base guide, policy, verify module]
```

## 19.2 Keep it isolated from the production room

Both rooms must run at the same time, and the experiment must not change the production room.

- **Give the experiment its own module names.** If the experiment re-uses the production modules'
  names, applying it re-publishes them. Copy them under a prefix (`ab-guide`, `ab-policy`) so the
  apply touches nothing the production seats read.
- **Own rig, own state directories, own supervisor** (chapter 17), own working directory.
- **Do not stop, restart or re-seat anything in the production room.** Verify afterwards that its
  node count and state are what they were.
- **Shared resources are the real risk.** Name them before launching: the terminal multiplexer
  server, the status bridge, the repository's index. A crash of a shared multiplexer takes both
  rooms down, and two rooms committing into one working tree collide. Give the experiment a
  read-only task set, or its own checkout.

## 19.3 The measurement

Give every arm the **same fixed task set**, small and bounded, with a check you can run without
judgement (a test that passes, a file that matches). Record per task and per arm:

| Field | Source |
|---|---|
| Passed the check (yes/no) | the check itself |
| Input and output tokens | the session transcript's usage fields |
| Wall-clock time | timestamps |
| Review score, 1–5 | one reviewer, blind to the arm, using a fixed rubric |

Then compare **quality per cost**: pass rate and review score against total tokens. Run each task at
least three times per arm; one run is an anecdote. Keep the raw rows; the summary is the last thing
you write.

Two cautions from practice:

- **Compression is lossy.** A style that saves 80% of the output tokens can still lose a fact. Count
  a dropped number or a dropped negation as a failure, not a rounding error. Instructions that
  shorten replies should say to keep negations, numbers, commands and error text exact.
- **Voice is not quality.** A seat that sounds clipped is not cheaper unless the token count says so.
  Prefer a plain-writing rule (answer first, then the reason, then the next step; literal wording)
  over a persona.

## 19.4 Reading the result

- If an arm matches the control's pass rate at lower cost, it is a candidate default.
- If it costs less and passes less, it is a trade-off for low-stakes seats only.
- If nothing beats the control, you have learned that the guide is already doing its job. That is a
  result.

Adopt a winner **per seat type**, not per fleet: a reviewer and a worker can want different arms.
Roll it out the way you roll out any guide change: change the module, record the new digest in the
lock file, re-seat, and watch one seat before the rest.

## 19.5 Check

- Both rooms are listed as running at the same time, with their original seat counts.
- The experiment's module names appear nowhere in the production room's overlays.
- Every arm ran the same tasks the same number of times, and the raw rows are saved.

Next: [chapter 20 — working agreements for several seats in one repository](20-working-agreements-shared-repo.md).
