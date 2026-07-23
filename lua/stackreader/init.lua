local M = {}

local defaults = {
  enabled = true,
  render_modes = { 'n', 'c' },
  anti_conceal = { above = 0, below = 0 },
  file_types = { 'markdown', 'mdx' },
  keymaps = {
    toggle = '<leader>sp',
  },
  heading = {
    icons = { '󰲡 ', '󰲣 ', '󰲥 ', '󰲧 ', '󰲩 ', '󰲫 ' },
    width = 'full',
  },
  code = {
    style = 'full',
    border = 'thin',
  },
  bullet = {
    icons = { '●', '○', '◆', '◇' },
  },
}

M.config = vim.deepcopy(defaults)

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', defaults, opts or {})

  require('stackreader.highlights').setup()

  local km = M.config.keymaps
  if km.toggle ~= false then
    vim.keymap.set('n', km.toggle, M.toggle, { desc = 'StackReader: toggle rendering' })
  end

  if M.config.enabled then
    require('stackreader.manager').setup(M.config)
  end
end

function M.toggle()
  local buf = vim.api.nvim_get_current_buf()
  local active = require('stackreader.manager').toggle(buf, M.config)
  vim.notify(
    active and 'StackReader: rendering enabled' or 'StackReader: rendering disabled',
    vim.log.levels.INFO
  )
end

return M
