'use strict';

const http = require('http');
const assert = require('assert');
const fs = require('fs');
const path = require('path');

// Use a temp database so tests don't pollute the real one
const tmpDb = path.join(__dirname, 'test_linkshelf.db');
[tmpDb, tmpDb + '-wal', tmpDb + '-shm'].forEach((f) => {
  try { fs.unlinkSync(f); } catch {}
});

const { app, startServer, stopServer } = require('./server');

const PORT = 3456;
let passed = 0;
let failed = 0;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function request(method, urlPath, body) {
  return new Promise((resolve, reject) => {
    const opts = {
      hostname: 'localhost',
      port: PORT,
      path: urlPath,
      method,
      headers: { 'Content-Type': 'application/json' },
    };
    const req = http.request(opts, (res) => {
      let data = '';
      res.on('data', (c) => (data += c));
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, body: JSON.parse(data) });
        } catch {
          resolve({ status: res.statusCode, body: data });
        }
      });
    });
    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function test(name, fn) {
  try {
    await fn();
    passed++;
    console.log(`  ✓ ${name}`);
  } catch (err) {
    failed++;
    console.log(`  ✗ ${name}`);
    console.log(`    ${err.message}`);
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

async function run() {
  startServer(tmpDb);
  await new Promise((r) => setTimeout(r, 200));

  console.log('\nLink Shelf — Test Suite\n');

  // --- Validation layer (unit) ---
  console.log('Validation:');
  const { validateLink, validatePartialLink, validateId, sanitizeString, isValidUrl, parseTags } = require('./validation');

  await test('validateLink rejects missing fields', () => {
    const r = validateLink({});
    assert.strictEqual(r.valid, false);
    assert.ok(r.errors.length >= 2);
  });

  await test('validateLink rejects invalid url', () => {
    const r = validateLink({ url: 'not-a-url', title: 'Test' });
    assert.strictEqual(r.valid, false);
    assert.ok(r.errors.some((e) => /url/i.test(e)));
  });

  await test('validateLink sanitizes HTML', () => {
    const r = validateLink({ url: 'https://example.com', title: '<b>Bold</b>' });
    assert.strictEqual(r.valid, true);
    assert.strictEqual(r.sanitized.title, 'Bold');
  });

  await test('validateLink passes valid input', () => {
    const r = validateLink({
      url: 'https://example.com',
      title: 'Example',
      description: 'A site',
      tags: 'demo',
    });
    assert.strictEqual(r.valid, true);
    assert.strictEqual(r.sanitized.url, 'https://example.com');
  });

  await test('validatePartialLink rejects empty input', () => {
    const r = validatePartialLink({});
    assert.strictEqual(r.valid, false);
  });

  await test('validatePartialLink accepts partial fields', () => {
    const r = validatePartialLink({ title: 'New' });
    assert.strictEqual(r.valid, true);
    assert.strictEqual(r.sanitized.title, 'New');
  });

  await test('validateId coerces string to number', () => {
    const r = validateId('42');
    assert.strictEqual(r.valid, true);
    assert.strictEqual(r.id, 42);
  });

  await test('validateId rejects non-positive', () => {
    assert.strictEqual(validateId(0).valid, false);
    assert.strictEqual(validateId(-1).valid, false);
    assert.strictEqual(validateId('abc').valid, false);
  });

  await test('sanitizeString strips HTML', () => {
    assert.strictEqual(sanitizeString('<script>evil</script>safe'), 'evilsafe');
  });

  await test('isValidUrl rejects non-http urls', () => {
    assert.strictEqual(isValidUrl('ftp://bad.com'), false);
    assert.strictEqual(isValidUrl('https://good.com'), true);
  });

  await test('parseTags handles array input', () => {
    assert.strictEqual(parseTags(['js', 'node']), 'js,node');
  });

  await test('parseTags handles comma string input', () => {
    assert.strictEqual(parseTags('js, node, '), 'js,node');
  });

  // --- Data layer (unit) ---
  console.log('\nData Layer:');
  const db = require('./db');

  await test('createLink inserts and returns row', () => {
    const row = db.createLink({ url: 'https://unit.test', title: 'Unit' });
    assert.ok(row.id);
    assert.strictEqual(row.url, 'https://unit.test');
    db.deleteLink(row.id);
  });

  await test('getLinkById returns undefined for missing', () => {
    const row = db.getLinkById(99999);
    assert.strictEqual(row, undefined);
  });

  await test('updateLink returns null for missing id', () => {
    const row = db.updateLink(99999, { title: 'Nope' });
    assert.strictEqual(row, null);
  });

  await test('deleteLink returns deleted false for missing', () => {
    const result = db.deleteLink(99999);
    assert.strictEqual(result.deleted, false);
  });

  // --- API integration ---
  console.log('\nAPI — CRUD lifecycle:');

  let createdId;

  await test('POST /api/links — create', async () => {
    const res = await request('POST', '/api/links', {
      url: 'https://nodejs.org',
      title: 'Node.js',
      description: 'JavaScript runtime',
      tags: 'node,js',
    });
    assert.strictEqual(res.status, 201);
    assert.ok(res.body.link.id);
    assert.strictEqual(res.body.link.url, 'https://nodejs.org');
    createdId = res.body.link.id;
  });

  await test('GET /api/links — list all', async () => {
    const res = await request('GET', '/api/links');
    assert.strictEqual(res.status, 200);
    assert.ok(Array.isArray(res.body.links));
    assert.ok(res.body.links.length >= 1);
  });

  await test('GET /api/links/:id — get one', async () => {
    const res = await request('GET', `/api/links/${createdId}`);
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.body.link.title, 'Node.js');
  });

  await test('PUT /api/links/:id — update', async () => {
    const res = await request('PUT', `/api/links/${createdId}`, {
      title: 'Node.js Updated',
      tags: 'node,javascript,runtime',
    });
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.body.link.title, 'Node.js Updated');
    assert.strictEqual(res.body.link.tags, 'node,javascript,runtime');
  });

  await test('DELETE /api/links/:id — delete', async () => {
    const res = await request('DELETE', `/api/links/${createdId}`);
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.body.deleted, true);
  });

  await test('GET /api/links/:id — 404 after delete', async () => {
    const res = await request('GET', `/api/links/${createdId}`);
    assert.strictEqual(res.status, 404);
  });

  // --- Error handling ---
  console.log('\nAPI — Error handling:');

  await test('POST /api/links — 400 on missing fields', async () => {
    const res = await request('POST', '/api/links', {});
    assert.strictEqual(res.status, 400);
    assert.ok(res.body.errors.length >= 1);
  });

  await test('POST /api/links — 400 on invalid URL', async () => {
    const res = await request('POST', '/api/links', { url: 'ftp://bad', title: 'Bad' });
    assert.strictEqual(res.status, 400);
  });

  await test('PUT /api/links/:id — 400 on empty body', async () => {
    const res = await request('PUT', '/api/links/1', {});
    assert.strictEqual(res.status, 400);
  });

  await test('GET /api/links/:id — 400 on invalid id', async () => {
    const res = await request('GET', '/api/links/abc');
    assert.strictEqual(res.status, 400);
  });

  await test('DELETE /api/links/999 — 404', async () => {
    const res = await request('DELETE', '/api/links/999');
    assert.strictEqual(res.status, 404);
  });

  await test('POST /api/links — HTML sanitization via API', async () => {
    const res = await request('POST', '/api/links', {
      url: 'https://xss.test',
      title: '<script>alert("xss")</script>Safe Title',
      description: '<img onerror=alert(1)>Clean',
    });
    assert.strictEqual(res.status, 201);
    assert.strictEqual(res.body.link.title, 'alert("xss")Safe Title');
    assert.strictEqual(res.body.link.description, 'Clean');
  });

  await test('POST /api/links — 409 duplicate URL', async () => {
    await request('POST', '/api/links', {
      url: 'https://duplicate.com',
      title: 'First',
    });
    const res = await request('POST', '/api/links', {
      url: 'https://duplicate.com',
      title: 'Second',
    });
    assert.strictEqual(res.status, 409);
    assert.ok(res.body.errors);
  });

  await test('POST /api/links — tags as array', async () => {
    const res = await request('POST', '/api/links', {
      url: 'https://tags-array.test',
      title: 'Tags Array Test',
      tags: ['javascript', 'nodejs'],
    });
    assert.strictEqual(res.status, 201);
    assert.strictEqual(res.body.link.tags, 'javascript,nodejs');
  });

  // --- Search API ---
  console.log('\nSearch API:');

  await test('Search returns matching results', async () => {
    await request('POST', '/api/links', {
      url: 'https://search-test-1.example.com',
      title: 'Search Target Alpha',
      description: 'A unique findable entry',
    });
    const res = await request('GET', '/api/links/search?q=Alpha');
    assert.strictEqual(res.status, 200);
    assert.ok(Array.isArray(res.body.links));
    assert.ok(res.body.links.length >= 1);
    assert.ok(res.body.links.some((l) => l.title === 'Search Target Alpha'));
  });

  await test('Search with no matches returns empty', async () => {
    const res = await request('GET', '/api/links/search?q=zzzznonexistent999');
    assert.strictEqual(res.status, 200);
    assert.ok(Array.isArray(res.body.links));
    assert.strictEqual(res.body.links.length, 0);
  });

  await test('Search is case-insensitive', async () => {
    await request('POST', '/api/links', {
      url: 'https://search-case-test.example.com',
      title: 'JavaScript Mastery',
    });
    const res = await request('GET', '/api/links/search?q=javascript');
    assert.strictEqual(res.status, 200);
    assert.ok(res.body.links.length >= 1);
    assert.ok(res.body.links.some((l) => /javascript/i.test(l.title)));
  });

  await test('Search validates input — missing q param returns 400', async () => {
    const res = await request('GET', '/api/links/search');
    assert.strictEqual(res.status, 400);
    assert.ok(res.body.errors);
  });

  await test('Search validates input — empty q param returns 400', async () => {
    const res = await request('GET', '/api/links/search?q=');
    assert.strictEqual(res.status, 400);
    assert.ok(res.body.errors);
  });

  // --- Favorites API ---
  console.log('\nFavorites API:');

  let favId;

  await test('POST create a link for favorites tests', async () => {
    const res = await request('POST', '/api/links', {
      url: 'https://favorites-test.example.com',
      title: 'Favorites Test Link',
    });
    assert.strictEqual(res.status, 201);
    favId = res.body.link.id;
    assert.strictEqual(res.body.link.is_favorite, 0);
  });

  await test('PUT /api/links/:id/favorite — toggle to favorite', async () => {
    const res = await request('PUT', `/api/links/${favId}/favorite`);
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.body.link.is_favorite, 1);
  });

  await test('GET /api/links/favorites — returns favorited links', async () => {
    const res = await request('GET', '/api/links/favorites');
    assert.strictEqual(res.status, 200);
    assert.ok(Array.isArray(res.body.links));
    assert.ok(res.body.links.some((l) => l.id === favId));
  });

  await test('PUT /api/links/:id/favorite — toggle to unfavorite', async () => {
    const res = await request('PUT', `/api/links/${favId}/favorite`);
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.body.link.is_favorite, 0);
  });

  await test('GET /api/links/favorites — unfavorited link not listed', async () => {
    const res = await request('GET', '/api/links/favorites');
    assert.strictEqual(res.status, 200);
    assert.ok(!res.body.links.some((l) => l.id === favId));
  });

  await test('PUT /api/links/999/favorite — 404 for non-existent', async () => {
    const res = await request('PUT', '/api/links/999/favorite');
    assert.strictEqual(res.status, 404);
    assert.ok(res.body.errors);
  });

  await test('PUT /api/links/abc/favorite — 400 for invalid id', async () => {
    const res = await request('PUT', '/api/links/abc/favorite');
    assert.strictEqual(res.status, 400);
    assert.ok(res.body.errors);
  });

  // --- Summary ---
  console.log(`\n─────────────────────────────`);
  console.log(`Results: ${passed} passed, ${failed} failed, ${passed + failed} total`);
  console.log(`─────────────────────────────\n`);

  stopServer(() => {
    [tmpDb, tmpDb + '-wal', tmpDb + '-shm'].forEach((f) => {
      try { fs.unlinkSync(f); } catch {}
    });
    process.exit(failed > 0 ? 1 : 0);
  });
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
