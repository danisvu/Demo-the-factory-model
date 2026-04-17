# Business Logic Report

## Public Interface

### `validateLink({ url, title, description, tags })`

Validates and sanitizes input for creating a new bookmark link. All string fields are trimmed and stripped of HTML tags.

**Parameters** (single object):
- `url` (string, required) — must be a valid HTTP/HTTPS URL, max 2048 chars
- `title` (string, required) — must be non-empty after trim, max 500 chars
- `description` (string, optional) — max 2000 chars, defaults to `""`
- `tags` (string or string[], optional) — comma-separated string or array, max 10 tags, each max 50 chars

**Returns:**
- Success: `{ valid: true, sanitized: { url, title, description, tags } }` — `tags` is always a comma-separated string
- Failure: `{ valid: false, errors: string[] }`

---

### `validatePartialLink(fields)`

Validates and sanitizes input for a partial update (PATCH/PUT). Same rules as `validateLink` but all fields are optional. At least one field must be present. Only provided fields appear in `sanitized`.

**Parameters** (single object): same fields as `validateLink`, all optional.

**Returns:**
- Success: `{ valid: true, sanitized: { ...onlyProvidedFields } }`
- Failure: `{ valid: false, errors: string[] }`

---

### `sanitizeString(str)`

Trims whitespace and strips HTML tags from a value. Returns `""` for null/undefined.

**Parameters:** `str` (any) — value to sanitize.

**Returns:** `string`

---

### `isValidUrl(url)`

Checks that a string starts with `http://` or `https://` and has content after the prefix.

**Parameters:** `url` (string)

**Returns:** `boolean`

---

### `parseTags(tags)`

Normalizes tags input. Accepts a comma-separated string or an array of strings. Each tag is sanitized (trimmed, HTML stripped). Empty tags are removed.

**Parameters:** `tags` (string | string[] | null | undefined)

**Returns:** `string` — comma-separated, e.g. `"javascript,nodejs"`

---

### `validateId(id)`

Validates that `id` is a positive integer. String-to-number coercion is applied.

**Returns:** `{ valid: true, id: number }` or `{ valid: false, errors: string[] }`

---

### `validateSearchQuery(query)`

Validates that the search query is a non-empty string after trimming.

**Returns:** `{ valid: true, query: string }` or `{ valid: false, errors: string[] }`

---

## Validation Rules

| Field         | Required (create) | Type            | Max Length       | Notes                              |
|---------------|-------------------|-----------------|------------------|------------------------------------|
| `url`         | Yes               | string          | 2048 chars       | Must start with http:// or https://|
| `title`       | Yes               | string          | 500 chars        | Must be non-empty after trim       |
| `description` | No                | string          | 2000 chars       | Defaults to empty string           |
| `tags`        | No                | string or array | 10 tags, 50/each | Normalized to comma-separated      |

All string fields are sanitized: trimmed of whitespace and stripped of HTML tags.

## Notes

- Zero external dependencies — all validation is pure JavaScript.
- `validateCreateLink` and `validateUpdateLink` are exported as aliases for `validateLink` and `validatePartialLink` respectively, for backward compatibility with server.js.
- `parseTags` accepts both arrays and comma-separated strings so the API can handle either format from clients.
- HTML stripping uses a simple regex (`/<[^>]*>/g`), which is sufficient for basic XSS prevention on stored data.
- Tags are stored as a single comma-separated string (no separate tags table).
