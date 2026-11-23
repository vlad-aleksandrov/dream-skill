#!/usr/bin/env bash
#
# session-start-hook.sh - SessionStart hook: picks up the .dream-pending flag
# and runs dream as a background subagent.

[[ -n "${DREAM_CHILD:-}" ]] && exit 0
pgrep -f '[s]kills/dream/SKILL.md and execute' >/dev/null && exit 0

PENDING="$HOME/.claude/.dream-pending"
[[ -f "$PENDING" ]] || exit 0

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(dirname "$HOOKS_DIR")"
SKILL_PATH="$PLUGIN_ROOT/skills/dream/SKILL.md"

# Manual-install fallback
[[ -f "$SKILL_PATH" ]] || SKILL_PATH="$HOME/.claude/skills/dream/SKILL.md"

rm -f "$PENDING"

DREAM_CHILD=1 nohup claude -p "Read $SKILL_PATH and execute all phases for all projects." \
    --strict-mcp-config \
    --allowedTools "Read,Write,Edit,Bash,Glob,Grep" \
    > /tmp/dream-$(date +%Y%m%d-%H%M%S).log 2>&1 &

exit 0
