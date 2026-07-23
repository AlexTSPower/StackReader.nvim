local M = {}

local BLOCK_QUERY = [[
  (atx_heading) @heading
  (fenced_code_block) @code
  (list_item) @bullet
  (block_quote) @quote
  (thematic_break) @dash
]]

local INLINE_QUERY = [[
  (code_span) @code_inline
]]

local _block_query
local _inline_query

local function block_query()
  if not _block_query then
    _block_query = vim.treesitter.query.parse('markdown', BLOCK_QUERY)
  end
  return _block_query
end

local function inline_query()
  if not _inline_query then
    _inline_query = vim.treesitter.query.parse('markdown_inline', INLINE_QUERY)
  end
  return _inline_query
end

local function make_item(capture_name, node)
  local sr, sc, er, ec = node:range()
  return { type = capture_name, node = node, start_row = sr, start_col = sc, end_row = er, end_col = ec }
end

-- Returns block-level captures in [start_row, end_row).
function M.query_block(buf, start_row, end_row)
  local ok, parser = pcall(vim.treesitter.get_parser, buf, 'markdown')
  if not ok or not parser then return {} end

  local trees = parser:parse()
  if not trees or not trees[1] then return {} end

  local q = block_query()
  local results = {}
  for id, node in q:iter_captures(trees[1]:root(), buf, start_row, end_row) do
    table.insert(results, make_item(q.captures[id], node))
  end
  return results
end

-- Returns inline captures (code_span) in [start_row, end_row).
function M.query_inline(buf, start_row, end_row)
  local ok, parser = pcall(vim.treesitter.get_parser, buf, 'markdown')
  if not ok or not parser then return {} end

  -- Ensure injection parsing has run
  parser:parse()

  local inline_parser = parser:children()['markdown_inline']
  if not inline_parser then return {} end

  local ok2, q = pcall(inline_query)
  if not ok2 then return {} end

  local inline_trees = inline_parser:parse()
  if not inline_trees then return {} end

  local results = {}
  for _, tree in ipairs(inline_trees) do
    local root = tree:root()
    local root_sr, _, root_er, _ = root:range()
    if root_sr <= end_row and root_er >= start_row then
      for id, node in q:iter_captures(root, buf, start_row, end_row) do
        table.insert(results, make_item(q.captures[id], node))
      end
    end
  end
  return results
end

return M
