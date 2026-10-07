--: mini.clue — the which-key equivalent, from the mini.nvim already in `base.lua`
--
-- Triggers are buffer-local mappings and only work while they are the *most
-- recent* ones on the buffer; when they are not, the symptom is silent — the
-- key still works, but only once the clue window is already up. mini.clue
-- re-asserts them itself on `BufWinEnter` and `LspAttach` (a `vim.schedule_wrap`
-- callback, so they do not exist yet at `VimEnter` — check with `:nmap g` from
-- a real session, not from `nvim -c`). Requiring this module last from
-- `plugins/init.lua` covers the gap before that first callback lands.
local MiniClue = require("mini.clue")

MiniClue.setup({
	triggers = {
		-- Leader is Space, and so is maplocalleader — markdown-plus's
		-- `<localleader>m*` tree shows up under this same trigger.
		{ mode = "n", keys = "<Leader>" },
		{ mode = "x", keys = "<Leader>" },

		-- Built-in prefixes
		{ mode = "n", keys = "g" },
		{ mode = "x", keys = "g" },
		{ mode = "n", keys = "z" },
		{ mode = "x", keys = "z" },
		{ mode = "n", keys = "[" },
		{ mode = "n", keys = "]" },

		-- Marks
		{ mode = "n", keys = "'" },
		{ mode = "n", keys = "`" },
		{ mode = "x", keys = "'" },
		{ mode = "x", keys = "`" },

		-- Registers
		{ mode = "n", keys = '"' },
		{ mode = "x", keys = '"' },
		{ mode = "i", keys = "<C-r>" },
		{ mode = "c", keys = "<C-r>" },

		-- Window commands
		{ mode = "n", keys = "<C-w>" },

		-- Built-in completion. Safe next to mini.completion: it replays
		-- `<C-x><C-o>` with `nvim_feedkeys(..., 'n', ...)`, which does not
		-- remap, so this trigger never sees it.
		{ mode = "i", keys = "<C-x>" },
	},

	-- `s` (mini.surround) and the operator-pending `a`/`i` (mini.ai) are
	-- deliberately absent: a trigger on `s` puts a delay on every `saiw`, and
	-- mini.clue documents that Operator-pending triggers have no foolproof
	-- support with custom operators.

	clues = {
		MiniClue.gen_clues.builtin_completion(),
		MiniClue.gen_clues.g(),
		MiniClue.gen_clues.marks(),
		MiniClue.gen_clues.registers(),
		MiniClue.gen_clues.windows(),
		MiniClue.gen_clues.z(),

		-- Only the *prefixes* need naming here. Individual keys take their
		-- text from the `desc` of the mapping itself, which mini.clue prefers
		-- over anything listed in `clues`.
		{ mode = "n", keys = "<Leader>m", desc = "+Markdown edit (markdown-plus)" },
		{ mode = "n", keys = "<Leader>o", desc = "+Open markdown reader" },
		{ mode = "n", keys = "<Leader>p", desc = "+Pick" },
		{ mode = "n", keys = "<Leader>r", desc = "+Reload" },
		{ mode = "n", keys = "<Leader>v", desc = "+View" },
		{ mode = "n", keys = "<Leader>x", desc = "+Diagnostics" },
	},

	window = {
		delay = 300,
		config = { width = "auto" },
	},
})
--:
