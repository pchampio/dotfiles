# WezTerm voice input

Press **Ctrl+Shift+B** in the destination pane. A two-row local pane at the bottom of the tab
records your default microphone, displays an ASCII level meter, and receives live
text from Ampere. Works with a local shell or an ordinary SSH session in that pane.
It uses `toggle_terminal.toggle_command`; press the shortcut again to hide/show
the same recording. Hiding does not pause recording. The regular Ctrl+; shell
toggle remains independent. Sending or cancelling closes the recording pane.

- **Space / Pause / Resume** toggles recording. Audio captured while paused is
  discarded locally, and recording resumes in the same transcript.
- **Enter / Send** works while recording or paused: finishes transcription and
  pastes the completed text into the original pane, without a terminal Enter.
- **Esc / Cancel** discards the recording and closes the window.
- Buttons are also clickable. Use Shift-selection to copy visible text if needed.

The target is a WezTerm pane: if you change the active tmux pane inside it during
recording, the paste goes to that newly active tmux pane.

## Install (no root)

From `~/dotfiles` on the desktop:

```sh
./install/parakeet --client
./install/parakeet --remote ampere
```

Or run `./install/parakeet --server` directly on the transcription host.
`PARAKEET_VOICE_INSTALL=server ./install/all` opts into it in the full installer;
`client` checks desktop prerequisites instead.

The remote mode transfers only this feature into
`~/.local/share/parakeet-voice/bootstrap`; it does not modify the remote dotfiles
checkout. Source, build, Python entrypoint, model, and optional CMake binary stay
under `~/.local/share/parakeet-voice`. The user unit is
`~/.config/systemd/user/parakeet-voice.service`. Re-running the installer reuses
the source/build/model and restarts the service.

Server prerequisites: Linux, user systemd, Python 3, git, curl, tar, g++, make,
sha256sum. Missing CMake is downloaded locally. No sudo, system packages, pip
environment, containers, or GPU runtime are used. Desktop prerequisites are
Python 3 with curses, `parecord` (PulseAudio or PipeWire Pulse), SSH, and WezTerm.
They are already present on this desktop.

Uses **nemotron-3.5-asr-streaming-0.6b Q8_0**, approximately 984 MB. The installer
pins the upstream source and model revision and checks the model's SHA-256.
Build parallelism defaults to eight jobs (`PARAKEET_BUILD_JOBS` to override).

The installer attempts `loginctl enable-linger` without authentication. On hosts
where account policy disallows that, it reports that the service cannot be
guaranteed after logout. Lingering is enabled on Ampere.

## Configuration and operation

`voice.apply_to_config` in `wezterm.lua` accepts `host`, `lang`, `key`, `mods`, and
`size` (default `2` rows). The first row has controls and the audio meter; the
second shows the latest transcript text with `...` on the left when it overflows.
The complete transcript is still pasted when sending.
Recognition defaults to English (`en-US`) in the WezTerm config, CLI, and service.
The model receives an English language prompt instead of auto-detecting the language.
Set `PARAKEET_MIC` in the WezTerm environment to select a PulseAudio source, or
pass `--device` when invoking `voice.py record` manually.

```sh
ssh ampere 'systemctl --user status parakeet-voice'
ssh ampere 'journalctl --user -u parakeet-voice -n 50'
ssh ampere 'systemctl --user restart parakeet-voice'
```

One recording at a time; additional sessions receive a busy message. Audio is
16 kHz mono PCM streamed through SSH to a private user Unix socket. The loaded
model is reused, with fresh streaming state for each recording. Text deltas are
displayed only in the recording window until Send. Audio and transcripts are
not saved to disk. On errors, nothing is pasted automatically.

Recordings are limited to ten minutes. A bounded 30-second audio queue reports
an error if recognition falls behind; captured/processed times show the backlog.
Closing the recording window or cancelling terminates microphone capture and SSH.
The original pane must still exist when sending.

Run protocol and cancellation tests:

```sh
python3 -m unittest discover -s config/wezterm/voice -p 'test_*.py'
```

Upstream references: [streaming C API](https://github.com/mudler/parakeet.cpp/blob/e75de9b6b9b688fd293aa22f7e27aa724ea286f8/include/parakeet_capi.h),
[model collection](https://huggingface.co/mudler/parakeet-cpp-gguf),
[WezTerm paste CLI](https://wezterm.org/cli/cli/send-text.html).
