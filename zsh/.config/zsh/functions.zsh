# Colormap
function colormap() {
  for i in {0..255}; do print -Pn "%K{$i}  %k%F{$i}${(l:3::0:)i}%f " ${${(M)$((i%6)):#3}:+$'\n'}; done
}

# Mean measurements of zsh loading
function timezsh() {
  shell=${1-$SHELL}
  for i in $(seq 1 10); do /usr/bin/time $shell -i -c exit; done
}

function rfv() {
  rg --color=always --line-number --no-heading --smart-case --hidden --glob "!.git" "${*:-}" |
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

# Mount the Air's media (/srv/media) on ~/AirMedia over SFTP and open it in
# Finder once the mount is up; stays in the foreground, Ctrl-C unmounts. IINA
# then loads Bazarr's sidecar .srt, which it skips when playing from a URL.
# --sftp-disable-hashcheck: otherwise rclone runs md5sum on the Air and reads hang.
# -o locallocks: otherwise any fcntl lock on the mount hangs.
function airmedia() {
  local mnt=~/AirMedia
  if mount | grep -q " on ${mnt} "; then
    open "$mnt"
    return
  fi
  mkdir -p "$mnt"
  ( for _ in {1..30}; do
      mount | grep -q " on ${mnt} " && { open "$mnt"; exit; }
      sleep 1
    done ) &!
  rclone nfsmount :sftp:/srv/media "$mnt" --sftp-ssh "ssh air" \
    --sftp-disable-hashcheck --read-only \
    --vfs-cache-mode full --vfs-cache-max-size 10G -o locallocks
}
