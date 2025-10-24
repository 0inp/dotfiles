return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      lemminx = {
        settings = {
          xml = {
            format = {
              enabled = true,
              splitAttributes = "alignWithFirstAttr",
              spaceBeforeEmptyCloseTag = true,
            },
          },
        },
      },
    },
  },
}
