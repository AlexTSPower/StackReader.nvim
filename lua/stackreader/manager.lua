local M = {}
local renderer = require('stackreader.renderer')

-- buf → Updater
local updaters = {}

local function win_for_buf(buf)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == buf then
      return win
    end
  end
end

function M.attach(buf, config)
  if updaters[buf] then return end

  local win = win_for_buf(buf)
  if not win then return end

  local updater = renderer.Updater:new(buf, win, config)
  updaters[buf] = updater

  local group = vim.api.nvim_create_augroup('StackReaderBuf' .. buf, { clear = true })

  local function schedule()
    local w = win_for_buf(buf)
    if w then updater.win = w end
    updater:schedule()
  end

  vim.api.nvim_create_autocmd(
    { 'ModeChanged', 'CursorMoved', 'CursorMovedI', 'TextChanged', 'BufWinEnter' },
    { group = group, buffer = buf, callback = schedule }
  )

  vim.api.nvim_create_autocmd('BufUnload', {
    group = group,
    buffer = buf,
    callback = function() M.detach(buf) end,
  })

  updater:schedule()
end

function M.detach(buf)
  local updater = updaters[buf]
  if not updater then return end

  if updater.timer then
    updater.timer:stop()
    updater.timer:close()
    updater.timer = nil
  end

  if vim.api.nvim_buf_is_valid(buf) then
    updater:clear()
  end

  pcall(vim.api.nvim_del_augroup_by_name, 'StackReaderBuf' .. buf)
  updaters[buf] = nil
end

-- Returns true if rendering is now active, false if it was disabled.
function M.toggle(buf, config)
  if updaters[buf] then
    M.detach(buf)
    return false
  else
    M.attach(buf, config)
    return updaters[buf] ~= nil
  end
end

function M.setup(config)
  -- Global autocmd for scroll/resize events (not buffer-local)
  vim.api.nvim_create_autocmd({ 'WinScrolled', 'WinResized' }, {
    group = vim.api.nvim_create_augroup('StackReaderWindows', { clear = true }),
    callback = function()
      local win = vim.api.nvim_get_current_win()
      local buf = vim.api.nvim_win_get_buf(win)
      local updater = updaters[buf]
      if updater then
        updater.win = win
        updater:schedule()
      end
    end,
  })

  -- FileType listener for auto-attach
  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('StackReaderFileType', { clear = true }),
    pattern = config.file_types,
    callback = function(ev)
      M.attach(ev.buf, config)
    end,
  })

  -- Attach to already-open matching buffers
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local ft = vim.bo[buf].filetype
      for _, allowed in ipairs(config.file_types) do
        if ft == allowed then
          M.attach(buf, config)
          break
        end
      end
    end
  end
end

return M
