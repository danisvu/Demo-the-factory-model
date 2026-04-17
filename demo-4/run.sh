#!/usr/bin/env bash
# ============================================================
# Demo 4 — Quality Gates & Self-Improving Agents
# O'Reilly CodeCon 2026 · "Orchestrating Coding Agents"
#
# This script demonstrates Pattern 3: Quality gates enforced
# by Agent Teams — plan approval, TaskCompleted hooks, and
# compound learning via AGENTS.md.
#
# Prerequisites: Demo 1 and Demo 2 must have been run first.
#
# Usage:
#   ./run.sh          # Copy base app + launch with quality gates
#   ./run.sh --smoke  # Run smoke test against built output
#   ./run.sh --reset  # Delete generated files and start fresh
# ============================================================

set -euo pipefail
DEMO_DIR="$(cd "$(dirname "$0")" && pwd)"
DEMO2_DIR="$(dirname "$DEMO_DIR")/demo-2"
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
  echo -e "${PURPLE}${BOLD}══════════════════════════════════════════════════${NC}"
  echo -e "${PURPLE}${BOLD}  $1${NC}"
  echo -e "${PURPLE}${BOLD}══════════════════════════════════════════════════${NC}"
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
      -d "{\"url\":\"https://example${i}.com\",\"title\":\"Example ${i}\",\"tags\":[\"test\"]}" > /dev/null
  done
  echo -e "  ${GREEN}→${NC} Seeded 3 bookmarks"

  echo ""
  step "Testing toggle favorite..."
  FAV=$(curl -s -X PUT http://localhost:3456/api/links/1/favorite)
  echo -e "  ${GREEN}→${NC} PUT /api/links/1/favorite"
  echo -e "  ${DIM}${FAV}${NC}"

  echo ""
  step "Testing list favorites..."
  FAVS=$(curl -s http://localhost:3456/api/links/favorites)
  echo -e "  ${GREEN}→${NC} GET /api/links/favorites"
  echo -e "  ${DIM}${FAVS}${NC}"

  echo ""
  step "Testing toggle favorite off..."
  FAV2=$(curl -s -X PUT http://localhost:3456/api/links/1/favorite)
  echo -e "  ${GREEN}→${NC} PUT /api/links/1/favorite (toggle off)"
  echo -e "  ${DIM}${FAV2}${NC}"

  echo ""
  step "Verify empty favorites..."
  FAVS2=$(curl -s http://localhost:3456/api/links/favorites)
  echo -e "  ${GREEN}→${NC} GET /api/links/favorites"
  echo -e "  ${DIM}${FAVS2}${NC}"

  echo ""
  step "Checking for console.log in production code..."
  if grep -r "console.log" --include="*.js" --exclude="test.js" . 2>/dev/null | grep -v node_modules | grep -v run.sh; then
    echo -e "  ${RED}✗${NC} Found console.log in production code (hook would catch this)"
  else
    echo -e "  ${GREEN}✓${NC} No console.log in production code"
  fi

  echo ""
  step "Checking AGENTS.md for new learnings..."
  if [[ -f AGENTS.md ]]; then
    LINES=$(wc -l < AGENTS.md)
    echo -e "  ${GREEN}→${NC} AGENTS.md has ${LINES} lines"
    echo -e "  ${DIM}Last 3 entries:${NC}"
    tail -3 AGENTS.md | while read -r line; do
      echo -e "  ${PURPLE}  ${line}${NC}"
    done
  fi

  kill $SERVER_PID 2>/dev/null || true
  rm -f linkshelf.db

  echo ""
  banner "Demo 4 Complete"
  echo -e "${DIM}Favorites added to Link Shelf with quality gates enforced:${NC}"
  echo -e "  ${ORANGE}1.${NC} Plan approval — lead reviewed and caught missing migration"
  echo -e "  ${GREEN}2.${NC} TaskCompleted hook — caught console.log, enforced test passing"
  echo -e "  ${PURPLE}3.${NC} AGENTS.md updated — compound learning for future sessions"
  echo ""
  echo -e "${BOLD}This is the self-improving loop:${NC}"
  echo -e "  ${DIM}Each session's mistakes become next session's guardrails.${NC}"
  echo ""
}

# ── Handle flags ─────────────────────────────────────────────

if [[ "${1:-}" == "--reset" ]]; then
  banner "Resetting Demo 4"
  rm -f linkshelf.db linkshelf.db-shm linkshelf.db-wal
  rm -f db.js validation.js server.js test.js search.js
  rm -f DATA_LAYER_REPORT.md BUSINESS_LOGIC_REPORT.md API_ROUTES_REPORT.md
  rm -rf node_modules package-lock.json
  # Restore AGENTS.md to original (without learned entries)
  echo -e "${DIM}Cleaned generated files. AGENTS.md preserved (reset manually if needed).${NC}"
  exit 0
fi

if [[ "${1:-}" == "--smoke" ]]; then
  banner "Running Smoke Test"
  run_smoke
  exit 0
fi

# ── Default: Copy base app + launch with quality gates ───────

banner "Demo 4: Quality Gates & Self-Improving Agents"

echo -e "${DIM}This demo shows Pattern 3: Quality gates that make agents self-improving.${NC}"
echo -e "${DIM}Starting from Link Shelf + search (Demo 2), we add favorites with:${NC}"
echo ""
echo -e "  ${ORANGE}ACT 1: PLAN APPROVAL${NC}"
echo -e "    Teammate submits plan → Lead reviews → ${RED}REJECT${NC} (missing migration)"
echo -e "    Teammate revises → Lead reviews → ${GREEN}APPROVE${NC}"
echo ""
echo -e "  ${GREEN}ACT 2: HOOKS ON TASK COMPLETION${NC}"
echo -e "    TaskCompleted hook fires automatically:"
echo -e "    ├── npm test ................... must ${GREEN}PASS${NC}"
echo -e "    └── grep console.log ........... must be ${GREEN}CLEAN${NC}"
echo -e "    Hook ${RED}FAILS${NC} → agent fixes → hook re-runs → ${GREEN}PASS${NC}"
echo ""
echo -e "  ${PURPLE}ACT 3: COMPOUND LEARNING${NC}"
echo -e "    Lead updates AGENTS.md with new learnings"
echo -e "    Next session reads these → avoids same mistakes"
echo ""

# ── Locate base app files ────────────────────────────────────

SOURCE_DIR=""
if [[ -f "$DEMO2_DIR/server.js" ]]; then
  SOURCE_DIR="$DEMO2_DIR"
  step "Using Demo 2 output (Link Shelf + search) as base..."
elif [[ -f "$DEMO1_DIR/server.js" ]]; then
  SOURCE_DIR="$DEMO1_DIR"
  step "Using Demo 1 output (Link Shelf) as base..."
else
  echo -e "${RED}Error: Neither Demo 1 nor Demo 2 output found.${NC}"
  echo -e "${DIM}Run demo-1/run.sh (and optionally demo-2/run.sh) first.${NC}"
  exit 1
fi

# ── Copy base app ────────────────────────────────────────────

step "Copying base app from $(basename "$SOURCE_DIR")..."
for f in db.js validation.js server.js test.js; do
  [[ -f "$SOURCE_DIR/$f" ]] && cp "$SOURCE_DIR/$f" .
done
# Copy search files if they exist (from demo-2)
for f in search.js search.html; do
  [[ -f "$SOURCE_DIR/$f" ]] && cp "$SOURCE_DIR/$f" .
done
# Copy reports for context
for f in DATA_LAYER_REPORT.md BUSINESS_LOGIC_REPORT.md API_ROUTES_REPORT.md; do
  [[ -f "$SOURCE_DIR/$f" ]] && cp "$SOURCE_DIR/$f" .
done
echo -e "  ${GREEN}→${NC} Copied base app files"

# ── Install dependencies ─────────────────────────────────────

if [[ ! -d node_modules ]]; then
  step "Installing dependencies..."
  npm install --silent 2>/dev/null
  echo ""
fi

# ── Save original AGENTS.md for diff later ───────────────────

cp AGENTS.md AGENTS.md.before 2>/dev/null || true

# ── Launch Claude Code with quality gates ────────────────────

step "Launching Claude Code with Agent Teams + quality gates..."
echo -e "  ${DIM}CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1${NC}"
echo ""

if ! cat <<'PROMPT' | CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 claude --dangerously-skip-permissions
You have a working bookmarks manager app called "Link Shelf" with Express and SQLite. Read the existing code files (db.js, validation.js, server.js, test.js) and the AGENTS.md file to understand the codebase.

Your task: Add a FAVORITES feature to Link Shelf using Agent Teams with QUALITY GATES enforced.

## Quality Gate 1: Plan Approval

Before writing ANY code, create a detailed plan for adding favorites. The plan must include:
- Database changes needed (schema migration)
- New API endpoints
- Validation rules
- Test cases

Submit the plan for review. Think critically about the plan — if it's missing a migration step for existing databases (ALTER TABLE to add an is_favorite column), the plan should be revised to include it. This is a common mistake: you can't just define a column in CREATE TABLE if the table already exists with data.

## Quality Gate 2: Implementation with Hooks

Implement the favorites feature:
1. Add is_favorite column to links table (ALTER TABLE migration for existing data)
2. Add PUT /api/links/:id/favorite endpoint to toggle favorites
3. Add GET /api/links/favorites endpoint to filter favorites only
4. Add tests for all favorites operations

After implementation, run these quality checks (simulating TaskCompleted hooks):
- Run `npm test` — ALL tests must pass
- Run `grep -rn "console.log" --include="*.js" --exclude="test.js" .` — there must be NO console.log in production code (test.js is excluded)
- If either check fails, fix the issue and re-run checks until both pass

## Quality Gate 3: Compound Learning

After all tasks pass, update AGENTS.md with new learnings from this session. Add entries like:
- Migration patterns (always use ALTER TABLE for existing tables)
- Any mistakes caught by hooks and how to avoid them
- New conventions discovered

These learnings will help future agent sessions avoid the same mistakes.

IMPORTANT: Show the plan review process explicitly in your output. Show the hook checks running and their results. Show the AGENTS.md update at the end.
PROMPT
then
  echo ""
  echo -e "${RED}Claude exited with an error. Run ./run.sh --smoke after fixing.${NC}"
  exit 1
fi

echo ""

# ── Post-build: verify quality gates worked ──────────────────

step "Verifying quality gates..."
echo ""

# Check 1: favorites functionality exists
if grep -q "favorite" server.js 2>/dev/null; then
  echo -e "  ${GREEN}✓${NC} Favorites feature found in server.js"
else
  echo -e "  ${RED}✗${NC} Favorites not found in server.js"
fi

# Check 2: no console.log in prod code
if grep -r "console.log" --include="*.js" --exclude="test.js" . 2>/dev/null | grep -v node_modules | grep -v run.sh | grep -q .; then
  echo -e "  ${RED}✗${NC} console.log found in production code (hook should have caught this)"
else
  echo -e "  ${GREEN}✓${NC} No console.log in production code"
fi

# Check 3: AGENTS.md was updated
if [[ -f AGENTS.md.before ]]; then
  BEFORE=$(wc -c < AGENTS.md.before)
  AFTER=$(wc -c < AGENTS.md)
  if [[ "$AFTER" -gt "$BEFORE" ]]; then
    echo -e "  ${GREEN}✓${NC} AGENTS.md was updated with new learnings"
    echo -e "  ${DIM}  Before: ${BEFORE} bytes → After: ${AFTER} bytes${NC}"
  else
    echo -e "  ${ORANGE}⚠${NC} AGENTS.md was not updated (agent may not have written learnings)"
  fi
  rm -f AGENTS.md.before
fi

echo ""

# Run full smoke test
run_smoke
