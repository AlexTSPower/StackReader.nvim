local M = {}

M.config = {
  keymaps = {
    preview    = "<leader>sp",
    sidebyside = "<leader>ss",
    browser    = "<leader>sb",
  },
  autopreview = true,
}

-- Returns path to the stackreader binary, or nil if not found.
function M.resolve_binary()
  local installed = vim.fn.expand("~/.local/share/nvim/stackreader/bin/stackreader")
  if vim.fn.executable(installed) == 1 then
    return installed
  end
  local system_path = vim.fn.exepath("stackreader")
  if system_path ~= "" then
    return system_path
  end
  return nil
end

function M.setup(opts)
  opts = opts or {}
  if opts.keymaps then
    for k, v in pairs(opts.keymaps) do
      M.config.keymaps[k] = v
    end
  end
  if opts.autopreview ~= nil then
    M.config.autopreview = opts.autopreview
  end

  local km = M.config.keymaps

  if km.preview ~= false then
    vim.keymap.set("n", km.preview, function()
      require("stackreader.preview").toggle()
    end, { desc = "StackReader: toggle preview" })
  end

  if km.sidebyside ~= false then
    vim.keymap.set("n", km.sidebyside, function()
      require("stackreader.sidebyside").toggle()
    end, { desc = "StackReader: side-by-side" })
  end

  if km.browser ~= false then
    vim.keymap.set("n", km.browser, function()
      require("stackreader.browser").toggle()
    end, { desc = "StackReader: browser" })
  end

  if M.config.autopreview then
    require("stackreader.autopreview").setup()
  end
end

return M
