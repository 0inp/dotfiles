return {
  "hrsh7th/nvim-cmp",
  dependencies = { "hrsh7th/cmp-cmdline" },
  ---@param opts cmp.ConfigSchema
  opts = function(_, opts)
    table.insert(opts.sources, { name = "cmdline" })
  end,
}
