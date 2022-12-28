-- [[ Setting options ]]
-- See `:help vim.o`
-- Line highlight
vim.o.cursorline = true
-- Line numbers
vim.o.number = true
vim.o.relativenumber = true
vim.o.ruler = true

-- Set highlight on search
vim.o.hlsearch = true
-- Search as you type character
vim.o.incsearch = true
-- Ignore case in search
vim.o.ignorecase = true
-- Search with smart case (if uppercase provided, search is case sensitive)
vim.o.smartcase = true

-- Make line numbers default
vim.wo.number = true

-- Enable mouse mode
vim.o.mouse = 'a'

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Decrease update time
vim.o.updatetime = 250
vim.wo.signcolumn = 'yes'

-- Default file encoding
vim.o.encoding = 'utf-8'

-- Wrap lines
vim.o.wrap = true

-- Show matching parenthesis
vim.o.showmatch = true

-- Disabling viminfo
vim.o.viminfo = ""
-- Turn on the Wild menu, better suggestion
vim.o.wildmenu = true
-- Be lazy when redrawing screen
vim.o.lazyredraw = true

-- Set colorscheme
vim.o.termguicolors = true
vim.cmd [[colorscheme onedark]]

-- Set completeopt to have a better completion experience
vim.o.completeopt = 'longest,menuone'

-- Set termguicolors to enable highlight groups
vim.opt.termguicolors = true

-- [[ Basic Keymaps ]]
-- Set "," as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = ','
vim.g.maplocalleader = ','

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Clear highlighting on escape in normal mode
vim.keymap.set('n', '<esc>', ":noh<return><esc>")
vim.keymap.set('n', '<esc>^[', '<esc>^[')

-- Mouvement between vim windows
vim.keymap.set({'n', 'v', 'o'}, '<C-h>', "<C-w>h")
vim.keymap.set({'n', 'v', 'o'}, '<C-j>', "<C-w>j")
vim.keymap.set({'n', 'v', 'o'}, '<C-k>', "<C-w>k")
vim.keymap.set({'n', 'v', 'o'}, '<C-l>', "<C-w>l")
vim.keymap.set({'n', 'v', 'o'}, '<up>', "<nop>")
vim.keymap.set({'n', 'v', 'o'}, '<down>', "<nop>")
vim.keymap.set({'n', 'v', 'o'}, '<left>', "<nop>")
vim.keymap.set({'n', 'v', 'o'}, '<right>', "<nop>")

-- Yank until the end of line
vim.keymap.set('n', 'Y', 'y$')
--  Add pdb breakpoints
vim.keymap.set('n', '<leader>m', "oimport pdb; pdb.set_trace()<Esc>")
vim.keymap.set('n', '<leader><S-p>', "Oimport pdb; pdb.set_trace()<Esc>")

-- In case you forgot to sudo
vim.keymap.set('c', 'w!!', "%!sudo tee > /dev/null %")

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

