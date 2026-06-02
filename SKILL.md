---
description: "Memory consolidation skill for Claude Code. Scans session transcripts for corrections, decisions, preferences, and patterns, then merges findings into persistent memory files. Auto-triggers via native Stop hook every 24hrs. Inspired by how sleep consolidates human memory."
tags: [memory, maintenance, consolidation, autonomous, hook]
---

# Dream - Memory Consolidation for Claude Code

> Your AI agent dreams like you do. Consolidates memory while you sleep.

---

## ONBOARDING (delete this section after setup is complete)

**Welcome! Follow these steps in order. After setup is verified, delete everything between `## ONBOARDING` and `## END ONBOARDING` from this file as the final step.**

### Step 1: Detect memory system

Before anything else, detect which memory system is in use. Run these checks:

```bash
# Check 1: Native Claude Code auto-memory
ls ~/.claude/projects/*/memory/MEMORY.md 2>/dev/null && echo "DETECTED: native-claude-code"

# Check 2: OpenClaw-style (memory/ folder in project root with daily logs)
ls ./memory/20*.md 2>/dev/null && echo "DETECTED: openclaw-daily-logs"

# Check 3: Project-root MEMORY.md (custom setup)
ls ./MEMORY.md 2>/dev/null && echo "DETECTED: project-root-memory"

# Check 4: Nothing found
echo "If none detected above: no memory system found"
```

**Based on what you detect, set DREAM_MEMORY_TYPE:**

| Detection | DREAM_MEMORY_TYPE | Memory location | Session transcripts |
|-----------|-------------------|-----------------|-------------------|
| `~/.claude/projects/*/memory/MEMORY.md` exists | `native` | `~/.claude/projects/<project>/memory/` | `~/.claude/projects/<project>/sessions/*.jsonl` |
| `./memory/20*.md` daily log files exist | `openclaw` | `./memory/` (project root) | `~/.claude/projects/<project>/sessions/*.jsonl` |
| `./MEMORY.md` exists in project root | `project-root` | `./` (project root, MEMORY.md + topic files) | `~/.claude/projects/<project>/sessions/*.jsonl` |
| Nothing found | `native` (default) | `~/.claude/projects/<project>/memory/` | `~/.claude/projects/<project>/sessions/*.jsonl` |

**If no memory system is found, default to native Claude Code memory.** This is the standard and requires no extra setup - Claude Code creates the directory automatically when auto-memory is enabled.

Write the detected type to the config so dream knows where to look:
```bash
echo "DREAM_MEMORY_TYPE=native" > ~/.claude/skills/dream/.dream-config
echo "DREAM_MEMORY_PATH=~/.claude/projects" >> ~/.claude/skills/dream/.dream-config
```

Replace `native` with `openclaw` or `project-root` if that's what was detected. For `openclaw` or `project-root`, also set the path:
```bash
# For openclaw:
echo "DREAM_MEMORY_TYPE=openclaw" > ~/.claude/skills/dream/.dream-config
echo "DREAM_MEMORY_PATH=$(pwd)/memory" >> ~/.claude/skills/dream/.dream-config

# For project-root:
echo "DREAM_MEMORY_TYPE=project-root" > ~/.claude/skills/dream/.dream-config
echo "DREAM_MEMORY_PATH=$(pwd)" >> ~/.claude/skills/dream/.dream-config
```

### Step 2: Install the Stop hook

Add the dream trigger to your Claude Code settings:

```bash
SETTINGS="$HOME/.claude/settings.json"
[ ! -f "$SETTINGS" ] && echo '{}' > "$SETTINGS"

python3 -c "
import json
with open('$HOME/.claude/settings.json') as f:
    s = json.load(f)
s.setdefault('hooks', {}).setdefault('Stop', [])
if not any('dream' in h.get('command','') for h in s['hooks']['Stop']):
    s['hooks']['Stop'].append({
        'type': 'command',
        'command': 'bash \$HOME/.claude/skills/dream/should-dream.sh && touch \$HOME/.claude/.dream-pending || true'
    })
with open('$HOME/.claude/settings.json', 'w') as f:
    json.dump(s, f, indent=2)
    f.write('\n')
print('Stop hook installed')
"
```

