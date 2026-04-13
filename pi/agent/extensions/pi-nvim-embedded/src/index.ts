/**
 * Neovim-embedded editor for pi.
 *
 * Spawns `nvim --embed`, forwards all keystrokes to neovim,
 * and syncs neovim's buffer/cursor state back to pi's Editor for rendering.
 *
 */

import {
  CustomEditor,
  type ExtensionAPI,
} from "@mariozechner/pi-coding-agent";
import {
  matchesKey,
  visibleWidth,
  truncateToWidth,
} from "@mariozechner/pi-tui";
import { NvimClient } from "./nvim-client.js";
import { loadSettings } from "./config.js";
import type { NvimEmbeddedSettings } from "./types.js";
import { execFile } from "child_process";

// ── cursor shapes (updated from settings at load time) ───────────────

let cursorInsert = "\x1b[6 q";
let cursorNormal = "\x1b[2 q";
let currentCursorShape = cursorNormal;

// ── internals type (access pi Editor private state) ───────────────────

type EditorInternals = {
  state?: { lines?: string[]; cursorLine?: number; cursorCol?: number };
  preferredVisualCol?: number | null;
  lastAction?: string | null;
  historyIndex?: number;
  history?: string[];
  onChange?: (text: string) => void;
  tui?: { requestRender?: () => void };
};

// ── NvimEditor ────────────────────────────────────────────────────────

let userBashRunning = false;

class NvimEditor extends CustomEditor {
  private nvim = new NvimClient();
  private ready = false;
  private fallback = false;
  private queue: string[] = [];
  private busy = false;

  // Shadow state (last-known neovim state, always current between keystrokes)
  private nLines: string[] = [""];
  private nCursorRow = 1;   // 1-indexed (neovim convention)
  private nCursorCol = 0;
  private nMode = "n";      // start in normal

  // Visual selection range (1-indexed rows, 0-indexed cols, like neovim)
  private vStartRow = 0;
  private vStartCol = 0;
  private vEndRow = 0;
  private vEndCol = 0;

  // Popup menu state (from ext_popupmenu or nvim-cmp polling)
  private pmenuVisible = false;
  private pmenuItems: [string, string, string, string][] = []; // [word, kind, menu, info]
  private pmenuSelected = -1;
  private pmenuSource: "ext" | "cmp" | null = null;

  // Cached highlight colors from neovim (true color ANSI prefixes)
  private pmenuStyle = { normal: "", selected: "", kindNormal: "", kindSelected: "", reset: "\x1b[0m" };
  private visualStyle = { on: "\x1b[47m", off: "\x1b[49m" };

  // Ghost text (inline completion virtual text from neovim extmarks)
  private ghostLines: string[] = [];
  private ghostPollTimer: ReturnType<typeof setInterval> | null = null;
  private static readonly GHOST_POLL_MS = 150;

  // Message line (from ext_messages msg_show events)
  private msgText = "";
  private msgKind = "";
  private msgTimer: ReturnType<typeof setTimeout> | null = null;
  private static readonly MSG_TIMEOUT = 4000;

  // Peak render height: prevents editor from shrinking after completion popup closes
  private peakHeight = 0;

  // Flush synchronization: resolves when neovim finishes processing input.
  private flushResolve: (() => void) | null = null;

  private readonly colorizers: {
    insert: (s: string) => string;
    normal: (s: string) => string;
  } | null;

  private readonly settings: NvimEmbeddedSettings;
  private readonly piCommands: { name: string; description: string }[];

  constructor(
    tui: any,
    theme: any,
    kb: any,
    colorizers: { insert: (s: string) => string; normal: (s: string) => string } | null,
    settings: NvimEmbeddedSettings,
    piCommands: { name: string; description: string }[],
  ) {
    super(tui, theme, kb);
    this.colorizers = colorizers;
    this.settings = settings;
    this.piCommands = piCommands;
    this.boot();
  }

  // ── lifecycle ──────────────────────────────────────────────────────

