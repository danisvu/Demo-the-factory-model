#!/usr/bin/env bash
# ============================================================
# Demo 2 — Agent Teams Add Search to Link Shelf
# O'Reilly CodeCon 2026 · "Orchestrating Coding Agents"
#
# This script demonstrates Pattern 2: Agent Teams (parallel
# execution with coordination primitives). Three teammates
# work simultaneously with a shared task list, peer messaging,
# and automatic dependency resolution.
#
# Prerequisites: Demo 1 must have been run first (needs the
# base Link Shelf app files).
#
# Usage:
#   ./run.sh          # Copy base app + launch Agent Teams
#   ./run.sh --smoke  # Run smoke test against built output
#   ./run.sh --reset  # Delete generated files and start fresh
# ============================================================

set -euo pipefail
DEMO_DIR="$(cd "$(dirname "$0")" && pwd)"
DEMO1_DIR="$(dirname "$DEMO_DIR")/demo-1"
cd "$DEMO_DIR"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
PURPLE='\033[0;35m'
RED='\033[0;31m'
TEAL='\033[0;36m'
DIM='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m'

banner() {
  echo ""
  echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════${NC}"
  echo -e "${GREEN}${BOLD}  $1${NC}"
  echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════${NC}"
  echo ""
}

step() {
  echo -e "${GREEN}▸${NC} ${BOLD}$1${NC}"
}

info() {
  echo -e "  ${DIM}$1${NC}"
}

# ── Smoke test function ──────────────────────────────────────

run_smoke() {
  if [[ ! -f server.js ]]; then
    echo -e "${RED}server.js not found — run ./run.sh first to build the app.${NC}"
    exit 1
  fi

  step "Installing dependencies (if needed)..."
  [[ -d node_modules ]] || npm install --silent 2>/dev/null

  if [[ -f test.js ]]; then
    step "Running test suite..."
    echo ""
    npm test
    echo ""
  fi

  step "Smoke test: starting server..."
  node server.js &
  SERVER_PID=$!
  sleep 1

  echo ""
  step "Seeding test data..."
  for i in 1 2 3; do
    curl -s -X POST http://localhost:3456/api/links \
      -H "Content-Type: application/json" \
      -d "{\"url\":\"https://example${i}.com\",\"title\":\"Example ${i} - Node.js\",\"tags\":[\"test\"]}" > /dev/null
  done
  curl -s -X POST http://localhost:3456/api/links \
    -H "Content-Type: application/json" \
    -d '{"url":"https://react.dev","title":"React Documentation","tags":["frontend"]}' > /dev/null
  echo -e "  ${GREEN}→${NC} Seeded 4 bookmarks"

  echo ""
  step "Testing search endpoint..."
  SEARCH=$(curl -s "http://localhost:3456/api/links/search?q=node")
  echo -e "  ${GREEN}→${NC} GET /api/links/search?q=node"
  echo -e "  ${DIM}${SEARCH}${NC}"

  echo ""
  SEARCH2=$(curl -s "http://localhost:3456/api/links/search?q=react")
  echo -e "  ${GREEN}→${NC} GET /api/links/search?q=react"
  echo -e "  ${DIM}${SEARCH2}${NC}"

  echo ""
  SEARCH3=$(curl -s "http://localhost:3456/api/links/search?q=nonexistent")
  echo -e "  ${GREEN}→${NC} GET /api/links/search?q=nonexistent"
  echo -e "  ${DIM}${SEARCH3}${NC}"

  kill $SERVER_PID 2>/dev/null || true
  rm -f linkshelf.db

  echo ""
  banner "Demo 2 Complete"
  echo -e "${DIM}Search added to Link Shelf by 3 Agent Team teammates in parallel.${NC}"
  echo -e "${DIM}Shared task list + peer messaging + automatic dependency resolution.${NC}"
  echo ""
  echo -e "${BOLD}Contrast with Demo 1:${NC}"
  echo -e "  Demo 1: Subagents — parallel execution, ${ORANGE}manual coordination${NC}"
  echo -e "  Demo 2: Agent Teams — parallel execution, ${GREEN}built-in coordination${NC}"
  echo ""
}

# ── Handle flags ─────────────────────────────────────────────

if [[ "${1:-}" == "--reset" ]]; then
  banner "Resetting Demo 2"
  rm -f linkshelf.db linkshelf.db-shm linkshelf.db-wal
  rm -f db.js validation.js server.js test.js search.js
  rm -f DATA_LAYER_REPORT.md BUSINESS_LOGIC_REPORT.md API_ROUTES_REPORT.md
  rm -rf node_modules package-lock.json
  echo "Cleaned generated files."
  exit 0
fi

if [[ "${1:-}" == "--smoke" ]]; then
  banner "Running Smoke Test"
  run_smoke
  exit 0
fi

# ── Default: Copy base app + launch Agent Teams ──────────────

