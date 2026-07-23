-- Auto-loaded by Neovim on startup. Registers user commands.
-- Keymaps are registered in setup() so users can customise them.

vim.api.nvim_create_user_command('StackReaderToggle', function()
  require('stackreader').toggle()
end, { desc = 'Toggle StackReader markdown rendering for current buffer' })
