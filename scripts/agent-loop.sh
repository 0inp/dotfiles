#!/bin/bash
# agent-loop.sh — Linear ticket → branch → implement → ship → CI watch → auto-fix.
#
# Usage:
#   ./agent-loop.sh <linear-url> [repo]
#
# Phases:
#   implement → Claude runs the autonomous-ticket skill until tests are green
#   ship      → Claude reviews the diff, commits, pushes, opens a DRAFT PR
#   ci_wait   → bash blocks on `gh pr checks --watch`
#   ci_fix    → on failure, Claude reads the failing job logs and fixes; loop with circuit breaker

set -euo pipefail

LINEAR_URL="${1:-}"
REPO_OVERRIDE="${2:-}"
MAX_CI_FIX_ATTEMPTS=3

if [ -z "$LINEAR_URL" ]; then
    echo "❌ Usage: $0 <linear-url> [repo]" >&2
    exit 1
fi

# --- 1. Load Linear token from vicat/.env.
ENV_FILE="$HOME/dev/sillant/vicat/.env"
if [ -f "$ENV_FILE" ]; then
    set -a
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +a
fi
LINEAR_API_TOKEN="${LINEAR_API_TOKEN:-${LINEAR_API_KEY:-}}"

if [ -z "$LINEAR_API_TOKEN" ]; then
    echo "❌ Neither LINEAR_API_TOKEN nor LINEAR_API_KEY is set (looked in $ENV_FILE)." >&2
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

# --- 3. Pick repo.
infer_repo() {
    local haystack
    haystack=$(printf '%s\n%s\n%s' "$TICKET_TITLE" "$TICKET_DESC" "$BRANCH_NAME" | tr '[:upper:]' '[:lower:]')
    case "$haystack" in
        *tbv2*|*price-bible*|*pdf-to-table*|*tech-report*) echo "Table" ;;
        *anvil*|*tender-bids*|*tbh*)                       echo "tender-bids-helper" ;;
        *vicat*|*fastapi*)                                 echo "vicat" ;;
        *front*|*table*|*react*)                           echo "Table" ;;
        *backend*|*\ back\ *|"back "*)                     echo "vicat" ;;
        *)                                                  echo "" ;;
    esac
}

REPO="$REPO_OVERRIDE"
[ -z "$REPO" ] && REPO=$(infer_repo)

if [ -z "$REPO" ]; then
    echo "🤔 Could not infer repo from ticket. Pick one:"
    PS3="> "
    select REPO in Table vicat tender-bids-helper; do
        [ -n "$REPO" ] && break
    done
fi

REPO_DIR="$HOME/dev/sillant/$REPO"
if [ ! -d "$REPO_DIR/.git" ]; then
    echo "❌ $REPO_DIR is not a git repository." >&2
    exit 1
fi

# --- 4. Prepare the branch. Refuse to touch a dirty tree.
cd "$REPO_DIR"

if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "❌ $REPO has uncommitted changes — commit or stash first." >&2
    exit 1
fi

git fetch origin
git checkout main
git pull --ff-only origin main

if git ls-remote --exit-code --heads origin "$BRANCH_NAME" >/dev/null 2>&1; then
    git checkout "$BRANCH_NAME"
    git pull --ff-only origin "$BRANCH_NAME"
elif git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
    git checkout "$BRANCH_NAME"
else
    git checkout -b "$BRANCH_NAME"
fi

# --- 5. Phases.
TICKET_CONTEXT=$(printf 'Ticket ID: %s\nTitle: %s\nRepo: %s\nBranch: %s\n\nDescription:\n%s\n' \
    "$ISSUE_ID" "$TICKET_TITLE" "$REPO" "$BRANCH_NAME" "$TICKET_DESC")

HEADLESS_OVERRIDE='You are running headless via `claude -p`. There is no human to confirm with. Do NOT ask for approval, do NOT produce a plan and stop, do NOT engage brainstorming alignment gates. Execute and emit only the final result on stdout.'

claude_run() {
    claude -p \
        --permission-mode bypassPermissions \
        --verbose \
        --output-format stream-json \
        --append-system-prompt "$HEADLESS_OVERRIDE" \
        "$1"
}

