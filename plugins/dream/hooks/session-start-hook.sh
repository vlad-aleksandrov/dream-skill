#!/usr/bin/env bash
#
# session-start-hook.sh - SessionStart hook: picks up the .dream-pending flag
# and runs dream as a background subagent.

PENDING="$HOME/.claude/.dream-pending"
[[ -f "$PENDING" ]] || exit 0

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(dirname "$HOOKS_DIR")"
SKILL_PATH="$PLUGIN_ROOT/skills/dream/SKILL.md"

# Manual-install fallback
[[ -f "$SKILL_PATH" ]] || SKILL_PATH="$HOME/.claude/skills/dream/SKILL.md"

rm -f "$PENDING"

nohup claude -p "Read $SKILL_PATH and execute all phases for all projects." \
    --allowedTools "Read,Write,Edit,Bash,Glob,Grep" \
    > /tmp/dream-$(date +%Y%m%d-%H%M%S).log 2>&1 &

exit 0
