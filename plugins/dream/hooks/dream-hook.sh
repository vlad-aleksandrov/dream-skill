#!/usr/bin/env bash
#
# dream-hook.sh - Stop hook: checks dream conditions and triggers consolidation.
#
# In plugin mode:  CLAUDE_PLUGIN_ROOT is set by the plugin system.
# In manual mode:  CLAUDE_PLUGIN_ROOT is unset; falls back to ~/.claude/skills/dream.

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$HOME/.claude/skills/dream}"
SHOULD_DREAM="$PLUGIN_ROOT/hooks/should-dream.sh"
SKILL_PATH="$PLUGIN_ROOT/skills/dream/SKILL.md"

# Manual-install fallback: scripts lived flat in the skill dir before plugin format.
[[ -f "$SHOULD_DREAM" ]] || SHOULD_DREAM="$HOME/.claude/skills/dream/should-dream.sh"
[[ -f "$SKILL_PATH"   ]] || SKILL_PATH="$HOME/.claude/skills/dream/SKILL.md"

if bash "$SHOULD_DREAM" 2>/dev/null; then
    nohup claude -p "Read $SKILL_PATH and execute all phases for all projects." \
        --allowedTools "Read,Write,Edit,Bash,Glob,Grep" \
        > /tmp/dream-$(date +%Y%m%d-%H%M%S).log 2>&1 &
    echo "Dream consolidation started in background (PID: $!)"
fi

# Always exit 0 so we don't block the session from closing.
exit 0