**What this does:** When you exit any Claude Code session, the Stop hook checks if 24+ hours have passed since the last dream. If yes, it creates a `.dream-pending` flag file. On your next session start, Claude sees the flag and runs `/dream` as a background subagent.

### Step 3: Install the session-start check

Add this to your global `~/.claude/CLAUDE.md` (or project CLAUDE.md):

```markdown
## Auto Dream
If the file `~/.claude/.dream-pending` exists at session start, run `/dream` as a subagent in the background, then delete the flag file: `rm ~/.claude/.dream-pending`. This is the memory consolidation system - it runs automatically every 24 hours.

At every session start also run:
`ls -t ~/.claude/.dream-reports/*.md 2>/dev/null | head -1`
If a report file exists, read its first 20 lines and tell the user in one sentence what the last dream did (fixes applied, warnings found). Say "show dream report YYYY-MM-DD" to read the full report.
```

### Step 4: Make should-dream.sh executable

```bash
chmod +x ~/.claude/skills/dream/should-dream.sh
```

### Step 5: Test it

Run a test dream to verify the full flow:

```bash
# Force the dream to trigger by creating the flag
touch ~/.claude/.dream-pending
```

Then tell Claude: "The .dream-pending flag exists. Run /dream now."

After it completes, verify:
- The flag file `~/.claude/.dream-pending` was deleted
- Memory files were reviewed and consolidated
- A `.last-dream` timestamp was written in the memory directory
- No relative dates remain in memory files
- MEMORY.md index is under 200 lines

### Step 6: Clean up onboarding

Everything is working. Now delete this entire ONBOARDING section from this SKILL.md file (everything between `## ONBOARDING` and `## END ONBOARDING`). The skill is fully set up and will auto-trigger every 24 hours via the Stop hook.

## END ONBOARDING

---

## How It Works

Dream runs in 6 sequential phases. Execute them in order. Do not skip phases.

```
ORIENT --> GATHER SIGNAL --> CONSOLIDATE --> PRUNE & INDEX --> LINT --> PROMOTE
```

### Auto-trigger flow (native Claude Code hooks)

```
Session ends
  --> Stop hook fires should-dream.sh (~10ms)
  --> Checks: 24hrs passed? 5+ sessions?
  --> If NO: exits silently, zero overhead
  --> If YES: creates ~/.claude/.dream-pending flag
Next session starts
  --> Claude reads CLAUDE.md, sees .dream-pending exists
  --> Spawns /dream as background subagent
  --> Dream runs all 6 phases
  --> Writes .last-dream timestamp, deletes .dream-pending
  --> Timer resets for next 24hrs
```

---

## Phase 1: ORIENT

**Goal:** Understand the current state of memory before changing anything.

### Step 0: Read config

```bash
cat ~/.claude/skills/dream/.dream-config 2>/dev/null || echo "DREAM_MEMORY_TYPE=native"
```

This tells you which memory system to target:
- `native` - scan `~/.claude/projects/*/memory/`
- `openclaw` - scan the `memory/` folder in the project root (daily logs + MEMORY.md)
- `project-root` - scan MEMORY.md and topic files in the project root

### Steps

1. Find memory directories based on type:
```bash
# native (default)
ls -d ~/.claude/projects/*/memory/ 2>/dev/null

# openclaw
ls ./memory/ 2>/dev/null

# project-root
ls ./MEMORY.md ./memory/ 2>/dev/null
```

2. Read the memory directory for the detected type:
```bash
# native
ls ~/.claude/projects/*/memory/ 2>/dev/null

