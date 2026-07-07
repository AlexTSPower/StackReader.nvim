-- Auto-loaded by Neovim on startup. Registers user commands.
-- Keymaps are registered separately in setup() so users can customise them.

vim.api.nvim_create_user_command("StackReaderInstall", function()
  require("stackreader.install").install()
end, { desc = "Install or update the StackReader binary" })

vim.api.nvim_create_user_command("StackReaderPreview", function()
  require("stackreader.preview").toggle()
end, { desc = "Toggle StackReader preview split for current file" })

vim.api.nvim_create_user_command("StackReaderSideBySide", function()
  require("stackreader.sidebyside").toggle()
end, { desc = "Toggle StackReader side-by-side edit + preview" })

vim.api.nvim_create_user_command("StackReaderBrowser", function()
  require("stackreader.browser").toggle()
end, { desc = "Open StackReader directory browser" })
