#!/bin/bash
# Changelog digest for update.sh — see scripts/CONTEXT.md.
#
# A changelog is a delta, and update.sh destroys the "before" half as it runs:
# once `brew upgrade` finishes `brew outdated` is empty, and every plugin repo
# has already fast-forwarded. So this comes in two halves — cl_snapshot records
# state before anything upgrades, cl_report diffs against it at the end.
#
# Nothing here may break the run. update.sh omits `set -e` on purpose so that
# one broken component cannot stop the rest, and a digest is the least load
# bearing thing in the script: every entry point returns 0, and any lookup that
# fails degrades to a bare "old → new" line instead of an error.
#
# Written for bash 3.2 (/bin/bash on macOS): no associative arrays, no mapfile,
# and no bare "${arr[@]}" on a possibly-empty array under `set -u`.

CL_DIR=""
CL_TIMEOUT="${CL_TIMEOUT:-10}"
CL_INDENT="               " # lines notes up under the version column
CL_CHANGED=0                # set by each section; drives the "nothing changed" case

# ---------- plumbing ----------

# Cap every network call. coreutils is in the Brewfile, but a digest must still
# work on a machine where it is missing.
_cl_run() {
  if command -v timeout &>/dev/null; then
    timeout "$CL_TIMEOUT" "$@"
  else
    "$@"
  fi
}

# "https://github.com/owner/repo/archive/v1.tar.gz" -> "owner/repo"
_cl_repo_from_url() {
  local re='github\.com/([^/]+)/([^/#?]+)'
  if [[ "$1" =~ $re ]]; then
    printf '%s/%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]%.git}"
  fi
}

# Strip markdown down to something that survives a 76-column terminal.
#
# Underscores are deliberately NOT stripped: markdown italics use them rarely,
# but release notes are full of identifiers like zvm_after_init_commands, and
# mangling those to zvmafterinitcommands makes the digest actively misleading.
#
# Order matters: the structural prefixes (bullet marker, then the commit SHA
# some projects prepend) come off FIRST, while their ^ anchors still hold. Strip
# inline emphasis before them and the `*` stripper eats the bullet marker, which
# leaves a leading space and silently disables both anchored rules.
_cl_clean() {
  sed -e 's/\r$//' \
    | sed -E -e 's/^[[:space:]]*[-*•][[:space:]]*//' \
      -e 's/^[0-9a-f]{7,40}:[[:space:]]*//' \
      -e 's/!\[[^]]*\]\([^)]*\)//g' \
      -e 's/\[([^]]*)\]\([^)]*\)/\1/g' \
      -e 's/<[^>]*>//g' \
      -e 's/[`*]//g' \
      -e 's/[[:space:]]+/ /g' \
      -e 's/^ //; s/ $//' \
    | grep -Ev '^[[:punct:][:space:]]*$' \
    | awk 'length($0) >= 8' \
    | cut -c1-60
}

# Turn a release body into at most three indented bullets. Most projects write
# bullet lists; the ones that write prose fall through to the first few lines.
_cl_notes_from_body() {
  local body="$1" out
  out="$(printf '%s\n' "$body" | grep -E '^[[:space:]]*[-*•]' | _cl_clean | head -3)"
  if [[ -z "$out" ]]; then
    out="$(printf '%s\n' "$body" | grep -Ev '^[[:space:]]*(#|$)' | _cl_clean | head -3)"
  fi
  [[ -n "$out" ]] || return 1
  printf '%s\n' "$out" | sed "s|^|${CL_INDENT}• |"
}

# _cl_notes <owner/repo> <version> [extra tag candidates...]
#
# Tag conventions split across this toolchain — ripgrep ships "14.1.1" while
# eza ships "v0.23.0" — so both are always tried. A caller that knows a project
# uses a third convention can pass extra candidates.
_cl_notes() {
  local repo="$1" ver="$2"
  shift 2
  local tag body
  for tag in "v$ver" "$ver" "$@"; do
    [[ -n "$tag" ]] || continue
    body="$(_cl_run gh api "repos/$repo/releases/tags/$tag" --jq '.body' 2>/dev/null)" || continue
    [[ -n "$body" && "$body" != "null" ]] || continue
    _cl_notes_from_body "$body" || continue
    printf '%s↗ https://github.com/%s/releases/tag/%s\n' "$CL_INDENT" "$repo" "$tag"
    return 0
  done
  return 1
}

