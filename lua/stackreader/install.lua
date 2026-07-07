local M = {}

function M.install()
  -- Find install.sh relative to this file's location in the plugin.
  local sources = vim.api.nvim_get_runtime_file("lua/stackreader/install.lua", false)
  if #sources == 0 then
    vim.notify("StackReader: cannot locate plugin directory", vim.log.levels.ERROR)
    return
  end
  -- sources[1] is .../StackReader.nvim/lua/stackreader/install.lua
  -- go up 3 dirs: stackreader/ -> lua/ -> StackReader.nvim/
  local plugin_dir = vim.fn.fnamemodify(sources[1], ":h:h:h")
  local script = plugin_dir .. "/scripts/install.sh"

  if vim.fn.filereadable(script) == 0 then
    vim.notify("StackReader: install.sh not found at " .. script, vim.log.levels.ERROR)
    return
  end

  vim.notify("StackReader: installing binary...", vim.log.levels.INFO)

  vim.fn.jobstart({ "bash", script }, {
    on_stdout = function(_, data)
      for _, line in ipairs(data) do
        if line ~= "" then
          vim.notify(line, vim.log.levels.INFO)
        end
      end
    end,
    on_stderr = function(_, data)
      for _, line in ipairs(data) do
        if line ~= "" then
          vim.notify(line, vim.log.levels.WARN)
        end
      end
    end,
    on_exit = function(_, code)
      if code ~= 0 then
        vim.notify(
          "StackReader: install failed (exit " .. code .. ")",
          vim.log.levels.ERROR
        )
      end
    end,
  })
end

return M