  private async boot(): Promise<void> {
    try {
      await this.nvim.start(this.settings.nvimBinary, this.settings.nvimExtraArgs);

      // Low timeoutlen: keys arrive one at a time from our pump, no need to wait
      await this.nvim.request("nvim_set_option_value", ["timeoutlen", this.settings.timeoutlen, {}]);

      // Keep buftype empty so LSP clients (Copilot, etc.) can attach.
      // File-related features are disabled individually instead.
      await this.nvim.request("nvim_set_option_value", ["bufhidden", "hide", { buf: 0 }]);
      await this.nvim.request("nvim_set_option_value", ["swapfile", false, { buf: 0 }]);
      await this.nvim.request("nvim_set_option_value", ["undofile", false, {}]);
      await this.nvim.request("nvim_set_option_value", ["backup", false, {}]);
      // Suppress all prompts ("Press ENTER", "--More--", etc.)
      await this.nvim.request("nvim_set_option_value", ["shortmess", "aAIcFWs", {}]);
      await this.nvim.request("nvim_set_option_value", ["more", false, {}]);
      await this.nvim.request("nvim_set_option_value", ["cmdheight", 1, {}]);
      // No line numbers / sign column — pi handles display chrome
      await this.nvim.request("nvim_set_option_value", ["number", false, {}]);
      await this.nvim.request("nvim_set_option_value", ["relativenumber", false, {}]);
      await this.nvim.request("nvim_set_option_value", ["signcolumn", "no", {}]);
      // Force completion popup to always show (even for single match)
      await this.nvim.request("nvim_set_option_value", ["completeopt", "menu,menuone,noselect", {}]);
      // Set a neutral filetype so LSP clients (e.g. Copilot) can attach
      await this.nvim.request("nvim_set_option_value", ["filetype", "text", { buf: 0 }]);
      // Disable features that block or are invisible in embedded mode
      const tmuxClipboard = this.settings.tmux.clipboard;
      const disabledKeysJson = JSON.stringify(this.settings.disabledKeys);
      await this.nvim.request("nvim_exec_lua", [`
        -- Suppress any input() calls from plugins (return empty immediately)
        vim.fn.input = function() return '' end
        vim.fn.inputlist = function() return 0 end
        vim.fn.confirm = function() return 1 end

        -- Disable treesitter for this buffer (LSP stays for inline completion)
        vim.api.nvim_create_autocmd({'BufEnter', 'BufNew'}, {
          callback = function(args)
            pcall(vim.treesitter.stop, args.buf)
          end
        })

        ${tmuxClipboard ? `-- Yank to register "y" → TypeScript copies to tmux
        vim.api.nvim_create_autocmd('TextYankPost', {
          callback = function()
            if vim.v.event.regname == 'y' then
              vim.g._pi_yanked = table.concat(vim.v.event.regcontents, string.char(10))
            end
          end
        })` : "-- Tmux clipboard disabled"}

        -- Suppress hit-enter prompts from plugins
        vim.opt.more = false
        vim.opt.lazyredraw = false

        -- Override keymaps AFTER user config loads (VimEnter fires after all init)
        vim.api.nvim_create_autocmd('VimEnter', {
          callback = function()
            local nop = '<Nop>'
            local modes = {'n', 'v', 'x'}

            -- Disable configured keys
            local disabled = vim.fn.json_decode('${disabledKeysJson}')
            for _, key in ipairs(disabled) do
              for _, m in ipairs(modes) do
                vim.keymap.set(m, key, nop)
              end
            end

            -- Window / tab commands (only one window in embedded mode)
            vim.keymap.set('n', '<C-w>', nop)

            -- Completion: Tab/S-Tab cycle
            vim.keymap.set('i', '<Tab>', '<C-n>', { noremap = true })
            vim.keymap.set('i', '<S-Tab>', '<C-p>', { noremap = true })

            -- Ctrl-C cancels operator-pending
            vim.keymap.set({'n', 'o'}, '<C-c>', '<Esc>', { noremap = true })

            ${tmuxClipboard ? `-- Y: yank to register y (TypeScript handles tmux clipboard)
            vim.keymap.set('n', 'Y', 'V"yy', { silent = true, noremap = true })
            vim.keymap.set({'v', 'x'}, 'Y', '"yy', { silent = true, noremap = true })` : "-- Tmux yank disabled"}
          end
        })
      `, []]);

      // Run user-provided init Lua commands
      for (const lua of this.settings.nvimInitLua) {
        await this.nvim.request("nvim_exec_lua", [lua, []]);
      }

      // Enable LSP inline completion when a client attaches (Copilot, etc.)
      await this.nvim.request("nvim_exec_lua", [`
        if vim.lsp and vim.lsp.inline_completion then
          vim.api.nvim_create_autocmd('LspAttach', {
            callback = function(args)
              pcall(vim.lsp.inline_completion.enable, true, { bufnr = args.buf })
            end
          })
          pcall(vim.lsp.inline_completion.enable, true, { bufnr = 0 })
        end
      `, []]);

      // Register nvim-cmp source for pi slash commands (deferred until cmp loads)
      const cmdsJson = JSON.stringify(this.piCommands);
      const cmpSourceLua = [
        "local cmds_json = select(1, ...)",
        "",
        "local function register_pi_source()",
        "  local ok, cmp = pcall(require, 'cmp')",
        "  if not ok then return false end",
        "  ",
        "  local decode_ok, commands = pcall(vim.json.decode, cmds_json)",
        "  if not decode_ok then commands = {} end",
        "",
        "  local source = {}",
        "  source.new = function() return setmetatable({}, { __index = source }) end",
        "  function source:get_trigger_characters() return { '/' } end",
        "  function source:get_keyword_pattern() return [[/\\S*]] end",
        "  function source:complete(params, callback)",
        "    local line = params.context.cursor_before_line",
        "    if not line:match('^/') then",
        "      callback({ items = {}, isIncomplete = false })",
        "      return",
        "    end",
        "    local items = {}",
        "    for _, cmd in ipairs(commands) do",
        "      items[#items + 1] = {",
        "        label = '/' .. cmd.name,",
        "        kind = 14,",
        "        detail = cmd.description or '',",
        "        filterText = '/' .. cmd.name,",
        "        sortText = cmd.name,",
        "      }",
        "    end",
        "    callback({ items = items, isIncomplete = false })",
        "  end",
        "",
        "  cmp.register_source('pi', source)",
        "",
        "  local cfg = require('cmp.config')",
        "  local global = cfg.get()",
        "  local existing = global.sources or {}",
        "  local filtered = {}",
        "  for _, s in ipairs(existing) do",
        "    if s.name ~= 'pi' then filtered[#filtered + 1] = s end",
        "  end",
        "  table.insert(filtered, 1, { name = 'pi', group_index = 0 })",
        "  cmp.setup({ sources = filtered })",
        "",

        "  return true",
        "end",
        "",
        "-- Try now, otherwise wait for VeryLazy / InsertEnter",
        "if register_pi_source() then return end",
        "vim.api.nvim_create_autocmd('User', {",
        "  pattern = 'VeryLazy',",
        "  once = true,",
        "  callback = function()",
        "    if not register_pi_source() then",
        "      vim.api.nvim_create_autocmd('InsertEnter', {",
        "        once = true,",
        "        callback = function()",
        "          register_pi_source()",
        "        end,",
        "      })",
        "    end",
        "  end,",
        "})",
      ].join("\n");
      await this.nvim.request("nvim_exec_lua", [cmpSourceLua, [cmdsJson]]);

      // Attach a UI so neovim processes typeahead and sends flush.
      await this.nvim.request("nvim_ui_attach", [80, 24, { ext_linegrid: true, ext_popupmenu: true, ext_messages: true }]);

      // Listen for flush and popupmenu events.
      this.nvim.onNotification("redraw", (batches) => {
        for (const batch of batches as unknown[][]) {
          if (!Array.isArray(batch)) continue;
          const event = batch[0];
          if (event === "flush") {
            if (this.flushResolve) {
              const resolve = this.flushResolve;
              this.flushResolve = null;
              resolve();
            }
          } else if (event === "popupmenu_show") {
            const args = batch[1] as [unknown[][], number, number, number];
            this.pmenuItems = (args[0] as unknown[][]).map(
              (item) => [String(item[0]), String(item[1]), String(item[2]), String(item[3])] as [string, string, string, string],
            );
            this.pmenuSelected = args[1] as number;
            this.pmenuVisible = true;
            this.pmenuSource = "ext";
          } else if (event === "popupmenu_select") {
            const args = batch[1] as [number];
            this.pmenuSelected = args[0];
          } else if (event === "popupmenu_hide") {
            this.pmenuVisible = false;
            this.pmenuItems = [];
            this.pmenuSelected = -1;
            this.pmenuSource = null;
          } else if (event === "msg_show") {
            // msg_show: [kind, content_chunks, replace_last]
            // content_chunks: [[attr_id, text], ...]
            for (let k = 1; k < batch.length; k++) {
              const args = batch[k] as [string, unknown[][], boolean];
              const kind = args[0] ?? "";
              if (kind === "search_count" || kind === "mode") continue;
              const chunks = args[1] ?? [];
              const text = chunks.map((c: unknown[]) => String(c[1] ?? "")).join("").trim();
              if (text) {
                this.msgText = text;
                this.msgKind = kind;
                if (this.msgTimer) clearTimeout(this.msgTimer);
                this.msgTimer = setTimeout(() => {
                  this.msgText = "";
                  this.msgKind = "";
                  this.msgTimer = null;
                  const e = this as unknown as EditorInternals;
                  e.tui?.requestRender?.();
                }, NvimEditor.MSG_TIMEOUT);
              }
            }
          } else if (event === "msg_clear") {
            this.msgText = "";
            this.msgKind = "";
            if (this.msgTimer) { clearTimeout(this.msgTimer); this.msgTimer = null; }
          }
        }
      });

      // Stay in normal mode (neovim starts in normal by default).
      await this.waitForFlush(100);
      await this.fetchHighlightColors();
      await this.sync();

      this.ready = true;

      // Poll for async ghost text updates (Copilot responds after a delay)
      this.ghostPollTimer = setInterval(async () => {
        if (!this.ready || this.busy || this.getMode() !== "insert" || this.pmenuVisible) return;
        try {
          const ghost = await this.queryGhostText();
          if (ghost.length !== this.ghostLines.length || ghost.some((g, i) => g !== this.ghostLines[i])) {
            this.ghostLines = ghost;
            const e = this as unknown as EditorInternals;
            e.tui?.requestRender?.();
          }
        } catch {}
      }, NvimEditor.GHOST_POLL_MS);

      // Drain anything queued while booting
      if (this.queue.length > 0) {
        this.pump();
      }
    } catch (err: any) {
      // If neovim failed, fall back to the base editor — pass queued input through.
      this.ready = false;
      this.fallback = true;
      for (const data of this.queue.splice(0)) {
        super.handleInput(data);
      }
    }
  }

  close(): void {
    if (this.ghostPollTimer) { clearInterval(this.ghostPollTimer); this.ghostPollTimer = null; }
    if (this.msgTimer) { clearTimeout(this.msgTimer); this.msgTimer = null; }
    this.nvim.close();
    process.stdout.write("\x1b[2 q");
  }

