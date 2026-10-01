#!/usr/bin/env bash
# One-screen status: teams, seats, DeepSeek jobs, ledger progress. Read-only.
# Usage: scripts/status.sh [path/to/LEDGER.md] [project-dir-with-deepseek-offload]
LEDGER="${1:-}"; PROJ="${2:-$PWD}"
echo "== Rigs";  rig ps 2>&1 | head -12
echo; echo "== tmux"; tmux ls 2>&1 | head -8
echo; echo "== Watchdogs"
rig watchdog list --json 2>/dev/null | python3 -c "
import json,sys
try: jobs=json.load(sys.stdin)
except Exception: jobs=[]
for j in jobs:
    if j.get('state')=='active' and 'kernel' not in j.get('targetSession',''):
        print(' ',j['jobId'][-8:], j['targetSession'], 'every', j['intervalSeconds'],'s')" 2>/dev/null
R="$PROJ/.agents/skills/deepseek-offload/scripts/dsh-offload.mjs"
if [ -f "$R" ]; then echo; echo "== DeepSeek jobs (newest)"; (cd "$PROJ" && node "$R" list 2>&1 | head -6); fi
if [ -n "$LEDGER" ] && [ -f "$LEDGER" ]; then
  echo; echo "== Ledger $LEDGER"
  printf '  todo: %s   done: %s   n/a: %s\n' "$(grep -c '| todo |' "$LEDGER")" "$(grep -c '| done' "$LEDGER")" "$(grep -c '| n/a' "$LEDGER")"
fi
