return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      yamlls = {
        settings = {
          yaml = {
            schemas = {
              ["https://raw.githubusercontent.com/not-first/glance-schema/master/schema.json"] = "glance.yml",
            },
          },
        },
      },
    },
  },
}