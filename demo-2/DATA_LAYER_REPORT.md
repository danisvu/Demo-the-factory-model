# Data Layer Report

## Public Interface

All functions are exported from `db.js` via `module.exports`. Call `initDb()` before using any other function.

### `initDb(dbPath?: string) -> Database`
Creates the `links` table if it does not exist. Returns the `better-sqlite3` database instance. Accepts an optional `dbPath` parameter (defaults to `linkshelf.db` in the project root). Idempotent -- subsequent calls return the cached instance.

### `getAllLinks() -> Row[]`
Returns all rows ordered by `created_at DESC`.

### `getLinkById(id: number) -> Row | undefined`
Returns a single row or `undefined` if not found.

### `createLink({ url, title, description?, tags? }) -> Row`
Inserts a new link. `description` defaults to `''`, `tags` defaults to `''`. Tags are stored as a comma-separated string. Returns the full inserted row (all columns including `id`, `created_at`, `updated_at`).

### `updateLink(id: number, fields: object) -> Row | null`
Accepts an object with any subset of `{ url, title, description, tags }`. Only the provided keys are updated; `updated_at` is always refreshed. Returns the updated row, or `null` if the id does not exist.

### `deleteLink(id: number) -> { deleted: boolean }`
Deletes the row. Returns `{ deleted: true }` when a row was removed, `{ deleted: false }` when the id was not found.

### `closeDb() -> void`
Closes the database connection and resets the internal reference.

## Schema

```sql
CREATE TABLE IF NOT EXISTS links (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  url         TEXT    NOT NULL UNIQUE,
  title       TEXT    NOT NULL,
  description TEXT    DEFAULT '',
  tags        TEXT    DEFAULT '',
  created_at  TEXT    DEFAULT CURRENT_TIMESTAMP,
  updated_at  TEXT    DEFAULT CURRENT_TIMESTAMP
)
```

## Notes

- **UNIQUE constraint on `url`** prevents duplicate bookmarks for the same URL.
- **WAL journal mode** is enabled for better concurrent read performance.
- **Module-level `db` variable** -- all functions share a single connection initialized by `initDb()`.
- **Dynamic SET clause in `updateLink`** -- only columns present in the `fields` object are included in the SQL, preventing accidental nullification of omitted fields.
- **Allowed-field whitelist in `updateLink`** -- prevents callers from overwriting `id`, `created_at`, or `updated_at` directly.
- **`initDb(dbPath)`** accepts an optional path so tests can use an in-memory or temp database without touching the production file.

### Row Shape

```json
{
  "id": 1,
  "url": "https://example.com",
  "title": "Example",
  "description": "",
  "tags": "demo,test",
  "created_at": "2026-03-25 12:00:00",
  "updated_at": "2026-03-25 12:00:00"
}
```