# openclaw - also list daily logs
ls ./memory/*.md 2>/dev/null
```

3. Read `MEMORY.md` (the index file) in each project's memory directory. Note:
   - How many topic files exist
   - Total line count of MEMORY.md
   - Last modified dates
   - Any entries that look stale (relative dates like "yesterday", "last week" with no anchor)

4. Read each topic file to understand what's already stored.

### Step 5: Detect brain/wiki path

Run this to auto-detect the Logseq brain location:

```bash
BRAIN_CONFIG=$(find ~/.claude/plugins/cache/skillsmith/logseq-brain/ -name ".brain-config.json" 2>/dev/null | sort | tail -1)
if [[ -n "$BRAIN_CONFIG" ]]; then
    BRAIN_PATH=$(python3 -c "
import json, os
with open('$BRAIN_CONFIG') as f:
    d = json.load(f)
p = d.get('graphPath', '')
print(p.replace('~', os.environ['HOME']))
" 2>/dev/null)
fi
# Fall back to explicit override in .dream-config
if [[ -z "$BRAIN_PATH" ]]; then
    BRAIN_PATH=$(grep '^DREAM_BRAIN_PATH=' ~/.claude/skills/dream/.dream-config 2>/dev/null | cut -d= -f2- | sed "s|~|$HOME|g")
fi
```

If `BRAIN_PATH` resolves to an existing directory:
```bash
ls "$BRAIN_PATH/pages/Projects___"*.md 2>/dev/null | wc -l   # count brain project pages
ls "$BRAIN_PATH/pages/Wiki___"*.md 2>/dev/null | wc -l        # count wiki pages
```
Note the path — Phase 5 will use it.

If the path is empty or the directory doesn't exist: note "brain path not found — Phase 5 will run L1 lint only."

### Output of this phase
You should now have a mental map of:
- Which projects have L1 memory, what topics are covered, what's potentially stale
- Whether an L2/L3 brain path is available for Phase 5

---

## Phase 2: GATHER SIGNAL

**Goal:** Extract important information from recent sessions without reading everything.

### Where to find transcripts
```bash
find ~/.claude/projects/*/sessions/ -name "*.jsonl" -mtime -7 2>/dev/null | sort -t/ -k6 -r
```

This finds JSONL session files modified in the last 7 days, sorted newest first. Adjust `-mtime -7` for different windows.

### What to scan for

Use targeted grep, not full reads. Each pattern targets a specific signal type:

**User corrections** (highest priority):
```bash
grep -il "actually\|no,\|wrong\|incorrect\|not right\|stop doing\|don't do\|I said\|I meant\|that's not\|correction" ~/.claude/projects/*/sessions/*.jsonl 2>/dev/null
```

**Preferences and configuration:**
```bash
grep -il "I prefer\|always use\|never use\|I like\|I don't like\|I want\|from now on\|going forward\|remember that\|keep in mind\|make sure to\|default to" ~/.claude/projects/*/sessions/*.jsonl 2>/dev/null
```

**Important decisions:**
```bash
grep -il "let's go with\|I decided\|we're using\|the plan is\|switch to\|move to\|chosen\|picked\|decision\|we agreed" ~/.claude/projects/*/sessions/*.jsonl 2>/dev/null
```

**Recurring patterns:**
```bash
grep -il "again\|every time\|keep forgetting\|as usual\|same as before\|like last time\|we always\|the usual" ~/.claude/projects/*/sessions/*.jsonl 2>/dev/null
```

### How to read matches

For each file that matches, read ONLY the surrounding context of the match (not the full session). JSONL files have one JSON object per line. Focus on lines where `type` is `"human"` (user messages) and the immediately following `"assistant"` response.

```bash
grep -n "I prefer\|always use\|never use" <session_file> | head -20
```

### What to extract

For each finding, note:
- **The fact** - What was said or decided
- **The date** - Derive from the session file's modification time
- **Confidence** - Was it an explicit instruction (high) or implied preference (medium)?
- **Contradictions** - Does this conflict with anything currently in memory?

---

## Phase 3: CONSOLIDATE

**Goal:** Merge new findings into existing memory. This is the most delicate phase.

### Rules

1. **Never duplicate.** Before adding anything, check if it already exists in memory. If it does, update the existing entry rather than creating a new one.

2. **Convert relative dates to absolute.** If a session from March 15 says "yesterday I changed the API key", write "2026-03-14: Changed API key" in memory. Never store "yesterday" or "last week".

3. **Delete contradicted facts.** If memory says "Prefers tabs" but a recent session has the user saying "Use spaces", remove the old entry and write the new one. Add a note: `(Updated YYYY-MM-DD, previously: tabs)`.

4. **Preserve source attribution.** When adding a new memory entry, note where it came from: `(from session YYYY-MM-DD)`.

5. **Topic file organization.** Group related memories into topic files:
   - `preferences.md` - How the user likes things done
   - `decisions.md` - Choices and their rationale
   - `corrections.md` - Things the user corrected
   - `patterns.md` - Recurring workflows, common tasks
   - `facts.md` - Project-specific knowledge, architecture notes
   - Create new topic files only when existing ones don't fit

6. **Entry format.** Each memory entry should be concise:
```markdown
- [YYYY-MM-DD] The fact or preference. (source: session, confidence: high/medium)
```

### How to write

Use the Edit tool to modify existing memory files, or Write to create new topic files. Always read a file before editing it.

---

## Phase 4: PRUNE & INDEX

**Goal:** Keep MEMORY.md as a lean index. Remove stale content. Enforce size limits.

### MEMORY.md rules

MEMORY.md is an **index file**, not a content store. It should contain:
- Links/references to topic files
- A brief (one-line) summary of what each topic file contains
- The last-updated date for each topic file

MEMORY.md should **never** contain:
- Full memory entries (those go in topic files)
- Verbose descriptions
- Duplicate content that exists in topic files

### Size limit: 200 lines

If MEMORY.md exceeds 200 lines after consolidation:
1. Move any inline content to the appropriate topic file
2. Replace verbose entries with one-line summaries + links
3. Remove entries that point to deleted or empty topic files
4. If still over 200 lines, demote the oldest entries to an `archive.md` topic file

### Prune stale entries

Remove or archive entries that are:
- More than 90 days old with no references in recent sessions
- Contradicted by newer entries (should have been caught in Phase 3)
- About projects/repos that no longer exist in `~/.claude/projects/`

### Final index format

```markdown
# Memory Index

Last consolidated: YYYY-MM-DD

## Topic Files

| File | Summary | Updated |
|------|---------|---------|
| preferences.md | Editor, formatting, communication style preferences | YYYY-MM-DD |
| decisions.md | Architecture choices, tool selections, project direction | YYYY-MM-DD |
| corrections.md | Past mistakes to avoid repeating | YYYY-MM-DD |
| patterns.md | Common workflows and recurring tasks | YYYY-MM-DD |
| facts.md | Project knowledge, API details, system architecture | YYYY-MM-DD |

## Quick Reference

<!-- Only the 5-10 MOST important facts that affect every session -->
- Fact 1
- Fact 2
```

The Quick Reference section is for facts so important they should be seen every time memory is loaded. Keep it to 10 items maximum.

### Record the dream timestamp

After completing Phase 4 (L1 consolidation), write timestamps so the auto-trigger knows when you last dreamed:
```bash
date +%s > ~/.claude/projects/<project>/memory/.last-dream
rm -f ~/.claude/.dream-pending
```

Then initialize the report archive entry for Phase 5 to append to:
```bash
mkdir -p ~/.claude/.dream-reports
REPORT_FILE=~/.claude/.dream-reports/$(date +%Y-%m-%d).md
# Write (or append) the L1 consolidation header
{
  echo "# Dream Report — $(date '+%Y-%m-%d %H:%M')"
  echo ""
  echo "## L1 Consolidation"
  echo "- Projects: <list the projects that were consolidated>"
  echo "- Added: N, updated: N, archived: N, contradictions: N, dates fixed: N"
  echo ""
} >> "$REPORT_FILE"
```

---

## Safety

- **Never delete memory without replacement.** If removing an entry, either it was contradicted (replaced by a newer entry) or it was moved (to a topic file or archive). Never just delete.
- **Back up before first run.** On the very first run against a project, copy the memory directory:
```bash
cp -r ~/.claude/projects/<project>/memory/ ~/.claude/projects/<project>/memory-backup-$(date +%Y%m%d)/
```
- **Dry run option.** On first use, read through all phases but only print what you WOULD change, without writing. Confirm with the user before applying.

---

## Verification

After running, verify the consolidation:
1. `wc -l` on MEMORY.md - should be under 200 lines
2. Check that no topic file has duplicate entries
3. Confirm no relative dates remain ("yesterday", "last week", etc.)
4. Verify all topic files referenced in MEMORY.md actually exist
5. Print a summary: entries added, entries updated, entries archived, contradictions resolved

---

## Phase 5: LINT

**Goal:** Detect and auto-apply mechanical fixes across all three memory layers. Write findings to the report archive. See `references/lint-rules.md` for the complete rule table.

### Step 0: Brain path check

Use the `BRAIN_PATH` detected in Phase 1. If it was not found:
- Run Step 1 (L1 lint) only
- Append to the report: "L2/L3 lint skipped: brain path not found"
- Skip Steps 2–5

### Step 1: L1 Enhanced Lint

**Dead wiki links in L1 files:**
```bash
grep -rl '\[\[Wiki/' ~/.claude/projects/*/memory/*.md 2>/dev/null
```
For each file found, extract all `[[Wiki/X/Y]]` patterns. Derive the expected file:
`[[Wiki/Tech/Docker]]` → `$BRAIN_PATH/pages/Wiki___Tech___Docker.md`
(replace `/` with `___`, prepend `Wiki___`).
If the file doesn't exist: use Edit to remove that link from the L1 file. Record fix.

**Orphaned project references:**
```bash
for dir in ~/.claude/projects/*/memory/; do
    project=$(basename "$(dirname "$dir")")
    for f in "$dir"project_*.md; do
        [[ -f "$f" ]] || continue
        # flag if project dir itself no longer matches any active project
        echo "check: $project / $f"
    done
