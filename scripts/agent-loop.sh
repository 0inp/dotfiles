#!/bin/bash
# agent-loop.sh — Linear ticket → branch → implement → ship → CI watch → auto-fix.
#
# Usage:
#   ./agent-loop.sh <linear-ticket-or-url> [repo...]
#
# Repo inference: Claude analyses the ticket and picks the repo(s) automatically.
# Pass extra repos as arguments to override (e.g. ./agent-loop.sh DEV-123 Table vicat).
#
# Phases (per repo, backend → frontend so the frontend sees the backend's contract):
#   implement → Claude runs the autonomous-ticket skill until tests are green
#   ship      → Claude reviews the diff, commits, pushes, opens a DRAFT PR
#   ci_wait   → bash blocks on `gh pr checks --watch` (guarded against the post-open race)
#   ci_fix    → on failure, Claude reads the failing job logs and fixes; circuit breaker

set -euo pipefail

LINEAR_URL="${1:-}"
shift || true
REPO_OVERRIDES=("$@")
MAX_CI_FIX_ATTEMPTS=3
SILLANT_DIR="$HOME/dev/sillant"
# The skill lives in the monorepo. The headless `claude -p` runs with cwd set to a sub-repo, so the
# Skill tool can't auto-discover it (it's neither the repo's project dir nor ~/.claude) — reference
# it by absolute path so the agent reads it directly. The implement-phase sentinel confirms it loaded.
SKILL_PATH="$HOME/.claude/skills/autonomous-ticket/SKILL.md"
# Canonical implement order — a contract flows backend → frontend, so vicat goes first.
REPO_ORDER=(vicat Table tender-bids-helper)

if [ -z "$LINEAR_URL" ]; then
  echo "❌ Usage: $0 <linear-url> [repo...]" >&2
  exit 1
fi

# --- 1. Load the Linear token (vicat/.env per the shared convention, then the repo-root .env).
for ENV_FILE in "$SILLANT_DIR/vicat/.env" "$SILLANT_DIR/.env"; do
  if [ -f "$ENV_FILE" ]; then
    set -a
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +a
  fi
done
LINEAR_API_TOKEN="${LINEAR_API_TOKEN:-${LINEAR_API_KEY:-}}"

if [ -z "$LINEAR_API_TOKEN" ]; then
  echo "❌ Neither LINEAR_API_TOKEN nor LINEAR_API_KEY is set (looked in vicat/.env and $SILLANT_DIR/.env)." >&2
  exit 1
fi

if [ ! -f "$SKILL_PATH" ]; then
  echo "❌ autonomous-ticket skill not found at $SKILL_PATH." >&2
  exit 1
fi

# --- 2. Fetch Linear ticket metadata.
ISSUE_ID=$(echo "$LINEAR_URL" | grep -oE '[A-Z]+-[0-9]+' || true)
if [ -z "$ISSUE_ID" ]; then
  echo "❌ Could not extract issue id from URL: $LINEAR_URL" >&2
  exit 1
fi

GRAPHQL_QUERY=$(printf '{"query":"query { issue(id: \\"%s\\") { title description branchName } }"}' "$ISSUE_ID")

