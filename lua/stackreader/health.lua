local M = {}

function M.check()
  vim.health.start("StackReader")

  local binary = require("stackreader").resolve_binary()

  if not binary then
    vim.health.error(
      "stackreader binary not found",
      {
        "Run :StackReaderInstall to download the binary automatically",
        "Or install manually: brew install AlexTSPower/tap/stackreader",
      }
    )
    return
  end

  vim.health.ok("binary found: " .. binary)

  local result = vim.system({ binary, "--version" }, { text = true }):wait()
  if result.code == 0 then
    vim.health.ok("version: " .. vim.trim(result.stdout))
  else
    vim.health.warn(
      "could not determine version",
      result.stderr ~= "" and result.stderr or "unknown error"
    )
  end
end

return M
