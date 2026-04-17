'use strict';

const path = require('path');
const Database = require('better-sqlite3');

const DEFAULT_DB_PATH = path.join(__dirname, 'linkshelf.db');

let db = null;

/**
 * Creates the links table if it does not exist and returns the db instance.
 * Accepts an optional dbPath for testing (defaults to linkshelf.db).
 * Safe to call multiple times (idempotent).
 */
function initDb(dbPath) {
  if (db) return db;

  db = new Database(dbPath || DEFAULT_DB_PATH);
  db.pragma('journal_mode = WAL');
  db.pragma('foreign_keys = ON');

  db.exec(`
    CREATE TABLE IF NOT EXISTS links (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      url         TEXT    NOT NULL UNIQUE,
      title       TEXT    NOT NULL,
      description TEXT    DEFAULT '',
      tags        TEXT    DEFAULT '',
      created_at  TEXT    DEFAULT CURRENT_TIMESTAMP,
      updated_at  TEXT    DEFAULT CURRENT_TIMESTAMP
    )
  `);

  return db;
}

/**
 * Return every link, newest first.
 */
function getAllLinks() {
  return db.prepare('SELECT * FROM links ORDER BY created_at DESC').all();
}

/**
 * Return a single link by id, or undefined if not found.
 */
function getLinkById(id) {
  return db.prepare('SELECT * FROM links WHERE id = ?').get(id);
}

/**
 * Insert a new link and return the full row.
 * Tags are stored as a comma-separated string.
 */
function createLink({ url, title, description = '', tags = '' }) {
  const stmt = db.prepare(
    `INSERT INTO links (url, title, description, tags)
     VALUES (@url, @title, @description, @tags)`
  );
  const info = stmt.run({ url, title, description, tags });
  return db.prepare('SELECT * FROM links WHERE id = ?').get(info.lastInsertRowid);
}

/**
 * Update only the provided fields on a link. Returns the updated row,
 * or null if the id does not exist.
 */
function updateLink(id, fields) {
  const allowed = ['url', 'title', 'description', 'tags'];
  const entries = Object.entries(fields).filter(([k]) => allowed.includes(k));

  if (entries.length === 0) {
    return getLinkById(id) || null;
  }

  const setClauses = entries.map(([k]) => `${k} = @${k}`);
  setClauses.push("updated_at = datetime('now')");

  const sql = `UPDATE links SET ${setClauses.join(', ')} WHERE id = @id`;
  const params = Object.fromEntries(entries);
  params.id = id;

  const info = db.prepare(sql).run(params);
  if (info.changes === 0) return null;

  return db.prepare('SELECT * FROM links WHERE id = ?').get(id);
}

/**
 * Delete a link by id. Returns { deleted: true } if a row was removed,
 * { deleted: false } otherwise.
 */
function deleteLink(id) {
  const info = db.prepare('DELETE FROM links WHERE id = ?').run(id);
  return { deleted: info.changes > 0 };
}

/**
 * Search links by title, url, or description (case-insensitive LIKE).
 * Returns matching rows, newest first.
 */
function searchLinks(query) {
  const pattern = `%${query}%`;
  return db
    .prepare(
      `SELECT * FROM links
       WHERE title LIKE @pattern
          OR url LIKE @pattern
          OR description LIKE @pattern
       ORDER BY created_at DESC`
    )
    .all({ pattern });
}

/**
 * Close the database connection.
 */
function closeDb() {
  if (db) {
    db.close();
    db = null;
  }
}

module.exports = {
  initDb,
  getAllLinks,
  getLinkById,
  createLink,
  updateLink,
  deleteLink,
  searchLinks,
  closeDb,
};