done
```
If a `project_*.md` file lives in a project directory that no longer corresponds to any real working directory (i.e., the path encoded in the directory name points nowhere), record as info in report. Do not delete.

**L1/L3 near-duplicate detection:**
For each `feedback_*.md` and `workflow_*.md` file in any L1 directory:
1. Extract 3–5 key nouns from the filename and first meaningful line.
2. Run: `grep -ril "<key terms>" "$BRAIN_PATH/pages/Wiki___"*.md 2>/dev/null`
3. If matches found: read both files. If they express the same core insight (not incidental mention), check whether the L1 file already has a `See also: [[Wiki/...]]` backlink. If not, add one using Edit. Record as info.

### Step 2: L2 Brain Lint

For each file in `$BRAIN_PATH/pages/Projects___*.md`:

**Property key typo (`updated::` → `last-updated::`):**
```bash
grep -rl '^updated::' "$BRAIN_PATH/pages/Projects___"*.md 2>/dev/null
```
For each file: use Edit to replace `updated::` with `last-updated::`. Record fix.

**Missing `last-updated::`:**
```bash
grep -rL 'last-updated::' "$BRAIN_PATH/pages/Projects___"*.md 2>/dev/null
```
Record each as a warning in the report. Do not fabricate timestamps.

**Stale active projects:**
For each `Projects___*.md` with `status:: active`: read `last-updated::`. Compute days since today:
```bash
TODAY=$(date +%Y-%m-%d)
```
If > 14 days since `last-updated::`: record as warning. No auto-fix.

**Broken internal links:**
For each `Projects___*.md`, extract all `[[...]]` patterns with:
```bash
grep -o '\[\[[^]]*\]\]' "$file"
```
Derive expected file for each:
- `[[Projects/Foo/Bar]]` → `Pages/Projects___Foo___Bar.md`
- `[[Wiki/X/Y]]` → `Pages/Wiki___X___Y.md`
- `[[Meta]]` → `pages/Meta.md`
- `[[Decisions]]` → `pages/Decisions.md`

All paths relative to `$BRAIN_PATH`. If the file doesn't exist: remove the broken `[[link]]` from the line using Edit (remove just the `[[...]]` token, preserve surrounding text). If the entire line's only content is the broken link, remove the whole line. Record each fix.

**Sub-issue orphan check:**
```bash
ls "$BRAIN_PATH/pages/Projects___"*___*.md 2>/dev/null
```
For each sub-issue page `Projects___Parent___Child.md`: check that `Projects___Parent.md` exists AND contains `[[Projects/Parent/Child]]`. If the link is missing: record as warning (no auto-add — parent structure varies).

### Step 3: L3 Wiki Lint

**Broken references (auto-fix: remove link):**
For each `Wiki___*.md`, extract all `[[...]]` links. For each, derive expected file (same mapping as Step 2). If not found: remove the broken `[[link]]` token (or whole line if it's the only content). Record fix.

**Hub completeness (auto-fix: add missing children):**
A hub page is any `Wiki___X.md` with no second `___` in the name (e.g., `Wiki___Tech.md`, `Wiki___Learning.md`).
For each hub:
```bash
# Find all direct children of this namespace
ls "$BRAIN_PATH/pages/Wiki___${NAMESPACE}___"*.md 2>/dev/null
```
For each child file `Wiki___X___Foo-Bar.md`: the expected link in the hub is `[[Wiki/X/Foo-Bar]]`.
```bash
grep -q '\[\[Wiki/'"$NAMESPACE"'/'"$CHILD_NAME"'\]\]' "$hub_file"
```
If not found: append the child link under the relevant section using Edit. Record fix.

**Stale confidence downgrade (auto-fix):**
```bash
grep -rl 'confidence:: high' "$BRAIN_PATH/pages/Wiki___"*.md 2>/dev/null
```
For each: read `updated::`. Compute the cutoff date (90 days before today):
```bash
# Linux
STALE_CUTOFF=$(date -d '90 days ago' +%Y-%m-%d 2>/dev/null)
# macOS fallback
[[ -z "$STALE_CUTOFF" ]] && STALE_CUTOFF=$(date -v-90d +%Y-%m-%d 2>/dev/null)
```
If `updated::` is before `$STALE_CUTOFF`: use Edit to replace `confidence:: high` with `confidence:: stale`. Record fix.

**Missing default properties (auto-fix where safe):**
For each `Wiki___*.md`:
- If `type:: entity` and `entity-type::` is missing: infer from content (look for tool/service/person/technology indicators in the page body) and add. Record fix.
- If `type:: entity` and `status::` is missing: add `status:: active`. Record fix.
- If `type:: knowledge` and `confidence::` is missing: add `confidence:: medium`. Record fix.
- If `created::` or `updated::` is missing: record as warning only — do not fabricate dates.

**Orphan detection (report only):**
Build an incoming-link index: for each wiki page, collect all `[[Wiki/...]]` references it receives from other pages. Pages with 0 incoming links (excluding hub pages) → record as info.

**Zero outgoing links (report only):**
```bash
grep -rL '\[\[' "$BRAIN_PATH/pages/Wiki___"*.md 2>/dev/null
```
Record each as warning.

**Empty pages (report only):**
A page where every non-blank line is a property (`word:: value` pattern) with no real content bullets. Record as warning.

**Credential leak (CRITICAL — report only, never auto-fix):**
```bash
grep -rni 'password\s*[:=]\|api.key\s*[:=]\|apikey\s*[:=]\|secret\s*[:=]\|bearer [A-Za-z0-9]\{20,\}' \
    "$BRAIN_PATH/pages/Wiki___"*.md 2>/dev/null
