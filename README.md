# Dream - Memory Consolidation for Claude Code

Your AI agent dreams like you do. Consolidates memory while you sleep.

Anthropic is building an auto-dream feature into Claude Code (currently unreleased). This skill replicates that functionality today - no feature flags, no waiting for rollout. Drop it in and your agent's memory stays clean, current, and contradiction-free.

## What It Does

When you use Claude Code across many sessions, auto-memory accumulates noise: stale facts, contradictions, relative dates that lose meaning. Dream fixes this by running a 4-phase consolidation pass over your memory files - the same way your brain consolidates memories during sleep.

**Phase 1 - Orient:** Reads your current memory directory to understand what exists.

**Phase 2 - Gather Signal:** Scans recent session transcripts (JSONL files) for user corrections, preference changes, important decisions, and recurring patterns. Uses targeted grep, not full reads.

**Phase 3 - Consolidate:** Merges new findings into existing memory. Converts relative dates to absolute. Resolves contradictions. Removes references to nonexistent files. No duplicates.

**Phase 4 - Prune & Index:** Rebuilds MEMORY.md as a lean index under 200 lines. Removes stale pointers. Demotes verbose entries to topic files.

## Auto-Trigger

Includes a native Claude Code Stop hook that checks every time you exit a session:
- Has 24+ hours passed since the last dream?
- If yes, flags the next session to run `/dream` automatically.

Zero overhead when conditions aren't met (~10ms check on exit).

## Memory System Auto-Detection

On first install, the skill detects which memory system you're using:
- **Native Claude Code** (`~/.claude/projects/*/memory/`) - default
- **OpenClaw-style** (`./memory/` with daily logs)
- **Project-root** (`./MEMORY.md` in project root)

If nothing is detected, defaults to native Claude Code memory.

## Quick Start

### Option 1: Plugin install (recommended)

```bash
/plugin marketplace add vlad-aleksandrov/dream-skill
/plugin install dream@dream
```

Then run `/dream:setup` (or just `/dream:dream`) to verify and complete setup. The Stop and SessionStart hooks are registered automatically.

### Option 2: Run the installer

```bash
git clone https://github.com/vlad-aleksandrov/dream-skill.git /tmp/dream-skill
bash /tmp/dream-skill/install.sh --auto
```

### Option 3: Manual install

1. Clone the repo and copy `plugins/dream/skills/dream/SKILL.md` and `plugins/dream/hooks/*.sh` to `~/.claude/skills/dream/`
2. Run `chmod +x ~/.claude/skills/dream/*.sh`
3. Start a Claude Code session and say `/dream` to run it

## What's Included

| File | Purpose |
|---|---|
| `plugins/dream/skills/dream/SKILL.md` | 6-phase consolidation instructions (the skill brain) |
| `plugins/dream/hooks/dream-hook.sh` | Stop hook — triggers dream after 24h |
| `plugins/dream/hooks/session-start-hook.sh` | SessionStart hook — picks up .dream-pending flag |
| `plugins/dream/hooks/should-dream.sh` | Condition checker (24hr timer) |
| `plugins/dream/commands/dream.md` | `/dream:dream` slash command |
| `plugins/dream/hooks/hooks.json` | Hook registrations for the plugin system |
| `plugins/dream/references/lint-rules.md` | Phase 5 lint rules reference |
| `plugins/dream/references/promotion-rules.md` | Phase 6 promotion rules reference |
| `install.sh` | Manual installer with `--auto` flag (for non-plugin installs) |
| `test-dream.sh` | Development test fixtures and verify scripts |

## Usage

### Plugin install
```
/dream:dream
```

### Automatic (after install --auto)
Just use Claude Code normally. The Stop hook checks on every session exit. When 24 hours have passed, your next session automatically runs a dream consolidation in the background.

## Requirements

- Claude Code v2.1.59+ (auto-memory support)
- No additional dependencies

## How It Compares to Anthropic's Auto-Dream

| Feature | Anthropic (unreleased) | This Skill |
|---------|----------------------|------------|
| 4-phase consolidation | Yes | Yes |
| Session transcript scanning | Yes | Yes |
| Contradiction resolution | Yes | Yes |
| Date normalization | Yes | Yes |
| Auto-trigger | Built into binary | Stop hook + flag file |
| Memory system detection | Native only | Native + OpenClaw + custom |
| Available now | Behind feature flag | Yes |

## License

MIT
