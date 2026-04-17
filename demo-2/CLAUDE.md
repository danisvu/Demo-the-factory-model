# Link Shelf + Search — Agent Teams Demo

This demo showcases **Pattern 2: Agent Teams** from the O'Reilly CodeCon talk
"Orchestrating Coding Agents."

## What This Demo Shows

Starting from the working Link Shelf bookmarks app (built in Demo 1), we use
**Claude Code Agent Teams** to add search functionality with 3 teammates
working in parallel.

## Key Contrast with Demo 1 (Subagents)

| Feature | Demo 1 (Subagents) | Demo 2 (Agent Teams) |
|---|---|---|
| Parallelism | Manual (parent decides) | Automatic (shared task list) |
| Communication | Report files only | Peer-to-peer messaging |
| Dependencies | Parent manages graph | Auto-unblock on completion |
| Task tracking | Parent's context | Shared task list (Ctrl+T) |
| File safety | Manual scoping | File locking |

## Architecture

```
Team Lead
  │
  ├── SHARED TASK LIST (pending → in_progress → completed/blocked)
  │
  ├── Backend Teammate   → search API endpoint in server.js + db.js
  │     │
  │     └── peer msg ──► Frontend: "API contract: GET /api/links/search?q="
  │
  ├── Frontend Teammate  → search UI (search.html or search route)
  │
  └── Test Teammate      → search tests (BLOCKED until API done → auto-unblocks)
```

## What to Watch in the Demo

1. **Lead creates task list** with dependencies (test task blocked on API task)
2. **Backend + Frontend start simultaneously** in separate tmux panes
3. **Backend sends API contract** to Frontend via peer message
4. **Test task auto-unblocks** when Backend marks API task as completed
5. **All three working in parallel** — code written across panes simultaneously
6. **Lead synthesizes** results when all tasks complete

## Tech Stack

Same as Demo 1: Node.js, Express, SQLite (better-sqlite3), CommonJS

## Testing

```bash
npm test                                    # Full test suite
curl "localhost:3456/api/links/search?q=node"  # Search endpoint
```

## Recording Notes — Two Videos from One Run

Record `./run.sh` once and cut two videos from the same session:

### Demo 2 video (slide 13) — 90 seconds
- **Wide shot** of all three tmux panes running simultaneously
- Emphasize the parallelism: code being written across all panes at once
- End with the search feature working (smoke test output)

### Demo 3 video (slide 14) — 60 seconds
- **Tight crop** on the coordination mechanics, not the code output
- Three moments to capture:
  1. **Ctrl+T task list overlay** — show pending/in_progress/blocked statuses
     and the dependency annotation on the test task
  2. **Peer message arriving** — backend sends frontend the API contract
     (`GET /api/links/search?q= returns [{id,title,url}]`) directly, no lead
  3. **Auto-unblock transition** — the moment backend marks API task completed,
     the test task flips from blocked → pending and the test teammate starts

No separate `demo-3/` directory needed — same run, different edit.