RESPONSE=$(curl -sS -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: $LINEAR_API_TOKEN" \
  -d "$GRAPHQL_QUERY" \
  https://api.linear.app/graphql)

TICKET_TITLE=$(echo "$RESPONSE" | jq -r '.data.issue.title // empty')
TICKET_DESC=$(echo "$RESPONSE" | jq -r '.data.issue.description // empty')
BRANCH_NAME=$(echo "$RESPONSE" | jq -r '.data.issue.branchName // empty')

if [ -z "$TICKET_TITLE" ] || [ -z "$BRANCH_NAME" ]; then
  echo "❌ Linear API returned no issue for $ISSUE_ID. Raw response:" >&2
  echo "$RESPONSE" >&2
  exit 1
fi

# --- 3. Infer repo(s) with Claude (newline-separated; grep filters to valid values).
infer_repos() {
  claude -p "You are analysing a Linear ticket for Sillant, a French BTP SaaS platform.

The platform has 3 repos:
  Table              — React/TypeScript frontend. Covers: price-bible UI (a.k.a. price_db / B-PU), pdf-to-table UI, structure, recap, matching, import, tech-report UI. Any ticket about what users see or interact with.
  vicat              — FastAPI Python backend. Covers: price_bible API, pdf_to_table API, tech_report_analysis, file_api, common. Any ticket about endpoints, database models, migrations, server-side business logic.
  tender-bids-helper — Anvil Python orchestrator (main app shell). Tickets explicitly mentioning 'anvil', 'tbh', or 'tender-bids'.

Rules:
- Output ONLY the repo name(s) that need code changes, one per line.
- Valid values (exact, case-sensitive): Table, vicat, tender-bids-helper
- Output BOTH if the ticket clearly implies frontend + backend changes.
- No explanation, no other text.

Ticket ID: $ISSUE_ID
Title: $TICKET_TITLE
Branch: $BRANCH_NAME

Description:
$TICKET_DESC" 2>/dev/null | grep -E '^(Table|vicat|tender-bids-helper)$' || true
}

# Reorder REPOS into canonical backend→frontend order. Only the three known repos are valid (see
# inference + validation), so an intersection with REPO_ORDER is exhaustive; if it somehow yields
# nothing, leave REPOS untouched (and avoid expanding an empty array under `set -u` on bash 3.2).
order_repos() {
  local ordered=() pref repo
  for pref in "${REPO_ORDER[@]}"; do
    for repo in "${REPOS[@]}"; do
      [ "$repo" = "$pref" ] && ordered+=("$pref")
    done
  done
  [ "${#ordered[@]}" -gt 0 ] && REPOS=("${ordered[@]}")
}

REPOS=()
if [ "${#REPO_OVERRIDES[@]}" -gt 0 ]; then
  REPOS=("${REPO_OVERRIDES[@]}")
else
  echo "🔎 Inferring repo(s) from ticket…"
  while IFS= read -r line; do
    [ -n "$line" ] && REPOS+=("$line")
  done < <(infer_repos)
fi

if [ "${#REPOS[@]}" -eq 0 ]; then
  echo "🤔 Could not infer repo(s) from ticket. Pick one:"
  PS3="> "
  select R in Table vicat tender-bids-helper; do
    [ -n "$R" ] && REPOS=("$R") && break
  done
fi

# --- 4. Validate repos and refuse dirty trees before touching anything.
for REPO in "${REPOS[@]}"; do
  REPO_DIR="$SILLANT_DIR/$REPO"
  if [ ! -d "$REPO_DIR/.git" ]; then
    echo "❌ $REPO_DIR is not a git repository." >&2
    exit 1
  fi
  if ! git -C "$REPO_DIR" diff --quiet || ! git -C "$REPO_DIR" diff --cached --quiet; then
    echo "❌ $REPO has uncommitted changes — commit or stash first." >&2
    exit 1
  fi
done

order_repos
echo "📦 Repo(s): ${REPOS[*]}"

# --- 5. Prepare branches in all repos.
for REPO in "${REPOS[@]}"; do
  REPO_DIR="$SILLANT_DIR/$REPO"
  echo "--- Preparing branch $BRANCH_NAME in $REPO"
  git -C "$REPO_DIR" fetch origin
  git -C "$REPO_DIR" checkout main
  git -C "$REPO_DIR" pull --ff-only origin main

  if git -C "$REPO_DIR" ls-remote --exit-code --heads origin "$BRANCH_NAME" >/dev/null 2>&1; then
    git -C "$REPO_DIR" checkout "$BRANCH_NAME"
    git -C "$REPO_DIR" pull --ff-only origin "$BRANCH_NAME"
  elif git -C "$REPO_DIR" show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
    git -C "$REPO_DIR" checkout "$BRANCH_NAME"
  else
    git -C "$REPO_DIR" checkout -b "$BRANCH_NAME"
  fi
done

# --- 6. Phase helpers.
HEADLESS_OVERRIDE='You are running headless via `claude -p`. There is no human to confirm with. Do NOT ask for approval, do NOT produce a plan and stop, do NOT engage brainstorming alignment gates. Execute and emit only the final result on stdout.'

claude_run() {
  local dir="$1"
  local prompt="$2"
  (cd "$dir" && claude -p \
    --permission-mode bypassPermissions \
    --verbose \
    --output-format stream-json \
    --append-system-prompt "$HEADLESS_OVERRIDE" \
    "$prompt")
}

has_local_work() {
  local repo_dir="$1"
  ! git -C "$repo_dir" diff --quiet ||
    ! git -C "$repo_dir" diff --cached --quiet ||
    [ -n "$(git -C "$repo_dir" log origin/main..HEAD --oneline 2>/dev/null || true)" ]
}

# For a multi-repo ticket, surface the (uncommitted) changes already made in sibling repos this
# run, so a later frontend agent stays consistent with the backend's contract (field names,
# endpoints, payload shapes). Capped so a large backend diff can't blow up the prompt.
sibling_context() {
  local current="$1" repo repo_dir diff out=""
  [ "${#REPOS[@]}" -le 1 ] && {
    printf ''
    return 0
  }
  for repo in "${REPOS[@]}"; do
    [ "$repo" = "$current" ] && continue
    repo_dir="$SILLANT_DIR/$repo"
    diff=$(git -C "$repo_dir" diff 2>/dev/null | head -n 400 || true)
    if [ -n "$diff" ]; then
      out+=$(printf '\n--- Contract context: changes already made this run in sibling repo %s (uncommitted, truncated to 400 lines). Stay consistent with these. ---\n%s\n' "$repo" "$diff")
    fi
  done
  printf '%s' "$out"
}

print_digest() {
  local repo="$1" status="$2" pr="${3:-}"
  local repo_dir="$SILLANT_DIR/$repo"
  echo "----------------------------------------"
  echo "📊 $ISSUE_ID — $repo @ $BRANCH_NAME"
  echo "   status  : $status"
  [ -n "$pr" ] &&
    echo "   PR      : $(cd "$repo_dir" && gh pr view "$pr" --json url --jq '.url' 2>/dev/null || echo "#$pr")"
  echo "   commits : $(git -C "$repo_dir" log origin/main..HEAD --oneline 2>/dev/null | wc -l | tr -d ' ')"
  echo "   changed : $(git -C "$repo_dir" diff origin/main...HEAD --name-only 2>/dev/null | wc -l | tr -d ' ') file(s)"
  git -C "$repo_dir" --no-pager diff origin/main...HEAD --stat 2>/dev/null | sed 's/^/     /' | tail -20
}

phase_implement() {
  local repo="$1"
  local repo_dir="$SILLANT_DIR/$repo"
  local impl_log
  impl_log=$(mktemp -t agent-loop-impl-XXXXXX.log)
  local ticket_context siblings
  ticket_context=$(printf 'Ticket ID: %s\nTitle: %s\nImplementing in repo: %s (all affected repos: %s)\nBranch: %s\n\nDescription:\n%s\n' \
    "$ISSUE_ID" "$TICKET_TITLE" "$repo" "${REPOS[*]}" "$BRANCH_NAME" "$TICKET_DESC")
  siblings=$(sibling_context "$repo")

  local prompt
  prompt=$(printf 'Working directory: %s\n\nRead the operating procedure at %s and follow it to implement this ticket end-to-end in the above working directory. The Skill tool is not registered for this repo, so read the file directly and treat it as your procedure. Emit its sentinel (AUTONOMOUS-TICKET-SKILL-ACTIVE) as your FIRST output line so loading is confirmable.\n\nVerify with the real test suite — `--passWithNoTests` (or equivalent) is NOT an acceptable pass criterion when you add or change logic; the new behaviour must be covered and green. The Linear MCP is available for status + progress comments. Stop when tests are green — do NOT commit or push, the next phase handles that.\n%s\n%s\n' \
    "$repo_dir" "$SKILL_PATH" "$ticket_context" "$siblings")
  claude_run "$repo_dir" "$prompt" | tee "$impl_log"
  if ! grep -q 'AUTONOMOUS-TICKET-SKILL-ACTIVE' "$impl_log"; then
    echo "⚠️  WARNING ($repo): skill sentinel absent from implement output — the autonomous-ticket skill may not have loaded; the run likely improvised without Phases A/B/C." >&2
  fi
  rm -f "$impl_log"
}

phase_ship() {
  local repo="$1"
  local repo_dir="$SILLANT_DIR/$repo"
  local ticket_context
  ticket_context=$(printf 'Ticket ID: %s\nTitle: %s\nRepo: %s\nBranch: %s\n\nDescription:\n%s\n' \
    "$ISSUE_ID" "$TICKET_TITLE" "$repo" "$BRANCH_NAME" "$TICKET_DESC")

  local prompt
  prompt=$(printf 'Working directory: %s\n\nImplementation phase finished. Ship the work:\n\n1. `git diff` to review the changes.\n2. Write a clean commit message — short subject (max 72 chars), optional body explaining the why.\n3. Stage, commit, push to origin.\n4. Open a DRAFT pull request: `gh pr create --draft --base main`\n   - title: ticket title verbatim\n   - body: includes "Fixes %s" so GitHub auto-links Linear\n\nDo not run tests — they already passed. Do not ask. Just ship.\n\n%s\n' \
    "$repo_dir" "$ISSUE_ID" "$ticket_context")
  claude_run "$repo_dir" "$prompt"
}

wait_for_checks_to_register() {
  # `gh pr checks --watch` exits non-zero the instant it is called when no checks are registered
  # yet — the normal state for the first few seconds after a PR is opened (or a fix is pushed).
  # Without this guard the orchestrator mistakes that empty window for a CI failure and burns a
  # ci_fix attempt on nothing. Poll until at least one check exists (or a timeout) before watching.
  local pr="$1" repo_dir="$2" waited=0 max=120 count
  while [ "$waited" -lt "$max" ]; do
    count=$(cd "$repo_dir" && gh pr checks "$pr" --json state --jq 'length' 2>/dev/null || echo 0)
    [ -n "$count" ] && [ "$count" -gt 0 ] 2>/dev/null && return 0
    sleep 10
    waited=$((waited + 10))
  done
  return 0
}

phase_ci_wait() {
  local pr="$1" repo_dir="$2"
  echo "----------------------------------------"
  echo "⏳ Waiting for CI on PR #$pr..."
  wait_for_checks_to_register "$pr" "$repo_dir"
  (cd "$repo_dir" && gh pr checks "$pr" --watch)
}

phase_ci_fix() {
  local pr="$1" repo="$2" attempt="$3"
  local repo_dir="$SILLANT_DIR/$repo"
  local log_file
  log_file=$(mktemp -t agent-loop-ci-XXXXXX.log)

  local run_id
  run_id=$(cd "$repo_dir" && gh run list --branch "$BRANCH_NAME" --limit 1 --json databaseId --jq '.[0].databaseId // empty')
  if [ -n "$run_id" ]; then
    (cd "$repo_dir" && gh run view "$run_id" --log-failed) >"$log_file" 2>&1 || true
  fi
  echo "📋 Failing CI logs at $log_file"

  local ticket_context
  ticket_context=$(printf 'Ticket ID: %s\nTitle: %s\nRepo: %s\nBranch: %s\n\nDescription:\n%s\n' \
    "$ISSUE_ID" "$TICKET_TITLE" "$repo" "$BRANCH_NAME" "$TICKET_DESC")

  local prompt
  prompt=$(printf 'Working directory: %s\n\nCI is failing on PR #%s (fix attempt %s of %s). Failing job logs are at:\n\n  %s\n\nDo this:\n1. Read the log file.\n2. Diagnose the failure.\n3. Fix the code following .claude/CLAUDE.md — clean, lean, upstream patterns over end-of-chain tweaks. Rechallenge the existing approach when a cleaner design fits.\n4. Run the relevant tests locally to verify the fix (never `--passWithNoTests` as the pass criterion).\n5. Commit and push to the existing branch — do NOT open a new PR.\n\n%s\n' \
    "$repo_dir" "$pr" "$attempt" "$MAX_CI_FIX_ATTEMPTS" "$log_file" "$ticket_context")

  claude_run "$repo_dir" "$prompt"
  rm -f "$log_file"
}

# --- 7. Implement across all repos, backend → frontend (sibling diffs flow forward as context).
for REPO in "${REPOS[@]}"; do
  echo "----------------------------------------"
  echo "▶ Phase 1: implement ($REPO @ $BRANCH_NAME)"
  phase_implement "$REPO"
done

# --- 8. Ship repos that have changes; collect PR numbers.
SHIP_REPOS=()
SHIP_PRS=()

for REPO in "${REPOS[@]}"; do
  REPO_DIR="$SILLANT_DIR/$REPO"
  PR_NUMBER=$(cd "$REPO_DIR" && gh pr view "$BRANCH_NAME" --json number --jq '.number' 2>/dev/null || true)

  if [ -z "$PR_NUMBER" ]; then
    if ! has_local_work "$REPO_DIR"; then
      echo "✅ $REPO: No changes produced. Skipping ship."
      continue
    fi
    echo "----------------------------------------"
    echo "▶ Phase 2: ship ($REPO)"
    phase_ship "$REPO"
    PR_NUMBER=$(cd "$REPO_DIR" && gh pr view "$BRANCH_NAME" --json number --jq '.number' 2>/dev/null || true)
  fi

  if [ -n "$PR_NUMBER" ]; then
    SHIP_REPOS+=("$REPO")
    SHIP_PRS+=("$PR_NUMBER")
  else
    echo "⚠️  $REPO: Ship phase did not open a PR for $BRANCH_NAME." >&2
  fi
done

if [ "${#SHIP_PRS[@]}" -eq 0 ]; then
  echo "✅ No PRs to watch. Done."
  exit 0
fi

# --- 9. CI watch + auto-fix per PR. Continue across repos; collect failures, report at the end.
FAILED_PRS=()
i=0
while [ "$i" -lt "${#SHIP_PRS[@]}" ]; do
  PR_NUMBER="${SHIP_PRS[$i]}"
  REPO="${SHIP_REPOS[$i]}"
  REPO_DIR="$SILLANT_DIR/$REPO"
  attempt=1
  failed=0
  while ! phase_ci_wait "$PR_NUMBER" "$REPO_DIR"; do
    if [ "$attempt" -gt "$MAX_CI_FIX_ATTEMPTS" ]; then
      echo "❌ CI still failing after $MAX_CI_FIX_ATTEMPTS fix attempts on PR #$PR_NUMBER ($REPO)." >&2
      failed=1
      break
    fi
    echo "----------------------------------------"
    echo "▶ Phase 3: ci_fix ($REPO, attempt $attempt of $MAX_CI_FIX_ATTEMPTS)"
    phase_ci_fix "$PR_NUMBER" "$REPO" "$attempt"
    attempt=$((attempt + 1))
  done
  if [ "$failed" -eq 1 ]; then
    print_digest "$REPO" "CI FAILED ❌ (circuit breaker)" "$PR_NUMBER"
    FAILED_PRS+=("#$PR_NUMBER ($REPO)")
  else
    echo "✅ CI green on PR #$PR_NUMBER ($REPO). Branch $BRANCH_NAME ready for review."
    print_digest "$REPO" "CI green ✅" "$PR_NUMBER"
  fi
  i=$((i + 1))
done

if [ "${#FAILED_PRS[@]}" -gt 0 ]; then
  echo "========================================"
  echo "❌ Unresolved CI failures on: ${FAILED_PRS[*]}" >&2
  exit 1
fi

echo "========================================"
echo "✅ All PRs green for $BRANCH_NAME (${SHIP_REPOS[*]})."
