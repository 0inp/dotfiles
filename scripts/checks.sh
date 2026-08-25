#!/bin/bash
# Repo invariants, enforced by lefthook before a push. See lefthook.yml.
#
# These are not linters. Each one encodes a way this repo has actually broken,
# and each is documented as a constraint in CLAUDE.md:
#
#   stow      a module can be committed, documented and mapped while never
#             being stowed — `worktrunk` was inert for months that way.
#   symlinks  ~/.claude and ~/.vibe are tree-folded to single symlinks, so a
#             relative link inside them resolves from the REPO, not from ~.
#             Getting the `..` count wrong hid 42 claude skills, and later
#             all 41 vibe skills, without ever producing an error.
#   zvm       zsh-vi-mode reads the lowercase `zvm_after_init_commands`. The
#             uppercase spelling is read by nothing and fails silently.
#   fnox      config.toml is committed on purpose because it holds only
#             keychain *references*. A literal value there is a secret pushed
#             to a public repo.
#   brewfile  the Brewfile is the source of truth for installed packages.
#
# No `set -e`: every check runs and reports, so one failure never hides the
# rest. Exit status is the number of failed checks.
set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 2

fail=0
_ok() { printf '  ✅ %s\n' "$1"; }
_bad() {
  printf '  ❌ %s\n' "$1"
  fail=$((fail + 1))
}
_skip() { printf '  ⏭️  %s\n' "$1"; }

# ---------- stow ----------
# Mirrors install.sh's `stow -t ~ */` exactly: one package per non-dot
# top-level directory. Dot-directories (.git, .github, .claude) are NOT
# packages — `stow -t ~ .git` would try to link COMMIT_EDITMSG into $HOME.
check_stow() {
  echo "🔗 stow — every module is linked into ~"
  if ! command -v stow >/dev/null 2>&1; then
    _skip "stow not installed"
    return
  fi
  local m out unstowed=""
  for m in */; do
    m="${m%/}"
    case "$m" in .*) continue ;; esac
    out=$(stow -n -v -t "$HOME" "$m" 2>&1 | grep -E '^(LINK|CONFLICT)' || true)
    [ -n "$out" ] && unstowed="$unstowed $m"
  done
  if [ -n "$unstowed" ]; then
    _bad "not stowed:$unstowed"
    printf '     fix: stow -t ~%s\n' "$unstowed"
  else
    _ok "all modules stowed"
  fi
}

# ---------- symlinks ----------
# Resolves each tracked symlink relative to its own directory IN THE REPO,
# which is where the kernel resolves it once the parent is tree-folded. This
# deliberately does not look at ~: the point is to validate committed content,
# so the answer is the same on every machine.
check_symlinks() {
  echo "🪢 symlinks — tracked links resolve inside the repo"
  local mode sha path tgt total=0 broken=0
  # field 3 is the merge stage, which is always 0 here and never used.
  while read -r mode sha _ path; do
    [ "$mode" = "120000" ] || continue
    total=$((total + 1))
    tgt=$(git cat-file -p "$sha")
    if [ ! -e "$(dirname "$path")/$tgt" ]; then
      broken=$((broken + 1))
      printf '     %s -> %s\n' "$path" "$tgt"
    fi
  done < <(git ls-files -s)
  if [ "$broken" -gt 0 ]; then
    _bad "$broken of $total tracked symlinks do not resolve"
  else
    _ok "$total tracked symlinks resolve"
  fi
}

# ---------- zsh-vi-mode ----------
# Restricted to *.zsh so the explanatory prose in CLAUDE.md does not match, and
# matched only as an ASSIGNMENT preceded by no `#`. bindings.zsh documents this
# very gotcha in a comment that names the uppercase spelling — a bare substring
# grep flags that comment and cries wolf on a correct repo.
check_zvm() {
  echo "⌨️  zsh-vi-mode — bindings use the lowercase array"
  local hits
  hits=$(git grep -nE '^[^#]*\bZVM_AFTER_INIT_COMMANDS[[:space:]]*\+?=' -- '*.zsh' 2>/dev/null || true)
  if [ -n "$hits" ]; then
    _bad "uppercase ZVM_AFTER_INIT_COMMANDS is read by nothing"
    printf '%s\n' "$hits" | sed 's/^/     /'
  else
    _ok "no uppercase ZVM_AFTER_INIT_COMMANDS"
  fi
}

