#!/usr/bin/env bash
# Claude Code status line — two rows.
#
#   ~/dotfiles  ⌂ tooling-refresh  ⑂ chore/tooling-refresh-2026-08 +2 ~1
#   Opus 5 (1M) · high  ▓▓▓▓░░░░░░ 37%  5h 24%  7d 41%
#
# Row 1 is "where am I", row 2 is "how is it going".
#
# Colours use the ANSI-16 slots rather than hex, so the line follows whatever
# palette the terminal is themed with (Gruvbox Dark here) instead of pinning
# itself to it.
#
# Sizing rule: branch, worktree and dirty counts are never shortened — the path
# absorbs all of it. Claude Code pipes stdout, so `tput cols` cannot find a tty;
# COLUMNS is exported for exactly this reason.

set -u

# ${#var} must count characters, not bytes, or the multi-byte glyphs below
# (… ⑂ ⌂ ▓ ░) inflate every width calculation and truncate far too early.
case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
  *[Uu][Tt][Ff]*) ;;
  *) export LC_ALL=en_US.UTF-8 ;;
esac

COLS=${COLUMNS:-80}
[ "$COLS" -lt 20 ] 2>/dev/null && COLS=80

RESET=$'\033[0m';  GREY=$'\033[90m';   BLUE=$'\033[94m'; CYAN=$'\033[36m'
GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m';  MAGENTA=$'\033[95m'
SEP='  '
US=$'\037'   # field delimiter, see below

input=$(cat)

# One jq pass. The delimiter is US (0x1f), not a tab: tab is an IFS *whitespace*
# character, so runs of them collapse and a single empty field would silently
# shift every field after it.
IFS="$US" read -r cwd worktree model effort ctx pct5h pct7d session <<EOF
$(printf '%s' "$input" | jq -r '[
    (.workspace.current_dir // .cwd // ""),
    (.workspace.git_worktree // ""),
    (.model.display_name // ""),
    (.effort.level // ""),
    (.context_window.used_percentage // ""),
    (.rate_limits.five_hour.used_percentage // ""),
    (.rate_limits.seven_day.used_percentage // ""),
    (.session_id // "")
  ] | map(tostring) | join("\u001f")')
EOF

# ---------------------------------------------------------------- helpers ----

# Sets GC to the threshold colour for a 0-100 gauge.
gauge_color() {
  if   [ "$1" -ge 90 ]; then GC=$RED
  elif [ "$1" -ge 70 ]; then GC=$YELLOW
  else                       GC=$GREEN
  fi
}

make_bar() {
  local pct=$1 w=10 f i out=''
  f=$(( pct * w / 100 ))
  (( f > w )) && f=$w
  (( f < 0 )) && f=0
  for (( i = 0; i < f; i++ )); do out+='▓'; done
  for (( i = f; i < w; i++ )); do out+='░'; done
  printf '%s' "$out"
}

# Fit a path into $2 columns, escalating only as far as needed.
shorten_path() {
  local p=$1 max=$2 cand i keep n
  (( max < 8 )) && max=8
  (( ${#p} <= max )) && { printf '%s' "$p"; return; }

  local -a parts
  IFS='/' read -r -a parts <<< "$p"
  n=${#parts[@]}

  # 1. Elide the middle, keeping the head and as many trailing parts as fit.
  for (( keep = n - 1; keep >= 1; keep-- )); do
    cand="${parts[0]}/…"
    for (( i = n - keep; i < n; i++ )); do cand+="/${parts[i]}"; done
    (( ${#cand} <= max )) && { printf '%s' "$cand"; return; }
  done

  # 2. Abbreviate every intermediate component to one character.
  cand="${parts[0]}"
  for (( i = 1; i < n - 1; i++ )); do cand+="/${parts[i]:0:1}"; done
  cand+="/${parts[n-1]}"
  (( ${#cand} <= max )) && { printf '%s' "$cand"; return; }

  # 3. Give up and clip the head.
  printf '…%s' "${p: -$(( max - 1 ))}"
}

# ------------------------------------------------------------------- git ----
# One `status --porcelain=v2 --branch` yields branch *and* dirty counts in a
# single process. Cached on session_id: $$ would change on every invocation and
# defeat the cache entirely.

branch=''; staged=0; modified=0
cache="${TMPDIR:-/tmp}/claude-statusline-${session:-nosession}"
stale=1
if [ -f "$cache" ]; then
  # The Linux form must be tried first: on macOS `stat -c` fails quietly to
  # stderr, whereas on Linux `stat -f` prints a filesystem report to stdout
  # that would be captured and wreck the arithmetic.
  mtime=$(stat -c %Y "$cache" 2>/dev/null || stat -f %m "$cache" 2>/dev/null || echo 0)
  (( $(date +%s) - mtime <= 5 )) && stale=0
fi
if (( stale )); then
  git -C "$cwd" --no-optional-locks status --porcelain=v2 --branch 2>/dev/null | awk '
    /^# branch\.oid /  { oid = substr($3, 1, 7) }
    /^# branch\.head / { head = $3 }
    /^[12] / { if (substr($2,1,1) != ".") s++; if (substr($2,2,1) != ".") m++ }
    END {
      if (head == "(detached)") head = oid
      printf "%s\037%d\037%d\n", head, s+0, m+0
    }' > "$cache" 2>/dev/null
fi
[ -s "$cache" ] && IFS="$US" read -r branch staged modified < "$cache"
[ -z "${branch:-}" ]   && branch=''
[ -z "${staged:-}" ]   && staged=0
[ -z "${modified:-}" ] && modified=0

# ----------------------------------------------------------------- row 1 ----

short_cwd=$cwd
case "$cwd" in
  "$HOME")   short_cwd='~' ;;
  "$HOME"/*) short_cwd="~${cwd#"$HOME"}" ;;
esac

# Staged green / unstaged red mirrors `git status` itself.
dirty_p=''; dirty_c=''
if (( staged > 0 )); then
  dirty_p+=" +$staged"; dirty_c+=" ${GREEN}+${staged}${RESET}"
fi
if (( modified > 0 )); then
  dirty_p+=" ~$modified"; dirty_c+=" ${RED}~${modified}${RESET}"
fi

wt_p=''; wt_c=''
if [ -n "$worktree" ]; then
  wt_p="⌂ $worktree"; wt_c="${MAGENTA}⌂ ${worktree}${RESET}"
fi

br_p=''; br_c=''
if [ -n "$branch" ]; then
  br_p="⑂ ${branch}${dirty_p}"; br_c="${YELLOW}⑂ ${branch}${RESET}${dirty_c}"
fi

# Builds ROW1 (coloured) alongside ROW1P (plain, for measuring). The path is
# the only elastic part: below ~10 columns it shortens to noise ("…refresh"),
# so it is dropped outright rather than clamped.
build_row1() {
  local with_wt=$1 protected='' avail sp
  ROW1=''; ROW1P=''

  (( with_wt )) && [ -n "$wt_p" ] && protected+="${SEP}${wt_p}"
  [ -n "$br_p" ] && protected+="${SEP}${br_p}"

  avail=$(( COLS - ${#protected} ))
  if (( avail >= 10 )); then
    sp=$(shorten_path "$short_cwd" "$avail")
    ROW1P=$sp; ROW1="${BLUE}${sp}${RESET}"
  fi
  if (( with_wt )) && [ -n "$wt_p" ]; then
    [ -n "$ROW1P" ] && { ROW1P+=$SEP; ROW1+=$SEP; }
    ROW1P+=$wt_p; ROW1+=$wt_c
  fi
  if [ -n "$br_p" ]; then
    [ -n "$ROW1P" ] && { ROW1P+=$SEP; ROW1+=$SEP; }
    ROW1P+=$br_p; ROW1+=$br_c
  fi
}

# Second pass: when the chip and the branch cannot both fit, the chip goes —
# its name is usually a substring of the branch anyway. The branch is the one
# thing never sacrificed, so a pathologically long one is allowed to wrap.
build_row1 1
(( ${#ROW1P} > COLS )) && [ -n "$wt_p" ] && build_row1 0

# ----------------------------------------------------------------- row 2 ----

ctx_pct=''; [ -n "$ctx" ]     && printf -v ctx_pct '%.0f' "$ctx"
p5='';      [ -n "$pct5h" ]   && printf -v p5 '%.0f' "$pct5h"
p7='';      [ -n "$pct7d" ]   && printf -v p7 '%.0f' "$pct7d"
CTX_BAR=''; [ -n "$ctx_pct" ] && CTX_BAR=$(make_bar "$ctx_pct")

# Builds R2P (plain, for measuring) and R2C (coloured, for printing) from a set
# of include-flags, so the fitting loop can retry with fewer segments.
compose_row2() {
  local want_effort=$1 want_bar=$2 want_5h=$3 want_7d=$4
  R2P=$model; R2C="${CYAN}${model}${RESET}"

  if (( want_effort )) && [ -n "$effort" ]; then
    R2P+=" · $effort"; R2C+="${GREY} · ${effort}${RESET}"
  fi
  if [ -n "$ctx_pct" ]; then
    gauge_color "$ctx_pct"
    if (( want_bar )); then
      R2P+="${SEP}${CTX_BAR} ${ctx_pct}%"
      R2C+="${SEP}${GC}${CTX_BAR}${RESET} ${GC}${ctx_pct}%${RESET}"
    else
      R2P+="${SEP}${ctx_pct}%"; R2C+="${SEP}${GC}${ctx_pct}%${RESET}"
    fi
  fi
  if (( want_5h )) && [ -n "$p5" ]; then
    gauge_color "$p5"
    R2P+="${SEP}5h ${p5}%"; R2C+="${SEP}${GREY}5h${RESET} ${GC}${p5}%${RESET}"
  fi
  if (( want_7d )) && [ -n "$p7" ]; then
    gauge_color "$p7"
    R2P+="${SEP}7d ${p7}%"; R2C+="${SEP}${GREY}7d${RESET} ${GC}${p7}%${RESET}"
  fi
}

# Shed right-to-left until it fits: 7d, then 5h, then effort, then the bar.
for cfg in '1 1 1 1' '1 1 1 0' '1 1 0 0' '0 1 0 0' '0 0 0 0'; do
  compose_row2 $cfg
  (( ${#R2P} <= COLS )) && break
done
(( ${#R2P} > COLS )) && R2C="${CYAN}${model:0:COLS}${RESET}"

printf '%s\n%s' "$ROW1" "$R2C"