```
Any match → record as CRITICAL in report. Do not modify the file. Require manual review.

### Step 4: Cross-Layer Checks

**L1 file wiki link → nonexistent L3 page (auto-fix: remove link):**
Already handled in Step 1 "Dead wiki links in L1 files."

**L1/L3 semantic contradiction:**
For each L1 feedback file that matched a wiki page in Step 1 near-duplicate detection: read both files. Look for directly contradictory statements on the same factual claim (e.g., "use X" vs. "use Y" for the same tool). If found: record as warning with both file paths. No auto-fix — requires human judgment.

### Step 5: Commit L2/L3 fixes

If any auto-fixes were applied to files inside `$BRAIN_PATH` (Steps 2 or 3):
```bash
# Count total fixes from all steps
FIX_COUNT=<total count of fixes applied>
git -C "$BRAIN_PATH" add -A
git -C "$BRAIN_PATH" commit -m "dream-lint: auto-fix $FIX_COUNT issues (property keys, broken links, hub completeness)"
```
Then check `gitAutoPush` in the `.brain-config.json`:
```bash
GIT_PUSH=$(python3 -c "import json; d=json.load(open('$BRAIN_CONFIG')); print(d.get('gitAutoPush', False))" 2>/dev/null)
if [[ "$GIT_PUSH" == "True" ]]; then
    git -C "$BRAIN_PATH" push origin master --quiet &
