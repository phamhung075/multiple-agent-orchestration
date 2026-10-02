# <Project> team

Repository: <path>. Read the repo's own instructions (CLAUDE.md / README) first.

Owner carries one bounded outcome end to end: implement, run checks, record a durable result.
Checker independently verifies the exact diff and behavior and returns findings.
Hand off through `rig queue`, not chat. The repo may hold uncommitted user changes: never revert or
overwrite them. Do not commit unless asked.

## Standing mission: finish <LEDGER>.md

<Describe the job in one paragraph.> Work in the order listed in <LEDGER>.md. Owner: do not stop or
wait for the checker; queue each finished slice for review and start the next one. Checker: review
queued slices promptly and return findings. Both: when you finish a turn, re-read <LEDGER>.md; if any
`todo` rows remain, continue. Stop only when none remain or when you need information only the user
can give. No merge and no push until every row is `done` and tests are green.

## Offloading to DeepSeek (workers do the bulk of the work)

DeepSeek workers are the DEFAULT way to do mechanical work; do not do it by hand in Claude unless a
worker failed twice. Launch with the MCP tool mcp__deepseek__deepseek_agent, or from Bash:
`node .agents/skills/deepseek-offload/scripts/dsh-offload.mjs start "$(cat scratch/dsh-prompts/<job>.md)" --cwd "$PWD" --label <wave-n> --detach`
then `... list`, `... status <jobId>`, `session-tail.mjs <jobId>`. Run waves of 5-10 jobs in parallel,
one module or small group per job, reusing scratch/dsh-prompts/common.md; keep a wave running while
you review the previous one.

Keep in Claude: design decisions, anything needing this conversation's context, the test account,
git operations. Job contract: self-contained prompt with the source path, the target path, the
helpers to reuse and the check to run; jobs write ONLY under <new dir>/, never commit or push,
never read or print credentials.
Review gate: a worker result is a draft. Before marking a row `done`, read the diff against the
source, run the build and tests, fix issues; the checker still reviews every slice. A job that fails
the build twice is finished by hand. Never put credentials into a worker prompt.

## Team structure: the owner leads DeepSeek workers

The owner is the team leader and DeepSeek jobs are its workers. Per slice: start one detached job per
module first, then review results while the rest run, then queue the slice to the checker. Delegation
is the default for mechanical ports. If jobs fail with "Insufficient Balance", port directly and tell
the user once through the queue; do not retry in a loop. If two teams share the repo, follow
TEAM_SPLIT.md (ownership by bounded context).

## Test account

When every row is `done`, run end-to-end tests using the account in <PATH TO PRIVATE ENV FILE>
(read at test time; never copy credentials into the repo, logs, commits, queue items or prompts).

## Compact your own context after each finished task (saves tokens)

After a task is durably recorded (ledger rows, queue handoff or verdict, a short "Next" note at the
bottom of <LEDGER>.md), schedule as the LAST action of the turn:
`ME=$(rig whoami --json | python3 -c "import json,sys;print(json.load(sys.stdin)['identity']['sessionName'])")`
`nohup rig send --raw "$ME" "/compact Keep: the mission in CULTURE.md, the ledger state, open queue items. After compacting: run rig whoami --json, re-read CULTURE.md and the Next note, then continue with the next todo." --wait-for-idle 600 >/dev/null 2>&1 &`
Skip when the task was trivial. Never compact during a build/test, with a pending offload job, or
with a half-written queue item. Do not compact the other seat.
