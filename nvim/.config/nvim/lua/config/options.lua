-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Set to true if you have a Nerd Font installed
vim.g.have_nerd_font = true

-- Enable break indent
vim.opt.breakindent = true

-- Sets how neovim will display certain whitespace in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Preview substitutions live, as you type!
vim.opt.inccommand = "split"

-- Do not comment out next newline
vim.opt.formatoptions:remove({ "r", "o" })

vim.g.python3_host_prog = "python"

vim.opt.path:append({ "**" })
vim.opt.wildignore:append({ "*/node_modules/*" })

-- remap localleader to ,
vim.g.maplocalleader = ","

-- blink compat
vim.g.lazyvim_blink_main = false

-- Set to `false` to prevent "non-lsp snippets"" from appearing inside completion windows
-- Motivation: Less clutter in completion windows and a more direct usage of snippits
vim.g.lazyvim_mini_snippets_in_completion = true