banner "Demo 2: Agent Teams Add Search to Link Shelf"

echo -e "${DIM}This demo shows Pattern 2: Agent Teams (true parallel with coordination).${NC}"
echo -e "${DIM}Starting from the Link Shelf app built in Demo 1, we add search using${NC}"
echo -e "${DIM}3 teammates with a shared task list, peer messaging, and auto-unblocking.${NC}"
echo ""
echo -e "  ${GREEN}Team Lead${NC} → creates task list, spawns teammates, synthesizes results"
echo -e "  ┌──────────────────────────────────────────────────────┐"
echo -e "  │  ${TEAL}SHARED TASK LIST${NC} (pending │ in_progress │ blocked)   │"
echo -e "  └──────────────────────────────────────────────────────┘"
echo -e "    ${BLUE}Backend${NC}  ←──peer msg──→  ${ORANGE}Frontend${NC}  ←──peer msg──→  ${PURPLE}Test${NC}"
echo -e "    search API             search UI              search tests"
echo -e "    (db + route)           (debounced)            ${RED}(blocked→auto-unblock)${NC}"
echo ""

# ── Check that Demo 1 has been run ───────────────────────────

if [[ ! -f "$DEMO1_DIR/server.js" ]] || [[ ! -f "$DEMO1_DIR/db.js" ]]; then
  echo -e "${RED}Error: Demo 1 output not found.${NC}"
  echo -e "${DIM}Run demo-1/run.sh first to build the base Link Shelf app.${NC}"
  exit 1
fi

# ── Copy base app from Demo 1 ───────────────────────────────

step "Copying base Link Shelf app from demo-1..."
cp "$DEMO1_DIR/db.js" .
cp "$DEMO1_DIR/validation.js" .
cp "$DEMO1_DIR/server.js" .
cp "$DEMO1_DIR/test.js" .
# Copy reports if they exist (for context)
cp "$DEMO1_DIR/DATA_LAYER_REPORT.md" . 2>/dev/null || true
cp "$DEMO1_DIR/BUSINESS_LOGIC_REPORT.md" . 2>/dev/null || true
cp "$DEMO1_DIR/API_ROUTES_REPORT.md" . 2>/dev/null || true
echo -e "  ${GREEN}→${NC} Copied db.js, validation.js, server.js, test.js"

# ── Install dependencies ─────────────────────────────────────

if [[ ! -d node_modules ]]; then
  step "Installing dependencies..."
  npm install --silent 2>/dev/null
  echo ""
fi

# ── Verify base app works ────────────────────────────────────

step "Verifying base app..."
if npm test 2>/dev/null | tail -1 | grep -q "0 failed"; then
  echo -e "  ${GREEN}→${NC} Base Link Shelf app is working"
else
  echo -e "  ${ORANGE}→${NC} Base app tests had issues (continuing anyway)"
fi
echo ""

# ── Launch Claude Code with Agent Teams ──────────────────────

step "Launching Claude Code with Agent Teams enabled..."
echo -e "  ${DIM}CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1${NC}"
echo ""

if ! cat <<'PROMPT' | CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 claude --dangerously-skip-permissions
You have a working bookmarks manager app called "Link Shelf" with Express and SQLite. The existing code has:
- db.js: SQLite data layer with CRUD operations
- validation.js: input validation and sanitization
- server.js: Express API with endpoints for /api/links (GET, POST, PUT, DELETE)
- test.js: test suite

Add SEARCH functionality to this app using Agent Teams. Create a team with 3 teammates:

1. BACKEND TEAMMATE: Add a search endpoint GET /api/links/search?q=<query> that searches links by title, url, and description using SQL LIKE queries. Add a searchLinks(query) function to db.js and wire up the route in server.js.

2. FRONTEND TEAMMATE: Add a simple search HTML page at GET /search that has a search input with debounced requests to the search API, and displays results as a list of clickable links. Serve it from server.js.

3. TEST TEAMMATE: Add search-specific tests to test.js that verify: search returns matching results, search with no matches returns empty array, search is case-insensitive, and the search endpoint validates input. This task DEPENDS on the backend teammate finishing the search API first.

The backend and frontend teammates should work IN PARALLEL. The test teammate should be BLOCKED until the backend API is done, then auto-unblock. The backend teammate should send the frontend teammate a peer message with the API contract once the endpoint is built. Use the shared task list with dependency tracking.
PROMPT
then
  echo ""
  echo -e "${RED}Claude exited with an error. Run ./run.sh --smoke after fixing.${NC}"
  exit 1
fi

echo ""

# ── Post-build: verify output ────────────────────────────────

if grep -q "search" server.js 2>/dev/null; then
  run_smoke
else
  echo -e "${ORANGE}Search functionality not found in server.js after Claude run.${NC}"
  echo -e "${DIM}Claude may not have finished. Re-run ./run.sh or check output.${NC}"
  exit 1
fi
