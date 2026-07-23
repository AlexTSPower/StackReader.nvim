local M = {}

function M.check()
  vim.health.start('StackReader')

  -- Treesitter markdown parser
  local md_ok = pcall(vim.treesitter.query.parse, 'markdown', '(atx_heading) @h')
  if md_ok then
    vim.health.ok('Treesitter markdown parser is installed')
  else
    vim.health.error(
      'Treesitter markdown parser not found',
      { 'Run: :TSInstall markdown', 'Or add "markdown" to treesitter ensure_installed' }
    )
  end

  -- Treesitter markdown_inline parser (for inline code)
  local inline_ok = pcall(vim.treesitter.query.parse, 'markdown_inline', '(code_span) @c')
  if inline_ok then
    vim.health.ok('Treesitter markdown_inline parser is installed')
  else
    vim.health.warn(
      'Treesitter markdown_inline parser not found — inline code rendering disabled',
      { 'Run: :TSInstall markdown_inline' }
    )
  end
end

return M
