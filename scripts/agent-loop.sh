#!/bin/bash
# agent-loop.sh — Linear ticket → branch → implement → ship → CI watch → auto-fix.
#
# Usage:
#   ./agent-loop.sh <linear-ticket-or-url> [repo...]
#
# Repo inference: Claude analyzes the ticket and picks the repo(s) automatically.
# Pass extra repos as arguments to override (e.g. agl DEV-123 Table vicat).
#
# Phases:
#   implement → Claude runs the autonomous-ticket skill until tests are green (per repo)
#   ship      → Claude reviews the diff, commits, pushes, opens a DRAFT PR   (per repo)
#   ci_wait   → bash blocks on `gh pr checks --watch`
#   ci_fix    → on failure, Claude reads the failing job logs and fixes; loop with circuit breaker

set -euo pipefail

LINEAR_URL="${1:-}"
shift || true
REPO_OVERRIDES=("$@")
MAX_CI_FIX_ATTEMPTS=3

if [ -z "$LINEAR_URL" ]; then
    echo "❌ Usage: $0 <linear-url> [repo...]" >&2
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

# --- 3. Infer repo(s) with Claude.
# Returns newline-separated repo names. Grep filters to valid values only.
infer_repos() {
    claude -p "You are analyzing a Linear ticket for Sillant, a French BTP SaaS platform.

The platform has 3 repos:
  Table              — React/TypeScript frontend. Covers: price-bible UI (also called price_db or B-PU), pdf-to-table UI, structure, recap, matching, import, tech-report UI. Any ticket about what users see or interact with.
  vicat              — FastAPI Python backend. Covers: price_bible API, pdf_to_table API, tech_report_analysis, file_api, common. Any ticket about endpoints, database models, migrations, business logic computed server-side.
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

REPOS=()
if [ "${#REPO_OVERRIDES[@]}" -gt 0 ]; then
    REPOS=("${REPO_OVERRIDES[@]}")
else
    echo "🔍 Inferring repo(s) from ticket…"
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

echo "📦 Repo(s): ${REPOS[*]}"

# --- 4. Validate repos and check for dirty trees before starting anything.
for REPO in "${REPOS[@]}"; do
    REPO_DIR="$HOME/dev/sillant/$REPO"
    if [ ! -d "$REPO_DIR/.git" ]; then
        echo "❌ $REPO_DIR is not a git repository." >&2
        exit 1
    fi
    if ! git -C "$REPO_DIR" diff --quiet || ! git -C "$REPO_DIR" diff --cached --quiet; then
        echo "❌ $REPO has uncommitted changes — commit or stash first." >&2
        exit 1
    fi
done

# --- 5. Prepare branches in all repos.
for REPO in "${REPOS[@]}"; do
    REPO_DIR="$HOME/dev/sillant/$REPO"
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
    ! git -C "$repo_dir" diff --quiet \
        || ! git -C "$repo_dir" diff --cached --quiet \
        || [ -n "$(git -C "$repo_dir" log origin/main..HEAD --oneline 2>/dev/null || true)" ]
}

phase_implement() {
    local repo="$1"
    local repo_dir="$HOME/dev/sillant/$repo"
    local all_repos="${REPOS[*]}"
    local ticket_context
    ticket_context=$(printf 'Ticket ID: %s\nTitle: %s\nImplementing in repo: %s (all affected repos: %s)\nBranch: %s\n\nDescription:\n%s\n' \
        "$ISSUE_ID" "$TICKET_TITLE" "$repo" "$all_repos" "$BRANCH_NAME" "$TICKET_DESC")

    local prompt
    prompt=$(printf 'Working directory: %s\n\nUse the `autonomous-ticket` skill (~/.claude/skills/autonomous-ticket/SKILL.md) and implement this ticket end-to-end in the above working directory. The Linear MCP is available for posting progress comments and updating ticket status. Stop when tests are green — do NOT commit or push, the next phase handles that.\n\n%s\n' \
        "$repo_dir" "$ticket_context")
    claude_run "$repo_dir" "$prompt"
}

phase_ship() {
    local repo="$1"
    local repo_dir="$HOME/dev/sillant/$repo"
    local ticket_context
    ticket_context=$(printf 'Ticket ID: %s\nTitle: %s\nRepo: %s\nBranch: %s\n\nDescription:\n%s\n' \
        "$ISSUE_ID" "$TICKET_TITLE" "$repo" "$BRANCH_NAME" "$TICKET_DESC")

    local prompt
    prompt=$(printf 'Working directory: %s\n\nImplementation phase finished. Ship the work:\n\n1. `git diff` to review the changes.\n2. Write a clean commit message — short subject (max 72 chars), optional body explaining the why.\n3. Stage, commit, push to origin.\n4. Open a DRAFT pull request: `gh pr create --draft --base main`\n   - title: ticket title verbatim\n   - body: includes "Fixes %s" so GitHub auto-links Linear\n\nDo not run tests — they already passed. Do not ask. Just ship.\n\n%s\n' \
        "$repo_dir" "$ISSUE_ID" "$ticket_context")
    claude_run "$repo_dir" "$prompt"
}

phase_ci_wait() {
    local pr="$1"
    echo "----------------------------------------"
    echo "⏳ Waiting for CI on PR #$pr..."
    gh pr checks "$pr" --watch
}

phase_ci_fix() {
    local pr="$1"
    local repo="$2"
    local attempt="$3"
    local repo_dir="$HOME/dev/sillant/$repo"
    local log_file
    log_file=$(mktemp -t agent-loop-ci-XXXXXX.log)

    local run_id
    run_id=$(cd "$repo_dir" && gh run list --branch "$BRANCH_NAME" --limit 1 --json databaseId --jq '.[0].databaseId // empty')
    if [ -n "$run_id" ]; then
        (cd "$repo_dir" && gh run view "$run_id" --log-failed) > "$log_file" 2>&1 || true
    fi
    echo "📋 Failing CI logs at $log_file"

    local ticket_context
    ticket_context=$(printf 'Ticket ID: %s\nTitle: %s\nRepo: %s\nBranch: %s\n\nDescription:\n%s\n' \
        "$ISSUE_ID" "$TICKET_TITLE" "$repo" "$BRANCH_NAME" "$TICKET_DESC")

    local prompt
    prompt=$(printf 'Working directory: %s\n\nCI is failing on PR #%s (fix attempt %s of %s). Failing job logs are at:\n\n  %s\n\nDo this:\n1. Read the log file.\n2. Diagnose the failure.\n3. Fix the code.\n4. Run the relevant tests locally to verify the fix.\n5. Commit and push to the existing branch — do NOT open a new PR.\n\n%s\n' \
        "$repo_dir" "$pr" "$attempt" "$MAX_CI_FIX_ATTEMPTS" "$log_file" "$ticket_context")

    claude_run "$repo_dir" "$prompt"
    rm -f "$log_file"
}

# --- 7. Implement across all repos.
for REPO in "${REPOS[@]}"; do
    echo "----------------------------------------"
    echo "▶ Phase 1: implement ($REPO @ $BRANCH_NAME)"
    phase_implement "$REPO"
done

# --- 8. Ship repos that have changes; collect PR numbers.
SHIP_REPOS=()
SHIP_PRS=()

for REPO in "${REPOS[@]}"; do
    REPO_DIR="$HOME/dev/sillant/$REPO"
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

# --- 9. CI watch + auto-fix per PR.
i=0
while [ "$i" -lt "${#SHIP_PRS[@]}" ]; do
    PR_NUMBER="${SHIP_PRS[$i]}"
    REPO="${SHIP_REPOS[$i]}"
    attempt=1
    while ! phase_ci_wait "$PR_NUMBER"; do
        if [ "$attempt" -gt "$MAX_CI_FIX_ATTEMPTS" ]; then
            echo "❌ CI still failing after $MAX_CI_FIX_ATTEMPTS fix attempts on PR #$PR_NUMBER ($REPO). Stopping." >&2
            exit 1
        fi
        echo "----------------------------------------"
        echo "▶ Phase 3: ci_fix ($REPO, attempt $attempt of $MAX_CI_FIX_ATTEMPTS)"
        phase_ci_fix "$PR_NUMBER" "$REPO" "$attempt"
        attempt=$((attempt + 1))
    done
    echo "✅ CI green on PR #$PR_NUMBER ($REPO). Branch $BRANCH_NAME ready for review."
    i=$((i + 1))
done
