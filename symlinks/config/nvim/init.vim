" Turnoff vi backward compatibility filetype off
set nocompatible

" PLUGINS
call plug#begin('~/.vim/plugged')
" INTERFACE
" Theme
Plug 'joshdick/onedark.vim'
" StatusLine
Plug 'semanser/vim-outdated-plugins'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
" Jinja
Plug 'lepture/vim-jinja'
" Code folding
Plug 'tmhedberg/SimpylFold'
" Syntax Highlighting
Plug 'sheerun/vim-polyglot'
" Use of :Make in vim
Plug 'tpope/vim-dispatch'

" EDITING
" " AutoCompletion
Plug 'ms-jpq/coq_nvim', {'branch': 'coq'}
Plug 'ms-jpq/coq.artifacts', {'branch': 'artifacts'}
" Commenting
Plug 'tpope/vim-commentary'
" editing around a letter, word or block in vim
Plug 'tpope/vim-surround'
" Automatic quote and bracket completion
Plug 'jiangmiao/auto-pairs'
" MultiCursor
Plug 'mg979/vim-visual-multi', {'branch': 'master'}

" NAVIGATING
" File fuzzy finder
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --bin' }
Plug 'junegunn/fzf.vim'
" Search tool ripgrep
Plug 'jremmen/vim-ripgrep'
" File system explorer
Plug 'ms-jpq/chadtree', {'branch': 'chad', 'do': 'python3 -m chadtree deps'}

" try Ale in contaner
Plug 'dense-analysis/ale'

call plug#end()            " required
filetype plugin indent on    " required

" THEME onedark
" Remove the ~ at the end of file
let g:onedark_hide_endofbuffer = 1
" 256-color terminals
let g:onedark_termcolors = 256
" Terminal emulator supports italics
let g:onedark_terminal_italics = 1
" Enable syntax color if exist
if exists(":syntax")
  syntax on
endif
colorscheme onedark

" Airline Status line
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'unique_tail_improved'
let g:airline_theme='onedark'

" MISCELLANEOUS
" Line highlight
set cursorline
" Line numbers
set number relativenumber
set ruler
augroup numbertoggle
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave * set relativenumber
  autocmd BufLeave,FocusLost,InsertEnter   * set norelativenumber
augroup END
" Default file encoding
set encoding=utf-8
" Auto reload file
if ! exists("g:CheckUpdateStarted")
    let g:CheckUpdateStarted=1
    call timer_start(1,'CheckUpdate')
endif
function! CheckUpdate(timer)
    silent! checktime
    call timer_start(1000,'CheckUpdate')
endfunction
" Disable backup files
set nobackup
set noswapfile
" Show current command combination on bottom right
set showcmd
" Confirm change save
set confirm
" Wrap lines
set wrap
" show trailing whitespace
set list
set listchars=trail:▫
" Spaces tab's width and indent size
set ai
set tabstop=4 shiftwidth=4
set softtabstop=4
set smartindent
if exists(':filetype')
	filetype indent on