fi
```
If no fixes were applied: skip the commit entirely.

### Step 6: Write report archive

Append the lint results to the report file initialized in Phase 4:
```bash
REPORT_FILE=~/.claude/.dream-reports/$(date +%Y-%m-%d).md
{
  echo "## Lint Fixes Applied"
  # list each fix, one per line, or "- none"
  echo ""
  echo "## Lint Warnings"
  # list each warning, one per line, or "- none"
  echo ""
  echo "## Lint Critical"
  # list each critical finding, or "- none"
} >> "$REPORT_FILE"
```

Print a final summary to the session output after Phase 6 completes:
```
Dream complete.
  L1: [N projects consolidated, N fixes]
  L2: [N brain pages checked, N fixes applied, N warnings]
  L3: [N wiki pages checked, N fixes applied, N warnings]
  Promotions: [N applied (L1→L3: N, L1→L2: N, L2→L3: N)]
  Report: ~/.claude/.dream-reports/YYYY-MM-DD.md
```

---

## Phase 6: PROMOTE

**Goal:** Move knowledge to the right layer. All promotions are auto-applied without confirmation. See `references/promotion-rules.md` for the complete criteria, target mappings, and distillation rules.

### Step 0: Brain path check

Use the `BRAIN_PATH` detected in Phase 1. If it was not found: skip all steps and append "L2/L3 promotion skipped: brain path not found" to the report.

### Step 1: L1 → L3 (Cross-project patterns to wiki)

For each `feedback_*.md` and `workflow_*.md` in `~/.claude/projects/*/memory/`:

**1a. Cross-project signal check.**
Read the file. Scan for project-specific identifiers using the patterns in `references/promotion-rules.md §Cross-Project Signal Detection`. If any are found → skip this file.

**1b. Near-duplicate check.**
Extract 3–5 key terms from the filename and first substantive line. Search L3:
```bash
grep -ril "<key terms>" "$BRAIN_PATH/pages/Wiki___"*.md 2>/dev/null
```
If the wiki already covers this insight: add a `See also: [[Wiki/...]]` backlink to the L1 file (if absent), skip promotion, record as "already in L3". Move to next file.

**1c. Select target wiki page.**
Apply the Target Namespace Mapping from `references/promotion-rules.md`:
- Gotcha / mistake-prevention → `Wiki___Reference___Failure-Patterns.md`
- Workflow / process rule → `Wiki___Learning___AI-Dev-Workflow-Patterns.md`
- `workflow_*.md` → `Wiki___Learning___AI-Dev-Workflow-Patterns.md`
- `ref_*.md` tool research → closest `Wiki___Tech___<Tool>.md`

If the target page doesn't exist: create it using the Schema template (`knowledge` type for patterns/workflows, `entity` type for tools). Hub pages must be updated to list the new child.

**1d. Distill and append.**
Read the target page. Write a new entry following the distillation format in `references/promotion-rules.md §Distillation Rules`. Append under the relevant section (`## Patterns`, `## Workflows`, or `## Key Decisions`). Update `updated::` on the target page using Edit.

**1e. Add backlink to source.**
Append `See also: [[Wiki/Namespace/Page]]` to the L1 source file using Edit. Record the promotion.

### Step 2: L1 → L2 (Project implementation details to brain)

For each `project_*.md` in `~/.claude/projects/*/memory/`:

**2a. Match to brain project.**
Extract a project key from the L1 directory name — take the last meaningful path segment (the portion after the final project-separator hyphen cluster):
```bash
# Example: ~/.claude/projects/-home-vladimir-dev-personal-antigravity-plugin-cc/memory/
# basename of parent dir: -home-vladimir-dev-personal-antigravity-plugin-cc
# project key (last word): antigravity-plugin-cc
```
Search for a matching brain page:
```bash
ls "$BRAIN_PATH/pages/Projects___"*.md 2>/dev/null | grep -i "$(echo $PROJECT_KEY | tr '-' '.')"
```
If no match found → skip.

**2b. Diff L1 vs L2.**
Read the L1 `project_*.md`. Read the matched brain page's `## Implementation` and `## Decisions` sections. Identify facts in L1 that are absent from L2 — typically: binary paths, auth mechanisms, interface flags, env vars, architecture decisions with rationale.

