#!/usr/bin/env bash
#
# dream-guard.sh - sourced by the launcher hooks right before they start a dream.
# Exits the caller unless it may launch; on return the caller holds the launch
# lock (fd 9) until it exits, so check + claim + spawn cannot interleave.

DREAM_MAX_AGE_SECS="${DREAM_MAX_AGE_SECS:-10800}"
DREAM_HOOK_LOG="$HOME/.claude/.dream-hook.log"

dream_log() { echo "$(date '+%F %T') $(basename "$0"): $*" >> "$DREAM_HOOK_LOG"; }

[[ -n "${DREAM_CHILD:-}" ]] && exit 0

if command -v flock >/dev/null; then
    exec 9>"$HOME/.claude/.dream.lock"
    flock -n 9 || { dream_log "skipped: another hook is launching a dream"; exit 0; }
fi

# A dream past the age limit is treated as hung, so it no longer blocks new ones.
for pid in $(pgrep -f '[s]kills/dream/SKILL.md and execute'); do
    age=$(ps -o etimes= -p "$pid" 2>/dev/null | tr -d ' ')
    if [[ -z "$age" ]] || (( age < DREAM_MAX_AGE_SECS )); then
        dream_log "skipped: dream PID $pid running for ${age:-?}s"
        exit 0
    fi
    dream_log "ignoring dream PID $pid: running for ${age}s, over ${DREAM_MAX_AGE_SECS}s, likely hung"
done