# Print "  name  old → new", with notes underneath or a "(no notes found)" tag.
# Notes are resolved before the header prints so the marker lands on that line.
#
# A caller that knows where the notes live even though the releases API cannot
# reach them sets CL_FALLBACK_URL first, and gets a link instead of the marker.
_cl_entry() {
  local name="$1" old="$2" new="$3" repo="$4"
  shift 4
  local notes=""
  if [[ -n "$repo" ]] && command -v gh &>/dev/null; then
    notes="$(_cl_notes "$repo" "$new" "$@")" || notes=""
  fi
  if [[ -n "$notes" ]]; then
    printf '  %-12s %s → %s\n' "$name" "$old" "$new"
    printf '%s\n' "$notes"
  elif [[ -n "${CL_FALLBACK_URL:-}" ]]; then
    printf '  %-12s %s → %s\n' "$name" "$old" "$new"
    printf '%s↗ %s\n' "$CL_INDENT" "$CL_FALLBACK_URL"
  else
    printf '  %-12s %s → %s  (no notes found)\n' "$name" "$old" "$new"
  fi
  CL_CHANGED=1
}

# Count the non-empty lines of a TSV blob held in a variable.
_cl_count() {
  [[ -n "$1" ]] || {
    printf '0\n'
    return 0
  }
  printf '%s\n' "$1" | grep -c '^.'
}

# ---------- Homebrew ----------