  /** Convert a 24-bit integer color to an ANSI true color sequence. */
  private static fgColor(c: number): string {
    return `\x1b[38;2;${(c >> 16) & 0xff};${(c >> 8) & 0xff};${c & 0xff}m`;
  }
  private static bgColor(c: number): string {
    return `\x1b[48;2;${(c >> 16) & 0xff};${(c >> 8) & 0xff};${c & 0xff}m`;
  }

  /** Fetch highlight colors (Pmenu*, Visual) from neovim for popup and selection rendering. */
  private async fetchHighlightColors(): Promise<void> {
    try {
      const hls = await this.nvim.request("nvim_exec_lua", [`
        local function get(name)
          local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
          if not ok then return {} end
          return { fg = hl.fg, bg = hl.bg, bold = hl.bold, italic = hl.italic, reverse = hl.reverse }
        end
        return { get('Pmenu'), get('PmenuSel'), get('PmenuKind'), get('PmenuKindSel'), get('Visual') }
      `, []]) as { fg?: number; bg?: number; bold?: boolean; italic?: boolean; reverse?: boolean }[];

      const build = (hl: { fg?: number; bg?: number; bold?: boolean; italic?: boolean; reverse?: boolean }) => {
        let s = "";
        if (hl.reverse) { s += "\x1b[7m"; return s; }
        if (hl.bg != null) s += NvimEditor.bgColor(hl.bg);
        if (hl.fg != null) s += NvimEditor.fgColor(hl.fg);
        if (hl.bold) s += "\x1b[1m";
        if (hl.italic) s += "\x1b[3m";
        return s;
      };

      this.pmenuStyle = {
        normal: build(hls[0] ?? {}) || "\x1b[100m",
        selected: build(hls[1] ?? {}) || "\x1b[7m",
        kindNormal: build(hls[2] ?? {}) || build(hls[0] ?? {}) || "\x1b[100m",
        kindSelected: build(hls[3] ?? {}) || build(hls[1] ?? {}) || "\x1b[7m",
        reset: "\x1b[0m",
      };

      const vis = hls[4] ?? {};
      const visOn = build(vis);
      if (visOn) {
        this.visualStyle = { on: visOn, off: "\x1b[0m" };
      }
    } catch {
      this.pmenuStyle = {
        normal: "\x1b[100m",
        selected: "\x1b[7m",
        kindNormal: "\x1b[100m",
        kindSelected: "\x1b[7m",
        reset: "\x1b[0m",
      };
    }
  }

  // ── mode helpers ───────────────────────────────────────────────────

  getMode(): "insert" | "normal" | "visual" {
    const m = this.nMode;
    if (m.startsWith("i") || m.startsWith("R")) return "insert";
    if (m === "v" || m === "V" || m === "\x16"
      || m.startsWith("s") || m.startsWith("S")) return "visual";
    return "normal";
  }

  /**
   * True only when neovim is in pure normal mode — no pending operator,
   * no replace-char wait, no Ctrl-O sub-mode, etc.
   * Only in this state should ESC / Ctrl-C bypass neovim and go to pi.
   */
  isPureNormal(): boolean {
    return this.nMode === "n";
  }

  hasPendingState(): boolean {
    // Operator-pending (no, nov, noV, no^V), replace-char (r, rm, r?),
    // Ctrl-O sub-modes (niI, niR, niV), etc. all count as pending.
    return this.getMode() === "normal" && !this.isPureNormal();
  }

  // ── input handling ─────────────────────────────────────────────────

