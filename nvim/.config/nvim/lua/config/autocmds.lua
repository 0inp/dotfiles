-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here
-- Do not comment out new line

vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function()
    vim.opt_local.formatoptions:remove({ "r", "o" })
  end,
})

local function augroup(name)
  return vim.api.nvim_create_augroup("lazyvim_" .. name, { clear = true })
end

vim.api.nvim_create_autocmd("VimEnter", {
  group = augroup("autoupdate"),
  callback = function()
    require("lazy").update({
      show = false,
    })
  end,
})

local function clean_lsp_logs()
  local log_path = vim.lsp.get_log_path()
  if vim.fn.filereadable(log_path) == 1 then
    vim.fn.delete(log_path)
    -- Optional: display a message confirming deletion
    -- vim.notify("LSP log file deleted: " .. log_path, vim.log.levels.INFO)
  end
end

-- Create an autocommand to run the cleanup function before Neovim exits
vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("LspLogCleanup", { clear = true }),
  callback = clean_lsp_logs,
  desc = "Delete LSP log file on Neovim enter",
})
