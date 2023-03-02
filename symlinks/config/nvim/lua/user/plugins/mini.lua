local mini_plugins = {
  "mini.animate",
  "mini.basics",
  "mini.comment",
  "mini.fuzzy",
  "mini.indentscope",
  "mini.pairs",
  "mini.starter",
  "mini.surround",
  "mini.tabline",
}

local M = {
  "echasnovski/mini.nvim",
  config = function()
    for k, l in ipairs(mini_plugins) do
      require(l).setup()
    end
  end
}
return M