phase_implement() {
    local prompt
    prompt=$(printf 'Use the `autonomous-ticket` skill (~/.claude/skills/autonomous-ticket/SKILL.md) and implement this ticket end-to-end. The Linear MCP is available for posting progress comments and updating ticket status. Stop when tests are green — do NOT commit or push, the next phase handles that.\n\n%s\n' \
        "$TICKET_CONTEXT")
    claude_run "$prompt"
}

phase_ship() {
    local prompt
    prompt=$(printf 'Implementation phase finished. Ship the work:\n\n1. `git diff` to review the changes.\n2. Write a clean commit message — short subject (max 72 chars), optional body explaining the why.\n3. Stage, commit, push to origin.\n4. Open a DRAFT pull request: `gh pr create --draft --base main`\n   - title: ticket title verbatim\n   - body: includes "Fixes %s" so GitHub auto-links Linear\n\nDo not run tests — they already passed. Do not ask. Just ship.\n\n%s\n' \
        "$ISSUE_ID" "$TICKET_CONTEXT")
    claude_run "$prompt"
}

phase_ci_wait() {
    local pr="$1"
    echo "----------------------------------------"
    echo "⏳ Waiting for CI on PR #$pr..."
    gh pr checks "$pr" --watch
}

phase_ci_fix() {
    local pr="$1"
    local attempt="$2"
    local log_file
    log_file=$(mktemp -t agent-loop-ci-XXXXXX.log)

    local run_id
    run_id=$(gh run list --branch "$BRANCH_NAME" --limit 1 --json databaseId --jq '.[0].databaseId // empty')
    if [ -n "$run_id" ]; then
        gh run view "$run_id" --log-failed > "$log_file" 2>&1 || true
    fi
    echo "📋 Failing CI logs at $log_file"

    local prompt
    prompt=$(printf 'CI is failing on PR #%s (fix attempt %s of %s). Failing job logs are at:\n\n  %s\n\nDo this:\n1. Read the log file.\n2. Diagnose the failure.\n3. Fix the code.\n4. Run the relevant tests locally to verify the fix.\n5. Commit and push to the existing branch — do NOT open a new PR.\n\n%s\n' \
        "$pr" "$attempt" "$MAX_CI_FIX_ATTEMPTS" "$log_file" "$TICKET_CONTEXT")
    claude_run "$prompt"

    rm -f "$log_file"
}

has_local_work() {
    ! git diff --quiet \
        || ! git diff --cached --quiet \
        || [ -n "$(git log origin/main..HEAD --oneline 2>/dev/null || true)" ]
}

# --- 6. Orchestrate.
echo "----------------------------------------"
echo "▶ Phase 1: implement ($REPO @ $BRANCH_NAME)"
phase_implement

PR_NUMBER=$(gh pr view "$BRANCH_NAME" --json number --jq '.number' 2>/dev/null || true)

if [ -z "$PR_NUMBER" ]; then
    if ! has_local_work; then
        echo "✅ No changes produced. Nothing to ship."
        exit 0
    fi
    echo "----------------------------------------"
    echo "▶ Phase 2: ship"
    phase_ship
    PR_NUMBER=$(gh pr view "$BRANCH_NAME" --json number --jq '.number' 2>/dev/null || true)
fi

if [ -z "$PR_NUMBER" ]; then
    echo "❌ No PR found for $BRANCH_NAME — ship phase did not open one." >&2
    exit 1
fi

attempt=1
while ! phase_ci_wait "$PR_NUMBER"; do
    if [ "$attempt" -gt "$MAX_CI_FIX_ATTEMPTS" ]; then
        echo "❌ CI still failing after $MAX_CI_FIX_ATTEMPTS fix attempts on PR #$PR_NUMBER. Stopping." >&2
        exit 1
    fi
    echo "----------------------------------------"
    echo "▶ Phase 3: ci_fix (attempt $attempt of $MAX_CI_FIX_ATTEMPTS)"
    phase_ci_fix "$PR_NUMBER" "$attempt"
    attempt=$((attempt + 1))
done

echo "✅ CI green on PR #$PR_NUMBER. Branch $BRANCH_NAME ready for review."
