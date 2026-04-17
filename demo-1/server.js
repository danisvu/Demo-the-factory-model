'use strict';

const express = require('express');
const db = require('./db');
const { validateLink, validatePartialLink, validateId } = require('./validation');

const app = express();
app.use(express.json());

// ---------------------------------------------------------------------------
// Routes
// ---------------------------------------------------------------------------

// GET /api/links — list all links
app.get('/api/links', (_req, res) => {
  const links = db.getAllLinks();
  res.json({ links });
});

// GET /api/links/:id — get single link
app.get('/api/links/:id', (req, res) => {
  const check = validateId(req.params.id);
  if (!check.valid) {
    return res.status(400).json({ errors: check.errors });
  }

  const link = db.getLinkById(check.id);
  if (!link) {
    return res.status(404).json({ errors: ['Link not found'] });
  }

  res.json({ link });
});

// POST /api/links — create a new link
app.post('/api/links', (req, res) => {
  const result = validateLink(req.body);
  if (!result.valid) {
    return res.status(400).json({ errors: result.errors });
  }

  try {
    const link = db.createLink(result.sanitized);
    res.status(201).json({ link });
  } catch (err) {
    if (err.code === 'SQLITE_CONSTRAINT_UNIQUE') {
      return res.status(409).json({ errors: ['A link with this URL already exists'] });
    }
    throw err;
  }
});

// PUT /api/links/:id — update an existing link
app.put('/api/links/:id', (req, res) => {
  const idCheck = validateId(req.params.id);
  if (!idCheck.valid) {
    return res.status(400).json({ errors: idCheck.errors });
  }

  const result = validatePartialLink(req.body);
  if (!result.valid) {
    return res.status(400).json({ errors: result.errors });
  }

  try {
    const link = db.updateLink(idCheck.id, result.sanitized);
    if (!link) {
      return res.status(404).json({ errors: ['Link not found'] });
    }
    res.json({ link });
  } catch (err) {
    if (err.code === 'SQLITE_CONSTRAINT_UNIQUE') {
      return res.status(409).json({ errors: ['A link with this URL already exists'] });
    }
    throw err;
  }
});

// DELETE /api/links/:id — delete a link
app.delete('/api/links/:id', (req, res) => {
  const check = validateId(req.params.id);
  if (!check.valid) {
    return res.status(400).json({ errors: check.errors });
  }

  const result = db.deleteLink(check.id);
  if (!result.deleted) {
    return res.status(404).json({ errors: ['Link not found'] });
  }

  res.json({ deleted: true });
});

// ---------------------------------------------------------------------------
// Server lifecycle helpers (for testing)
// ---------------------------------------------------------------------------

let server = null;

/**
 * Initialize the database and start listening on port 3456.
 * Returns the http.Server instance.
 */
function startServer(dbPath) {
  db.initDb(dbPath);
  server = app.listen(3456, () => {
    console.log('Link Shelf API listening on http://localhost:3456');
  });
  return server;
}

/**
 * Close the database and stop the HTTP server.
 */
function stopServer(callback) {
  db.closeDb();
  if (server) {
    server.close(callback);
    server = null;
  } else if (callback) {
    callback();
  }
}

// ---------------------------------------------------------------------------
// Start when run directly
// ---------------------------------------------------------------------------

if (require.main === module) {
  startServer();
}

module.exports = { app, startServer, stopServer };
