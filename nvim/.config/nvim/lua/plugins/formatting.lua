return {
  {
    "mfussenegger/nvim-jdtls",
    opts = {
      settings = {
        java = {
          format = {
            enabled = true,
            settings = {
              url = "/Users/spoint/dotfiles/nvim/.config/nvim/formatter/java_format_checkstyle.xml",
              profile = "TwilioCheckstyle",
            },
          },
          organizeImports = {
            importOrder = { "java", "javax", "com", "org" },
          },
        },
      },
    },
  },
}