# Homebrew stores no changelog, so the only route to release notes is the
# source tarball URL (reliable for GitHub-hosted projects), falling back to the
# homepage. Projects predating GitHub — git, ffmpeg, stow — resolve to nothing,
# which is expected: the caller prints a bare version delta for those.
_cl_brew_repo() {
  local kind="$1" name="$2" flag url repo
  if [[ "$kind" == cask ]]; then flag="--cask"; else flag="--formula"; fi
  while IFS= read -r url; do
    [[ -n "$url" ]] || continue
    repo="$(_cl_repo_from_url "$url")"
    if [[ -n "$repo" ]]; then
      printf '%s\n' "$repo"
      return 0
    fi
  done < <(_cl_run brew info --json=v2 "$flag" "$name" 2>/dev/null \
    | jq -r '((.formulae // []) + (.casks // []))[0]
                    | [(.urls.stable.url // empty), (.url // empty), (.homepage // empty)]
                    | .[]' 2>/dev/null)
  return 0
}

_cl_section_brew() {
  local json="$CL_DIR/brew.json"
  [[ -s "$json" ]] || return 0
  command -v brew &>/dev/null || return 0

  local wanted
  wanted="$(jq -r '
      ((.formulae // []) | map(. + {kind:"formula"}))
    + ((.casks    // []) | map(. + {kind:"cask"}))
    | .[]
    | [ .kind, .name,
        ((.installed_versions // []) | join(", ")),
        (.current_version // "") ]
    | @tsv' "$json" 2>/dev/null)"
  [[ -n "$wanted" ]] || return 0

  # `brew outdated` records intent, not outcome — a package can still fail to
  # upgrade, and printing its release notes would be a lie. Keep only the rows
  # whose new version is actually on disk now.
  local have_f have_c rows kind name old new haystack
  have_f="$(brew list --formula --versions 2>/dev/null)"
  have_c="$(brew list --cask --versions 2>/dev/null)"
  # A broken `brew list` would fail every check below and drop the whole
  # section without a word, which reads as "nothing was upgraded". Say so.
  if [[ -z "$have_f" && -z "$have_c" ]]; then
    printf '\n🍺 Homebrew\n  ⚠️  cannot read installed versions, skipping\n'
    return 0
  fi
  rows=""
  while IFS=$'\t' read -r kind name old new; do
    [[ -n "$name" && -n "$new" ]] || continue
    if [[ "$kind" == cask ]]; then haystack="$have_c"; else haystack="$have_f"; fi
    printf '%s\n' "$haystack" | awk -v n="$name" -v v="$new" \
      '$1 == n { for (i = 2; i <= NF; i++) if ($i == v) found = 1 } END { exit !found }' \
      || continue
    rows="$rows$kind	$name	$old	$new
"
  done <<<"$wanted"
  [[ -n "$rows" ]] || return 0

  printf '\n🍺 Homebrew (%s)\n' "$(_cl_count "$rows")"
  while IFS=$'\t' read -r kind name old new; do
    [[ -n "$name" ]] || continue
    _cl_entry "$name" "$old" "$new" "$(_cl_brew_repo "$kind" "$name")"
  done <<<"$rows"
  return 0
}

# ---------- mise ----------

# mise knows each tool's backend, and most backends are "aqua:owner/repo" or
# "ubi:owner/repo" — already the shape we need.
#
# The core runtimes are the exception. Only Node publishes GitHub releases;
# golang/go and python/cpython have tags but zero releases (verified against
# the API), so asking for release notes there is three guaranteed 404s. They
# resolve to no repo and lean on _cl_mise_docs instead.
_cl_mise_repo() {
  local spec="$1"
  case "$spec" in
    core:node) printf 'nodejs/node\n' ;;
    core:python | core:go | core:*) : ;;
    aqua:*/* | ubi:*/* | github:*/*) printf '%s\n' "${spec#*:}" | cut -d/ -f1,2 ;;
    *) _cl_repo_from_url "$spec" ;;
  esac
}

# Where a runtime's notes actually live when the releases API cannot reach them.
# Both pages are keyed on the major.minor series, not the patch version.
_cl_mise_docs() {
  local tool="$1" series="${2%.*}"
  case "$tool" in
    go) printf 'https://go.dev/doc/go%s\n' "$series" ;;
    python) printf 'https://docs.python.org/3/whatsnew/%s.html\n' "$series" ;;
  esac
}

_cl_section_mise() {
  local json="$CL_DIR/mise.json"
  [[ -s "$json" ]] || return 0
  command -v mise &>/dev/null || return 0

  local wanted
  wanted="$(jq -r 'to_entries[] | [.key, (.value.current // ""), (.value.latest // "")] | @tsv' \
    "$json" 2>/dev/null)"
  [[ -n "$wanted" ]] || return 0

  # A tool that upgraded has dropped off the outdated list; one that failed is
  # still on it. That is a cleaner check than re-parsing installed versions.
  local still rows tool old new
  still="$(mise outdated --json 2>/dev/null | jq -r 'keys[]' 2>/dev/null)"
  rows=""
  while IFS=$'\t' read -r tool old new; do
    [[ -n "$tool" && -n "$new" ]] || continue
    printf '%s\n' "$still" | grep -qx "$tool" && continue
    rows="$rows$tool	$old	$new
"
  done <<<"$wanted"
  [[ -n "$rows" ]] || return 0

  local registry spec repo
  registry="$(mise registry 2>/dev/null)"
  printf '\n🧰 Runtimes (%s)\n' "$(_cl_count "$rows")"
  while IFS=$'\t' read -r tool old new; do
    [[ -n "$tool" ]] || continue
    spec="$(printf '%s\n' "$registry" | awk -v t="$tool" '$1 == t { print $2; exit }')"
    repo="$(_cl_mise_repo "$spec")"
    CL_FALLBACK_URL="$(_cl_mise_docs "$tool" "$new")"
    _cl_entry "$tool" "$old" "$new" "$repo"
    CL_FALLBACK_URL=""
  done <<<"$rows"
  return 0
}

# ---------- gh extensions ----------

_cl_section_gh() {
  local before="$CL_DIR/gh-ext.tsv"
  [[ -s "$before" ]] || return 0
  command -v gh &>/dev/null || return 0

  local after rows repo old new
  after="$(gh extension list 2>/dev/null)"
  [[ -n "$after" ]] || return 0
  rows=""
  while IFS=$'\t' read -r _ repo old; do
    [[ -n "$repo" ]] || continue
    new="$(printf '%s\n' "$after" | awk -F'\t' -v r="$repo" '$2 == r { print $3; exit }')"
    [[ -n "$new" && "$new" != "$old" ]] || continue
    rows="$rows$repo	$old	$new
"
  done <"$before"
  [[ -n "$rows" ]] || return 0

  printf '\n🐙 gh extensions (%s)\n' "$(_cl_count "$rows")"
  while IFS=$'\t' read -r repo old new; do
    [[ -n "$repo" ]] || continue
    _cl_entry "${repo#*/}" "$old" "$new" "$repo"
  done <<<"$rows"
  return 0
}

# ---------- zsh plugins ----------

# The only source with an exact changelog: these are git checkouts, so the
# commits between the two revisions are the release notes. No network, no
# guessing at which upstream repo a package came from.
_cl_section_plugins() {
  local before="$CL_DIR/plugins.tsv"
  [[ -s "$before" ]] || return 0

  local rows name old dir new
  rows=""
  while IFS=$'\t' read -r name old dir; do
    [[ -n "$name" && -n "$old" && -d "$dir/.git" ]] || continue
    new="$(git -C "$dir" rev-parse HEAD 2>/dev/null)"
    [[ -n "$new" && "$new" != "$old" ]] || continue
    rows="$rows$name	$old	$new	$dir
"
  done <"$before"
  [[ -n "$rows" ]] || return 0

  printf '\n🔌 Zsh plugins (%s)\n' "$(_cl_count "$rows")"
  local log
  while IFS=$'\t' read -r name old new dir; do
    [[ -n "$name" ]] || continue
    printf '  %-12s %s → %s\n' "$name" "${old:0:7}" "${new:0:7}"
    log="$(git -C "$dir" log --no-merges --format='%s' "$old..$new" 2>/dev/null | _cl_clean | head -3)"
    if [[ -n "$log" ]]; then
      printf '%s\n' "$log" | sed "s|^|${CL_INDENT}• |"
    else
      printf '%s(no commit subjects)\n' "$CL_INDENT"
    fi
    CL_CHANGED=1
  done <<<"$rows"
  return 0
}

# ---------- entry points ----------

# Record the "before" side of every delta. Must run before anything upgrades.
cl_snapshot() {
  CL_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dotup-changelog.XXXXXX" 2>/dev/null)" || {
    CL_DIR=""
    return 0
  }

  command -v brew &>/dev/null && brew outdated --json=v2 >"$CL_DIR/brew.json" 2>/dev/null
  command -v mise &>/dev/null && mise outdated --json >"$CL_DIR/mise.json" 2>/dev/null
  command -v gh &>/dev/null && gh extension list >"$CL_DIR/gh-ext.tsv" 2>/dev/null

  local dir sha
  for dir in "${ZPLUGINDIR:-$HOME/.config/zsh/plugins}"/*/; do
    [[ -d "$dir/.git" ]] || continue
    sha="$(git -C "$dir" rev-parse HEAD 2>/dev/null)"
    [[ -n "$sha" ]] || continue
    printf '%s\t%s\t%s\n' "$(basename "$dir")" "$sha" "${dir%/}" >>"$CL_DIR/plugins.tsv"
  done
  return 0
}

# Diff against the snapshot and print the digest. Must run after every upgrade.
cl_report() {
  [[ -n "$CL_DIR" && -d "$CL_DIR" ]] || return 0

  printf '\n📋 Changelog digest\n'
  # Warn but keep going. The jq-dependent sections degrade to nothing on their
  # own, and the zsh-plugin section needs neither tool — bailing out here would
  # throw away the one source with an exact changelog.
  if ! command -v jq &>/dev/null; then
    printf '  ⚠️  jq not installed — brew, mise and gh sections unavailable\n'
  fi
  if ! command -v gh &>/dev/null; then
    printf '  ⚠️  gh not installed — versions only, no release notes\n'
  fi

  _cl_section_brew
  _cl_section_mise
  _cl_section_gh
  _cl_section_plugins

  [[ $CL_CHANGED -eq 0 ]] && printf '  Nothing changed.\n'
  rm -rf "$CL_DIR"
  CL_DIR=""
  return 0
}
