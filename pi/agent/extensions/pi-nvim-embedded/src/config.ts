import { existsSync } from "node:fs";
import { readFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import type { NvimEmbeddedConfigFile, NvimEmbeddedSettings } from "./types.js";

const extensionDir = dirname(fileURLToPath(import.meta.url));
const configPath = join(extensionDir, "..", "config.json");

const DEFAULT_DISABLED_KEYS = [":", "/", "?", "q:", "q/", "q?", "Q", "gQ", "q"];

const DEFAULT_PI_KEYS = ["ctrl+d", "ctrl+o", "alt+up", "alt+return", "ctrl+t", "ctrl+\\"];

const DEFAULT_TMUX_PANE_KEYS: Record<string, string[]> = {
  "ctrl+h": ["select-pane", "-L"],
  "ctrl+j": ["select-pane", "-D"],
  "ctrl+k": ["select-pane", "-U"],
  "ctrl+l": ["select-pane", "-R"],
  "alt+k": ["copy-mode", "-H", ";", "send-keys", "-X", "cursor-up"],
};

async function readConfigFile(): Promise<{ config: NvimEmbeddedConfigFile; error?: string }> {
  if (!existsSync(configPath)) return { config: {} };

  try {
    const raw = await readFile(configPath, "utf8");
    return { config: JSON.parse(raw) ?? {} };
  } catch (error) {
    return {
      config: {},
      error: error instanceof Error ? error.message : String(error),
    };
  }
}

export async function loadSettings(): Promise<NvimEmbeddedSettings> {
  const { config, error } = await readConfigFile();

  if (error) {
    console.error(`[pi-nvim-embedded] Failed to read config.json: ${error}`);
  }

  return {
    nvimBinary: config.nvimBinary ?? "nvim",
    nvimExtraArgs: config.nvimExtraArgs ?? [],
    timeoutlen: config.timeoutlen ?? 5,
    doubleTapEscTimeout: config.doubleTapEscTimeout ?? 400,
    disabledKeys: config.disabledKeys ?? DEFAULT_DISABLED_KEYS,
    enterOnEmptyLineSubmits: config.enterOnEmptyLineSubmits ?? true,
    enterInNormalSubmits: config.enterInNormalSubmits ?? true,
    historyNavigation: config.historyNavigation ?? true,
    tabTogglesPlanMode: config.tabTogglesPlanMode ?? true,
    tmux: {
      clipboard: config.tmux?.clipboard ?? true,
      binary: config.tmux?.binary ?? "tmux",
      paneKeys: config.tmux?.paneKeys ?? DEFAULT_TMUX_PANE_KEYS,
    },
    cursor: {
      insert: config.cursor?.insert ?? "\x1b[6 q",
      normal: config.cursor?.normal ?? "\x1b[2 q",
    },
    piKeys: config.piKeys ?? DEFAULT_PI_KEYS,
    nvimInitLua: config.nvimInitLua ?? [],
    borderChar: "borderChar" in config ? (config.borderChar?.length ? config.borderChar[0]! : null) : "-",
    maxCompletionItems: config.maxCompletionItems ?? 5,
  };
}
