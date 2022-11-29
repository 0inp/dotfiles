" Turnoff vi backward compatibility filetype off

"PLUGINS
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
" syntax checking
Plug 'dense-analysis/ale'
" AutoCompletion
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'nvim-treesitter/nvim-treesitter', { 'do': ':TSUpdate' }
Plug 'jamestthompson3/nvim-remote-containers'
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
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
" Snippets.
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
" Search tools
Plug 'vim-scripts/matchit.zip'

call plug#end()            " required
filetype plugin indent on    " required

" PLUGINS CONFIGURATION
" Vim-Plug updates status
" Do not show any message if all plugins are up to date. 0 by default
let g:outdated_plugins_silent_mode = 1

" SimpylFold
let g:SimpylFold_docstring_preview = 1
"
" Ale
nmap <silent> <C-e> <Plug>(ale_next_wrap)
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

" vim-snippets
" If you want :UltiSnipsEdit to split your window.
let g:UltiSnipsEditSplit="vertical"

" fzf+Vim
nmap <C-P> :FZF<CR>
" Ripgrep
nnoremap <leader>r :Rg<CR>

"NerdTree
nnoremap <leader>d :NERDTreeToggle<CR>
nnoremap <leader>f :NERDTreeFind<CR>
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
let g:NERDSpaceDelims=1

" Coc.nvim
" Some servers have issues with backup files, see #649.
set nobackup
set nowritebackup
" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300
" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
set signcolumn=yes
" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1):
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"
" Make <CR> to accept selected completion item or notify coc.nvim to format
" <C-g>u breaks current undo, please make your own choice.
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction
" Use <c-space> to trigger completion.
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif
" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
" Use K to show documentation in preview window.
nnoremap <silent> K :call ShowDocumentation()<CR>
function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction
" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')
" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)
" Formatting selected code.
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)
augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder.
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end
" Applying codeAction to the selected region.
" Example: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)
" Remap keys for applying codeAction to the current buffer.
nmap <leader>ac  <Plug>(coc-codeaction)
" Apply AutoFix to problem on the current line.
nmap <leader>qf  <Plug>(coc-fix-current)
" Run the Code Lens action on the current line.
nmap <leader>cl  <Plug>(coc-codelens-action)
" Map function and class text objects
" NOTE: Requires 'textDocument.documentSymbol' support from the language server.
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)
" Remap <C-f> and <C-b> for scroll float windows/popups.
if has('nvim-0.4.0') || has('patch-8.2.0750')
  nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
  inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
  inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
  vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
endif
" Use CTRL-S for selections ranges.
" Requires 'textDocument/selectionRange' support of language server.
nmap <silent> <C-s> <Plug>(coc-range-select)
xmap <silent> <C-s> <Plug>(coc-range-select)
" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocActionAsync('format')
" Add `:Fold` command to fold current buffer.
command! -nargs=? Fold :call     CocAction('fold', <f-args>)
" Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR   :call     CocActionAsync('runCommand', 'editor.action.organizeImport')
" Add (Neo)Vim's native statusline support.
" NOTE: Please see `:h coc-status` for integrations with external plugins that
" provide custom statusline: lightline.vim, vim-airline.
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}
" Mappings for CoCList
" Show all diagnostics.
nnoremap <silent><nowait> <space>a  :<C-u>CocList diagnostics<cr>
" Manage extensions.
nnoremap <silent><nowait> <space>e  :<C-u>CocList extensions<cr>
" Show commands.
nnoremap <silent><nowait> <space>c  :<C-u>CocList commands<cr>
" Find symbol of current document.
nnoremap <silent><nowait> <space>o  :<C-u>CocList outline<cr>
" Search workspace symbols.
nnoremap <silent><nowait> <space>s  :<C-u>CocList -I symbols<cr>
" Do default action for next item.
nnoremap <silent><nowait> <space>j  :<C-u>CocNext<CR>
" Do default action for previous item.
nnoremap <silent><nowait> <space>k  :<C-u>CocPrev<CR>
" Resume latest coc list.
nnoremap <silent><nowait> <space>p  :<C-u>CocListResume<CR>
let g:coc_global_extensions = ['coc-pyright', 'coc-json', 'coc-git']
let g:coc#preferences#extensionUpdateCheck = 'daily'
" devcontainer options
hi Container guifg=#BADA55 guibg=Black
set statusline+=%#Container#%{g:currentContainer}


" Status line
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
set autoread
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
" Omni completion
set completeopt=longest,menuone
set omnifunc=syntaxcomplete#Complete
" Enable syntax color if exist
if exists(":syntax")
  syntax on
endif
colorscheme onedark
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
autocmd BufRead,BufNewFile *.md set spell

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

set encoding=UTF-8
