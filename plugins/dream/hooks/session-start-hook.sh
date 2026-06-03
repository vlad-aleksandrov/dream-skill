#!/usr/bin/env bash
#
# session-start-hook.sh - SessionStart hook: picks up the .dream-pending flag and
# runs dream as a background subagent.
#
# The flag is set by dream-hook.sh when the Stop hook fires but direct spawning
# isn't available, or by the CLAUDE.md instruction for manual-install users.

PENDING="$HOME/.claude/.dream-pending"
[[ -f "$PENDING" ]] || exit 0

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$HOME/.claude/skills/dream}"
SKILL_PATH="$PLUGIN_ROOT/skills/dream/SKILL.md"
[[ -f "$SKILL_PATH" ]] || SKILL_PATH="$HOME/.claude/skills/dream/SKILL.md"

rm -f "$PENDING"

nohup claude -p "Read $SKILL_PATH and execute all phases for all projects." \
    --allowedTools "Read,Write,Edit,Bash,Glob,Grep" \
    > /tmp/dream-$(date +%Y%m%d-%H%M%S).log 2>&1 &

exit 0
