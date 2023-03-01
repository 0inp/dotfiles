local opts = { noremap = true, silent = true, desc = nil }

-- Shorten function name
-- local keymap = vim.api.nvim_set_keymap
local function keymap(mode, keys, func, opts, desc)
	local local_opts
	local_opts = opts
	if desc then
		local_opts["desc"] = desc
	end
	vim.api.nvim_set_keymap(mode, keys, func, local_opts)
end

-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

-- Normal --
-- Better window navigation
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-k>", "<C-w>k", opts)
keymap("n", "<C-l>", "<C-w>l", opts)
-- Disabling arrows
keymap("n", "<up>", "<nop>", opts)
keymap("n", "<down>", "<nop>", opts)
keymap("n", "<left>", "<nop>", opts)
keymap("n", "<right>", "<nop>", opts)
keymap("v", "<up>", "<nop>", opts)
keymap("v", "<down>", "<nop>", opts)
keymap("v", "<left>", "<nop>", opts)
keymap("v", "<right>", "<nop>", opts)
keymap("o", "<up>", "<nop>", opts)
keymap("o", "<down>", "<nop>", opts)
keymap("o", "<left>", "<nop>", opts)
keymap("o", "<right>", "<nop>", opts)

-- Resize with arrows
keymap("n", "<C-Up>", ":resize -2<CR>", opts)
keymap("n", "<C-Down>", ":resize +2<CR>", opts)
keymap("n", "<C-Left>", ":vertical resize -2<CR>", opts)
keymap("n", "<C-Right>", ":vertical resize +2<CR>", opts)

-- Navigate buffers
keymap("n", "<S-l>", ":bnext<CR>", opts)
keymap("n", "<S-h>", ":bprevious<CR>", opts)

-- Move text up and down
keymap("n", "<A-j>", "<Esc>:m .+1<CR>==gi", opts)
keymap("n", "<A-k>", "<Esc>:m .-2<CR>==gi", opts)

-- Insert --
-- Press jk fast to exit insert mode
keymap("i", "jk", "<ESC>", opts)
keymap("i", "kj", "<ESC>", opts)

-- Visual --
-- Stay in indent mode
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Move text up and down
keymap("v", "<A-j>", ":m .+1<CR>==", opts)
keymap("v", "<A-k>", ":m .-2<CR>==", opts)
keymap("v", "p", '"_dP', opts)

-- Visual Block --
-- Move text up and down
keymap("x", "J", ":move '>+1<CR>gv-gv", opts)
keymap("x", "K", ":move '<-2<CR>gv-gv", opts)
keymap("x", "<A-j>", ":move '>+1<CR>gv-gv", opts)
keymap("x", "<A-k>", ":move '<-2<CR>gv-gv", opts)
--
-- Yank until the end of line
keymap("n", "Y", "y$", opts)
--  Add pdb breakpoints
keymap("n", "<leader>m", "oimport pdb; pdb.set_trace()<Esc>", opts)
keymap("n", "<leader><S-p>", "Oimport pdb; pdb.set_trace()<Esc>", opts)

-- In case you forgot to sudo
keymap("c", "w!!", "%!sudo tee > /dev/null %", opts)

-- Terminal --
-- Better terminal navigation
-- keymap("t", "<C-h>", "<C-\\><C-N><C-w>h", term_opts)
-- keymap("t", "<C-j>", "<C-\\><C-N><C-w>j", term_opts)
-- keymap("t", "<C-k>", "<C-\\><C-N><C-w>k", term_opts)
-- keymap("t", "<C-l>", "<C-\\><C-N><C-w>l", term_opts)

-- Telescope
keymap(
	"n",
	"<leader>?",
	"<cmd>lua require'telescope.builtin'.oldfiles()<cr>",
	opts,
	"LSP: [?] Find recently opened files"
)
keymap(
	"n",
	"<leader><space>",
	"<cmd>lua require'telescope.builtin'.buffers()<cr>",
	opts,
	"LSP: [ ] Find existing buffers"
)
-- You can pass additional configuration to telescope to change theme, layout, etc.
keymap(
	"n",
	"<leader>/",
	"<cmd>lua require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown { winblend = 10, previewer = false, })<cr>",
	opts,
	"LSP: [/] Fuzzily search in current buffer"
)
keymap("n", "<leader>sf", "<cmd>lua require'telescope.builtin'.find_files()<cr>", opts, "LSP: [S]earch [F]iles")
keymap("n", "<leader>sh", "<cmd>lua require'telescope.builtin'.help_tags()<cr>", opts, "LSP: [S]earch [H]elp")
keymap("n", "<leader>sw", "<cmd>lua require'telescope.builtin'.grep_string()<cr>", opts, "LSP: [S]earch current [W]ord")
keymap("n", "<leader>sg", "<cmd>lua require'telescope.builtin'.live_grep()<cr>", opts, "LSP: [S]earch by [G]rep")
keymap("n", "<leader>sd", "<cmd>lua require'telescope.builtin'.diagnostics()<cr>", opts, "LSP: [S]earch [D]iagnostics")

-- Nvim-Tree
keymap("n", "<leader>e", ":NvimTreeToggle<cr>", opts, "Nvim-Tree: Toggle")
