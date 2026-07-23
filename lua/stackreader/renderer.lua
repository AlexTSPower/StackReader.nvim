local M = {}
local parser = require('stackreader.parser')

local ns = vim.api.nvim_create_namespace('stackreader')
M.ns = ns

local Updater = {}
Updater.__index = Updater

-- node:range() end position is exclusive; if end_col==0, last content is on end_row-1
local function last_row(item)
  if item.end_col == 0 and item.end_row > item.start_row then
    return item.end_row - 1
  end
  return item.end_row
end

function Updater:new(buf, win, config)
  return setmetatable({
    buf = buf,
    win = win,
    config = config,
    timer = nil,
    original_conceallevel = vim.wo[win].conceallevel,
    mark_ids = {},
  }, Updater)
end

function Updater:schedule()
  if self.timer then
    self.timer:stop()
    self.timer:close()
  end
  self.timer = vim.uv.new_timer()
  self.timer:start(100, 0, vim.schedule_wrap(function()
    self:run()
  end))
end

function Updater:run()
  if not vim.api.nvim_buf_is_valid(self.buf) then return end
  if not vim.api.nvim_win_is_valid(self.win) then return end

  local mode = vim.api.nvim_get_mode().mode
  local should_render = self.config.enabled
  if should_render then
    should_render = false
    for _, m in ipairs(self.config.render_modes) do
      if mode:sub(1, #m) == m then
        should_render = true
        break
      end
    end
  end

  if should_render then
    self:render()
  else
    self:clear()
  end
end

function Updater:clear()
  vim.api.nvim_buf_clear_namespace(self.buf, ns, 0, -1)
  self.mark_ids = {}
  if vim.api.nvim_win_is_valid(self.win) then
    vim.wo[self.win].conceallevel = self.original_conceallevel
  end
end

function Updater:set_mark(row, col, opts)
  opts.strict = false
  local ok, id = pcall(vim.api.nvim_buf_set_extmark, self.buf, ns, row, col, opts)
  if ok and id then
    table.insert(self.mark_ids, { id = id, row = row })
    return id
  end
end

function Updater:render()
  if not vim.api.nvim_buf_is_valid(self.buf) then return end
  if not vim.api.nvim_win_is_valid(self.win) then return end

  local topline = vim.fn.line('w0', self.win) - 1
  local botline = vim.fn.line('w$', self.win) + 10
  botline = math.min(botline, vim.api.nvim_buf_line_count(self.buf))

  vim.api.nvim_buf_clear_namespace(self.buf, ns, 0, -1)
  self.mark_ids = {}

  local win_width = vim.api.nvim_win_get_width(self.win)

  for _, item in ipairs(parser.query_block(self.buf, topline, botline)) do
    if item.type == 'heading' then
      self:render_heading(item)
    elseif item.type == 'code' then
      self:render_code_block(item, win_width)
    elseif item.type == 'bullet' then
      self:render_bullet(item)
    elseif item.type == 'quote' then
      self:render_quote(item)
    elseif item.type == 'dash' then
      self:render_dash(item, win_width)
    end
  end

  for _, item in ipairs(parser.query_inline(self.buf, topline, botline)) do
    if item.type == 'code_inline' then
      self:render_inline_code(item)
    end
  end

  self:apply_anti_conceal()

  vim.wo[self.win].conceallevel = 3
end

function Updater:render_heading(item)
  local row = item.start_row
  local line = vim.api.nvim_buf_get_lines(self.buf, row, row + 1, false)[1] or ''

  local hashes = line:match('^(#+%s*)')
  if not hashes then return end

  -- Level from number of leading # chars
  local level = math.min(6, #(hashes:match('^#+') or ''))
  if level < 1 then return end

  local hl = 'StackReaderH' .. level
  local icons = self.config.heading.icons
  local icon = icons[level] or ('H' .. level .. ' ')

  -- Conceal the `#+ ` prefix
  self:set_mark(row, 0, {
    end_row = row,
    end_col = #hashes,
    conceal = '',
  })

  -- Icon + line background
  self:set_mark(row, 0, {
    virt_text = { { icon, hl } },
    virt_text_pos = 'overlay',
    hl_group = hl,
    hl_eol = true,
  })
end

function Updater:render_code_block(item, win_width)
  local cfg = self.config.code
  if cfg.style == 'none' then return end

  local sr = item.start_row
  local er = last_row(item)

  local first_line = vim.api.nvim_buf_get_lines(self.buf, sr, sr + 1, false)[1] or ''
  local fence_open = first_line:match('^(`+)')
  if not fence_open then return end

  local lang = vim.trim(first_line:sub(#fence_open + 1))

  -- Conceal opening fence
  self:set_mark(sr, 0, {
    end_row = sr,
    end_col = #fence_open,
    conceal = '',
  })

  if lang ~= '' and (cfg.style == 'full' or cfg.style == 'language') then
    self:set_mark(sr, 0, {
      virt_text = { { ' ' .. lang .. ' ', 'StackReaderCodeLang' } },
      virt_text_pos = 'eol',
    })
  end

  -- Top border
  if cfg.border ~= 'none' then
    local ch = cfg.border == 'thick' and '━' or '─'
    self:set_mark(sr, 0, {
      virt_lines = { { { string.rep(ch, win_width - 2), 'StackReaderCodeBorder' } } },
      virt_lines_above = true,
    })
  end

  -- Conceal closing fence
  if er > sr then
    local last_line = vim.api.nvim_buf_get_lines(self.buf, er, er + 1, false)[1] or ''
    local fence_close = last_line:match('^(`+)')
    if fence_close then
      self:set_mark(er, 0, {
        end_row = er,
        end_col = #fence_close,
        conceal = '',
      })
      if cfg.border ~= 'none' then
        local ch = cfg.border == 'thick' and '━' or '─'
        self:set_mark(er, 0, {
          virt_lines = { { { string.rep(ch, win_width - 2), 'StackReaderCodeBorder' } } },
        })
      end
    end
  end

  -- Background on interior lines
  if cfg.style == 'full' then
    local buf_lines = vim.api.nvim_buf_line_count(self.buf)
    for row = sr + 1, er - 1 do
      if row >= 0 and row < buf_lines then
        self:set_mark(row, 0, {
          end_row = row,
          end_col = 0,
          hl_group = 'StackReaderCodeBg',
          hl_eol = true,
        })
      end
    end
  end
end

function Updater:render_bullet(item)
  local node = item.node
  local row = item.start_row

  local marker_node
  for child in node:iter_children() do
    local t = child:type()
    if t == 'list_marker_minus' or t == 'list_marker_star' or t == 'list_marker_plus' then
      marker_node = child
      break
    end
  end
  if not marker_node then return end

  local msr, msc, _, mec = marker_node:range()
  local line = vim.api.nvim_buf_get_lines(self.buf, msr, msr + 1, false)[1] or ''

  -- Detect checkbox pattern after the marker
  local after = line:sub(mec + 1)
  local checkbox = after:match('^%s*%[(.-)%]')

  if checkbox then
    local icon, hl
    local c = checkbox:lower()
    if c == 'x' then
      icon, hl = '󰱒 ', 'StackReaderCheckboxChecked'
    elseif c == '-' then
      icon, hl = '󰡖 ', 'StackReaderCheckboxPending'
    else
      icon, hl = '󰄱 ', 'StackReaderCheckboxUnchecked'
    end

    -- Conceal the `- ` marker
    self:set_mark(msr, msc, {
      end_row = msr,
      end_col = mec,
      conceal = '',
    })

    -- Find `[x]` span in the line and overlay icon
    local cb_s = line:find('%[', mec + 1)
    local cb_e = line:find('%]', mec + 1)
    if cb_s and cb_e then
      self:set_mark(msr, cb_s - 1, {
        end_row = msr,
        end_col = cb_e,
        virt_text = { { icon, hl } },
        virt_text_pos = 'overlay',
        conceal = '',
      })
    end
  else
    -- Regular bullet — replace marker with icon
    local depth = math.floor(msc / 2)
    local icons = self.config.bullet.icons
    local icon = icons[(depth % #icons) + 1] or '●'

    self:set_mark(msr, msc, {
      end_row = msr,
      end_col = mec,
      virt_text = { { icon, 'StackReaderBullet' } },
      virt_text_pos = 'overlay',
      conceal = '',
    })
  end
end

function Updater:render_quote(item)
  local sr = item.start_row
  local er = last_row(item)

  for row = sr, er do
    local line = vim.api.nvim_buf_get_lines(self.buf, row, row + 1, false)[1] or ''
    local ms, me = line:find('^%s*>')
    if ms then
      self:set_mark(row, ms - 1, {
        end_row = row,
        end_col = me,
        virt_text = { { '▋', 'StackReaderQuote' } },
        virt_text_pos = 'overlay',
        conceal = '',
      })
    end
  end
end

function Updater:render_dash(item, win_width)
  local row = item.start_row
  local line = vim.api.nvim_buf_get_lines(self.buf, row, row + 1, false)[1] or ''
  self:set_mark(row, 0, {
    end_row = row,
    end_col = #line,
    virt_text = { { string.rep('─', win_width - 2), 'StackReaderDash' } },
    virt_text_pos = 'overlay',
    conceal = '',
  })
end

function Updater:render_inline_code(item)
  local sr, sc, er, ec = item.start_row, item.start_col, item.end_row, item.end_col
  local line = vim.api.nvim_buf_get_lines(self.buf, sr, sr + 1, false)[1] or ''

  -- Conceal opening backtick(s)
  local open_ticks = line:sub(sc + 1):match('^(`+)')
  if open_ticks then
    self:set_mark(sr, sc, {
      end_row = sr,
      end_col = sc + #open_ticks,
      conceal = '',
    })
  end

  -- Conceal closing backtick(s) on same row only
  if er == sr and ec > sc then
    local close_ticks = line:sub(ec - #(open_ticks or '`') + 1, ec):match('(`+)$')
    if close_ticks then
      self:set_mark(er, ec - #close_ticks, {
        end_row = er,
        end_col = ec,
        conceal = '',
      })
    end
  end

  -- Background highlight on the span
  self:set_mark(sr, sc, {
    end_row = er,
    end_col = ec,
    hl_group = 'StackReaderCodeInline',
  })
end

function Updater:apply_anti_conceal()
  if not vim.api.nvim_win_is_valid(self.win) then return end
  local cursor = vim.api.nvim_win_get_cursor(self.win)
  local cursor_row = cursor[1] - 1
  local above = self.config.anti_conceal.above
  local below = self.config.anti_conceal.below

  local marks = vim.api.nvim_buf_get_extmarks(
    self.buf, ns,
    { math.max(0, cursor_row - above), 0 },
    { cursor_row + below, -1 },
    {}
  )
  for _, mark in ipairs(marks) do
    pcall(vim.api.nvim_buf_del_extmark, self.buf, ns, mark[1])
  end
end

M.Updater = Updater
return M
