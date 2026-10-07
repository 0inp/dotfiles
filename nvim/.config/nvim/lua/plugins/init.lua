require("plugins.base")
require("plugins.code-enhancements")
require("plugins.colorscheme")
require("plugins.formatting")
require("plugins.lsp")
require("plugins.markdown")
require("plugins.treesitter")
require("plugins.ui")

-- Last on purpose: mini.clue's triggers must be the newest buffer-local
-- mappings. See the header of `plugins/clue.lua`.
require("plugins.clue")
