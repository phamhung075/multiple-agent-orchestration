#!/usr/bin/env bash
# rig-watchdog.sh — notice when a rig's tmux seats have vanished, and restore it.
#
# Chapters 23 and 14. Why this exists: every tool that answers "is it up?" asks the
# daemon's cached lifecycle. On 2026-10-05 the tmux server holding all ten seats of a
# rig died; `rig ps` kept saying 10 running and `rig crash-cart` (a daemon-down
# verdict) said "up". tmux is the ground truth, so this asks tmux.
#
# Usage:
#   rig-watchdog.sh --check            report every running rig; changes nothing (safe)
#   rig-watchdog.sh <rig>              one-shot check of one rig
#   rig-watchdog.sh <rig> --watch [s]  loop; restore the rig when its seats go
#   rig-watchdog.sh --all --watch [s]  loop over every running rig
#   rig-watchdog.sh --self-test        exercise the decision rule on fixtures
#
# To run it detached, send stdout somewhere OTHER than $LOG or every line is logged
# twice (log() both appends to $LOG and prints):
#   setsid nohup rig-watchdog.sh <rig> --watch 60 \
#     >> ~/.openrig/logs/rig-watchdog.out 2>&1 < /dev/null &
set -u
export PATH=$HOME/.local/bin:$PATH
LOGDIR=$HOME/.openrig/logs
mkdir -p "$LOGDIR"
LOG=$LOGDIR/rig-watchdog.log

# Append to the log file and also print, so a foreground run is readable and a piped
# run is capturable.
log(){
  local line; line="$(date -Is) $*"
  echo "$line" >>"$LOG"
  echo "$line"
  return 0
}

# Server-identity heartbeat: the next time the tmux server changes, the log carries a
# timestamp for the transition instead of leaving it to be inferred afterwards.
# Identity is pid + start time, so a reused pid cannot look like the same server.
IDFILE=${XDG_STATE_HOME:-$HOME/.openrig/state}/rig-watchdog.server-id
server_identity(){ tmux display-message -p '#{pid} #{start_time}' 2>/dev/null || echo none; }
note_server_identity(){
  local id prev
  id=$(server_identity)
  prev=$(cat "$IDFILE" 2>/dev/null || true); [ -z "$prev" ] && prev=none
  if [ "$id" != "$prev" ]; then
    mkdir -p "$(dirname "$IDFILE")"
    printf '%s' "$id" >"$IDFILE"
    if [ "$prev" = none ]; then log "tmux server identity: $id (no earlier poll recorded)"
    else log "tmux SERVER CHANGED: $prev -> $id (the previous server is gone)"; fi
  fi
}

# The decision rule, kept pure so --self-test can exercise it without a fleet.
# exp = seats the daemon believes are running; live = sessions tmux actually has.
verdict(){
  if [ "$1" -eq 0 ]; then echo stopped
  elif [ "$2" -gt 0 ]; then echo healthy
  else echo dead; fi
}

# Seats actually present, straight from tmux. A dead server yields 0, not an error.
live_seats(){
  local n; n=$(tmux ls -F '#{session_name}' 2>/dev/null | grep -c "@$1\$"); [ -z "$n" ] && n=0
  echo "$n"
}

# Seats the daemon believes are running, from a documented JSON field rather than the
# pretty-printed table.
expected_seats(){
  rig ps --nodes --rig "$1" --json 2>/dev/null | python3 -c '
import json, sys
try: rows = json.load(sys.stdin)
except Exception: print(0); raise SystemExit
print(sum(1 for r in rows if r.get("lifecycleState") == "running"))
' 2>/dev/null || echo 0
}

# Rigs the daemon says are running — the only ones worth watching. A deliberately
# stopped rig must never be resurrected by a watchdog.
rigs_running(){
  rig ps --json 2>/dev/null | python3 -c '
import json, sys
try: rows = json.load(sys.stdin)
except Exception: raise SystemExit
rows = rows if isinstance(rows, list) else rows.get("rigs", [])
for r in rows:
    if r.get("lifecycleState") == "running" and (r.get("runningCount") or 0) > 0:
        print(r.get("name") or r.get("rigName"))
' 2>/dev/null
}

restore_rig(){
  local rig=$1
  local helper=$HOME/.openrig/bin/rig-continue.sh
  if [ -x "$helper" ]; then "$helper" "$rig" >>"$LOG" 2>&1
  else rig up "$rig" --existing >>"$LOG" 2>&1; fi
}

check_rig(){
  local rig=$1 act=$2 exp live v
  note_server_identity
  exp=$(expected_seats "$rig"); live=$(live_seats "$rig"); v=$(verdict "$exp" "$live")
  case "$v" in
    stopped) log "$rig: daemon expects no running seats (expected 0, live $live) — deliberate stop or already handled; no action"; return 0 ;;
    healthy) log "$rig: healthy (daemon expects $exp, tmux has $live)"; return 0 ;;
    dead)
      if [ "$act" != restore ]; then
        log "$rig: DEAD — daemon expects $exp running seats, tmux has 0. Re-run with --watch to restore."
        return 2
      fi
      log "$rig: DEAD — daemon expects $exp running seats, tmux has 0. Restoring."
      if restore_rig "$rig"; then log "$rig: restore invoked; tmux now has $(live_seats "$rig")"
      else log "$rig: restore FAILED — see $LOG"; fi
      return 0 ;;
  esac
}

watch_rig(){
  local rig=$1 interval=$2 beat=${3:-15} misses=0 exp live polls=0
  # A healthy rig is otherwise silent, which makes "watchdog died" indistinguishable
  # from "all is well". The heartbeat is why silence is never load-bearing.
  log "$rig: watching every ${interval}s (two consecutive misses required before acting; heartbeat every $((beat * interval))s)"
  while true; do
    note_server_identity
    exp=$(expected_seats "$rig"); live=$(live_seats "$rig")
    if [ "$(verdict "$exp" "$live")" = dead ]; then
      misses=$((misses + 1)); log "$rig: MISS $misses/2 (daemon expects $exp, tmux has 0)"
      if [ "$misses" -ge 2 ]; then check_rig "$rig" restore; misses=0; fi
    else
      [ "$misses" -gt 0 ] && log "$rig: live again before acting (live=$live); counter reset"
      misses=0
    fi
    polls=$((polls + 1))
    [ $((polls % beat)) -eq 0 ] && log "$rig: heartbeat — alive, daemon expects $exp, tmux has $live, no misses"
    sleep "$interval"
  done
}

self_test(){
  local pass=0 fail=0 got want
  t(){ got=$(verdict "$1" "$2"); want=$3
       if [ "$got" = "$want" ]; then pass=$((pass+1)); echo "  ok   verdict($1,$2) = $want"
       else fail=$((fail+1)); echo "  FAIL verdict($1,$2) = $got, wanted $want"; fi; }
  echo "decision rule:"
  t 10 10 healthy   # normal running rig
  t 10 0  dead      # the 2026-10-05 crash: daemon expects ten, tmux has none
  t 1  0  dead      # single-seat rig, same shape
  t 3  2  healthy   # partial loss is not this script's job; it restores whole rigs
  t 0  0  stopped   # a deliberately stopped rig must never trigger a restore
  t 0  10 stopped   # stale daemon rows but no expectation: no action
  echo "result: $pass passed, $fail failed"
  [ "$fail" -eq 0 ]
}

case "${1:-}" in
  --self-test) self_test ;;
  "") echo "Usage: $(basename "$0") --check | <rig> [--watch [secs]] | --all --watch [secs] | --self-test"
      echo "rigs the daemon calls running:"; rigs_running | sed 's/^/  /' ;;
  --check) for r in $(rigs_running); do check_rig "$r" report; done ;;
  --all)
    [ "${2:-}" = --watch ] || { echo "--all requires --watch (or use --check)"; exit 2; }
    interval=${3:-60}
    for r in $(rigs_running); do watch_rig "$r" "$interval" & done
    log "--all: watching $(rigs_running | wc -l) rig(s) at ${interval}s"
    wait ;;
  *)
    rig=$1
    if [ "${2:-}" = --watch ]; then watch_rig "$rig" "${3:-60}" "${4:-15}"; else check_rig "$rig" report; fi ;;
esac
