local M = {}

-- [term_buf] = { filepath, file_buf, term_win }
local state = {}

local function is_markdown(filepath)
  local ext = vim.fn.fnamemodify(filepath, ":e"):lower()
  return ext == "md" or ext == "mdx"
end

local function enter_edit(term_buf)
  local s = state[term_buf]
  if not s then return end

  local width  = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines   * 0.85)
  local row    = math.floor((vim.o.lines   - height) / 2)
  local col    = math.floor((vim.o.columns - width)  / 2)

  local float_win = vim.api.nvim_open_win(s.file_buf, true, {
    relative = "editor",
    width = width, height = height, row = row, col = col,
    style = "minimal", border = "rounded",
  })
  vim.cmd("startinsert")

  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(float_win),
    once = true,
    callback = function()
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(s.term_win) then
          vim.api.nvim_set_current_win(s.term_win)
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

      local file_buf = ev.buf
      vim.bo[file_buf].buflisted = false

      local win = vim.api.nvim_get_current_win()
      local term_buf = vim.api.nvim_create_buf(false, true)
      vim.bo[term_buf].bufhidden = "hide"
      vim.api.nvim_win_set_buf(win, term_buf)

      vim.fn.termopen({ binary, "--watch", filepath }, {
        on_exit = function()
          vim.schedule(function()
            local s = state[term_buf]
            if not s then return end
            vim.bo[s.file_buf].buflisted = true
            if vim.api.nvim_win_is_valid(s.term_win) then
              vim.api.nvim_win_set_buf(s.term_win, s.file_buf)
            end
            state[term_buf] = nil
          end)
        end,
      })

      state[term_buf] = { filepath = filepath, file_buf = file_buf, term_win = win }

      -- 'i' in normal mode opens the file in a floating editor.
      -- 'a', '<Insert>', '<CR>' etc. still enter terminal mode for StackReader interaction.
      vim.keymap.set("n", "i", function()
        enter_edit(term_buf)
      end, { buffer = term_buf, desc = "StackReader: edit file" })
    end,
  })
end

return M
