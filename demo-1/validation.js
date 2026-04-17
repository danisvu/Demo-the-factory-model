"use strict";

// ---------------------------------------------------------------------------
// Link Shelf — Business Logic / Validation
// Pure JavaScript, zero external dependencies.
// ---------------------------------------------------------------------------

/**
 * Strip HTML tags from a string using a simple regex.
 */
function stripHtml(str) {
  return str.replace(/<[^>]*>/g, "");
}

/**
 * Trim whitespace and strip HTML tags from a string.
 * Returns the cleaned string.
 *
 * @param {*} str
 * @returns {string}
 */
function sanitizeString(value) {
  if (value === undefined || value === null) return "";
  return stripHtml(String(value).trim());
}

/**
 * Check whether a string looks like a valid HTTP(S) URL.
 *
 * @param {string} url
 * @returns {boolean}
 */
function isValidUrl(str) {
  if (typeof str !== "string") return false;
  return /^https?:\/\/.+/i.test(str);
}

/**
 * Accept tags as a comma-separated string or an array.
 * Returns a cleaned comma-separated string.
 * Each tag is trimmed and sanitized; empty tags are removed.
 *
 * @param {string|string[]} tags
 * @returns {string}
 */
function parseTags(tags) {
  if (tags === undefined || tags === null) return "";
  let arr;
  if (Array.isArray(tags)) {
    arr = tags;
  } else {
    arr = String(tags).split(",");
  }
  return arr
    .map((t) => sanitizeString(t))
    .filter((t) => t.length > 0)
    .join(",");
}

// ---------------------------------------------------------------------------
// Core validation helpers
// ---------------------------------------------------------------------------

/**
 * Validate tag constraints: each tag max 50 chars, max 10 tags.
 * Returns an array of error strings (empty if valid).
 */
function validateTagRules(tagsStr) {
  const errors = [];
  if (!tagsStr) return errors;
  const arr = tagsStr.split(",");
  if (arr.length > 10) {
    errors.push("tags must have at most 10 entries");
  }
  for (const tag of arr) {
    if (tag.length > 50) {
      errors.push("each tag must be at most 50 characters");
      break; // one error is enough
    }
  }
  return errors;
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/**
 * Validate input for creating a new link.
 *
 * @param {{ url: string, title: string, description?: string, tags?: string|string[] }} input
 * @returns {{ valid: true, sanitized: object } | { valid: false, errors: string[] }}
 */
function validateLink(input) {
  const errors = [];
  const fields = input || {};

  // --- url (required) ---
  const url = sanitizeString(fields.url);
  if (!url) {
    errors.push("url is required");
  } else if (!isValidUrl(url)) {
    errors.push("url must start with http:// or https://");
  } else if (url.length > 2048) {
    errors.push("url must be at most 2048 characters");
  }

  // --- title (required) ---
  const title = sanitizeString(fields.title);
  if (!title) {
    errors.push("title is required");
  } else if (title.length > 500) {
    errors.push("title must be at most 500 characters");
  }

  // --- description (optional) ---
  const description = sanitizeString(fields.description);
  if (description.length > 2000) {
    errors.push("description must be at most 2000 characters");
  }

  // --- tags (optional) ---
  const tags = parseTags(fields.tags);
  errors.push(...validateTagRules(tags));

  if (errors.length > 0) {
    return { valid: false, errors };
  }

  return {
    valid: true,
    sanitized: { url, title, description, tags },
  };
}

/**
 * Validate input for a partial update of an existing link.
 * At least one field must be present. All fields are optional.
 *
 * @param {object} fields
 * @returns {{ valid: true, sanitized: object } | { valid: false, errors: string[] }}
 */
function validatePartialLink(fields) {
  const errors = [];
  const input = fields || {};
  const sanitized = {};

  const allowedKeys = ["url", "title", "description", "tags"];
  const presentKeys = allowedKeys.filter(
    (k) => input[k] !== undefined && input[k] !== null
  );

  if (presentKeys.length === 0) {
    return {
      valid: false,
      errors: ["At least one field (url, title, description, tags) must be provided"],
    };
  }

  if (input.url !== undefined && input.url !== null) {
    const url = sanitizeString(input.url);
    if (!url) {
      errors.push("url must not be empty");
    } else if (!isValidUrl(url)) {
      errors.push("url must start with http:// or https://");
    } else if (url.length > 2048) {
      errors.push("url must be at most 2048 characters");
    } else {
      sanitized.url = url;
    }
  }

  if (input.title !== undefined && input.title !== null) {
    const title = sanitizeString(input.title);
    if (!title) {
      errors.push("title must not be empty");
    } else if (title.length > 500) {
      errors.push("title must be at most 500 characters");
    } else {
      sanitized.title = title;
    }
  }

  if (input.description !== undefined && input.description !== null) {
    const description = sanitizeString(input.description);
    if (description.length > 2000) {
      errors.push("description must be at most 2000 characters");
    } else {
      sanitized.description = description;
    }
  }

  if (input.tags !== undefined && input.tags !== null) {
    const tags = parseTags(input.tags);
    const tagErrors = validateTagRules(tags);
    if (tagErrors.length > 0) {
      errors.push(...tagErrors);
    } else {
      sanitized.tags = tags;
    }
  }

  if (errors.length > 0) {
    return { valid: false, errors };
  }

  return { valid: true, sanitized };
}

/**
 * Validate that an id is a positive integer (string coercion allowed).
 *
 * @param {*} id
 * @returns {{ valid: true, id: number } | { valid: false, errors: string[] }}
 */
function validateId(id) {
  const num = Number(id);
  if (!Number.isInteger(num) || num <= 0) {
    return { valid: false, errors: ["id must be a positive integer"] };
  }
  return { valid: true, id: num };
}

/**
 * Validate a search query string.
 *
 * @param {*} query
 * @returns {{ valid: true, query: string } | { valid: false, errors: string[] }}
 */
function validateSearchQuery(query) {
  if (query === undefined || query === null) {
    return { valid: false, errors: ["query is required"] };
  }
  const trimmed = String(query).trim();
  if (trimmed.length === 0) {
    return { valid: false, errors: ["query must not be empty"] };
  }
  return { valid: true, query: trimmed };
}

// ---------------------------------------------------------------------------
// Exports
// ---------------------------------------------------------------------------

module.exports = {
  // Primary interface (per spec)
  validateLink,
  validatePartialLink,
  sanitizeString,
  isValidUrl,
  parseTags,

  // Aliases used by server.js and tests
  validateCreateLink: validateLink,
  validateUpdateLink: validatePartialLink,

  // Additional validators used by server.js
  validateId,
  validateSearchQuery,
};
