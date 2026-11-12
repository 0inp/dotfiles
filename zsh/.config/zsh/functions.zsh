# Colormap
function colormap() {
  for i in {0..255}; do print -Pn "%K{$i}  %k%F{$i}${(l:3::0:)i}%f " ${${(M)$((i%6)):#3}:+$'\n'}; done
}

# Interactive latency as felt: first prompt, first command, per-command and
# per-keystroke lag, through a real pty. `zsh -i -c exit`, the old measure, never
# draws a prompt, so it skipped zsh-vi-mode's deferred init and every precmd hook
# (atuin, fnox, mise, pure). zsh-bench is cloned on first use.
function timezsh() {
  local bench="$XDG_DATA_HOME/zsh-bench"
  [[ -d $bench ]] || git clone --depth=1 https://github.com/romkatv/zsh-bench "$bench" || return
  "$bench/zsh-bench" "$@"
}

function rfv() {
  # --smart-case, --hidden and the .git exclusion come from ripgreprc.
  rg --color=always --line-number --no-heading "${*:-}" |
    fzf --ansi \
        --color "hl:-1:underline,hl+:-1:underline:reverse" \
        --delimiter : \
        --preview 'bat --color=always {1} --highlight-line {2}' \
        --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
	--bind 'enter:become(nvim {1} +{2})'
}
zle -N rfv{,}
zvm_after_init_commands+=("bindkey '^g' rfv")

# leaf's own picker fuzzy-matches the BASENAME, so `leaf --fuzzy fiches` never
# reaches docs/fiches/*.md -- no `f` in DEV-1937-prix-contractuel-au-lot.md. It
# also reads no .gitignore, so it walks node_modules and quits at its hard
# directory cap (the "Indexing limited" line). fd honours .gitignore and fzf
# matches the whole path: 444 files in 81ms where leaf gave up at 66k
# directories. $1 pre-fills the query. Enter reads in leaf, ctrl-e edits in nvim.
function lf() {
  fd --type f --extension md --hidden --exclude .git \
    | fzf --ansi \
          --query "${1:-}" \
          --prompt "leaf> " \
          --preview 'leaf --inline ansi:$FZF_PREVIEW_COLUMNS -- {}' \
          --preview-window 'right,62%,border-left' \
          --bind 'ctrl-e:become(nvim -- {})' \
          --bind 'enter:become(leaf -w -- {})'
}
