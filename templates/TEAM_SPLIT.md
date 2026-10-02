# Team split — who works on which rows

Two teams work in parallel in the same repo. Ownership is by bounded context: the first path segment
of the source module, across ALL slices. Touch only rows you own.

| Team | Seats | Owns (first path segment of the source module) | Todo rows |
|---|---|---|---|
| A | <a-owner> / <a-check> @<rig> | <context-1> | <n> |
| B | <b-owner> / <b-check> @<rig> | <every other context, listed> | <n> |

Count rows per team with the ledger before you write this table, and aim for roughly equal work
(weight by the model: a smaller model needs fewer rows).

## Rules
- Pick the next `todo` row in your own contexts, in slice order.
- Edit the ledger with a targeted edit of your own rows only; re-read it right before editing, because
  the other team edits it too. Never rewrite the whole file.
- Do not edit, move or delete files in the other team's contexts. If you need something from them, ask
  their owner with `rig send`, or define a minimal local interface and note it in the ledger.
- Shared files (dependency manifests, shared helpers): add only, never change existing definitions.
  Build before and after.
- Checkers check only their own team's rows.
- The end-to-end test runs once, by <named seat>, when neither team has a `todo` row.

## Each owner leads DeepSeek workers
The owner plans a slice, starts one detached DeepSeek job per module, reviews each result against the
source, runs build/vet/test, queues the slice to the checker. Hand-written code is for design-heavy
modules, jobs that failed the build twice, or when workers are unavailable (for example
`Insufficient Balance`: port directly and report once).
