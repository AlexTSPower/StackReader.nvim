local M = {}

function M.setup()
  -- Headings — bold, colorscheme-linked foreground
  vim.api.nvim_set_hl(0, 'StackReaderH1', { link = 'markdownH1', default = true })
  vim.api.nvim_set_hl(0, 'StackReaderH2', { link = 'markdownH2', default = true })
  vim.api.nvim_set_hl(0, 'StackReaderH3', { link = 'markdownH3', default = true })
  vim.api.nvim_set_hl(0, 'StackReaderH4', { link = 'markdownH4', default = true })
  vim.api.nvim_set_hl(0, 'StackReaderH5', { link = 'markdownH5', default = true })
  vim.api.nvim_set_hl(0, 'StackReaderH6', { link = 'markdownH6', default = true })

  -- Fallbacks in case markdownH* groups aren't defined
  local fallback_fgs = { '#7aa2f7', '#9ece6a', '#e0af68', '#bb9af7', '#2ac3de', '#f7768e' }
  for i = 1, 6 do
    local group = 'StackReaderH' .. i
    local ok, existing = pcall(vim.api.nvim_get_hl, 0, { name = group, create = false })
    if not ok or vim.tbl_isempty(existing) or not existing.link then
      vim.api.nvim_set_hl(0, group, { fg = fallback_fgs[i], bold = true })
    end
  end

  -- Code blocks
  vim.api.nvim_set_hl(0, 'StackReaderCodeBg', { link = 'ColorColumn', default = true })
  vim.api.nvim_set_hl(0, 'StackReaderCodeBorder', { link = 'NonText', default = true })
  vim.api.nvim_set_hl(0, 'StackReaderCodeLang', { link = 'Comment', default = true })

  -- Inline code
  vim.api.nvim_set_hl(0, 'StackReaderCodeInline', { link = 'String', default = true })

  -- Block quote
  vim.api.nvim_set_hl(0, 'StackReaderQuote', { link = 'Comment', default = true })

  -- Thematic break
  vim.api.nvim_set_hl(0, 'StackReaderDash', { link = 'NonText', default = true })

  -- Bullets
  vim.api.nvim_set_hl(0, 'StackReaderBullet', { link = 'Special', default = true })

  -- Checkboxes
  vim.api.nvim_set_hl(0, 'StackReaderCheckboxUnchecked', { link = 'Comment', default = true })
  vim.api.nvim_set_hl(0, 'StackReaderCheckboxChecked', { link = 'DiagnosticOk', default = true })
  vim.api.nvim_set_hl(0, 'StackReaderCheckboxPending', { link = 'DiagnosticWarn', default = true })
end

return M
