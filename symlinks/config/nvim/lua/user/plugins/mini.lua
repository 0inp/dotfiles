-------------------------------------------------
-- name : nvim-tree
-- url  : https://github.com/echasnovski/mini.nvim
-------------------------------------------------
local mini_plugins = {
  -- "mini.animate",
  "mini.basics",
  "mini.comment",
  "mini.fuzzy",
  "mini.indentscope",
  "mini.pairs",
  "mini.surround",
  "mini.tabline",
}

local M = {
  "echasnovski/mini.nvim",
	dependencies = {"nvim-tree/nvim-web-devicons"},
  config = function()
    for k, l in ipairs(mini_plugins) do
      require(l).setup()
    end
  end
}

return M