# ---------- fnox ----------
# Every entry under [secrets] must be an inline table naming a provider.
# A bare `KEY = "..."` is a literal secret, and this repo is public.
check_fnox() {
  echo "🔐 fnox — config holds references, never values"
  local f=fnox/.config/fnox/config.toml
  if [ ! -f "$f" ]; then
    _skip "$f not found"
    return
  fi
  local bad
  bad=$(awk '
    /^\[secrets\]/ { in_s = 1; next }
    /^\[/          { in_s = 0 }
    in_s && /^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*=/ && !/provider[[:space:]]*=/ {
      printf "     line %d: %s\n", NR, $0
    }
  ' "$f")
  if [ -n "$bad" ]; then
    _bad "literal value in [secrets] — must be { provider = ..., value = ... }"
    printf '%s\n' "$bad"
  else
    _ok "all [secrets] entries are provider references"
  fi
}

# ---------- secrets ----------
# Scans only the commits about to be pushed.
#
# Scope is the push range, not history — deliberately, and not for speed.
# (A full scan costs ~0.6s here since .gitleaks.toml's path allowlist skips
# the vendored Raycast bundles that were most of the 116 MB; before that file
# existed it took ~95s.) The reason is the failure message: a range-scoped
# failure names something you are about to publish and can still fix. A
# full-history failure fires on old commits you are not touching and blocks
# every push until someone triages history, which is how hooks get disabled.
#
# History is audited weekly instead — see .github/workflows/gitleaks.yml.
# That job exists because the per-push Action does NOT audit history: it runs
# gitleaks with `--log-opts=-1`, the last commit only, and stayed green in 10s
# while 47 findings sat in history untouched.
#
# With no upstream (a brand-new branch) there is no range to diff against, so
# everything reachable is scanned — correct, since none of it has been seen.
check_secrets() {
  echo "🔑 gitleaks — commits about to be pushed"
  if ! command -v gitleaks >/dev/null 2>&1; then
    _skip "gitleaks not installed"
    return
  fi
  local upstream range out status=0
  upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)
  if [ -n "$upstream" ] && git rev-parse --verify -q "$upstream" >/dev/null 2>&1; then
    range="$upstream..HEAD"
    if [ -z "$(git rev-list "$range" 2>/dev/null)" ]; then
      _ok "nothing to push"
      return
    fi
  else
    range=""
  fi
  if [ -n "$range" ]; then
    out=$(gitleaks git --redact --no-banner --log-opts="$range" . 2>&1) || status=$?
  else
    out=$(gitleaks git --redact --no-banner . 2>&1) || status=$?
  fi
  if [ "$status" -eq 0 ]; then
    _ok "no leaks in ${range:-full history}"
  else
    _bad "secret found in ${range:-full history} — do NOT push, rewrite it out"
    printf '%s\n' "$out" | tail -20 | sed 's/^/     /'
  fi
}

# ---------- Brewfile ----------
check_brewfile() {
  echo "🍺 Brewfile — installed packages match the manifest"
  if ! command -v brew >/dev/null 2>&1; then
    _skip "brew not installed"
    return
  fi
  local out
  if out=$(brew bundle check --global 2>&1); then
    _ok "Brewfile satisfied"
  else
    _bad "Brewfile out of sync"
    printf '%s\n' "$out" | sed 's/^/     /'
    printf '     fix: brew bundle --global  (or: brew bundle dump --force --global)\n'
  fi
}

usage() {
  cat <<'EOF'
usage: checks.sh <check>...

  secrets    gitleaks over the commits about to be pushed
  stow       every module is linked into ~
  symlinks   tracked symlinks resolve repo-relative
  zvm        no uppercase ZVM_AFTER_INIT_COMMANDS
  fnox       [secrets] holds references, never literals
  brewfile   installed packages match the Brewfile
  all        run all of the above

Exit status is the number of failed checks.
EOF
}

[ $# -eq 0 ] && {
  usage
  exit 2
}

for arg in "$@"; do
  case "$arg" in
    secrets) check_secrets ;;
    stow) check_stow ;;
    symlinks) check_symlinks ;;
    zvm) check_zvm ;;
    fnox) check_fnox ;;
    brewfile) check_brewfile ;;
    all)
      check_secrets
      check_stow
      check_symlinks
      check_zvm
      check_fnox
      check_brewfile
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      printf 'unknown check: %s\n\n' "$arg" >&2
      usage >&2
      exit 2
      ;;
  esac
done

exit "$fail"