If no new facts → skip, record as "already in L2".

**2c. Append to brain page.**
For each new fact: append a distilled bullet to `## Implementation` (facts) or `## Decisions` (choices with rationale). Update `last-updated::`. Record promotion.

### Step 3: L2 → L3 (Graduated project knowledge to wiki)

**3a. Identify candidates.**
```bash
# Completed projects
grep -rl 'status:: completed' "$BRAIN_PATH/pages/Projects___"*.md 2>/dev/null

# Dormant active projects (last-updated > 45 days)
DORMANT_CUTOFF=$(date -d '45 days ago' +%Y-%m-%d 2>/dev/null || date -v-45d +%Y-%m-%d 2>/dev/null)
```
For each candidate: read `## Session Log` and `## Decisions`.

**3b. Extract durable learnings.**
Apply the eligibility rules from `references/promotion-rules.md §L2→L3 Eligibility`. Discard pure progress entries. Keep:
- Technology/library choices with rationale
- Recurring failure patterns that were resolved
- Process insights that generalize beyond the project

**3c. Near-duplicate check.**
For each durable learning: grep relevant wiki pages for key terms. If already covered → skip that entry.

**3d. Distill and write.**
For each new learning: read the target wiki page. Write a distilled entry in Logseq outliner format — Dream digests; it does not dump raw session notes. Target pages follow the mapping in `references/promotion-rules.md §Target Namespace Mapping`. Update `updated::`.

**3e. Mark source.**
In the brain page, append `promoted-to:: [[Wiki/Namespace/Page]] (YYYY-MM-DD)` as a child of the promoted entry. Do not delete the source.

### Step 4: Commit promotion writes

If any promotions were applied to files inside `$BRAIN_PATH`:
```bash
PROMO_COUNT=<total promotions applied>
git -C "$BRAIN_PATH" add -A
git -C "$BRAIN_PATH" commit -m "dream-promote: $PROMO_COUNT promotions (L1→L3, L1→L2, L2→L3)"
```
Check `gitAutoPush` in `.brain-config.json` (same as Phase 5 Step 5). Push if true.

### Step 5: Write promotion section to report

```bash
REPORT_FILE=~/.claude/.dream-reports/$(date +%Y-%m-%d).md
{
  echo "## Promotions Applied"
  # one line per promotion: "L1/project/feedback_foo.md → Wiki/Reference/Failure-Patterns"
  # or "- none"
  echo ""
} >> "$REPORT_FILE"
```
