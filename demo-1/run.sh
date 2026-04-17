#!/usr/bin/env bash
# ============================================================
# Demo 1 — Subagents Build Link Shelf
# O'Reilly CodeCon 2026 · "Orchestrating Coding Agents"
#
# This script demonstrates Pattern 1: Subagents with parallel
# execution. Independent subagents run simultaneously; dependent
# ones wait for their prerequisites.
#
# Usage:
#   ./run.sh          # Launch Claude Code to build Link Shelf
#   ./run.sh --test   # Just run tests on existing output
#   ./run.sh --smoke  # Run smoke test against built output
#   ./run.sh --reset  # Delete generated files and start fresh
# ============================================================

set -euo pipefail
DEMO_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DEMO_DIR"

# Colors for terminal output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
PURPLE='\033[0;35m'
RED='\033[0;31m'
DIM='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m'

banner() {
  echo ""
  echo -e "${BLUE}${BOLD}══════════════════════════════════════════════════${NC}"
  echo -e "${BLUE}${BOLD}  $1${NC}"
  echo -e "${BLUE}${BOLD}══════════════════════════════════════════════════${NC}"
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

  step "Running test suite..."
  echo ""
  npm test
  echo ""

  step "Smoke test: starting server..."
  node server.js &
  SERVER_PID=$!
  sleep 1

  echo ""
  step "Creating a bookmark..."
  RESULT=$(curl -s -X POST http://localhost:3456/api/links \
    -H "Content-Type: application/json" \
    -d '{"url":"https://addyosmani.com","title":"Addy Osmani","tags":["blog","engineering"]}')
  echo -e "  ${GREEN}→${NC} $RESULT"

  echo ""
  step "Listing all bookmarks..."
  LIST=$(curl -s http://localhost:3456/api/links)
  echo -e "  ${GREEN}→${NC} $LIST"

  echo ""
  step "Health check..."
  HEALTH=$(curl -s http://localhost:3456/api/health)
  echo -e "  ${GREEN}→${NC} $HEALTH"

  kill $SERVER_PID 2>/dev/null || true
  rm -f linkshelf.db

  echo ""
  banner "Demo 1 Complete"
  echo -e "${DIM}Link Shelf built by 3 subagents (2 parallel + 1 dependent).${NC}"
  echo -e "${DIM}Parallel execution where possible, but parent manages all dependencies.${NC}"
  echo -e "${DIM}No peer messaging, no shared task list, no auto-unblocking.${NC}"
  echo ""
  echo -e "${GREEN}${BOLD}Next:${NC} Demo 2 adds search using Agent Teams — same parallelism${NC}"
  echo -e "${NC}      but with coordination primitives: shared task list, peer${NC}"
  echo -e "${NC}      messaging, and automatic dependency resolution.${NC}"
  echo ""
}

# ── Handle flags ─────────────────────────────────────────────

if [[ "${1:-}" == "--reset" ]]; then
  banner "Resetting Demo 1"
  rm -f linkshelf.db
  rm -rf node_modules
  rm -f db.js validation.js server.js test.js
  rm -f DATA_LAYER_REPORT.md BUSINESS_LOGIC_REPORT.md API_ROUTES_REPORT.md
  echo "Cleaned generated files."
  exit 0
fi

if [[ "${1:-}" == "--test" ]]; then
  banner "Running Tests Only"
  npm test
  exit $?
fi

if [[ "${1:-}" == "--smoke" ]]; then
  banner "Running Smoke Test"
  run_smoke
  exit 0
fi

# ── Default: Launch Claude Code ──────────────────────────────

banner "Demo 1: Subagents Build Link Shelf"

echo -e "${DIM}This demo shows Pattern 1: Subagents with parallel execution.${NC}"
echo -e "${DIM}The parent orchestrator identifies independent tasks and runs them${NC}"
echo -e "${DIM}simultaneously, then runs dependent tasks after their prereqs complete.${NC}"
echo ""
echo -e "  ${GREEN}PHASE 1 (parallel)${NC}"
echo -e "    ${BLUE}Subagent 1${NC} → Data Layer    (db.js)          ┐"
echo -e "    ${ORANGE}Subagent 2${NC} → Business Logic (validation.js) ├─ run simultaneously"
echo -e "                                                ┘"
echo -e "  ${ORANGE}PHASE 2 (after both complete)${NC}"
echo -e "    ${PURPLE}Subagent 3${NC} → API Routes     (server.js)     ← reads both reports"
echo ""
echo -e "${DIM}Each subagent writes a report file. The parent manages dependencies manually.${NC}"
echo -e "${DIM}No shared task list, no peer messaging — that's what Agent Teams add (Demo 2).${NC}"
echo ""

# Install deps before Claude runs so subagents can require() them
if [[ ! -d node_modules ]]; then
  step "Installing dependencies..."
  npm install --silent 2>/dev/null
  echo ""
fi

step "Launching Claude Code with subagent prompt..."
echo ""

if ! cat <<'PROMPT' | claude --dangerously-skip-permissions
Build a bookmarks manager called "Link Shelf" using Express and SQLite (better-sqlite3). The app should support CRUD operations for bookmark links (url, title, description, tags), input validation and sanitization, RESTful API endpoints, and a test suite that verifies everything works.

IMPORTANT: Use the subagent pattern. Decompose this into exactly 3 focused subagents:

1. DATA LAYER SUBAGENT - builds db.js with SQLite schema and CRUD operations. When done, writes DATA_LAYER_REPORT.md documenting its public interface.

2. BUSINESS LOGIC SUBAGENT - builds validation.js with input validation and sanitization rules. When done, writes BUSINESS_LOGIC_REPORT.md.

3. API ROUTES SUBAGENT - reads both report files, then builds server.js wiring Express routes to validation and db layers. When done, writes API_ROUTES_REPORT.md documenting all endpoints.

Subagents 1 and 2 are INDEPENDENT - spawn them IN PARALLEL (simultaneously). Subagent 3 DEPENDS on both reports - spawn it AFTER both 1 and 2 complete. Each subagent should ONLY touch its own files. After all 3 finish, create test.js to verify the integration. Use port 3456.
PROMPT
then
  echo ""
  echo -e "${RED}Claude exited with an error. Run ./run.sh --smoke after fixing.${NC}"
  exit 1
fi

echo ""

# ── Post-build: verify output ────────────────────────────────

if [[ -f server.js ]]; then
  run_smoke
else
  echo -e "${ORANGE}server.js not found after Claude run.${NC}"
  echo -e "${DIM}Claude may not have finished. Re-run ./run.sh or check output.${NC}"
  exit 1
fi
