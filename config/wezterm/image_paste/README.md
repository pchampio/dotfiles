# Clipboard images

**Ctrl+Shift+V** with an image in the Wayland clipboard saves it with a random
name such as `/tmp/wezterm-image-4K8nE6zG3qWP.png`, then replaces the clipboard
with that path and inserts it into the focused pane immediately, without Enter.
For SSH, insertion happens only after the remote upload succeeds. Ordinary text still pastes
directly into the focused pane.

If the clipboard contains a local image path created by this plugin and you
paste it into an SSH pane, the plugin uploads that image, updates the clipboard,
and pastes its remote path. This supports saving locally and then switching to
SSH without copying the original image again. Paths that exist only remotely
continue to paste as ordinary text.

The plugin is entirely Lua. It supports PNG, JPEG, WebP, GIF, BMP, and TIFF without
conversion. Clipboard bytes are redirected into a private temporary file and
transferred through SSH when required; image bytes do not pass through Lua or
the terminal input stream. Failed transfers leave the clipboard unchanged.

Destination detection:

- Local foreground shell/application: local `/tmp`.
- Foreground `ssh` or `tssh`: `/tmp` on that SSH destination.
- Local tmux: follows the attached client's active pane, including nested local
  tmux sessions, then checks that pane for SSH. Other clients/background SSH jobs
  do not determine the destination.
- Native WezTerm SSH domain: uses its configured remote address and username.

SSH aliases, ports, identities, and jump hosts are retained. A separate SSH
connection writes the file; it never types shell commands into the target app.
The receiving host only needs `sh`, `mktemp`, and `cat`, with writable `/tmp`.
No remote plugin installation or root access is needed.

The destination is the first SSH host reached from the local pane. A further
SSH connection launched *inside* that remote session cannot be inferred from
local process information. Mosh and an unresolved interactive tssh host picker
are not supported. Those cases require an explicit destination integration.

Missing local prerequisites produce a WezTerm notification listing the missing
tools when you press Ctrl+Shift+V. Successful checks are cached until config reload;
missing tools are checked again on the next attempt. Ordinary text paste only
requires `wl-paste`. There is no separate installer/check command. The module is loaded
directly from `~/dotfiles/config/wezterm/image_paste/init.lua` by `wezterm.lua`.
Run Lua routing/clipboard tests with:

```sh
lua config/wezterm/image_paste/test.lua
python3 config/wezterm/image_paste/test_copy.py
```

On failure a toast and the WezTerm log show the error; the plugin does not silently
save locally when it cannot identify an SSH or tmux destination.

Clipboard path copying detaches the background clipboard owner's output pipes
so insertion does not wait for another screenshot or clipboard change. Startup
has a five-second timeout; failures retain the saved image and report its path.
