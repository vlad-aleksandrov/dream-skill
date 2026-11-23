#!/usr/bin/env bash
#
# dream-hook.sh - Stop hook: checks dream conditions and triggers consolidation.
#
# Resolves its own location via $0 (absolute path when invoked by the plugin
# system), so no dependency on CLAUDE_PLUGIN_ROOT being set as an env var.

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(dirname "$HOOKS_DIR")"
SHOULD_DREAM="$HOOKS_DIR/should-dream.sh"
SKILL_PATH="$PLUGIN_ROOT/skills/dream/SKILL.md"

# Manual-install fallback
[[ -f "$SHOULD_DREAM" ]] || SHOULD_DREAM="$HOME/.claude/skills/dream/should-dream.sh"
[[ -f "$SKILL_PATH"   ]] || SKILL_PATH="$HOME/.claude/skills/dream/SKILL.md"

[[ -n "${DREAM_CHILD:-}" ]] && exit 0
pgrep -f '[s]kills/dream/SKILL.md and execute' >/dev/null && exit 0

if bash "$SHOULD_DREAM" --claim 2>/dev/null; then
    DREAM_CHILD=1 nohup claude -p "Read $SKILL_PATH and execute all phases for all projects." \
        --allowedTools "Read,Write,Edit,Bash,Glob,Grep" \
        > /tmp/dream-$(date +%Y%m%d-%H%M%S).log 2>&1 &
    echo "Dream consolidation started in background (PID: $!)"
fi

exit 0
