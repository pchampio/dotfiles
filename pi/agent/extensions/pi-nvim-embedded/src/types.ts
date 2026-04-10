/** User-facing config file schema (all fields optional, merged over defaults). */
export interface NvimEmbeddedConfigFile {
  /** Neovim binary path (default: "nvim") */
  nvimBinary?: string;
  /** Extra args passed to nvim --embed (default: []) */
  nvimExtraArgs?: string[];

  /** Neovim timeoutlen in ms — how long nvim waits for multi-key sequences (default: 5) */
  timeoutlen?: number;
  /** Double-tap ESC window in ms to cancel running operations (default: 400) */
  doubleTapEscTimeout?: number;

  /** Keys disabled inside neovim (mapped to <Nop>). Set to [] to allow all. */
  disabledKeys?: string[];
  /** Whether Enter on empty last line submits the prompt in insert mode (default: true) */
  enterOnEmptyLineSubmits?: boolean;
  /** Whether Enter in normal mode submits the buffer (default: true) */
  enterInNormalSubmits?: boolean;
  /** Whether K/J navigate message history in normal mode (default: true) */
  historyNavigation?: boolean;
  /** Whether Tab toggles plan mode in normal mode (default: true) */
  tabTogglesPlanMode?: boolean;

  /** Tmux integration settings */
  tmux?: {
    /** Enable tmux clipboard integration — Ctrl+V paste, Y yank (default: true) */
    clipboard?: boolean;
    /** Tmux binary path (default: "tmux") */
    binary?: string;
    /** Tmux pane navigation keybindings. Set to {} to disable. */
    paneKeys?: Record<string, string[]>;
    /** Extra tmux keys, e.g. {"alt+k": ["copy-mode", "-H"]} */
    extraKeys?: Record<string, string[]>;
  };

  /** Cursor shape settings */
  cursor?: {
    /** Insert mode cursor shape escape sequence (default: "\x1b[6 q" — bar) */
    insert?: string;
    /** Normal mode cursor shape escape sequence (default: "\x1b[2 q" — block) */
    normal?: string;
  };

  /** Extra nvim init commands run after boot (Lua strings executed via nvim_exec_lua) */
  nvimInitLua?: string[];

  /** Character to replace ─ with on border lines. If unset, no replacement is done. */
  borderChar?: string;
}

/** Resolved settings with all fields guaranteed present. */
export interface NvimEmbeddedSettings {
  nvimBinary: string;
  nvimExtraArgs: string[];
  timeoutlen: number;
  doubleTapEscTimeout: number;
  disabledKeys: string[];
  enterOnEmptyLineSubmits: boolean;
  enterInNormalSubmits: boolean;
  historyNavigation: boolean;
  tabTogglesPlanMode: boolean;

  tmux: {
    clipboard: boolean;
    binary: string;
    paneKeys: Record<string, string[]>;
    extraKeys: Record<string, string[]>;
  };

  cursor: {
    insert: string;
    normal: string;
  };

  nvimInitLua: string[];
  borderChar: string | null;
}
