local M = {}

-- Tracks open browser windows: { [dirpath] = win_id }
local windows = {}

function M.toggle()
  local binary = require("stackreader").resolve_binary()
  if not binary then
    vim.notify(
      "StackReader not installed. Run :StackReaderInstall",
      vim.log.levels.ERROR
    )
    return
  end

  -- Use the directory of the current buffer's file.
  local dirpath = vim.fn.expand("%:p:h")
  if dirpath == "" then
    dirpath = vim.fn.getcwd()
  end

  -- Toggle off: close the existing browser window.
  local existing_win = windows[dirpath]
  if existing_win and vim.api.nvim_win_is_valid(existing_win) then
    vim.api.nvim_win_close(existing_win, true)
    windows[dirpath] = nil
    return
  end

  -- Open vertical split on the right.
  local edit_win = vim.api.nvim_get_current_win()
  vim.cmd("vsplit")
  local win = vim.api.nvim_get_current_win()
  windows[dirpath] = win

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(win, buf)

  -- No --watch: browser mode, user navigates within StackReader.
  vim.fn.termopen({ binary, dirpath }, {
    on_exit = function()
      windows[dirpath] = nil
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end,
  })

  vim.cmd("startinsert")
end

return M