endif
" Show matching parenthesis
set showmatch
" Insert spaces instead of tabs
set expandtab
" show where you are
" Backspace behavior for corresponding to most common apps
set backspace=indent,eol,start
" Hightlight search
set hlsearch
" Clear highlighting on escape in normal mode
nnoremap <esc> :noh<return><esc>
nnoremap <esc>^[ <esc>^[
" Search as you type character
set incsearch
" Ignore case in search
set ignorecase
" Search with smart case (if uppercase provided, search is case sensitive)
set smartcase
"" Omni completion
set completeopt=longest,menuone
"set omnifunc=syntaxcomplete#Complete
" Disabling viminfo
set viminfo=""
" Turn on the Wild menu, better suggestion
set wildmenu
" Be lazy when redrawing screen
set lazyredraw

" KEYBOARD SHORTCUTS
" Selecting Indent Objects
onoremap <silent>ai :<C-U>cal <SID>IndTxtObj(0)<CR>
onoremap <silent>ii :<C-U>cal <SID>IndTxtObj(1)<CR>
vnoremap <silent>ai :<C-U>cal <SID>IndTxtObj(0)<CR><Esc>gv
vnoremap <silent>ii :<C-U>cal <SID>IndTxtObj(1)<CR><Esc>gv
function! s:IndTxtObj(inner)
  let curline = line(".")
  let lastline = line("$")
  let i = indent(line(".")) - &shiftwidth * (v:count1 - 1)
  let i = i < 0 ? 0 : i
  if getline(".") !~ "^\\s*$"
    let p = line(".") - 1
    let nextblank = getline(p) =~ "^\\s*$"
    while p > 0 && ((i == 0 && !nextblank) || (i > 0 && ((indent(p) >= i && !(nextblank && a:inner)) || (nextblank && !a:inner))))
      -
      let p = line(".") - 1
      let nextblank = getline(p) =~ "^\\s*$"
    endwhile
    normal! 0V
    call cursor(curline, 0)
    let p = line(".") + 1
    let nextblank = getline(p) =~ "^\\s*$"
    while p <= lastline && ((i == 0 && !nextblank) || (i > 0 && ((indent(p) >= i && !(nextblank && a:inner)) || (nextblank && !a:inner))))
      +
      let p = line(".") + 1
      let nextblank = getline(p) =~ "^\\s*$"
    endwhile
    normal! $
  endif
endfunction

let mapleader = ','

" Mouvement between vim windows
noremap <C-h> <C-w>h
noremap <C-j> <C-w>j
noremap <C-k> <C-w>k
noremap <C-l> <C-w>l
map <up> <nop>
map <down> <nop>
map <left> <nop>
map <right> <nop>
imap <up> <nop>
imap <down> <nop>
imap <left> <nop>
imap <right> <nop>

" Other shortcuts
nnoremap Y y$
" add pdb breakpoints
nnoremap <leader>m oimport pdb; pdb.set_trace()<Esc>
nnoremap <leader><S-p> Oimport pdb; pdb.set_trace()<Esc>

" in case you forgot to sudo
cnoremap w!! %!sudo tee > /dev/null %

" md is markdown
autocmd BufRead,BufNewFile *.md set filetype=markdown
autocmd BufRead,BufNewFile *.md set spell spelllang=en_us

" Fix Cursor in TMUX
if exists('$TMUX')
  let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=1\x7\<Esc>\\"
  let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=0\x7\<Esc>\\"
else
  let &t_SI = "\<Esc>]50;CursorShape=1\x7"
  let &t_EI = "\<Esc>]50;CursorShape=0\x7"
endif

let g:pymode_options_max_line_length = 180
let g:pymode_lint_options_pep8 = {'max_line_length': 180}
"
" PLUGINS CONFIGURATION
" Vim-Plug updates status
" Do not show any message if all plugins are up to date. 0 by default
let g:outdated_plugins_silent_mode = 0

" SimpylFold
let g:SimpylFold_docstring_preview = 1

" Vim-Polyglot
let g:python_highlight_all = 1

" fzf+Vim
nmap <C-P> :FZF<CR>
" Ripgrep
nmap <leader>r :Rg<CR>

" CHADTree
nnoremap <leader>v <cmd>CHADopen<cr>
let g:chadtree_settings = {'theme.icon_glyph_set': 'ascii_hollow', 'theme.text_colour_set': 'nord'}

" COQ
let g:coq_settings = {'display.icons.mode': 'none', 'auto_start': 'shut-up', 'keymap.jump_to_mark': 'null'}

" Ale
nmap <silent> <C-k> <Plug>(ale_previous_wrap)
nmap <silent> <C-j> <Plug>(ale_next_wrap)
function! LinterStatus() abort
    let l:counts = ale#statusline#Count(bufnr(''))    let l:all_errors = l:counts.error + l:counts.style_error
    let l:all_non_errors = l:counts.total - l:all_errors    return l:counts.total == 0 ? 'OK' : printf(
        \   '%d⨉ %d⚠ ',
        \   all_non_errors,
        \   all_errors
        \)
endfunction
set statusline+=%=
set statusline+=\ %{LinterStatus()}
let g:ale_python_auto_pipenv = 0
let g:ale_lint_on_enter = 0
let g:ale_lint_on_save = 1
let g:ale_fix_on_save = 0
let g:ale_sign_error = '●'
let g:ale_sign_warning = '.'
let g:airline#extensions#ale#enabled = 1
let g:ale_linters = {'python': ['flake8', 'mypy', 'black', 'isort'],}
let g:ale_fixers = {'python': ['autoflake', 'black', 'isort'],}
let g:ale_floating_window_border = ['│', '─', '╭', '╮', '╯', '╰']
" let g:ale_python_flake8_executable = '/Users/stephanepoint/flake8_script.sh'
" let g:ale_python_mypy_executable = '/Users/stephanepoint/mypy_script.sh'
" let g:ale_python_black_executable = '/Users/stephanepoint/black_script.sh'
" let g:ale_python_isort_executable = '/Users/stephanepoint/isort_script.sh'
