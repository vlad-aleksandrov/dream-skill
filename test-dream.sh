#!/usr/bin/env bash
#
# test-dream.sh - Creates a realistic test environment for the dream skill
#
# Usage:
#   ./test-dream.sh setup     Create test fixtures
#   ./test-dream.sh verify    Check consolidation results after running /dream
#   ./test-dream.sh teardown  Remove test fixtures
#
# Workflow:
#   1. ./test-dream.sh setup
#   2. Run /dream in Claude Code (scoped to the test project)
#   3. ./test-dream.sh verify
#   4. ./test-dream.sh teardown
#

set -euo pipefail

TEST_PROJECT="dream-test-project"
BASE_DIR="$HOME/.claude/projects/$TEST_PROJECT"
SESSIONS_DIR="$BASE_DIR/sessions"
MEMORY_DIR="$BASE_DIR/memory"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# ============================================================================
# SETUP - Create test fixtures
# ============================================================================
do_setup() {
    info "Creating test environment at $BASE_DIR"

    if [[ -d "$BASE_DIR" ]]; then
        warn "Test directory already exists. Run '$0 teardown' first."
        exit 1
    fi

    mkdir -p "$SESSIONS_DIR" "$MEMORY_DIR"

    # --- Create initial MEMORY.md with deliberate problems ---
    cat > "$MEMORY_DIR/MEMORY.md" << 'MEMEOF'
# Memory Index

Last consolidated: 2025-01-15

## Topic Files

| File | Summary | Updated |
|------|---------|---------|
| preferences.md | Code style and tool preferences | 2025-01-15 |
| decisions.md | Project architecture decisions | 2025-01-10 |
| nonexistent.md | This file does not actually exist | 2025-01-05 |

## Quick Reference

- User prefers tabs for indentation
- Default branch is "develop"
- API base URL is https://api.oldservice.com/v1
- Yesterday the user mentioned they like dark themes
- The project uses React 17
- Last week we decided to use PostgreSQL
- User's timezone is PST
- Always use semicolons in JavaScript
- The user hates verbose commit messages
- Keep PRs under 200 lines
- User prefers vim keybindings
- Never auto-format on save
- The deploy target is AWS us-east-1
- Use yarn, not npm
- The user's name is probably Alex
MEMEOF

    # --- Create existing preferences.md with some stale entries ---
    cat > "$MEMORY_DIR/preferences.md" << 'PREFEOF'
# Preferences

- [2025-01-10] Prefers tabs for indentation (source: session, confidence: high)
- [2025-01-08] Always use semicolons in JavaScript (source: session, confidence: high)
- [2025-01-05] Use yarn for package management, not npm (source: session, confidence: high)
- [2025-01-03] Prefers dark theme in editor (source: inference, confidence: medium)
- [2024-06-15] Likes to use Sublime Text for quick edits (source: session, confidence: medium)
PREFEOF

    # --- Create existing decisions.md ---
    cat > "$MEMORY_DIR/decisions.md" << 'DECEOF'
# Decisions

- [2025-01-10] Using PostgreSQL for the database (source: session, confidence: high)
- [2025-01-08] Default branch is "develop" (source: session, confidence: high)
- [2025-01-05] Deploy target is AWS us-east-1 (source: session, confidence: high)
- [2025-01-03] API hosted at https://api.oldservice.com/v1 (source: session, confidence: high)
DECEOF

    # --- Session 1: 3 days ago - User corrects indentation preference ---
    local session1_date
    session1_date=$(date -v-3d +%Y-%m-%d 2>/dev/null || date -d "3 days ago" +%Y-%m-%d)
    local session1_file="$SESSIONS_DIR/${session1_date}_session1.jsonl"

    cat > "$session1_file" << SESS1EOF
{"type":"human","content":"Can you fix the indentation in src/app.ts?"}
{"type":"assistant","content":"Sure, I'll fix the indentation. I'll use tabs as per your preference."}
{"type":"human","content":"No, actually use spaces. 2 spaces. I switched from tabs a while ago, stop doing tabs."}
{"type":"assistant","content":"Got it! I'll use 2 spaces for indentation from now on. Updating the file now."}
{"type":"human","content":"Also, I prefer prettier for formatting. Always run prettier before committing."}
{"type":"assistant","content":"Understood. I'll make sure to run prettier before any commits."}
{"type":"human","content":"And my name is Jordan, not Alex. Not sure where that came from."}
{"type":"assistant","content":"Apologies Jordan! I'll remember that correctly going forward."}
SESS1EOF
    # Set the modification time to 3 days ago
    touch -t "$(date -v-3d +%Y%m%d1200 2>/dev/null || date -d '3 days ago' +%Y%m%d1200)" "$session1_file" 2>/dev/null || true

    # --- Session 2: 2 days ago - Architecture decision change ---
    local session2_date
    session2_date=$(date -v-2d +%Y-%m-%d 2>/dev/null || date -d "2 days ago" +%Y-%m-%d)
    local session2_file="$SESSIONS_DIR/${session2_date}_session2.jsonl"

    cat > "$session2_file" << SESS2EOF
{"type":"human","content":"We're moving the API to the new domain. The base URL is now https://api.newplatform.io/v2"}
{"type":"assistant","content":"I'll update all references to use the new API base URL: https://api.newplatform.io/v2"}
{"type":"human","content":"Also, I decided we're switching from PostgreSQL to SQLite for the local dev environment. Keep Postgres for production though."}
{"type":"assistant","content":"Makes sense. SQLite for local development, PostgreSQL for production. I'll update the config accordingly."}
{"type":"human","content":"Let's go with main as the default branch instead of develop. We're simplifying the git flow."}
{"type":"assistant","content":"Switching default branch from develop to main. I'll update the branch references."}
{"type":"human","content":"From now on, always include a test plan in PR descriptions. Every single PR, no exceptions."}
{"type":"assistant","content":"Understood. Every PR description will include a test plan section going forward."}
SESS2EOF
    touch -t "$(date -v-2d +%Y%m%d1400 2>/dev/null || date -d '2 days ago' +%Y%m%d1400)" "$session2_file" 2>/dev/null || true

    # --- Session 3: 1 day ago - Recurring patterns and preferences ---
    local session3_date
    session3_date=$(date -v-1d +%Y-%m-%d 2>/dev/null || date -d "1 day ago" +%Y-%m-%d)
    local session3_file="$SESSIONS_DIR/${session3_date}_session3.jsonl"

    cat > "$session3_file" << SESS3EOF
{"type":"human","content":"Again, can you make sure the error handling follows our pattern? Every time I have to remind you."}
{"type":"assistant","content":"Sorry about that. I'll follow the try/catch with custom error types pattern consistently. Could you confirm the pattern you want?"}
{"type":"human","content":"Use Result types, not try/catch. We use neverthrow. I keep forgetting to mention this at the start."}
{"type":"assistant","content":"Got it - Result types via neverthrow, not try/catch. I'll apply this pattern consistently."}
{"type":"human","content":"I prefer short commit messages. One line, under 50 chars. The body can have detail but the subject must be tight."}
{"type":"assistant","content":"Understood. Short subject lines under 50 characters, details in the commit body when needed."}
{"type":"human","content":"Oh and we're using pnpm now, not yarn. Switched last month."}
{"type":"assistant","content":"Updated - pnpm instead of yarn for package management."}
{"type":"human","content":"Remember that I'm usually reviewing code on my phone during commute, so keep PR descriptions scannable. Bullet points, not paragraphs."}
{"type":"assistant","content":"Will do - bullet points and scannable formatting in PR descriptions since you review on mobile."}
SESS3EOF
    touch -t "$(date -v-1d +%Y%m%d1600 2>/dev/null || date -d '1 day ago' +%Y%m%d1600)" "$session3_file" 2>/dev/null || true

    # --- Session 4: Old session (should be outside 7-day window but include anyway) ---
    local session4_file="$SESSIONS_DIR/2024-08-10_old_session.jsonl"
    cat > "$session4_file" << SESS4EOF
{"type":"human","content":"I like using Sublime Text for quick file edits"}
{"type":"assistant","content":"Noted, I'll keep that in mind."}
SESS4EOF
    touch -t "202408101200" "$session4_file" 2>/dev/null || true

    echo ""
    info "Test environment created successfully!"
    echo ""
    echo "Directory structure:"
    find "$BASE_DIR" -type f | sort | while read -r f; do
        echo "  $f"
    done
    echo ""
    echo "=== KNOWN ISSUES THE DREAM SKILL SHOULD FIX ==="
    echo ""
    echo "  1. MEMORY.md references nonexistent.md (does not exist)"
    echo "  2. MEMORY.md has relative dates ('Yesterday', 'Last week')"
    echo "  3. MEMORY.md exceeds ideal Quick Reference size (15 items, should be <=10)"
    echo "  4. preferences.md says 'tabs' but session corrected to '2 spaces'"
    echo "  5. preferences.md says 'yarn' but session corrected to 'pnpm'"
    echo "  6. decisions.md says branch is 'develop' but session changed to 'main'"
    echo "  7. decisions.md has old API URL, session provides new one"
    echo "  8. MEMORY.md says user's name is 'probably Alex' but it's Jordan"
    echo "  9. New preference: prettier before commits (not in memory yet)"
    echo "  10. New preference: Result types / neverthrow (not in memory yet)"
    echo "  11. New preference: short commit messages under 50 chars (not in memory yet)"
    echo "  12. New preference: test plan required in every PR (not in memory yet)"
    echo "  13. New preference: PR descriptions should be bullet points (mobile review)"
    echo "  14. New pattern: user keeps forgetting to mention neverthrow (recurring)"
    echo ""
    echo "=== NEXT STEPS ==="
    echo ""
    echo "  1. Open Claude Code"
    echo "  2. Run: /dream --project $TEST_PROJECT"
    echo "     (or invoke the dream skill and point it at $BASE_DIR)"
    echo "  3. After it completes, run: $0 verify"
    echo ""
}

