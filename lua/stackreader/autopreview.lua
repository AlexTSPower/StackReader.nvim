local M = {}

-- [file_buf] = { filepath, job_id, term_buf, float_win, main_win }
local state = {}

local function is_markdown(filepath)
  local ext = vim.fn.fnamemodify(filepath, ":e"):lower()
  return ext == "md" or ext == "mdx"
end

local function create_float(file_buf)
  local s = state[file_buf]
  if not s then return end
  if not vim.api.nvim_win_is_valid(s.main_win) then return end

  -- Close any existing float first.
  if s.float_win and vim.api.nvim_win_is_valid(s.float_win) then
    vim.api.nvim_win_close(s.float_win, true)
  end

  local width  = vim.api.nvim_win_get_width(s.main_win)
  local height = vim.api.nvim_win_get_height(s.main_win)
  s.float_win = vim.api.nvim_open_win(s.term_buf, false, {
    relative  = "win",
    win       = s.main_win,
    row       = 0, col   = 0,
    width     = width, height = height,
    style     = "minimal",
    focusable = false,
    zindex    = 1,
  })
end

local function enter_edit(file_buf)
  local s = state[file_buf]
  if not s then return end

  if s.float_win and vim.api.nvim_win_is_valid(s.float_win) then
    vim.api.nvim_win_close(s.float_win, true)
    s.float_win = nil
  end

  vim.api.nvim_set_current_win(s.main_win)
  vim.cmd("startinsert")

  vim.keymap.set("i", "<Esc>", function()
    vim.cmd("stopinsert")
    vim.cmd("silent! w")
    create_float(file_buf)
  end, { buffer = file_buf, desc = "StackReader: save and return to preview" })

  vim.keymap.set("n", "ZZ", function()
    vim.cmd("silent! w")
    create_float(file_buf)
  end, { buffer = file_buf, desc = "StackReader: save and return to preview" })

  vim.keymap.set("n", "ZQ", function()
    create_float(file_buf)
  end, { buffer = file_buf, desc = "StackReader: discard and return to preview" })
end

local function setup_keymaps(file_buf)
  local opts = { buffer = file_buf, silent = true }

  vim.keymap.set("n", "j", function()
    if not state[file_buf] then return end
    vim.fn.chansend(state[file_buf].job_id, "j")
  end, opts)

  vim.keymap.set("n", "k", function()
    if not state[file_buf] then return end
    vim.fn.chansend(state[file_buf].job_id, "k")
  end, opts)

  vim.keymap.set("n", "<C-d>", function()
    if not state[file_buf] then return end
    vim.fn.chansend(state[file_buf].job_id, "\x04")
  end, opts)

  vim.keymap.set("n", "<C-u>", function()
    if not state[file_buf] then return end
    vim.fn.chansend(state[file_buf].job_id, "\x15")
  end, opts)

  vim.keymap.set("n", "g", function()
    if not state[file_buf] then return end
    vim.fn.chansend(state[file_buf].job_id, "g")
  end, opts)

  vim.keymap.set("n", "G", function()
    if not state[file_buf] then return end
    vim.fn.chansend(state[file_buf].job_id, "G")
  end, opts)

  vim.keymap.set("n", "i", function()
    enter_edit(file_buf)
  end, vim.tbl_extend("force", opts, { desc = "StackReader: edit file" }))

  -- Suppress q so the user doesn't accidentally quit; :bd/:q work normally.
  vim.keymap.set("n", "q", "<Nop>", opts)
end

local function setup_autocmds(file_buf)
  local group = "StackReaderAutoPreview"

  vim.api.nvim_create_autocmd("BufLeave", {
    group = group, buffer = file_buf,
    callback = function()
      local s = state[file_buf]
      if not s then return end
      if s.float_win and vim.api.nvim_win_is_valid(s.float_win) then
        vim.api.nvim_win_close(s.float_win, true)
        s.float_win = nil
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufEnter", {
    group = group, buffer = file_buf,
    callback = function()
      local s = state[file_buf]
      if not s then return end
      if vim.api.nvim_get_current_win() == s.main_win then
        create_float(file_buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
    group = group,
    callback = function()
      local s = state[file_buf]
      if not s then return end
      if not s.float_win then return end
      if not vim.api.nvim_win_is_valid(s.float_win) then return end
      if not vim.api.nvim_win_is_valid(s.main_win) then return end
      vim.api.nvim_win_set_config(s.float_win, {
        width  = vim.api.nvim_win_get_width(s.main_win),
        height = vim.api.nvim_win_get_height(s.main_win),
      })
    end,
  })

  vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
    group = group, buffer = file_buf,
    callback = function()
      local s = state[file_buf]
      if not s then return end
      vim.fn.jobstop(s.job_id)
      if s.float_win and vim.api.nvim_win_is_valid(s.float_win) then
        vim.api.nvim_win_close(s.float_win, true)
      end
      state[file_buf] = nil
    end,
  })
end

function M.setup()
  vim.api.nvim_create_augroup("StackReaderAutoPreview", { clear = true })

  vim.api.nvim_create_autocmd("BufReadPost", {
    group = "StackReaderAutoPreview",
    pattern = { "*.md", "*.mdx" },
    callback = function(ev)
      local filepath = vim.api.nvim_buf_get_name(ev.buf)
      if filepath == "" or not is_markdown(filepath) then return end
      if vim.wo.diff then return end

      local binary = require("stackreader").resolve_binary()
      if not binary then return end

      -- Guard against duplicate setup when BufReadPost fires more than once.
      if state[ev.buf] then return end

      local file_buf = ev.buf
      local main_win = vim.api.nvim_get_current_win()

      local term_buf = vim.api.nvim_create_buf(false, true)
      vim.bo[term_buf].bufhidden = "hide"

      -- termopen() acts on the current buffer, so we must call it from within
      -- term_buf's context, not from file_buf's context.
      local job_id
      vim.api.nvim_buf_call(term_buf, function()
        job_id = vim.fn.termopen(
          { binary, "--no-chrome", "--watch", filepath },
          {
            on_exit = function()
              vim.schedule(function()
                local s = state[file_buf]
                if not s then return end
                if s.float_win and vim.api.nvim_win_is_valid(s.float_win) then
                  vim.api.nvim_win_close(s.float_win, true)
                end
                state[file_buf] = nil
              end)
            end,
          }
        )
      end)

      state[file_buf] = {
        filepath  = filepath,
        job_id    = job_id,
        term_buf  = term_buf,
        float_win = nil,
        main_win  = main_win,
      }

      create_float(file_buf)
      setup_keymaps(file_buf)
      setup_autocmds(file_buf)
    end,
  })
end

return M
