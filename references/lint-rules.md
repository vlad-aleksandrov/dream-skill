# Lint Rules Reference

All lint rules for Phase 5 of the Dream skill. Organized by layer. Marks which fixes are auto-applied vs. reported only.

## L1 — Local Claude Memory

| Rule | Severity | Auto-fix |
|------|----------|----------|
| MEMORY.md references a topic file that doesn't exist | warning | Remove broken reference line |
| Relative date in any memory file ("yesterday", "last week", etc.) | warning | Already handled in Phase 3 |
| Entry references a project dir that no longer exists in `~/.claude/projects/` | info | Report only |
| `[[Wiki/X/Y]]` link in an L1 file pointing to a nonexistent wiki page | warning | Remove the broken link |
| L1 feedback/workflow file content overlaps significantly with an L3 wiki page | info | Add `See also: [[Wiki/...]]` if not present; no removal |

## L2 — Brain Project Pages (`Projects___*.md`)

| Rule | Severity | Auto-fix |
|------|----------|----------|
| `updated::` property key instead of `last-updated::` | warning | Rename key in-place |
| `last-updated::` property missing entirely | warning | Report only (don't fabricate timestamps) |
| `status:: active` and last-updated > 14 days ago | warning | Report only |
| `status:: active` and `## Current Plan` is still placeholder | info | Report only |
| `[[Projects/X]]` link where `Projects___X.md` doesn't exist | critical | Remove the broken link or link line |
| `[[Wiki/X/Y]]` link where `Wiki___X___Y.md` doesn't exist | critical | Remove the broken link or link line |
| Sub-issue page `Projects___Parent___Child.md` exists but not linked from parent | warning | Report only |

## L3 — Wiki Pages (`Wiki___*.md`)

| Rule | Severity | Auto-fix |
|------|----------|----------|
| `[[link]]` pointing to a nonexistent `pages/*.md` file | critical | Remove the broken link |
| Hub page missing a child that exists as a file | warning | Append missing child link to hub |
| `confidence:: high` with `updated::` > 90 days old | warning | Change to `confidence:: stale` |
| Entity page missing `entity-type::` — inferable from content | warning | Add inferred value |
| Entity page missing `status::` | warning | Add `status:: active` as default |
| Knowledge page missing `confidence::` | warning | Add `confidence:: medium` as default |
| Page with 0 incoming links (not a hub page) | info | Report only |
| Page with 0 outgoing `[[links]]` | warning | Report only |
| Page with only property lines, no content | warning | Report only |
| Credential leak pattern (`password`, `api.key`, `apikey`, `secret`, `bearer [A-Za-z0-9]{20,}`) | critical | Report only — NEVER auto-fix |

## Cross-Layer

| Rule | Severity | Auto-fix |
|------|----------|----------|
| L1 file contains `[[Wiki/X/Y]]` link to nonexistent wiki page | warning | Remove the broken link from L1 file |
| L1 feedback entry and L3 wiki page state contradictory facts on same topic | warning | Report only — requires human judgment |

## Auto-Fix Commit

After applying all auto-fixes to L2/L3 files, commit in a single batch:
```bash
git -C $BRAIN_PATH add -A
git -C $BRAIN_PATH commit -m "dream-lint: auto-fix N issues (property keys, broken links, hub completeness)"
```
If `gitAutoPush: true` in `.brain-config.json`:
```bash
git -C $BRAIN_PATH push origin master --quiet &
```
If nothing was fixed, skip the commit.

## Report Archive Format

Written to `~/.claude/.dream-reports/YYYY-MM-DD.md` after each dream run. If a file already exists for today, append.

```markdown
# Dream Report — YYYY-MM-DD HH:MM

## L1 Consolidation
- Projects: [list]
- Added: N, updated: N, archived: N, contradictions: N, dates fixed: N

## Lint Fixes Applied
- [file]: [what was fixed]
- (or "none")

## Lint Warnings
- [file]: [issue]

## Lint Critical
- [file]: [issue] ← requires immediate attention
```
