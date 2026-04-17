# Link Shelf — Project Knowledge

## Patterns & Conventions
- Use better-sqlite3 in WAL mode for concurrent reads
- Tags stored as JSON text in SQLite column
- CommonJS modules (require/module.exports)
- Express on port 3456
- Run `npm test` before marking any task as done

## Gotchas
- SQLite doesn't support array columns — tags are JSON.stringify'd text
- Always validate URL format before inserting
- Express route order matters — put specific routes before parameterized ones

## Style
- Prefer early returns for validation errors
- Use descriptive HTTP status codes (400 for validation, 404 for not found, 500 for server)
- Keep functions small and focused — one function per operation
- No console.log in production code — use only in test files

## Migrations (learned 2026-03-25)
- NEVER rely solely on CREATE TABLE IF NOT EXISTS to add new columns — it's a no-op when the table already exists with data
- ALWAYS use ALTER TABLE ADD COLUMN for adding columns to existing tables
- Wrap ALTER TABLE in try/catch ignoring "duplicate column" errors to make migrations idempotent (safe to run multiple times)
- Test migrations against both fresh databases AND existing databases with data

## Route Ordering (learned 2026-03-25)
- Named sub-routes like `/api/links/favorites` MUST be defined BEFORE parameterized routes like `/api/links/:id`, otherwise Express matches "favorites" as an :id parameter
- Same applies to `/api/links/search` — all literal paths before wildcard params

## Hook-Caught Mistakes (learned 2026-03-25)
- The grep console.log hook catches accidental debug logging — always check before marking a task done
- If adding new features, ensure the test file covers both positive AND negative cases (valid toggle, invalid id, non-existent link)
- Quality gate hooks are only as good as their exclusion patterns — exclude node_modules/ from grep checks to avoid false positives
