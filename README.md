# StackReader.nvim

GitHub-style markdown rendering inside Neovim — pure Lua, no external
binaries. Headings, code blocks, lists, block quotes, and inline code
render in normal mode; entering insert mode reveals raw markdown for
editing.

Powered by Treesitter and Neovim's extmark API, the same technique used
by [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim).

## Requirements

- Neovim 0.10+
- Treesitter parsers: `markdown` and `markdown_inline`

## Installation

### lazy.nvim

```lua
{
  "AlexTSPower/StackReader.nvim",
  ft = { "markdown", "mdx" },
  config = function()
    require("stackreader").setup()
  end,
}
```

Install the required Treesitter parsers:

```vim
:TSInstall markdown markdown_inline
```

Run `:checkhealth stackreader` to confirm everything is ready.

## Usage

Rendering activates automatically when you open a markdown file. The
display switches between rendered and raw based on your mode:

| Mode             | Display                                  |
| ---------------- | ---------------------------------------- |
| Normal / Command | Rendered (headings, code blocks, lists…) |
| Insert           | Raw markdown for editing                 |

| Keymap        | Command             | Description                              |
| ------------- | ------------------- | ---------------------------------------- |
| `<leader>sp`  | `:StackReaderToggle` | Toggle rendering on/off for current buffer |

## Configuration

```lua
require("stackreader").setup({
  enabled = true,
  render_modes = { "n", "c" },
  anti_conceal = { above = 0, below = 0 },
  file_types = { "markdown", "mdx" },
  keymaps = {
    toggle = "<leader>sp", -- false to disable
  },
  heading = {
    icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
    width = "full", -- "full" | "block"
  },
  code = {
    style = "full",   -- "full" | "language" | "none"
    border = "thin",  -- "thin" | "thick" | "none"
  },
  bullet = {
    icons = { "●", "○", "◆", "◇" },
  },
})
```

## What gets rendered

| Element                    | Appearance                                |
| -------------------------- | ----------------------------------------- |
| ATX headings h1–h6         | Nerd Font icon + coloured line background |
| Fenced code blocks         | Language label, border lines, background  |
| Bullet lists               | `●` / `○` / `◆` / `◇` icons by depth     |
| Checkboxes `[ ]` `[x]` `[-]` | Nerd Font tick icons                    |
| Block quotes               | `▋` border                                |
| Thematic breaks `---`      | Full-width `─` line                       |
| Inline code `` `…` ``      | Background highlight, backticks concealed |

## License

MIT
