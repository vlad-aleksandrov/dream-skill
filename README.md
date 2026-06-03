# Dream - Memory Consolidation for Claude Code

Your AI agent dreams like you do. Consolidates memory while you sleep.

Anthropic is building an auto-dream feature into Claude Code (currently unreleased). This plugin replicates that functionality today — no feature flags, no waiting for rollout. Drop it in and your agent's memory stays clean, current, and contradiction-free.

## What It Does

Dream runs **6 sequential phases** every 24 hours via a Stop hook:

**Phase 1 — Orient:** Surveys all three memory layers — L1 (local `~/.claude/` memory), L2 (Logseq brain project pages), L3 (Logseq wiki).

**Phase 2 — Gather Signal:** Scans recent session transcripts (JSONL files) for corrections, preference changes, decisions, and recurring patterns. Uses targeted grep, not full reads.

**Phase 3 — Consolidate:** Merges findings into L1 memory. Converts relative dates to absolute. Resolves contradictions. Removes references to nonexistent files. No duplicates.

**Phase 4 — Prune & Index:** Rebuilds `MEMORY.md` as a lean index under 200 lines. Removes stale pointers. Demotes verbose entries to topic files. Writes the dream report header.

**Phase 5 — Lint:** Auto-applies mechanical fixes across all three layers — property key typos, broken `[[links]]`, hub completeness, stale confidence downgrades. Commits fixes to the brain git repo.

**Phase 6 — Promote:** Moves knowledge to the right layer automatically. Cross-project `feedback_*.md` and `workflow_*.md` → L3 wiki. Project implementation details → L2 brain page. Completed project learnings → L3 wiki (distilled, not raw notes).

Each run writes an archive entry to `~/.claude/.dream-reports/YYYY-MM-DD.md`.

## Install

### Plugin (recommended)

In any Claude Code session:

```
/plugin marketplace add vlad-aleksandrov/dream-skill
/plugin install sweet-dreams@second-brain
```

The Stop hook (fires on session exit) and SessionStart hook (picks up the pending flag) are registered automatically. No settings.json edits needed.

### Manual

```bash
git clone https://github.com/vlad-aleksandrov/dream-skill.git /tmp/dream-skill
bash /tmp/dream-skill/install.sh --auto
```

## Setup (one-time, after install)

Dream needs to know which memory system you're using. Run these checks in a Claude Code session:

```bash
# Detect your memory system
ls ~/.claude/projects/*/memory/MEMORY.md 2>/dev/null && echo "native"
ls ./memory/20*.md 2>/dev/null && echo "openclaw"
ls ./MEMORY.md 2>/dev/null && echo "project-root"
```

Then write the config:

```bash
mkdir -p ~/.claude/skills/dream

# For native Claude Code memory (most common):
echo "DREAM_MEMORY_TYPE=native" > ~/.claude/skills/dream/.dream-config

# For openclaw-style:
# echo "DREAM_MEMORY_TYPE=openclaw" > ~/.claude/skills/dream/.dream-config
# echo "DREAM_MEMORY_PATH=$(pwd)/memory" >> ~/.claude/skills/dream/.dream-config
```

**Logseq brain/wiki (optional):** If you use a Logseq brain with the `logseq-brain` plugin, Phases 5 and 6 will auto-detect it from the plugin's `.brain-config.json`. No extra config needed.

## Usage

### Run manually

```
/sweet-dreams:dream
```

This spawns dream as a background `claude` process and immediately returns the PID and log path. Your session stays free.

### Automatic

After install, dream fires automatically when you end a session — if 24+ hours have passed since the last run. Zero overhead when the condition isn't met (~10ms check).

Dream report at next session start: the SessionStart hook checks for a new report and mentions it briefly in one line.

## Requirements

- Claude Code v2.1.59+
- No additional dependencies

## L1/L2/L3 Architecture

Dream operates across all three memory layers:

| Layer | Location | What it holds | Dream phases |
|-------|----------|---------------|--------------|
| L1 | `~/.claude/projects/*/memory/` | Per-project feedback, decisions, preferences | Phases 1–4 (consolidate), Phase 5 (lint), Phase 6 (promote from) |
| L2 | Logseq brain `Projects___*.md` | Active project context, session logs, plans | Phase 5 (lint), Phase 6 (promote from + to) |
| L3 | Logseq wiki `Wiki___*.md` | Cross-project knowledge, tech docs, patterns | Phase 5 (lint), Phase 6 (promote to) |

## How It Compares to Anthropic's Auto-Dream

| Feature | Anthropic (unreleased) | This Plugin |
|---------|----------------------|-------------|
| Session transcript scanning | Yes | Yes |
| Contradiction resolution | Yes | Yes |
| Date normalization | Yes | Yes |
| Auto-trigger | Built into binary | Stop hook (plugin system) |
| Memory system detection | Native only | Native + OpenClaw + custom |
| L2/L3 brain + wiki lint | Unknown | Yes (Phase 5) |
| Cross-layer promotion | Unknown | Yes (Phase 6) |
| Available now | Behind feature flag | Yes |

## License

MIT
