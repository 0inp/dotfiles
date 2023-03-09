require("user.config.globals")
require("user.config.options")
require("user.config.lazy")

vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
        require("user.config.autocommands")
        require("user.config.keymaps")
    end,
})
