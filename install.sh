#!/usr/bin/env bash
#
# install.sh - Install the dream skill for Claude Code
#
# Copies the skill to your .claude/skills/ directory and optionally
# sets up the auto-trigger Stop hook in settings.json.
#
# Usage:
#   bash install.sh              # Install skill only (manual /dream)
#   bash install.sh --auto       # Install skill + Stop hook (auto-triggers)
#   bash install.sh --uninstall  # Remove skill and hook

set -euo pipefail

SKILL_DIR="$HOME/.claude/skills/dream"
SETTINGS_FILE="$HOME/.claude/settings.json"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
ok() { echo -e "${GREEN}[OK]${NC} $1"; }
err() { echo -e "${RED}[ERR]${NC} $1"; }

install_skill() {
    info "Installing dream skill to $SKILL_DIR"
    mkdir -p "$SKILL_DIR/references"

    # Source files live inside the plugin directory in the repo.
    PLUGIN_SRC="$SCRIPT_DIR/plugins/dream"

    cp "$PLUGIN_SRC/skills/dream/SKILL.md"    "$SKILL_DIR/SKILL.md"
    cp "$PLUGIN_SRC/hooks/should-dream.sh"    "$SKILL_DIR/should-dream.sh"
    cp "$PLUGIN_SRC/hooks/dream-hook.sh"      "$SKILL_DIR/dream-hook.sh"
    cp "$PLUGIN_SRC/hooks/session-start-hook.sh" "$SKILL_DIR/session-start-hook.sh"
    cp "$PLUGIN_SRC/references/"*.md          "$SKILL_DIR/references/"
    chmod +x "$SKILL_DIR/should-dream.sh" "$SKILL_DIR/dream-hook.sh" "$SKILL_DIR/session-start-hook.sh"

    # Register /dream as a Claude Code slash command (manual install only;
    # plugin users get /dream:dream via the plugin system).
    mkdir -p "$HOME/.claude/commands"
    cat > "$HOME/.claude/commands/dream.md" << 'CMDEOF'
Read `~/.claude/skills/dream/SKILL.md` and execute the dream memory consolidation — all phases in order. This is an autonomous memory maintenance task; run all phases completely without asking for confirmation.
CMDEOF
    ok "Skill installed. Use /dream in Claude Code to run manually."
}

install_auto_trigger() {
    info "Setting up Stop hook in $SETTINGS_FILE"

    if [[ ! -f "$SETTINGS_FILE" ]]; then
        echo '{}' > "$SETTINGS_FILE"
    fi

    python3 << 'PYEOF'
import json, sys

settings_file = sys.argv[1] if len(sys.argv) > 1 else "$HOME/.claude/settings.json"

with open("SETTINGS_FILE_PATH") as f:
    settings = json.load(f)

if "hooks" not in settings:
    settings["hooks"] = {}

dream_hook = {
    "type": "command",
    "command": "bash ~/.claude/skills/dream/dream-hook.sh"
}

# Check if hook already exists
stop_hooks = settings["hooks"].get("Stop", [])
already_installed = any("dream-hook.sh" in h.get("command", "") for h in stop_hooks)

if not already_installed:
    stop_hooks.append(dream_hook)
    settings["hooks"]["Stop"] = stop_hooks
    with open("SETTINGS_FILE_PATH", "w") as f:
        json.dump(settings, f, indent=2)
        f.write("\n")
    print("Hook added to settings.json")
else:
    print("Hook already installed")
PYEOF

    # Actually run the python with correct path substitution
    python3 -c "
import json

settings_path = '$SETTINGS_FILE'

with open(settings_path) as f:
    settings = json.load(f)

if 'hooks' not in settings:
    settings['hooks'] = {}

dream_hook = {
    'type': 'command',
    'command': 'bash ~/.claude/skills/dream/dream-hook.sh'
}

stop_hooks = settings['hooks'].get('Stop', [])
already_installed = any('dream-hook.sh' in h.get('command', '') for h in stop_hooks)

if not already_installed:
    stop_hooks.append(dream_hook)
    settings['hooks']['Stop'] = stop_hooks
    with open(settings_path, 'w') as f:
        json.dump(settings, f, indent=2)
        f.write('\n')
    print('Hook added to settings.json')
else:
    print('Hook already installed')
"

    ok "Auto-trigger configured."
    echo ""
    info "How it works:"
    info "  1. When you exit a Claude Code session, the Stop hook fires"
    info "  2. should-dream.sh checks: 24hrs passed?"
    info "  3. If yes: spawns claude in background to run all 6 phases"
    info "  4. Dream consolidates L1 memory, lints L2/L3, promotes cross-project knowledge"
    info "  5. Zero overhead when conditions aren't met (~10ms check)"
    info ""
    info "Tip: Install via the plugin system for the best experience:"
    info "  /plugin marketplace add vlad-aleksandrov/dream-skill"
    info "  /plugin install dream@dream"
}

uninstall() {
    info "Removing dream skill"
    rm -rf "$SKILL_DIR"
    rm -f "$HOME/.claude/commands/dream.md"

    if [[ -f "$SETTINGS_FILE" ]]; then
        python3 -c "
import json

with open('$SETTINGS_FILE') as f:
    settings = json.load(f)

if 'hooks' in settings and 'Stop' in settings['hooks']:
    settings['hooks']['Stop'] = [
        h for h in settings['hooks']['Stop']
        if 'dream-hook.sh' not in h.get('command', '')
    ]
    if not settings['hooks']['Stop']:
        del settings['hooks']['Stop']
    if not settings['hooks']:
        del settings['hooks']

with open('$SETTINGS_FILE', 'w') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')
print('Hook removed from settings.json')
"
    fi

    ok "Dream skill and hook removed."
}

case "${1:-}" in
    --auto)
        install_skill
        install_auto_trigger
        ;;
    --uninstall)
        uninstall
        ;;
    *)
        install_skill
        echo ""
        info "To enable auto-trigger (fires on session exit, checks every 24h):"
        info "  bash install.sh --auto"
        echo ""
        info "Or run manually anytime:"
        info "  /dream"
        ;;
esac
