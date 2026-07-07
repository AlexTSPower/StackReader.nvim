# StackReader.nvim

A Neovim plugin for [StackReader](https://github.com/AlexTSPower/StackReader) — a terminal markdown viewer with GitHub-style rendering.

## Requirements

- Neovim 0.10+
- `curl` and `tar` (used by the auto-installer)

## Installation

### lazy.nvim

```lua
{
  "AlexTSPower/StackReader.nvim",
  build = ":StackReaderInstall",
  config = function()
    require("stackreader").setup({
      keymaps = {
        preview    = "<leader>sp",
        sidebyside = "<leader>ss",
        browser    = "<leader>sb",
      },
    })
  end,
}
```

Run `:checkhealth stackreader` after install to confirm the binary is ready.

## Usage

| Keymap | Command | Description |
|--------|---------|-------------|
| `<leader>sp` | `:StackReaderPreview` | Toggle rendered preview alongside current buffer |
| `<leader>ss` | `:StackReaderSideBySide` | Side-by-side: edit on left, live preview on right |
| `<leader>sb` | `:StackReaderBrowser` | Open markdown browser for current directory |

Set any keymap to `false` to disable it:

```lua
require("stackreader").setup({
  keymaps = { browser = false }
})
```

## Manual Binary Install

If `:StackReaderInstall` fails:

```sh
brew install AlexTSPower/tap/stackreader
```

Or download from [GitHub Releases](https://github.com/AlexTSPower/StackReader/releases) and place the `stackreader` binary anywhere on your `$PATH`.

## How it works

StackReader.nvim opens the [`stackreader`](https://github.com/AlexTSPower/StackReader) binary inside Neovim terminal buffers. In preview and side-by-side modes, `--watch` is passed so the binary uses `fsnotify` to detect file saves and re-render automatically — no polling, no BufWritePost hooks needed.

## License

MIT
