# Promotion Rules Reference

Criteria for Phase 6 of the Dream skill. Covers all three promotion directions.

## Cross-Project Signal Detection

An L1 memory file is **project-specific** (not a promotion candidate) if it contains any of these patterns:

- Repo/service names: `callfire`, `nova`, `contacts`, `accounts`, `admin`, `notification`, `EZTexting`, `EZT`
- Ticket patterns: `EZ-\d+`, `JIRA-\d+`, `#\d{4,}`
- Absolute file paths referencing a specific repo (e.g., `/home/user/dev/callfire/src/...`)
- Database names, internal service hostnames, or internal API URLs specific to one project
- References to teammates by name in a task context ("assigned to X", "X's PR")

If **none** of the above are found → the file is a cross-project candidate.

## Target Namespace Mapping

| Source type | Content signal | Target |
|---|---|---|
| `feedback_*.md` | Mistake-prevention, gotcha, "always fetch before update", "don't do X" | `Wiki/Reference/Failure-Patterns` |
| `feedback_*.md` | Workflow rule, session process, agent behavior | `Wiki/Learning/AI-Dev-Workflow-Patterns` |
| `workflow_*.md` | Any content | `Wiki/Learning/AI-Dev-Workflow-Patterns` |
| `ref_*.md` | Research on a named tool | `Wiki/Tech/<ToolName>` (create if absent) |
| `ref_*.md` | General reference / comparison | `Wiki/Reference/<Topic>` (create if absent) |
| L2 Session Log entry | Tool/library choice with rationale | `Wiki/Tech/<Tool>` — `## Key Decisions` section |
| L2 Session Log entry | Failure pattern / gotcha | `Wiki/Reference/Failure-Patterns` — `## Patterns` section |
| L2 Session Log entry | Workflow insight | `Wiki/Learning/AI-Dev-Workflow-Patterns` |

When the target page doesn't exist: create it using the Schema template for the appropriate type (`entity` for tools, `knowledge` for patterns/workflows).

## Distillation Rules

Dream distills; it does not copy. For each promotion:

1. **Extract the principle** — the rule or insight in one line, stripped of task-specific context
2. **Preserve the why** — one line explaining the motivation or root cause
3. **Concrete how** — one example or trigger condition
4. **Source attribution** — `promoted-from::` property pointing at the source file path

Entry format (Logseq outliner):
```
  - [YYYY-MM-DD] <principle in one line>
    - **Why:** <motivation>
    - **How:** <application or trigger>
    - promoted-from:: <source file path>
```

Do NOT include:
- Ticket numbers or PR references from the source
- Names of specific engineers
- Task-specific implementation details
- More than 3 bullet levels

## Backlink Format

After promoting, add to the source L1 file (if not present):
```
See also: [[Wiki/Namespace/Page]]
```

After promoting from L2, add to the source brain page entry:
```
    - promoted-to:: [[Wiki/Namespace/Page]] (YYYY-MM-DD)
```

## Conservatism Rules

- When uncertain whether content is cross-project: **skip it**. Better to miss a promotion than to pollute L3 with project-specific noise.
- When a wiki page already covers the topic even partially: **add a backlink only**, do not append.
- When a completed project has mixed session log entries (some durable, some task-progress): promote **only** the durable entries; ignore "implemented X", "MR opened", "tests passing" lines.
- Never promote credentials, internal URLs, or anything that looks like a secret.

## L2 → L3 Eligibility

A brain project page is a promotion candidate if:
- `status:: completed` — project is done; learnings should graduate to L3
- `status:: active` AND last-updated > 45 days — effectively dormant; stable learnings can graduate

A Session Log or Decisions entry graduates to L3 if it contains:
- A technology/library choice and the rationale ("chose X over Y because...")
- A recurring failure that was resolved ("always do X before Y to avoid Z")
- A process insight that generalizes beyond this project

Pure progress entries do NOT graduate ("implemented feature X", "opened MR", "deployed to staging").
