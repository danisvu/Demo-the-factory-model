# Link Shelf — Quality Gates Demo

This demo showcases **Pattern 3: Quality Gates & Self-Improving Agents** from the
O'Reilly CodeCon talk "Orchestrating Coding Agents."

## What This Demo Shows

Starting from the working Link Shelf app (with search from Demo 2), we add a
**favorites** feature using Agent Teams with quality gates enforced:

1. **Plan approval** — teammate must submit a plan for lead review before coding
2. **Hooks on task completion** — automated checks run when tasks are marked done
3. **AGENTS.md compound learning** — new discoveries get recorded for future sessions

## Architecture

```
Team Lead (reviews plans, enforces quality)
  │
  ├── SHARED TASK LIST with plan-approval gate
  │
  └── Feature Teammate
        │
        ├── Submits plan → Lead reviews
        │   ├── REJECT (missing migration) → revise plan
        │   └── APPROVE → proceed to implement
        │
        ├── Implements favorites feature
        │   ├── ALTER TABLE for is_favorite column
        │   ├── PUT /api/links/:id/favorite toggle
        │   ├── GET /api/links/favorites filter
        │   └── Tests for all favorites operations
        │
        ├── TaskCompleted hook fires:
        │   ├── npm test ............. must PASS
        │   └── grep console.log ..... must be CLEAN
        │   (if hook fails → fix issue → re-run hook)
        │
        └── Lead updates AGENTS.md with learnings
```

## Quality Gates Demonstrated

### 1. Plan Approval Gate
The teammate MUST submit a plan before writing any code. The lead reviews and
can reject with feedback. This catches architectural mistakes early — before any
code is written.

### 2. TaskCompleted Hook
When a task is marked as done, a hook automatically runs:
- `npm test` — all tests must pass
- `grep -r "console.log" --include="*.js" --exclude="test.js"` — no debug logs in production code

If the hook fails, the task stays in_progress and the agent must fix the issue.

### 3. Compound Learning (AGENTS.md)
After the session, the lead appends new learnings to AGENTS.md:
- Migration patterns discovered during plan review
- Common mistakes caught by hooks
- New conventions established

These learnings persist for all future agent sessions on this codebase.

## Tech Stack

Same as Demos 1-2: Node.js, Express, SQLite (better-sqlite3), CommonJS

## Testing

```bash
npm test                                           # Full test suite
curl -X PUT localhost:3456/api/links/1/favorite     # Toggle favorite
curl localhost:3456/api/links/favorites             # List favorites
```

## Key Points for the Talk

- Plan approval catches mistakes **before code is written** (shift-left)
- Hooks enforce quality **automatically** — no human needs to remember to check
- AGENTS.md creates **compound learning** — each session makes future sessions better
- This is the "self-improving" part: the system gets smarter over time
- Contrast with Demos 1-2: those had no quality enforcement at all