  handleInput(data: string): void {
    // If neovim failed to start, pass everything to the base editor
    if (this.fallback) {
      super.handleInput(data);
      return;
    }

    // Bracketed paste: \x1b[200~<text>\x1b[201~
    if (data.includes("\x1b[200~")) {
      const text = data.replace(/\x1b\[200~/g, "").replace(/\x1b\[201~/g, "");
      if (text) {
        this.pasteText(text);
      }
      return;
    }

    this.queue.push(data);
    if (this.ready && !this.busy) {
      this.pump();
    }
  }

  /** Paste text into neovim at cursor position */
  private async pasteText(text: string): Promise<void> {
    if (!this.ready) return;
    try {
      // Strip all terminal escape sequences and control chars — tmux buffers can contain styled text
      const clean = text
        .replace(/\x1b(?:\[[^\x40-\x7e]*[\x40-\x7e]|\][^\x07]*\x07|.)/g, "")
        .replace(/[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]/g, "");
      const lines = clean.split(/\r?\n/);
      await this.nvim.request("nvim_put", [lines, "c", false, true]);
      await this.waitForFlush(50);
      await this.sync();
    } catch (err: any) {
    }
  }

  // Keys bypassed to pi (used by pump + batch check)
  private get piKeys(): string[] {
    return this.settings.piKeys;
  }

  /** Merged tmux keys from settings (paneKeys). */
  private get tmuxKeys(): Record<string, string[]> {
    return { ...this.settings.tmux.paneKeys };
  }

  /** Process the input queue serially — each key waits for neovim to finish. */
  private async pump(): Promise<void> {
    this.busy = true;
    const PI_KEYS = this.piKeys;
    const TMUX_KEYS = this.tmuxKeys;
    try {
      while (this.queue.length > 0) {
        const data = this.queue.shift()!;

        // ── keys that bypass neovim ──

        // Keys that go to pi (editor shortcuts, exit, etc.)
        if (PI_KEYS.some(k => matchesKey(data, k))) {
          super.handleInput(data);
          continue;
        }

        // Tab in normal mode → toggle plan mode
        if (this.settings.tabTogglesPlanMode && (matchesKey(data, "tab") || data === "\t") && this.getMode() !== "insert") {
          const g = globalThis as any;
          if (typeof g.__piTogglePlanMode === "function") g.__piTogglePlanMode();
          continue;
        }

        // Shift+Tab: pi (thinking toggle) in normal mode, neovim (completion) in insert
        if (matchesKey(data, "shift+tab") && this.getMode() !== "insert") {
          super.handleInput(data);
          continue;
        }

        // Keys that go to tmux (only in normal mode — insert/visual send to neovim)
        if (this.isPureNormal()) {
          let tmuxHandled = false;
          for (const [key, args] of Object.entries(TMUX_KEYS)) {
            if (matchesKey(data, key)) {
              execFile(this.settings.tmux.binary, args, () => {});
              tmuxHandled = true;
              break;
            }
          }
          if (tmuxHandled) continue;
        }

        // Ctrl+V → paste from tmux buffer
        if (this.settings.tmux.clipboard && matchesKey(data, "ctrl+v")) {
          try {
            const result = await new Promise<string>((resolve, reject) => {
              execFile(this.settings.tmux.binary, ["show-buffer"], (err, stdout) => {
                if (err) reject(err); else resolve(stdout);
              });
            });
            if (result) await this.pasteText(result);
          } catch (err: any) {
          }
          continue;
        }

        // J/K in normal mode → message history navigation
        if (this.settings.historyNavigation && (data === "K" || data === "J") && this.isPureNormal()) {
          await this.navigateHistory(data === "K" ? -1 : 1);
          continue;
        }

        // ESC in pure normal mode → pi (agent abort)
        // In operator-pending / replace-char / Ctrl-O sub-modes → neovim (cancel pending op)
        if (this.isEsc(data) && this.isPureNormal()) {
          super.handleInput(data);
          continue;
        }

        // Ctrl+C in pure normal mode:
        // 1. Call onEscape() to abort user bash / agent (if running)
        // Ctrl+C in pure normal mode:
        // - If user bash is running, call onEscape to abort it.
        // - Always call super.handleInput for the "clear" action (double Ctrl+C exit).
        // In other modes → neovim handles it (cancel pending op).
        if (matchesKey(data, "ctrl+c") && this.isPureNormal()) {
          if (this.onEscape && userBashRunning) {
            this.onEscape();
            userBashRunning = false;
          }
          super.handleInput(data);
          continue;
        }

        // ── submission check ──
        // Normal mode: Enter submits the full buffer
        if (this.settings.enterInNormalSubmits && this.isEnter(data) && this.isPureNormal() && this.getText().trim() !== "") {
          await this.submit(false);
          continue;
        }
        // Insert mode: Enter on empty last line submits (strips trailing empty line)
        if (this.settings.enterOnEmptyLineSubmits && this.isEnter(data) && this.getMode() === "insert" && this.shouldSubmit()) {
          await this.submit(false);
          continue;
        }

        // ── forward to neovim ──
        // Batch: send this key + any remaining queued keys to neovim at once,
        // then flush + sync only once. This makes multi-key commands (diw, "0p, etc.) fast.
        try {
          let batch = this.translateKey(data);
          while (this.queue.length > 0) {
            const next = this.queue[0]!;
            // Stop batching if the next key needs special handling
            if (matchesKey(next, "ctrl+d") || this.isEsc(next) || matchesKey(next, "ctrl+c")
              || this.isEnter(next) || PI_KEYS.some(k => matchesKey(next, k))) break;
            let tmuxMatch = false;
            for (const key of Object.keys(TMUX_KEYS)) {
              if (matchesKey(next, key)) { tmuxMatch = true; break; }
            }
            if (tmuxMatch) break;
            if ((next === "K" || next === "J") && this.isPureNormal()) break;
            this.queue.shift();
            batch += this.translateKey(next);
          }
          await this.nvim.request("nvim_input", [batch]);
          await this.waitForFlush(50);
          await this.sync();
        } catch (err: any) {
          try { await this.sync(); } catch {}
        }
      }
    } finally {
      this.busy = false;
    }
  }

  // ── helpers ────────────────────────────────────────────────────────

  /** Translate kitty protocol keys to sequences neovim understands */
  private translateKey(data: string): string {
    // Raw backspace bytes → BS (\x08) for neovim
    if (data === "\x7f" || data === "\x08") return "\x08";
    if (data === "\t") return "\t";
    if (data.length > 1) {
      if (matchesKey(data, "ctrl+w")) return "\x17";
      if (matchesKey(data, "ctrl+u")) return "\x15";
      if (matchesKey(data, "ctrl+a")) return "\x01";
      if (matchesKey(data, "ctrl+e")) return "\x05";
      if (matchesKey(data, "ctrl+r")) return "\x12";
      if (matchesKey(data, "ctrl+n")) return "\x0e";
      if (matchesKey(data, "ctrl+p")) return "\x10";
      if (matchesKey(data, "ctrl+h")) return "\x08";
      if (matchesKey(data, "ctrl+j")) return "\x0a";
      if (matchesKey(data, "ctrl+k")) return "\x0b";
      if (matchesKey(data, "ctrl+l")) return "\x0c";
      if (matchesKey(data, "backspace")) return "\x08";
      if (matchesKey(data, "tab")) return "\x09";
      if (matchesKey(data, "shift+tab")) return "\x1b[Z";
    }
    return data;
  }

  private async queryGhostText(): Promise<string[]> {
    const ghost = await this.nvim.request("nvim_exec_lua", [`
      local row = vim.fn.line('.') - 1
      local marks = vim.api.nvim_buf_get_extmarks(0, -1, {row, 0}, {row + 1, 0}, {details = true})
      local texts = {}
      for _, mark in ipairs(marks) do
        local d = mark[4]
        local pos = d.virt_text_pos or ''
        if d.virt_text and #d.virt_text > 0 and (pos == 'inline' or pos == 'overlay') then
          local s = ''
          for _, c in ipairs(d.virt_text) do s = s .. c[1] end
          if #s > 0 then texts[#texts+1] = s end
        end
        if d.virt_lines then
          for _, vl in ipairs(d.virt_lines) do
            local s = ''
            for _, c in ipairs(vl) do s = s .. c[1] end
            if #s > 0 then texts[#texts+1] = s end
          end
        end
      end
      if #texts == 0 then return nil end
      return texts
    `, []]) as string[] | null;
    return ghost ?? [];
  }

  private isEsc(data: string): boolean {
    return matchesKey(data, "escape") || matchesKey(data, "ctrl+[");
  }

  private isEnter(data: string): boolean {
    return data === "\r" || data === "\n" || matchesKey(data, "return");
  }

  /** Returns a promise that resolves on the next flush notification (or timeout). */
  private waitForFlush(timeoutMs: number): Promise<void> {
    return new Promise<void>((resolve) => {
      this.flushResolve = resolve;
      setTimeout(() => {
        if (this.flushResolve === resolve) {
          this.flushResolve = null;
          resolve();
        }
      }, timeoutMs);
    });
  }

  /** Navigate message history. dir=-1 is older (K), dir=+1 is newer (J). */
  private async navigateHistory(dir: -1 | 1): Promise<void> {
    const e = this as unknown as EditorInternals;
    const history = e.history ?? [];
    const idx = e.historyIndex ?? -1;

    if (history.length === 0) {
      return;
    }

    // Save current text as draft when first entering history
    if (idx === -1 && dir === -1) {
      this.historyDraft = this.nLines.join("\n");
    }

    let newIdx: number;
    if (dir === -1) {
      // K → older: go from -1 to last entry, then further back
      newIdx = idx === -1 ? history.length - 1 : idx - 1;
      if (newIdx < 0) return;
    } else {
      // J → newer: go forward, past last entry returns to draft
      if (idx === -1) return;
      newIdx = idx + 1;
      if (newIdx >= history.length) newIdx = -1; // back to draft
    }

    e.historyIndex = newIdx;
    const text = newIdx === -1 ? (this.historyDraft ?? "") : history[newIdx]!;

    // Push to neovim
    const lines = text ? text.split("\n") : [""];
    try {
      await this.nvim.request("nvim_buf_set_lines", [0, 0, -1, false, lines]);
      // Move cursor to end of buffer
      await this.nvim.request("nvim_win_set_cursor", [0, [lines.length, 0]]);
      await this.waitForFlush(50);
      await this.sync();
    } catch {}

    // Clear draft when returning to it
    if (newIdx === -1) this.historyDraft = null;
  }


  /** Submit if cursor is on an empty line and buffer has real content above. */
  private shouldSubmit(): boolean {
    if (this.nLines.length <= 1 && (this.nLines[0] ?? "") === "") return false;
    const cursorLine = this.nLines[this.nCursorRow - 1] ?? "";
    return cursorLine.trim() === "";
  }

  private async submit(stripLastLine: boolean): Promise<void> {
    const text = stripLastLine
      ? this.nLines.slice(0, -1).join("\n")
      : this.nLines.join("\n").trimEnd();

    // Clear neovim buffer and go to normal mode
    try {
      await this.nvim.request("nvim_buf_set_lines", [0, 0, -1, false, [""]]);
      await this.nvim.request("nvim_input", ["\x1b"]); // ESC to ensure normal mode
      await this.waitForFlush(50);
    } catch (err: any) {
    }

    this.nLines = [""];
    this.nCursorRow = 1;
    this.nCursorCol = 0;
    this.nMode = "n";
    this.peakHeight = 0;
    this.pushToEditor();

    const onSubmit = (this as any).onSubmit as ((text: string) => void) | undefined;
    if (onSubmit) onSubmit(text);
  }

  // ── neovim → pi state sync ─────────────────────────────────────────

  /** Read buffer lines, cursor, mode from neovim and update pi's Editor. */
  private async sync(): Promise<void> {
    try {
      // Use nvim_exec_lua for mode (nvim_get_mode can hang in embedded mode).
      const [lines, cursor, mode] = await Promise.all([
        this.nvim.request("nvim_buf_get_lines", [0, 0, -1, false]) as Promise<string[]>,
        this.nvim.request("nvim_win_get_cursor", [0]) as Promise<number[]>,
        this.nvim.request("nvim_exec_lua", ["return vim.fn.mode(1)", []]) as Promise<string>,
      ]);

      const prevMode = this.nMode;
      this.nLines = lines.length > 0 ? lines : [""];
      this.nCursorRow = cursor[0] ?? 1;
      this.nCursorCol = cursor[1] ?? 0;
      this.nMode = mode ?? "n";

      if (prevMode !== this.nMode) {
      }

      // Fetch visual selection bounds when in visual mode
      if (this.getMode() === "visual") {
        try {
          const sel = await this.nvim.request("nvim_exec_lua", [`
            local s = vim.fn.getpos("v")
            local e = vim.fn.getpos(".")
            return {s[2], s[3]-1, e[2], e[3]-1}
          `, []]) as number[];
          this.vStartRow = sel[0]!; this.vStartCol = sel[1]!;
          this.vEndRow = sel[2]!;   this.vEndCol = sel[3]!;
          // Normalize so start <= end
          if (this.vStartRow > this.vEndRow ||
              (this.vStartRow === this.vEndRow && this.vStartCol > this.vEndCol)) {
            [this.vStartRow, this.vStartCol, this.vEndRow, this.vEndCol] =
              [this.vEndRow, this.vEndCol, this.vStartRow, this.vStartCol];
          }
        } catch {}
      } else {
        this.vStartRow = this.vEndRow = 0;
      }

      // Escape command-line mode immediately — it's invisible in pi and will eat input.
      if (this.nMode === "c") {
        try {
          await this.nvim.request("nvim_input", ["\x03"]); // Ctrl-C
          await this.waitForFlush(50);
          // Re-sync to get the mode after escaping
          const [lines2, cursor2, mode2] = await Promise.all([
            this.nvim.request("nvim_buf_get_lines", [0, 0, -1, false]) as Promise<string[]>,
            this.nvim.request("nvim_win_get_cursor", [0]) as Promise<number[]>,
            this.nvim.request("nvim_exec_lua", ["return vim.fn.mode(1)", []]) as Promise<string>,
          ]);
          this.nLines = lines2.length > 0 ? lines2 : [""];
          this.nCursorRow = cursor2[0] ?? 1;
          this.nCursorCol = cursor2[1] ?? 0;
          this.nMode = mode2 ?? "n";
        } catch {}
      }

      // Query ghost text (virtual text at cursor from inline completion / copilot / etc.)
      if (this.getMode() === "insert") {
        try {
          this.ghostLines = await this.queryGhostText();
        } catch {
          this.ghostLines = [];
        }
      } else {
        this.ghostLines = [];
      }

      // Poll nvim-cmp popup state (if nvim-cmp is installed)
      try {
        const cmpState = await this.nvim.request("nvim_exec_lua", [`
          local ok, cmp = pcall(require, 'cmp')
          if not ok or not cmp.visible() then return nil end
          local entries = cmp.get_entries()
          if #entries == 0 then return nil end
          local items = {}
          for _, entry in ipairs(entries) do
            local ci = entry:get_completion_item()
            local kind = ''
            if entry.source.name == 'pi' then
              kind = 'pi'
            elseif ci.kind then
              local names = vim.lsp.protocol.CompletionItemKind
              if type(names) == 'table' then kind = names[ci.kind] or '' end
            end
            table.insert(items, {ci.label or '', '[' .. kind .. ']', ci.detail or '', ''})
          end
          local sel = -1
          local selected = cmp.get_selected_entry()
          if selected then
            for i, entry in ipairs(entries) do
              if entry == selected then sel = i - 1; break end
            end
          end
          return {items, sel}
        `, []]) as [unknown[][], number] | null;

        if (cmpState) {
          this.pmenuItems = (cmpState[0] as unknown[][]).map(
            (item) => [String(item[0]), String(item[1]), String(item[2]), String(item[3])] as [string, string, string, string],
          );
          this.pmenuSelected = cmpState[1] as number;
          this.pmenuVisible = true;
          this.pmenuSource = "cmp";
        } else if (this.pmenuSource === "cmp") {
          this.pmenuVisible = false;
          this.pmenuItems = [];
          this.pmenuSelected = -1;
          this.pmenuSource = null;
        }
      } catch {
        // nvim-cmp not installed or errored — fall back to ext_popupmenu events
      }

      // Check for yanked text and copy to tmux
      if (this.settings.tmux.clipboard) {
        try {
          const yanked = await this.nvim.request("nvim_get_var", ["_pi_yanked"]) as string;
          if (yanked) {
            execFile(this.settings.tmux.binary, ["set-buffer", "-w", yanked], () => {});
            await this.nvim.request("nvim_del_var", ["_pi_yanked"]);
          }
        } catch {} // var doesn't exist = no yank
      }

      this.pushToEditor();
    } catch (err: any) {
      // Full sync failed — try to at least keep mode in sync so
      // ESC/Ctrl-C routing stays correct and we don't get stuck.
      try {
        const mode = await this.nvim.request("nvim_exec_lua", ["return vim.fn.mode(1)", []]) as string;
        if (mode) {
          this.nMode = mode;
        }
      } catch (err2: any) {
      }
    }
  }

  /** Push shadow state into pi's Editor internals and request a re-render. */
  // Draft saved when browsing history, restored when returning to current message
  private historyDraft: string | null = null;

  private pushToEditor(): void {
    const e = this as unknown as EditorInternals;
    if (!e.state) {
      return;
    }

    e.state.lines = [...this.nLines];
    e.state.cursorLine = Math.max(0, this.nCursorRow - 1);
    e.state.cursorCol = this.nCursorCol;
    e.preferredVisualCol = null;
    e.lastAction = null;
    // Don't reset historyIndex here — navigateHistory manages it

    e.onChange?.(this.nLines.join("\n"));
    e.tui?.requestRender?.();
  }

  // ── text get/set (used by pi) ──────────────────────────────────────

  override getText(): string {
    return this.nLines.join("\n");
  }

  override setText(text: string): void {
    super.setText(text);
    // Reset peak height when editor is cleared (e.g. after submission)
    if (!text) this.peakHeight = 0;
    if (!this.ready) return;
    const lines = text ? text.split("\n") : [""];
    this.nvim.request("nvim_buf_set_lines", [0, 0, -1, false, lines]).then(() => {
      this.nLines = lines;
      this.pushToEditor();
    }).catch(() => {});
  }

  /** Splice `content` into `rendered` at visible column `col`, replacing `contentWidth` visible characters. */
  private spliceAtCol(rendered: string, col: number, content: string, contentWidth: number): string {
    let visPos = 0;
    let beforePopup = "";
    let afterPopup = "";
    let phase: "before" | "skip" | "after" = "before";
    let skipped = 0;

    for (let j = 0; j < rendered.length; ) {
      if (rendered[j] === "\x1b") {
        let end = j + 1;
        if (rendered[end] === "[") {
          while (end < rendered.length && rendered[end] !== "m") end++;
          end++;
        } else if (rendered[end] === "_") {
          while (end < rendered.length && rendered[end] !== "\x07") end++;
          end++;
        } else {
          end++;
        }
        const seq = rendered.slice(j, end);
        if (phase === "before") beforePopup += seq;
        else afterPopup += seq;
        j = end;
        continue;
      }

      if (phase === "before" && visPos >= col) phase = "skip";
      if (phase === "skip" && skipped >= contentWidth) phase = "after";

      if (phase === "before") { beforePopup += rendered[j]; visPos++; }
      else if (phase === "skip") { skipped++; visPos++; }
      else { afterPopup += rendered[j]; visPos++; }
      j++;
    }

    while (visibleWidth(beforePopup) < col) beforePopup += " ";
    return beforePopup + content + afterPopup;
  }

  // ── render (add mode label) ────────────────────────────────────────

  render(width: number): string[] {
    const lines = super.render(width);
    if (lines.length === 0) return lines;

    // OSC 133;D (command finished) + 133;A (prompt start) — enables tmux K/J prompt navigation
    lines[0] = "\x1b]133;D\x07\x1b]133;A\x07" + lines[0];

    const IS_BORDER_LINE = /^([^─]*─){6,}/;
    for (let i = 0; i < lines.length; i++) {
      if (this.settings.borderChar !== null && IS_BORDER_LINE.test(lines[i]!)) {
        lines[i] = lines[i]!.replace(/─/g, this.settings.borderChar);
      }
      // Strip pi's visual block cursor but keep the APC position marker.
      lines[i] = lines[i]!
        .replace(/(\x1b_pi:c\x07)\x1b\[7m(.)\x1b\[0m/g, "$1$2")
        .replace(/(\x1b_pi:c\x07)\x1b\[7m(.)\x1b\[27m/g, "$1$2");
    }

    // Find cursor's actual render row from pi's APC cursor marker.
    // When pi truncates content ("↑ N more" / "↓ N more" indicators),
    // buffer rows no longer map 1:1 to render line indices.
    let cursorRenderRow = this.nCursorRow;
    for (let i = 1; i < lines.length - 1; i++) {
      if (lines[i]!.includes("\x1b_pi:c\x07")) {
        cursorRenderRow = i;
        break;
      }
    }
    const rowOffset = cursorRenderRow - this.nCursorRow;

    // Detect truncation indicator lines so overlays skip them
    const hasTopTrunc = lines.length > 2 && /↑/.test(lines[1]!);
    const hasBottomTrunc = lines.length > 2 && /↓/.test(lines[lines.length - 2]!);
    const contentFirstIdx = hasTopTrunc ? 2 : 1;
    const contentLastIdx = hasBottomTrunc ? lines.length - 3 : lines.length - 2;

    // Apply visual selection highlight
    const mode = this.getMode();
    if (mode === "visual" && this.vStartRow > 0) {
      const isLinewise = this.nMode === "V" || this.nMode === "Vs";
      const isBlock = this.nMode === "\x16" || this.nMode === "\x16s";
      // Content lines are between the border lines (index 1 to lines.length-2)
      for (let bufRow = this.vStartRow; bufRow <= this.vEndRow && bufRow <= this.nLines.length; bufRow++) {
        const renderIdx = bufRow + rowOffset;
        if (renderIdx < contentFirstIdx || renderIdx > contentLastIdx) continue;

        const lineText = this.nLines[bufRow - 1] ?? "";
        let selStart: number, selEnd: number;

        if (isLinewise) {
          selStart = 0;
          selEnd = lineText.length;
        } else if (isBlock) {
          selStart = Math.min(this.vStartCol, this.vEndCol);
          selEnd = Math.max(this.vStartCol, this.vEndCol) + 1;
        } else {
          // Charwise
          selStart = bufRow === this.vStartRow ? this.vStartCol : 0;
          selEnd = bufRow === this.vEndRow ? this.vEndCol + 1 : lineText.length;
        }

        // Apply reverse video to selected range in the rendered line
        // Strip ANSI codes to find character positions, then re-inject highlight
        const rendered = lines[renderIdx]!;
        let visPos = 0;
        let result = "";
        let inHighlight = false;
        // Walk through rendered string, tracking visible character position
        for (let j = 0; j < rendered.length; ) {
          // Skip ANSI escape sequences
          if (rendered[j] === "\x1b") {
            let end = j + 1;
            if (rendered[end] === "[") {
              while (end < rendered.length && rendered[end] !== "m") end++;
              end++; // past 'm'
            } else if (rendered[end] === "_") {
              // APC sequence: \x1b_ ... \x07
              while (end < rendered.length && rendered[end] !== "\x07") end++;
              end++; // past BEL
            } else {
              end++;
            }
            result += rendered.slice(j, end);
            j = end;
            continue;
          }
          // Visible character
          if (visPos >= selStart && visPos < selEnd && !inHighlight) {
            result += this.visualStyle.on;
            inHighlight = true;
          }
          if (visPos >= selEnd && inHighlight) {
            result += this.visualStyle.off;
            inHighlight = false;
          }
          result += rendered[j];
          visPos++;
          j++;
        }
        if (inHighlight) result += this.visualStyle.off;
        lines[renderIdx] = result;
      }
    }

    // Render ghost text (inline completion) — hide when popup menu is open
    if (this.ghostLines.length > 0 && mode === "insert" && !this.pmenuVisible) {
      const ghostOn = "\x1b[2;3m";
      const ghostOff = "\x1b[22;23m";
      const padX = this.getPaddingX();
      const cursorRenderIdx = cursorRenderRow;

      if (cursorRenderIdx > 0 && cursorRenderIdx < lines.length - 1) {
        const col = padX + this.nCursorCol;
        const maxGhostWidth = width - col;
        if (maxGhostWidth > 0) {
          const truncGhost = truncateToWidth(this.ghostLines[0]!, maxGhostWidth);
          const styledGhost = `${ghostOn}${truncGhost}${ghostOff}`;
          const spliced = this.spliceAtCol(lines[cursorRenderIdx]!, col, styledGhost, 0);
          lines[cursorRenderIdx] = truncateToWidth(spliced, width);

          for (let g = 1; g < this.ghostLines.length; g++) {
            const truncLine = truncateToWidth(this.ghostLines[g]!, width - padX);
            const ghostLine = " ".repeat(padX) + `${ghostOn}${truncLine}${ghostOff}`;
            const padRight = " ".repeat(Math.max(0, width - visibleWidth(ghostLine)));
            lines.splice(cursorRenderIdx + g, 0, ghostLine + padRight);
          }
        }
      }
    }

    // Render popup menu overlay
    if (this.pmenuVisible && this.pmenuItems.length > 0) {
      const MAX_VISIBLE = this.settings.maxCompletionItems;
      const items = this.pmenuItems;
      const sel = this.pmenuSelected;

      // Scroll window: keep selected item visible
      let scrollTop = 0;
      if (sel >= 0) {
        if (sel >= scrollTop + MAX_VISIBLE) scrollTop = sel - MAX_VISIBLE + 1;
        if (sel < scrollTop) scrollTop = sel;
      }
      const visibleItems = items.slice(scrollTop, scrollTop + MAX_VISIBLE);
      const hasScrollIndicator = items.length > MAX_VISIBLE;
      const popupHeight = visibleItems.length + (hasScrollIndicator ? 1 : 0);

      // Compute max column widths for alignment
      let maxWord = 0;
      let maxKind = 0;
      let maxMenu = 0;
      for (const item of visibleItems) {
        if (item[0].length > maxWord) maxWord = item[0].length;
        if (item[1].length > maxKind) maxKind = item[1].length;
        if (item[2].length > maxMenu) maxMenu = item[2].length;
      }
      const popupInnerWidth = Math.min(
        maxWord + (maxKind ? maxKind + 1 : 0) + (maxMenu ? maxMenu + 2 : 0) + 2,
        width - 4,
      );
      const popupWidth = popupInnerWidth;

      // Popup position: below cursor row, using actual render position.
      const popupStartRow = cursorRenderRow + 1;
      const popupCol = Math.min(this.nCursorCol + 1, width - popupWidth - 1);

      // Inject blank lines before the bottom border if the popup extends past content
      const bottomBorderIdx = lines.length - 1;
      const popupEndRow = popupStartRow + popupHeight;
      if (popupEndRow > bottomBorderIdx) {
        const extraLines = popupEndRow - bottomBorderIdx;
        const blankLine = " ".repeat(width);
        for (let e = 0; e < extraLines; e++) {
          lines.splice(bottomBorderIdx, 0, blankLine);
        }
      }

      for (let i = 0; i < visibleItems.length; i++) {
        const renderIdx = popupStartRow + i;
        if (renderIdx <= 0 || renderIdx >= lines.length - 1) continue;

        const [word, kind, menu] = visibleItems[i]!;
        const isSelected = (scrollTop + i) === sel;
        const ps = this.pmenuStyle;

        const wordPad = " ".repeat(Math.max(0, maxWord - word.length));
        const kindPart = maxKind > 0 ? ` ${(kind || "").padEnd(maxKind)}` : "";
        const menuPart = maxMenu > 0 ? ` ${(menu || "").padEnd(maxMenu)}` : "";

        const leftText = `${word}${wordPad}${kindPart}`;
        const leftTrunc = leftText.slice(0, popupWidth);
        const menuTrunc = menuPart.slice(0, Math.max(0, popupWidth - visibleWidth(leftTrunc)));
        const remaining = popupWidth - visibleWidth(leftTrunc) - visibleWidth(menuTrunc);
        const pad = " ".repeat(Math.max(0, remaining));

        const wordStyle = isSelected ? ps.selected : ps.normal;
        const kindStyle = isSelected ? ps.kindSelected : ps.kindNormal;
        const styledItem = `${wordStyle}${leftTrunc}${ps.reset}${kindStyle}${pad}${menuTrunc}${ps.reset}`;

        lines[renderIdx] = this.spliceAtCol(lines[renderIdx]!, popupCol, styledItem, popupWidth);
      }

      // Scroll indicator
      if (hasScrollIndicator) {
        const indicatorRow = popupStartRow + visibleItems.length;
        if (indicatorRow > 0 && indicatorRow < lines.length - 1) {
          const remaining = items.length - scrollTop - MAX_VISIBLE;
          const scrollInfo = remaining > 0
            ? ` +${remaining} more `
            : ` ${items.length} items `;
          const info = truncateToWidth(scrollInfo, popupWidth);
          const padded = info + " ".repeat(Math.max(0, popupWidth - visibleWidth(info)));
          const styledInfo = `\x1b[2m${this.pmenuStyle.normal}${padded}${this.pmenuStyle.reset}\x1b[22m`;
          lines[indicatorRow] = this.spliceAtCol(lines[indicatorRow]!, popupCol, styledInfo, popupWidth);
        }
      }
    }

    const rawLabel = mode === "insert" ? " INSERT "
      : mode === "visual" ? " VISUAL "
      : " NORMAL ";
    const colorize = this.colorizers
      ? (mode === "insert" ? this.colorizers.insert : this.colorizers.normal)
      : null;
    const label = colorize ? colorize(rawLabel) : rawLabel;

    const last = lines.length - 1;

    // Show message from neovim (print/echo/errors) on the bottom border line
    if (this.msgText) {
      const isError = this.msgKind === "emsg" || this.msgKind === "echoerr" || this.msgKind === "lua_error";
      const msgColor = isError ? "\x1b[31m" : "\x1b[2m";
      const maxMsgWidth = width - visibleWidth(rawLabel) - 2;
      const msgDisplay = ` ${truncateToWidth(this.msgText, maxMsgWidth, "…")} `;
      const styledMsg = `${msgColor}${msgDisplay}\x1b[0m`;
      const labelWidth = visibleWidth(rawLabel);
      const msgWidth = visibleWidth(msgDisplay);
      if (visibleWidth(lines[last]!) >= labelWidth + msgWidth) {
        lines[last] = truncateToWidth(lines[last]!, width - labelWidth - msgWidth, "") + styledMsg + label;
      } else {
        lines[last] = truncateToWidth(lines[last]!, width - visibleWidth(rawLabel), "") + label;
      }
    } else if (visibleWidth(lines[last]!) >= visibleWidth(rawLabel)) {
      lines[last] = truncateToWidth(lines[last]!, width - visibleWidth(rawLabel), "") + label;
    }

    // Maintain peak height: prevent editor from shrinking after completion popup closes.
    // When the popup adds extra lines, peakHeight grows. When it hides, we pad to keep
    // the editor at the same height so the UI doesn't jump.
    if (lines.length > this.peakHeight) {
      this.peakHeight = lines.length;
    } else if (lines.length < this.peakHeight) {
      const bottomBorder = lines.length - 1;
      const padCount = this.peakHeight - lines.length;
      const blankLine = " ".repeat(width);
      for (let p = 0; p < padCount; p++) {
        lines.splice(bottomBorder, 0, blankLine);
      }
    }

    // Always re-assert cursor shape — pi may reset it between renders
    const shape = mode === "insert" ? cursorInsert : cursorNormal;
    currentCursorShape = shape;
    setImmediate(() => process.stdout.write(shape));
    return lines;
  }
}

// ── Pi command collection ─────────────────────────────────────────────

const BUILTIN_COMMANDS: { name: string; description: string }[] = [
  { name: "settings", description: "Open settings menu" },
  { name: "model", description: "Select model (opens selector UI)" },
  { name: "scoped-models", description: "Enable/disable models for Ctrl+P cycling" },
  { name: "export", description: "Export session (HTML default, or specify path)" },
  { name: "import", description: "Import and resume a session from a JSONL file" },
  { name: "share", description: "Share session as a secret GitHub gist" },
  { name: "copy", description: "Copy last agent message to clipboard" },
  { name: "name", description: "Set session display name" },
  { name: "session", description: "Show session info and stats" },
  { name: "changelog", description: "Show changelog entries" },
  { name: "hotkeys", description: "Show all keyboard shortcuts" },
  { name: "fork", description: "Create a new fork from a previous message" },
  { name: "tree", description: "Navigate session tree (switch branches)" },
  { name: "login", description: "Login with OAuth provider" },
  { name: "logout", description: "Logout from OAuth provider" },
  { name: "new", description: "Start a new session" },
  { name: "compact", description: "Manually compact the session context" },
  { name: "resume", description: "Resume a different session" },
  { name: "reload", description: "Reload keybindings, extensions, skills, prompts, and themes" },
  { name: "quit", description: "Quit pi" },
];

function collectPiCommands(pi: ExtensionAPI): { name: string; description: string }[] {
  const builtinNames = new Set(BUILTIN_COMMANDS.map(c => c.name));
  const commands = [...BUILTIN_COMMANDS];
  try {
    for (const cmd of pi.getCommands()) {
      if (!builtinNames.has(cmd.name)) {
        commands.push({ name: cmd.name, description: cmd.description ?? "" });
      }
    }
  } catch {}
  return commands;
}

// ── Extension entry point ─────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
  let inputUnsub: (() => void) | null = null;

  let currentEditor: NvimEditor | null = null;
  let lastEscTime = 0;
  let pendingEscTimer: ReturnType<typeof setTimeout> | null = null;
  let settings: NvimEmbeddedSettings | null = null;

  // Tmux prompt tracking (mirrors zsh __prompt_precmd for J/K navigation)
  let promptCount = 0;
  let promptLookupMax = 0;

  function generateLookupFmt(n: number): string {
    const cur = "#{e|+|:#{e|-|:#{history_size},#{scroll_position}},#{copy_cursor_y}}";
    let result = "0";
    for (let i = 1; i <= n; i++) {
      result = `#{?#{&&:#{@prompt_line_${i}},#{e|<=|:#{@prompt_line_${i}},${cur}}},${i},${result}}`;
    }
    return result;
  }

  function updateTmuxPromptVars(tmuxBin: string): void {
    if (!process.env.TMUX) return;
    promptCount++;
    execFile(tmuxBin, ["display-message", "-p", "#{e|+|:#{e|+|:#{history_size},#{cursor_y}},1}"], (err, stdout) => {
      if (err || !stdout.trim()) return;
      const line = stdout.trim();
      execFile(tmuxBin, ["set", "-p", `@prompt_line_${promptCount}`, line], () => {});
      execFile(tmuxBin, ["set", "-p", "@prompt_total", String(promptCount)], () => {});
      if (promptCount > promptLookupMax) {
        const newMax = (Math.floor(promptCount / 50) + 1) * 50;
        execFile(tmuxBin, ["set", "-p", "@prompt_lookup_fmt", generateLookupFmt(newMax)], () => {});
        promptLookupMax = newMax;
      }
    });
  }

  function initTmuxPromptCount(tmuxBin: string): void {
    if (!process.env.TMUX) return;
    execFile(tmuxBin, ["display-message", "-p", "#{@prompt_total}"], (err, stdout) => {
      if (err) return;
      const total = parseInt(stdout.trim(), 10);
      if (!isNaN(total) && total > 0) {
        promptCount = total;
        promptLookupMax = (Math.floor(total / 50) + 1) * 50;
      }
    });
  }

  function hasRunningOperations(): boolean {
    const g = globalThis as any;
    if (typeof g.__piHasRunningSubagents === "function" && g.__piHasRunningSubagents()) return true;
    if (g.__piActiveChain && typeof g.__piHasRunningChain === "function" && g.__piHasRunningChain()) return true;
    if (g.__piActivePipeline && typeof g.__piHasRunningPipeline === "function" && g.__piHasRunningPipeline()) return true;
    if (typeof g.__piHasRunningTeam === "function" && g.__piHasRunningTeam()) return true;
    return false;
  }

  function cancelAll(ctx: any) {
    const g = globalThis as any;
    let cancelled = false;
    if (!ctx.isIdle()) { ctx.abort(); cancelled = true; }
    if (typeof g.__piKillAllSubagents === "function") { const k = g.__piKillAllSubagents(); if (k > 0) cancelled = true; }
    if (typeof g.__piKillChainProc === "function") { if (g.__piKillChainProc()) cancelled = true; }
    if (typeof g.__piKillPipelineProc === "function") { if (g.__piKillPipelineProc()) cancelled = true; }
    if (typeof g.__piKillTeamProcs === "function") { const k = g.__piKillTeamProcs(); if (k > 0) cancelled = true; }
    if (cancelled) ctx.ui.notify("All operations cancelled (ESC ESC)", "warning");
  }

  pi.on("user_bash", async () => {
    userBashRunning = true;
  });

  pi.on("agent_start", async (_event, ctx) => {
    userBashRunning = false;
    if (ctx.hasUI) ctx.ui.setStatus("esc-hint", "\x1b[2m ESC ESC to cancel\x1b[0m");
  });

  pi.on("agent_end", async (_event, ctx) => {
    userBashRunning = false;
    if (ctx.hasUI) ctx.ui.setStatus("esc-hint", undefined);
    if (settings) updateTmuxPromptVars(settings.tmux.binary);
  });

  pi.on("session_start", async (_event, ctx) => {
    if (!ctx.hasUI) return;
    lastEscTime = 0;

    if (!settings) settings = await loadSettings();
    initTmuxPromptCount(settings.tmux.binary);
    updateTmuxPromptVars(settings.tmux.binary);
    cursorInsert = settings.cursor.insert;
    cursorNormal = settings.cursor.normal;

    const t = ctx.ui.theme;
    const colorizers = t
      ? {
          insert: (s: string) => t.fg("borderMuted", `\x1b[7m${s}\x1b[27m`),
          normal: (s: string) => t.fg("borderAccent", `\x1b[7m${s}\x1b[27m`),
        }
      : null;

    const s = settings;
    const piCommands = collectPiCommands(pi);
    ctx.ui.setEditorComponent((tui, theme, kb) => {
      if (currentEditor) currentEditor.close();
      const editor = new NvimEditor(tui, theme, kb, colorizers, s, piCommands);
      currentEditor = editor;
      return editor;
    });

    currentCursorShape = cursorNormal;
    process.stdout.write(cursorNormal);
    process.stdout.write("\x1b[?1004h");

    if (inputUnsub) return;

    inputUnsub = ctx.ui.onTerminalInput((data: string) => {
      // Keys that pi's base editor consumes before our handleInput sees them.
      // Intercept here and forward to our editor directly.
      // Skip when an overlay is active (model picker, session picker, etc.)
      if (matchesKey(data, "backspace") || data === "\x7f" || data === "\x08"
        || matchesKey(data, "tab") || data === "\t"
        || matchesKey(data, "shift+tab")) {
        if (currentEditor && (currentEditor as any).focused) {
          currentEditor.handleInput(data);
          return { consume: true };
        }
      }

      if (data === "\x1b[I") {
        process.stdout.write(`\x1b[?25h${currentCursorShape}`);
        return { consume: true };
      }
      if (data === "\x1b[O") {
        process.stdout.write("\x1b[0 q\x1b[?25l"); // reset shape + hide
        return { consume: true };
      }

      // Ctrl+C: cancel agent/subagent operations if any are running,
      // then fall through to the editor's normal handling.
      if (matchesKey(data, "ctrl+c")) {
        const isIdle = ctx.isIdle();
        const hasOps = hasRunningOperations();
        if (!isIdle || hasOps) cancelAll(ctx);
        return undefined;
      }

      // ESC double-tap cancel (only in pure normal mode while something runs)
      if (matchesKey(data, "escape") || matchesKey(data, "ctrl+[")) {
        const editor = currentEditor;
        if (!editor) return undefined;
        if (!editor.isPureNormal()) {
          return undefined;
        }

        const isIdle = ctx.isIdle();
        const hasOps = hasRunningOperations();
        const somethingRunning = !isIdle || hasOps;
        if (!somethingRunning) return undefined;

        const doubleTapWindow = settings?.doubleTapEscTimeout ?? 400;
        const now = Date.now();
        if (now - lastEscTime < doubleTapWindow) {
          lastEscTime = 0;
          if (pendingEscTimer) { clearTimeout(pendingEscTimer); pendingEscTimer = null; }
          cancelAll(ctx);
          return { consume: true };
        }

        lastEscTime = now;
        if (pendingEscTimer) clearTimeout(pendingEscTimer);
        pendingEscTimer = setTimeout(() => { lastEscTime = 0; pendingEscTimer = null; }, doubleTapWindow);
        return { consume: true };
      }

      return undefined;
    });
  });

  pi.on("session_switch", async (_event, ctx) => {
    lastEscTime = 0;
    if (ctx.hasUI) ctx.ui.setStatus("esc-hint", undefined);
  });

  pi.on("session_shutdown", async () => {
    if (inputUnsub) { inputUnsub(); inputUnsub = null; }
    if (currentEditor) { currentEditor.close(); currentEditor = null; }
    lastEscTime = 0;
    process.stdout.write("\x1b[?1004l\x1b[?25h\x1b[2 q");
  });
}
