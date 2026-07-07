local M = {}

-- [term_buf] = { filepath, term_win }
local state = {}

local function is_markdown(filepath)
  local ext = vim.fn.fnamemodify(filepath, ":e"):lower()
  return ext == "md" or ext == "mdx"
end

local function open_edit(term_buf)
  local s = state[term_buf]
  if not s then return end

  vim.cmd("vsplit " .. vim.fn.fnameescape(s.filepath))
  local edit_buf = vim.api.nvim_get_current_buf()

  -- When the edit window closes (write-quit or just quit), return focus to preview.
  vim.api.nvim_create_autocmd("BufWinLeave", {
    buffer = edit_buf,
    once = true,
    callback = function()
      vim.schedule(function()
        local s2 = state[term_buf]
        if s2 and vim.api.nvim_win_is_valid(s2.term_win) then
          vim.api.nvim_set_current_win(s2.term_win)
        end
      end)
    end,
  })
end

function M.setup()
  local group = vim.api.nvim_create_augroup("StackReaderAutoPreview", { clear = true })

  vim.api.nvim_create_autocmd("BufReadPost", {
    group = group,
    pattern = { "*.md", "*.mdx" },
    callback = function(ev)
      local filepath = vim.api.nvim_buf_get_name(ev.buf)
      if filepath == "" or not is_markdown(filepath) then return end
      if vim.wo.diff then return end

      local binary = require("stackreader").resolve_binary()
      if not binary then return end

      local win = vim.api.nvim_get_current_win()
      local term_buf = vim.api.nvim_create_buf(false, true)
      vim.bo[term_buf].bufhidden = "wipe"
      vim.api.nvim_win_set_buf(win, term_buf)

      vim.fn.termopen({ binary, "--watch", filepath }, {
        on_exit = function()
          state[term_buf] = nil
        end,
      })

      state[term_buf] = { filepath = filepath, term_win = win }

      -- 'i' in normal mode opens the file in a vertical split for editing.
      -- 'a', '<Insert>', '<CR>' etc. still enter terminal mode for StackReader interaction.
      vim.keymap.set("n", "i", function()
        open_edit(term_buf)
      end, { buffer = term_buf, desc = "StackReader: edit file" })
    end,
  })
end

return M
