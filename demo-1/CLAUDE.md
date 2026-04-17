# Link Shelf — Subagent Demo

This demo showcases **Pattern 1: Subagents** from the O'Reilly CodeCon talk
"Orchestrating Coding Agents."

## What This Demo Shows

A parent orchestrator decomposes a single prompt into subagent briefs and runs
**independent tasks in parallel**. Each subagent:

1. Gets a **focused brief** with only the files it owns
2. Writes its code
3. Produces a **report file** (e.g. `DATA_LAYER_REPORT.md`) documenting its
   public interface and decisions
4. Dependent subagents read the report(s) to understand the interface

## Architecture

```
Parent Orchestrator
  ├─► Subagent 1: Data Layer     → db.js + DATA_LAYER_REPORT.md     ─┐
  ├─► Subagent 2: Business Logic → validation.js + BUSINESS_LOGIC_REPORT.md ─┤ (parallel)
  │                                                                   │
  └─► [waits for both] ──────────────────────────────────────────────-┘
      └─► Subagent 3: API Routes → server.js + API_ROUTES_REPORT.md   (sequential)
```

Data Layer and Business Logic are independent — they run simultaneously.
API Routes depends on both reports, so it runs after both complete.

## Tech Stack

- **Runtime**: Node.js
- **Framework**: Express
- **Database**: SQLite (via better-sqlite3)
- **Style**: CommonJS, minimal dependencies

## Key Points for the Talk

- Subagents CAN run in **parallel** when tasks are independent
- Parent **manually manages** the dependency graph (contrast with Agent Teams)
- Each subagent has **focused context** — only the files it owns
- Report files **bridge context** — but no peer messaging (contrast with Demo 2)
- Total cost is ~220k tokens — roughly 2 normal API calls
- The parent never touches a file directly — it just coordinates

## Testing

```bash
npm test           # Run the test suite
npm start          # Start the server on port 3456
curl localhost:3456/api/links  # List all bookmarks
```
