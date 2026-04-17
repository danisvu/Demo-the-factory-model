# API Routes Report

## Endpoints

| Method | Path | Description | Request Body | Success Response | Error Response |
|--------|------|-------------|--------------|------------------|----------------|
| GET | `/api/links` | List all bookmarks (newest first) | -- | `200 { links: [...] }` | -- |
| GET | `/api/links/:id` | Get a single bookmark by ID | -- | `200 { link: {...} }` | `400` invalid id, `404` not found |
| POST | `/api/links` | Create a new bookmark | `{ url, title, description?, tags? }` | `201 { link: {...} }` | `400` validation errors, `409` duplicate URL |
| PUT | `/api/links/:id` | Update an existing bookmark | `{ url?, title?, description?, tags? }` (at least one) | `200 { link: {...} }` | `400` validation errors, `404` not found, `409` duplicate URL |
| DELETE | `/api/links/:id` | Delete a bookmark | -- | `200 { deleted: true }` | `400` invalid id, `404` not found |

## Notes

- **Port**: The server listens on `3456`.
- **Body parsing**: `express.json()` middleware is enabled globally.
- **ID validation**: All `:id` params are validated with `validateId` -- must be a positive integer. Returns `400 { errors: [...] }` on failure.
- **Input validation**: POST uses `validateLink` (url and title required). PUT uses `validatePartialLink` (at least one field required). Both return `400 { errors: [...] }` on failure, and the sanitized data is forwarded to the data layer.
- **Unique constraint**: If a POST or PUT would create a duplicate `url`, the server catches the SQLite `SQLITE_CONSTRAINT_UNIQUE` error and returns `409 { errors: ["A link with this URL already exists"] }`.
- **Consistent error shape**: All error responses use `{ errors: [...] }` (an array of strings), never a single `error` string.
- **Exports**: `module.exports = { app, startServer, stopServer }`. The `app` export allows supertest-style testing without binding a port. `startServer(dbPath?)` initializes the database and listens; `stopServer(callback?)` closes the database and HTTP server.
- **Row shape**: `{ id, url, title, description, tags, created_at, updated_at }` -- tags is a comma-separated string.
