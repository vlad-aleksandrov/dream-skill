#!/usr/bin/env bash
#
# should-dream.sh - Check if dream consolidation should run.
#
# Returns exit code 0 if dream should run, 1 if not.
# Condition: 24+ hours since last consolidation.
#
# User config lives at ~/.claude/skills/dream/.dream-config regardless of
# whether dream was installed via the plugin system or manually.

set -euo pipefail

CONFIG="$HOME/.claude/skills/dream/.dream-config"

# Read config or default to native
DREAM_MEMORY_TYPE="native"
if [[ -f "$CONFIG" ]]; then
    DREAM_MEMORY_TYPE=$(grep '^DREAM_MEMORY_TYPE=' "$CONFIG" | cut -d= -f2 || echo "native")
fi

# Find the .last-dream timestamp based on memory type
LAST_DREAM_FILE=""
case "$DREAM_MEMORY_TYPE" in
    native)
        # Newest stamp wins: glob order would pin the gate to whichever project sorts first.
        LAST_DREAM_FILE=$(ls -t "$HOME/.claude/projects/"*/memory/.last-dream 2>/dev/null | head -1 || true)
        if [[ -z "$LAST_DREAM_FILE" ]]; then
            if [[ "${1:-}" == "--claim" ]]; then
                FIRST_DIR=$(ls -d "$HOME/.claude/projects/"*/memory/ 2>/dev/null | head -1 || true)
                [[ -n "$FIRST_DIR" ]] && date +%s > "$FIRST_DIR/.last-dream"
            fi
            echo "Dream conditions met: first-run (no .last-dream found)"
            exit 0
        fi
        ;;
    openclaw|project-root)
        DREAM_MEMORY_PATH=$(grep '^DREAM_MEMORY_PATH=' "$CONFIG" | cut -d= -f2 || echo ".")
        DREAM_MEMORY_PATH="${DREAM_MEMORY_PATH/#\~/$HOME}"
        LAST_DREAM_FILE="$DREAM_MEMORY_PATH/.last-dream"
        if [[ ! -f "$LAST_DREAM_FILE" ]]; then
            [[ "${1:-}" == "--claim" ]] && date +%s > "$LAST_DREAM_FILE"
            echo "Dream conditions met: first-run"
            exit 0
        fi
        ;;
esac

LAST_DREAM=$(cat "$LAST_DREAM_FILE")
NOW=$(date +%s)
ELAPSED=$(( NOW - LAST_DREAM ))
HOURS_ELAPSED=$(( ELAPSED / 3600 ))

if (( HOURS_ELAPSED < 24 )); then
    exit 1
fi

# The dream itself runs headless and cannot write under ~/.claude, so the launcher closes the gate.
[[ "${1:-}" == "--claim" ]] && date +%s > "$LAST_DREAM_FILE"

echo "Dream conditions met: ${HOURS_ELAPSED}h since last dream"
exit 0
