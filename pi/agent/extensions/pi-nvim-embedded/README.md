# pi-nvim-embedded

<p align="center">
  <img src="https://github.com/user-attachments/assets/2e6541ae-974a-4465-ab62-e47595849136" width="80%"/>

</p>

<details>
  <summary>👾 Click to see more GIFs</summary>
  
![2026-04-10 11-20-43](https://github.com/user-attachments/assets/14d7e323-78fa-480b-8d2c-5ca4e210128a)


</details>


Embedded neovim editor extension for [pi](https://github.com/badlogic/pi-mono) -- full vim keybindings in the pi coding agent prompt.

Spawns `nvim --embed` as a subprocess, forwards all keystrokes via msgpack-RPC, and syncs neovim's buffer/cursor/mode state back to pi's editor for rendering.

## Features

- Full neovim keybindings (motions, operators, text objects, undo/redo, registers, macros)
- Mode indicator (`NORMAL` / `INSERT` / `VISUAL`) in the editor border
- Visual selection highlighting (charwise, linewise, blockwise)
- Message history navigation with `K`/`J` in normal mode
- Tmux pane navigation (`Ctrl+H/J/K/L`) and clipboard integration (`Ctrl+V` paste, `Y` yank)
- Cursor shape changes per mode (bar for insert, block for normal)
- `Enter` in normal mode submits the buffer; `Enter` on an empty last line in insert mode submits
- `Tab` in normal mode toggles plan mode
- Double-tap `ESC` cancels all running operations (agents, chains, pipelines, teams)
- Graceful fallback to the default editor if neovim is not available

## Prerequisites

- [neovim](https://neovim.io/) must be installed and available in `PATH` (or configure `nvimBinary`)
- [tmux](https://github.com/tmux/tmux) for clipboard/pane integration (optional -- disable via config)

## Installation

### Manual install via git clone

This is the recommended way to install the plugin,
as you will want to customize the internal of it (with your favorite
LLM of course).

Clone the repo into your pi agent directory and add it to `packages` in your `settings.json`:

```bash
cd ~/.pi/agent
git clone https://github.com/pchampio/pi-nvim-embedded extensions/pi-nvim-embedded
```

Then edit `~/.pi/agent/settings.json` (create it if it doesn't exist):

```json
{
  "packages": [
    "extensions/pi-nvim-embedded"
  ]
}
```

Restart pi — the extension will be loaded from the local clone.


### From GitHub

```
pi install git:github.com/pchampio/pi-nvim-embedded
```

### Test without installing

```
pi -e git:github.com/pchampio/pi-nvim-embedded
```

## Configuration

All settings are optional. The extension works out of the box with sensible defaults.

To customize, copy `config.example.json` to `config.json` in the extension directory and edit:

```
cp config.example.json config.json
```

### Config options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `nvimBinary` | `string` | `"nvim"` | Path to the neovim binary |
| `nvimExtraArgs` | `string[]` | `[]` | Extra arguments passed to `nvim --embed` |
| `timeoutlen` | `number` | `5` | Neovim `timeoutlen` in ms (how long nvim waits for multi-key sequences) |
| `doubleTapEscTimeout` | `number` | `400` | Double-tap ESC window in ms to cancel running operations |
| `disabledKeys` | `string[]` | `[":", "/", "?", ...]` | Keys disabled inside neovim (mapped to `<Nop>`). Set to `[]` to allow all |
| `enterOnEmptyLineSubmits` | `boolean` | `true` | Whether Enter on an empty last line submits the prompt in insert mode |
| `enterInNormalSubmits` | `boolean` | `true` | Whether Enter in normal mode submits the buffer |
| `historyNavigation` | `boolean` | `true` | Whether `K`/`J` navigate message history in normal mode |
| `tabTogglesPlanMode` | `boolean` | `true` | Whether `Tab` toggles plan mode in normal mode |
| `tmux.clipboard` | `boolean` | `true` | Enable tmux clipboard integration (`Ctrl+V` paste, `Y` yank) |
| `tmux.binary` | `string` | `"tmux"` | Path to the tmux binary |
| `tmux.paneKeys` | `Record<string, string[]>` | `{"ctrl+h": [...], ...}` | Tmux pane navigation keybindings. Set to `{}` to disable |
| `cursor.insert` | `string` | `"\x1b[6 q"` | Insert mode cursor shape escape sequence (bar) |
| `cursor.normal` | `string` | `"\x1b[2 q"` | Normal mode cursor shape escape sequence (block) |
| `nvimInitLua` | `string[]` | `[]` | Extra Lua commands run after neovim boot (executed via `nvim_exec_lua`) |
| `piKeys` | `string[]` | `["ctrl+d", "ctrl+o", "alt+up", "alt+return", "ctrl+t", "ctrl+\\"]` | Keys that bypass neovim and are forwarded directly to pi |
| `maxCompletionItems` | `number` | `5` | Maximum number of items visible in the completion popup menu |
| `borderChar` | `string` | `"-"` | Character used to replace `─` on editor border lines. Set to `""` to keep the original `─` character |

### Example: disable tmux integration

```json
{
  "tmux": {
    "clipboard": false,
    "paneKeys": {},
  }
}
```

### Example: add custom neovim init

```json
{
  "nvimInitLua": [
    "vim.opt.scrolloff = 5",
    "vim.keymap.set('n', 'U', '<C-r>', { noremap = true })"
  ]
}
```

### Example: re-enable command-line mode

```json
{
  "disabledKeys": []
}
```

## Key Bindings

### Normal mode

| Key | Action |
|-----|--------|
| `Enter` | Submit the buffer |
| `ESC` | Pass through to pi (abort agent) |
| `ESC ESC` | Cancel all running operations |
| `K` / `J` | Navigate message history (older / newer) |
| `Tab` | Toggle plan mode |
| `Shift+Tab` | Toggle thinking level |
| `Y` | Yank line to tmux clipboard |
| `Ctrl+H/J/K/L` | Navigate tmux panes |
| `Ctrl+V` | Paste from tmux buffer |
| `Ctrl+D` | Pass through to pi (exit) |

### Insert mode

| Key | Action |
|-----|--------|
| `Enter` (empty last line) | Submit the buffer |
| `Tab` / `Shift+Tab` | Cycle completion (neovim `<C-n>` / `<C-p>`) |
| `Ctrl+V` | Paste from tmux buffer |

### Visual mode

| Key | Action |
|-----|--------|
| `Y` | Yank selection to tmux clipboard |

## Architecture

```
pi terminal input
  -> NvimEditor.handleInput()
    -> queue -> pump() (serial processing)
      -> nvim_input() via msgpack-RPC
      -> waitForFlush() (redraw batch complete)
      -> sync() (read buffer/cursor/mode from nvim)
      -> pushToEditor() (update pi's Editor internals)
        -> render() (pi re-renders with mode label + visual highlights)
```

The extension communicates with neovim entirely over stdio using the msgpack-RPC protocol. It maintains a shadow copy of neovim's state (buffer lines, cursor position, mode) and pushes updates to pi's editor after every keystroke.

## License

MIT
