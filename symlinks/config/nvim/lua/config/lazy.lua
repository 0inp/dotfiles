local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- load lazy
require("lazy").setup("plugins")
-- require("lazy").setup("plugins", {
-- 	install = { colorscheme = { "onedark" } },
-- 	defaults = { lazy = true },
-- 	ui = {
-- 		border = "rounded",
-- 	},
-- 	checker = { enabled = true },
-- 	debug = false,
-- })



-- Install your plugins here
local plugins = {
	-- "nvim-lua/plenary.nvim", -- Useful lua functions used by lots of plugins

	-- "jiangmiao/auto-pairs", -- Autopairs, integrates with both cmp and treesitter
	-- {
	-- 	"numToStr/Comment.nvim", -- "gc" to comment visual regions/lines
	-- 	config = function()
	-- 		require("Comment").setup()
	-- 	end,
	-- },

	-- "kyazdani42/nvim-web-devicons",
	-- "nvim-lualine/lualine.nvim",
	"lukas-reineke/indent-blankline.nvim",
	"folke/which-key.nvim",

	-- Colorschemes
	--"navarasu/onedark.nvim", -- Theme inspired by Atom
	-- "rebelot/kanagawa.nvim",
	-- {
	-- 	"rose-pine/neovim",
	-- 	as = "rose-pine",
	-- 	config = function()
	-- 		require("rose-pine").setup()
	-- 		vim.cmd("colorscheme rose-pine")
	-- 	end,
	-- },

	-- Cmp
	"hrsh7th/nvim-cmp", -- The completion plugin
	"hrsh7th/cmp-buffer", -- buffer completions
	"hrsh7th/cmp-path", -- path completions
	"saadparwaiz1/cmp_luasnip", -- snippet completions
	"hrsh7th/cmp-nvim-lua", -- lua completions
	"hrsh7th/cmp-nvim-lsp", -- lsp completions

	-- Snippets
	"L3MON4D3/LuaSnip", --snippet engine
	"rafamadriz/friendly-snippets", -- a bunch of snippets to use

	-- LSP
	"neovim/nvim-lspconfig", -- enable LSP
	"williamboman/mason.nvim", -- simple to use language server installer
	"williamboman/mason-lspconfig.nvim",
	"jose-elias-alvarez/null-ls.nvim", -- for formatters and linters
	"RRethy/vim-illuminate", -- highlighting

  -- Telescope
  "nvim-telescope/telescope.nvim",
  -- Fuzzy Finder Algorithm which requires local dependencies to be built. Only load if `make` is available
  { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },

	-- Treesitter
	{ "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },

	-- Nvim-Tree
	"kyazdani42/nvim-tree.lua",

	-- Git
	-- "lewis6991/gitsigns.nvim",

  -- Toggle between relative and absolute number according to focus
  -- "sitiom/nvim-numbertoggle",
  "mg979/vim-visual-multi",
}

local opts = {}
