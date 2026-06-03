---
description: Spawn dream memory consolidation as a background process
allowed-tools: Bash
---

Spawn dream as a detached background process, then immediately return control to the user. Do NOT execute the dream phases yourself inline — delegate entirely to a separate `claude` process.

Run this bash command:

```bash
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$HOME/.claude/skills/dream}"
SKILL_PATH="$PLUGIN_ROOT/skills/dream/SKILL.md"
[[ -f "$SKILL_PATH" ]] || SKILL_PATH="$HOME/.claude/skills/dream/SKILL.md"
LOG_FILE="/tmp/dream-$(date +%Y%m%d-%H%M%S).log"
nohup claude -p "Read $SKILL_PATH and execute all phases for all projects." \
    --allowedTools "Read,Write,Edit,Bash,Glob,Grep" \
    > "$LOG_FILE" 2>&1 &
echo "PID=$! LOG=$LOG_FILE"
```

Report the PID and log file path to the user. Dream is running in the background — the current session is free.
