local M = {}

-- Tracks open preview windows for side-by-side mode: { [filepath] = win_id }
local windows = {}

local function is_markdown(filepath)
  local ext = vim.fn.fnamemodify(filepath, ":e"):lower()
  return ext == "md" or ext == "mdx"
end

function M.toggle()
  local binary = require("stackreader").resolve_binary()
  if not binary then
    vim.notify(
      "StackReader not installed. Run :StackReaderInstall",
      vim.log.levels.ERROR
    )
    return
  end

  local filepath = vim.fn.expand("%:p")
  if filepath == "" or not is_markdown(filepath) then
    vim.notify("StackReader: not a markdown file", vim.log.levels.WARN)
    return
  end

  -- Toggle off: close the preview split, keep the edit buffer.
  local existing_win = windows[filepath]
  if existing_win and vim.api.nvim_win_is_valid(existing_win) then
    vim.api.nvim_win_close(existing_win, true)
    windows[filepath] = nil
    return
  end

  -- Remember the edit window so we can return focus to it.
  local edit_win = vim.api.nvim_get_current_win()

  -- Open preview split to the right.
  vim.cmd("vsplit")
  local preview_win = vim.api.nvim_get_current_win()
  windows[filepath] = preview_win

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_win_set_buf(preview_win, buf)

  vim.fn.termopen({ binary, "--watch", filepath }, {
    on_exit = function()
      windows[filepath] = nil
      if vim.api.nvim_win_is_valid(preview_win) then
        vim.api.nvim_win_close(preview_win, true)
      end
    end,
  })

  -- Return focus to the edit buffer so the user can keep typing.
  vim.api.nvim_set_current_win(edit_win)
end

return M