# ============================================================================
# VERIFY - Check consolidation results
# ============================================================================
do_verify() {
    if [[ ! -d "$BASE_DIR" ]]; then
        fail "Test directory does not exist. Run '$0 setup' first."
        exit 1
    fi

    echo ""
    info "Verifying dream consolidation results..."
    echo ""

    local total=0
    local passed=0

    run_check() {
        total=$((total + 1))
        if eval "$1"; then
            pass "$2"
            passed=$((passed + 1))
        else
            fail "$2"
        fi
    }

    # --- MEMORY.md checks ---
    local memfile="$MEMORY_DIR/MEMORY.md"

    run_check "[[ -f '$memfile' ]]" \
        "MEMORY.md exists"

    run_check "[[ \$(wc -l < '$memfile') -le 200 ]]" \
        "MEMORY.md is under 200 lines ($(wc -l < "$memfile" 2>/dev/null || echo '?') lines)"

    run_check "! grep -qi 'nonexistent.md' '$memfile' 2>/dev/null" \
        "Stale reference to nonexistent.md removed"

    run_check "! grep -qi 'yesterday' '$memfile' 2>/dev/null" \
        "No relative date 'yesterday' in MEMORY.md"

    run_check "! grep -qi 'last week' '$memfile' 2>/dev/null" \
        "No relative date 'last week' in MEMORY.md"

    run_check "! grep -qi 'probably Alex' '$memfile' 2>/dev/null" \
        "Incorrect name 'probably Alex' removed from MEMORY.md"

    # --- Contradiction resolution ---
    local preffile="$MEMORY_DIR/preferences.md"

    if [[ -f "$preffile" ]]; then
        run_check "grep -qi 'spaces\|2.space' '$preffile' 2>/dev/null" \
            "Indentation updated to spaces in preferences"

        run_check "! grep -qE '(^|\s)tabs' '$preffile' 2>/dev/null || grep -qi 'previously.*tabs' '$preffile' 2>/dev/null" \
            "Old 'tabs' preference removed or marked as superseded"

        run_check "grep -qi 'pnpm' '$preffile' 2>/dev/null" \
            "Package manager updated to pnpm"

        run_check "grep -qi 'prettier' '$preffile' 2>/dev/null" \
            "Prettier preference added"

        run_check "grep -qi 'neverthrow\|result.type' '$preffile' 2>/dev/null" \
            "neverthrow / Result types preference added"
    else
        fail "preferences.md not found"
        total=$((total + 5))
    fi

    # --- Decision updates ---
    local decfile="$MEMORY_DIR/decisions.md"

    if [[ -f "$decfile" ]]; then
        run_check "grep -qi 'main' '$decfile' 2>/dev/null" \
            "Default branch updated to 'main'"

        run_check "grep -qi 'newplatform' '$decfile' 2>/dev/null" \
            "API URL updated to newplatform.io"

        run_check "grep -qi 'sqlite\|SQLite' '$decfile' 2>/dev/null" \
            "SQLite for dev environment noted"
    else
        fail "decisions.md not found"
        total=$((total + 3))
    fi

    # --- New entries that should have been created ---
    local all_memory
    all_memory=$(cat "$MEMORY_DIR"/*.md 2>/dev/null || echo "")

    run_check "echo '$all_memory' | grep -qi 'test.plan\|test plan'" \
        "Test plan requirement captured somewhere in memory"

    run_check "echo '$all_memory' | grep -qi 'bullet\|scannable\|mobile'" \
        "PR description format preference captured"

    run_check "echo '$all_memory' | grep -qi 'jordan'" \
        "User's name (Jordan) captured in memory"

    run_check "echo '$all_memory' | grep -qi 'commit.*50\|50.*char\|short commit'" \
        "Commit message length preference captured"

    # --- Date format checks ---
    run_check "! grep -rE '(yesterday|last week|last month|today|tomorrow)' '$MEMORY_DIR'/*.md 2>/dev/null | grep -v 'previously\|was\|changed from\|Updated.*previously' > /dev/null 2>&1" \
        "No unresolved relative dates in any memory file"

    # --- No duplicates check (basic) ---
    if [[ -f "$preffile" ]]; then
        local dup_count
        dup_count=$(sort "$preffile" | uniq -d | grep -c '.' 2>/dev/null || echo "0")
        run_check "[[ $dup_count -eq 0 ]]" \
            "No exact duplicate lines in preferences.md"
    fi

    # --- Summary ---
    echo ""
    echo "=============================="
    echo -e "  Results: ${passed}/${total} checks passed"
    echo "=============================="
    echo ""

    if [[ $passed -eq $total ]]; then
        echo -e "${GREEN}All checks passed! Dream consolidation looks correct.${NC}"
    elif [[ $passed -ge $((total * 3 / 4)) ]]; then
        echo -e "${YELLOW}Most checks passed. Review the failures above.${NC}"
    else
        echo -e "${RED}Several checks failed. The dream skill needs work.${NC}"
    fi

    echo ""
    echo "Manual review recommended. Check these files:"
    echo "  $MEMORY_DIR/MEMORY.md"
    find "$MEMORY_DIR" -name "*.md" ! -name "MEMORY.md" | sort | while read -r f; do
        echo "  $f"
    done
    echo ""
}

# ============================================================================
# TEARDOWN - Clean up test fixtures
# ============================================================================
do_teardown() {
    if [[ ! -d "$BASE_DIR" ]]; then
        warn "Test directory does not exist. Nothing to clean up."
        exit 0
    fi

    info "Removing test environment at $BASE_DIR"
    rm -rf "$BASE_DIR"

    if [[ -n "$LINT_BRAIN_DIR" && -d "$LINT_BRAIN_DIR" ]]; then
        info "Removing lint test brain at $LINT_BRAIN_DIR"
        rm -rf "$LINT_BRAIN_DIR"
    fi

    pass "Test environment removed."
}

# ============================================================================
# LINT SETUP - Create L2/L3 fixtures with known lint issues
# ============================================================================

LINT_BRAIN_DIR="$HOME/.claude/dream-lint-test-brain"

do_lint_setup() {
    if [[ -d "$LINT_BRAIN_DIR" ]]; then
        warn "Lint test brain already exists. Run '$0 lint-teardown' first."
        exit 1
    fi

    info "Creating lint test brain at $LINT_BRAIN_DIR"
    mkdir -p "$LINT_BRAIN_DIR/pages" "$LINT_BRAIN_DIR/journals"

    # Write a minimal .brain-config.json so the skill can find this test brain
    cat > "$LINT_BRAIN_DIR/.brain-config.json" << CFGEOF
{"graphPath": "$LINT_BRAIN_DIR", "gitAutoPush": false}
CFGEOF

    git -C "$LINT_BRAIN_DIR" init --quiet
    git -C "$LINT_BRAIN_DIR" commit --allow-empty -m "init" --quiet

    # --- L2: Project page with wrong property key (updated:: instead of last-updated::) ---
    cat > "$LINT_BRAIN_DIR/pages/Projects___Stale-Props.md" << 'PROJ1EOF'
type:: project
status:: active
created:: 2026-05-01
updated:: 2026-05-01

- ## Overview
  - Test project with wrong property key.
- ## Current Plan
  - _No active plan yet._
- ## Session Log
  - 2026-05-01 — Created.
PROJ1EOF

    # --- L2: Project page with a broken [[Wiki/...]] link ---
    cat > "$LINT_BRAIN_DIR/pages/Projects___Broken-Links.md" << 'PROJ2EOF'
type:: project
status:: active
created:: 2026-05-10
last-updated:: 2026-05-10

- ## Overview
  - Test project with a broken internal wiki link.
  - See [[Wiki/Tech/NonExistentPage]] for details.
- ## Current Plan
  - _No active plan yet._
- ## Session Log
  - 2026-05-10 — Created.
PROJ2EOF

    # --- L3: Wiki hub page missing a child entry ---
    cat > "$LINT_BRAIN_DIR/pages/Wiki___Tech.md" << 'HUBEOF'
- type:: hub
- namespace:: Wiki/Tech
- updated:: 2026-05-15
- ## Tech
	- [[Wiki/Tech/Docker]] -- container runtime
HUBEOF

    # Child exists as a file but is NOT listed in the hub
    cat > "$LINT_BRAIN_DIR/pages/Wiki___Tech___Docker.md" << 'TECHEOF'
- type:: entity
- entity-type:: tool
- created:: 2026-05-15
- updated:: 2026-05-15
- status:: active
- source:: ingest
- ## Docker
	- Container runtime.
	- [[Wiki/Tech]]
TECHEOF

    cat > "$LINT_BRAIN_DIR/pages/Wiki___Tech___Unlisted-Tool.md" << 'TECHEOF2'
- type:: entity
- entity-type:: tool
- created:: 2026-05-15
- updated:: 2026-05-15
- status:: active
- source:: ingest
- ## Unlisted Tool
	- This tool exists as a page but is NOT listed in the Wiki/Tech hub.
	- [[Wiki/Tech]]
TECHEOF2

    # --- L3: Wiki page with a broken cross-reference ---
    cat > "$LINT_BRAIN_DIR/pages/Wiki___Learning___Test-Topic.md" << 'LEARNEOF'
- type:: knowledge
- domain:: tech
- created:: 2026-05-15
- updated:: 2026-05-15
- confidence:: high
- ## Test Topic
	- Some learning content.
	- See also [[Wiki/Tech/NonExistentPage]] for more.
	- [[Wiki/Tech/Docker]]
LEARNEOF

    # --- L3: Wiki page with stale high-confidence (updated > 90 days ago) ---
    cat > "$LINT_BRAIN_DIR/pages/Wiki___Learning___Old-Topic.md" << 'OLDEOF'
- type:: knowledge
- domain:: tech
- created:: 2025-11-01
- updated:: 2025-11-01
- confidence:: high
- ## Old Topic
	- Content that hasn't been updated in over 90 days.
	- [[Wiki/Tech/Docker]]
OLDEOF

    # --- L3: Wiki entity page missing entity-type:: ---
    cat > "$LINT_BRAIN_DIR/pages/Wiki___Tech___Missing-Props.md" << 'PROPEOF'
- type:: entity
- created:: 2026-05-20
- updated:: 2026-05-20
- source:: ingest
- ## Missing Props Tool
	- An entity page without entity-type:: or status:: properties.
	- [[Wiki/Tech]]
PROPEOF

    # --- L1: feedback file with dead wiki link ---
    mkdir -p "$HOME/.claude/projects/dream-lint-test-l1/memory"
    cat > "$HOME/.claude/projects/dream-lint-test-l1/memory/feedback_test_dead_link.md" << FEEDEOF
---
name: feedback-test-dead-link
description: Test feedback file with a dead wiki link
metadata:
  type: feedback
---

Always check something before doing it.

**Why:** Test case for dead wiki link detection.

See [[Wiki/Tech/NonExistentPage]]
FEEDEOF

    cat > "$HOME/.claude/projects/dream-lint-test-l1/memory/MEMORY.md" << 'MEMEOF'
# Memory Index

- [Test dead link feedback](feedback_test_dead_link.md) — test fixture with dead wiki link
MEMEOF

    # Write a fake .dream-config pointing at the test brain
    # (backup real config if present, restore on teardown)
    REAL_CONFIG="$HOME/.claude/skills/dream/.dream-config"
    if [[ -f "$REAL_CONFIG" ]]; then
        cp "$REAL_CONFIG" "${REAL_CONFIG}.lint-test-backup"
    fi
    mkdir -p "$HOME/.claude/skills/dream"
    echo "DREAM_MEMORY_TYPE=native" > "$REAL_CONFIG"
    echo "DREAM_BRAIN_PATH=$LINT_BRAIN_DIR" >> "$REAL_CONFIG"

    echo ""
    info "Lint test environment created!"
    echo ""
    echo "=== KNOWN ISSUES THE LINT PHASE SHOULD FIX ==="
    echo ""
    echo "  L2 fixes (auto-apply):"
    echo "  1. Projects/Stale-Props: 'updated::' → 'last-updated::' property rename"
    echo "  2. Projects/Broken-Links: remove broken [[Wiki/Tech/NonExistentPage]] link"
    echo ""
    echo "  L3 fixes (auto-apply):"
    echo "  3. Wiki/Tech hub: missing child [[Wiki/Tech/Unlisted-Tool]] entry"
    echo "  4. Wiki/Learning/Test-Topic: remove broken [[Wiki/Tech/NonExistentPage]] link"
    echo "  5. Wiki/Learning/Old-Topic: confidence:: high → stale (updated 2025-11-01, >90 days)"
    echo "  6. Wiki/Tech/Missing-Props: add entity-type:: (infer from content) + status:: active"
    echo ""
    echo "  L1 fixes (auto-apply):"
    echo "  7. feedback_test_dead_link.md: remove dead [[Wiki/Tech/NonExistentPage]] link"
    echo ""
    echo "  Report only (no auto-fix):"
    echo "  8. Projects/Broken-Links: has last-updated:: but might be stale warning"
    echo ""
    echo "=== NEXT STEPS ==="
    echo ""
    echo "  1. Open Claude Code in this project"
    echo "  2. Run: /dream"
    echo "  3. After it completes, run: $0 lint-verify"
    echo ""
}

# ============================================================================
# LINT VERIFY - Check Phase 5 lint results
# ============================================================================
do_lint_verify() {
    if [[ ! -d "$LINT_BRAIN_DIR" ]]; then
        fail "Lint test brain does not exist. Run '$0 lint-setup' first."
        exit 1
    fi

    echo ""
    info "Verifying Phase 5 lint results..."
    echo ""

    local total=0
    local passed=0

    run_check() {
        total=$((total + 1))
        if eval "$1"; then
            pass "$2"
            passed=$((passed + 1))
        else
            fail "$2"
        fi
    }

    PAGES="$LINT_BRAIN_DIR/pages"
    L1_MEM="$HOME/.claude/projects/dream-lint-test-l1/memory"

    # --- L2 fixes ---
    run_check "grep -q 'last-updated::' '$PAGES/Projects___Stale-Props.md' && ! grep -q '^updated::' '$PAGES/Projects___Stale-Props.md'" \
        "L2: 'updated::' renamed to 'last-updated::' in Projects/Stale-Props"

    run_check "! grep -q 'NonExistentPage' '$PAGES/Projects___Broken-Links.md'" \
        "L2: broken [[Wiki/Tech/NonExistentPage]] link removed from Projects/Broken-Links"

    # --- L3 fixes ---
    run_check "grep -q 'Unlisted-Tool' '$PAGES/Wiki___Tech.md'" \
        "L3: Wiki/Tech hub now lists [[Wiki/Tech/Unlisted-Tool]]"

    run_check "! grep -q 'NonExistentPage' '$PAGES/Wiki___Learning___Test-Topic.md'" \
        "L3: broken [[Wiki/Tech/NonExistentPage]] removed from Wiki/Learning/Test-Topic"

    run_check "grep -q 'confidence:: stale' '$PAGES/Wiki___Learning___Old-Topic.md'" \
        "L3: Wiki/Learning/Old-Topic confidence downgraded from high to stale"

    run_check "grep -q 'entity-type::' '$PAGES/Wiki___Tech___Missing-Props.md'" \
        "L3: entity-type:: added to Wiki/Tech/Missing-Props"

    run_check "grep -q 'status:: active' '$PAGES/Wiki___Tech___Missing-Props.md'" \
        "L3: status:: active added to Wiki/Tech/Missing-Props"

    # --- L1 fixes ---
    run_check "! grep -q 'NonExistentPage' '$L1_MEM/feedback_test_dead_link.md'" \
        "L1: dead [[Wiki/Tech/NonExistentPage]] link removed from feedback file"

    # --- Report archive ---
    REPORT=$(ls -t ~/.claude/.dream-reports/*.md 2>/dev/null | head -1)
    run_check "[[ -n '$REPORT' && -f '$REPORT' ]]" \
        "Report archive written to ~/.claude/.dream-reports/"

    run_check "[[ -n '$REPORT' ]] && grep -q '## Lint' '$REPORT' 2>/dev/null" \
        "Report archive contains lint section"

    # --- Git commit in brain ---
    run_check "git -C '$LINT_BRAIN_DIR' log --oneline 2>/dev/null | grep -q 'dream-lint'" \
        "L2/L3 fixes committed to brain git repo"

    echo ""
    echo "=============================="
    echo -e "  Results: ${passed}/${total} checks passed"
    echo "=============================="
    echo ""

    if [[ $passed -eq $total ]]; then
        echo -e "${GREEN}All lint checks passed!${NC}"
    elif [[ $passed -ge $((total * 3 / 4)) ]]; then
        echo -e "${YELLOW}Most checks passed. Review failures above.${NC}"
    else
        echo -e "${RED}Several checks failed. Phase 5 needs work.${NC}"
    fi
    echo ""
}

# ============================================================================
# LINT TEARDOWN - Clean up lint fixtures
# ============================================================================
do_lint_teardown() {
    info "Removing lint test brain at $LINT_BRAIN_DIR"
    rm -rf "$LINT_BRAIN_DIR"

    info "Removing lint L1 test project"
    rm -rf "$HOME/.claude/projects/dream-lint-test-l1"

    # Restore real .dream-config if backed up
    REAL_CONFIG="$HOME/.claude/skills/dream/.dream-config"
    BACKUP="${REAL_CONFIG}.lint-test-backup"
    if [[ -f "$BACKUP" ]]; then
        mv "$BACKUP" "$REAL_CONFIG"
        info "Restored original .dream-config"
    elif [[ -f "$REAL_CONFIG" ]]; then
        rm -f "$REAL_CONFIG"
    fi

    pass "Lint test environment removed."
}

# ============================================================================
# Main
# ============================================================================
case "${1:-}" in
    setup)
        do_setup
        ;;
    verify)
        do_verify
        ;;
    teardown)
        do_teardown
        ;;
    lint-setup)
        do_lint_setup
        ;;
    lint-verify)
        do_lint_verify
        ;;
    lint-teardown)
        do_lint_teardown
        ;;
    *)
        echo "Usage: $0 {setup|verify|teardown|lint-setup|lint-verify|lint-teardown}"
        echo ""
        echo "  setup          - Create L1 test fixtures (original dream phases 1-4)"
        echo "  verify         - Verify phases 1-4 results"
        echo "  teardown       - Remove all test fixtures"
        echo ""
        echo "  lint-setup     - Create L2/L3 lint test fixtures (phase 5)"
        echo "  lint-verify    - Verify phase 5 lint results"
        echo "  lint-teardown  - Remove lint test fixtures"
        exit 1
        ;;
esac
