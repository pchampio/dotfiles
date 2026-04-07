/**
 * Modal Editor - vim-like modal editing extension (vendored + borderless cursor)
 *
 * Vendored from npm:pi-vim v0.3.2 with:
 *   - Borderless cursor rendering (strips reverse-video, replaces ─ with -)
 *   - Hardware cursor shape per mode: bar (insert), block (normal), underline (replace)
 *   - Tmux focus reporting for cursor visibility
 *
 * Original usage: pi --extension ./index.ts
 *
 * - Escape / ctrl+[: insert → normal mode (in normal mode, aborts agent)
 * - i: normal → insert mode (at cursor)
 * - a: insert after cursor
 * - A: insert at end of line
 * - I: insert at start of line
 * - o: open new line below (insert mode)
 * - O: open new line above (insert mode)
 * - hjkl: navigation in normal mode
 * - 0/$: line start/end
 * - ^: first non-whitespace char of line
 * - _: first non-whitespace (with count: down count-1 lines first); linewise with d/c/y
 * - x: delete char under cursor
 * - D: delete to end of line
 * - S: substitute line (delete line content + insert mode)
 * - s: substitute char (delete char + insert mode)
 * - d{motion}: delete with motion (`w/b/e` + `W/B/E`, `$`, `0`, `^`, `dd`/`d_`, `f/t/F/T{char}`)
 * - c{motion}: change with same motion set as `d` (then enter insert mode)
 * - y{motion}: yank with same motion set as `d` (no text mutation)
 * - f{char}: jump to next {char} on line
 * - F{char}: jump to previous {char} on line
 * - t{char}: jump to just before next {char} on line
 * - T{char}: jump to just after previous {char} on line
 * - ;: repeat last f/F/t/T motion (same direction)
 * - ,: repeat last f/F/t/T motion (reverse direction)
 * - w/b/e: `word` motions (keyword/punctuation aware)
 * - W/B/E: `WORD` motions (whitespace-delimited non-space runs)
 * - {/}: paragraph motions to previous/next paragraph start (line start col 0)
 * - `{count}` prefixes supported for navigation, paragraph motions, and `d/c` word/WORD motions
 * - operator forms with braces (`d{`, `d}`, `c{`, `c}`, `y{`, `y}`) are out of scope
 * - counted yank caveat: `y2w`, `2yw`, `y2W`, `2yW` cancel (linewise counts still supported)
 * - Shift+Alt+A: go to end of line (insert mode shortcut)
 * - Shift+Alt+I: go to start of line (insert mode shortcut)
 * - Alt+o: open new line below (insert mode shortcut)
 * - Alt+Shift+o: open new line above (insert mode shortcut)
 * - u: undo (normal mode, sends ctrl+_ to underlying readline editor)
 * - ctrl+c, ctrl+d, etc. work in both modes
 *
 * Inspired by original repo:
 * - https://github.com/badlogic/pi-mono
 *   (packages/coding-agent/examples/extensions/modal-editor.ts)
 *
 * Additional ideas adapted from:
 * - https://github.com/l-lin/dotfiles
 *   (home-manager/modules/share/ai/pi/.pi/agent/extensions/vim-mode)
 */

import {
  copyToClipboard,
  CustomEditor,
  type ExtensionAPI,
} from "@mariozechner/pi-coding-agent";
import {
  Key,
  matchesKey,
  truncateToWidth,
  visibleWidth,
} from "@mariozechner/pi-tui";

import type {
  Mode,
  CharMotion,
  PendingMotion,
  PendingOperator,
  LastCharMotion,
} from "./types.js";
import {
  NORMAL_KEYS,
  CHAR_MOTION_KEYS,
  ESC_LEFT,
  ESC_RIGHT,
  ESC_UP,
  CTRL_A,
  CTRL_E,
  CTRL_K,
  CTRL_R,
  CTRL_UNDERSCORE,
  NEWLINE,
  ESC_DOWN,
} from "./types.js";
import {
  reverseCharMotion,
  findCharMotionTarget,
  findParagraphMotionTarget,
  findFirstNonWhitespaceColumn,
  getLineGraphemes,
  type WordMotionClass,
} from "./motions.js";
import {
  WordBoundaryCache,
  type WordMotionDirection,
  type WordMotionTarget,
} from "./word-boundary-cache.js";

/** Lines containing more than 5 ─ characters are border lines */
const IS_BORDER_LINE = /^([^─]*─){6,}/;

/**
 * Full software cursor pattern emitted by the base Editor:
 *   \x1b[7m<char>\x1b[0m   (cursor on a character)
 *   \x1b[7m \x1b[0m        (cursor at end of line — space placeholder)
 * We strip the entire pattern, keeping just the character ($1).
 * This avoids leaving a dangling \x1b[0m reset that can cause
 * visible artefacts in some terminals.
 */
const SOFTWARE_CURSOR = /\x1b\[7m(.)\x1b\[0m/g;
/** Fallback: strip any remaining standalone reverse-video-on */
const REVERSE_ON = /\x1b\[7m/g;

/** Hardware cursor shapes */
const CURSOR_BAR = "\x1b[6 q";       // steady bar  — insert mode
const CURSOR_BLOCK = "\x1b[2 q";     // steady block — normal mode
const CURSOR_UNDERLINE = "\x1b[4 q"; // steady underline — replace pending

/** Module-level cursor shape tracker for focus restore */
let currentCursorShape = CURSOR_BAR;

const BRACKETED_PASTE_START = "\x1b[200~";
const BRACKETED_PASTE_END = "\x1b[201~";
const BRACKETED_PASTE_END_TAIL = BRACKETED_PASTE_END.slice(1);
const MAX_COUNT = 9999;

type EditorSnapshot = {
  text: string;
  cursor: { line: number; col: number };
};

type TransitionState = "none" | "undo" | "redo";

type ModalEditorInternals = {
  state?: { lines?: string[]; cursorLine?: number; cursorCol?: number };
  preferredVisualCol?: number | null;
  lastAction?: string | null;
  historyIndex?: number;
  onChange?: (text: string) => void;
  tui?: { requestRender?: () => void };
  pushUndoSnapshot?: () => void;
  setCursorCol?: (col: number) => void;
};

export class ModalEditor extends CustomEditor {
  private mode: Mode = "insert";
  private pendingMotion: PendingMotion = null;
  private pendingTextObject: "i" | "a" | null = null;
  private pendingOperator: PendingOperator = null;
  private prefixCount: string = "";
  private operatorCount: string = "";
  private pendingG: boolean = false;
  private pendingGCount: string = "";
  private lastCharMotion: LastCharMotion | null = null;
  private visualAnchor: { line: number; col: number } | null = null;
  private lastKnownWidth: number = 80;
  private preferredDisplayCol: number | null = null;
  private savedPromptBeforeHistory: string | null = null;
  private discardingBracketedPasteInNormalMode: boolean = false;
  private pendingEscWhileDiscardingBracketedPasteInNormalMode: boolean = false;
  private wordBoundaryCache = new WordBoundaryCache();
  private readonly redoStack: EditorSnapshot[] = [];
  private currentTransition: TransitionState = "none";
  private onChangeHooked: boolean = false;
  private readonly labelColorizers: { insert: (s: string) => string; normal: (s: string) => string; visual?: (s: string) => string } | null;

  // Unnamed register
  private unnamedRegister: string = "";
  private clipboardFn: (text: string) => Promise<void> = async (text: string) => {
    await copyToClipboard(text);
  };

  constructor(
    tui: any,
    theme: any,
    kb: any,
    labelColorizers?: { insert: (s: string) => string; normal: (s: string) => string; visual?: (s: string) => string } | null,
  ) {
    super(tui, theme, kb);
    this.labelColorizers = labelColorizers ?? null;
  }

  // Test seams
  setClipboardFn(fn: (text: string) => unknown): void {
    this.clipboardFn = async (text: string) => {
      await fn(text);
    };
  }
  getRegister(): string { return this.unnamedRegister; }
  setRegister(text: string): void { this.unnamedRegister = text; }
  getMode(): Mode { return this.mode; }
  getText(): string { return this.getLines().join("\n"); }

  override setText(text: string): void {
    this.clearRedoStack();
    super.setText(text);
  }

  private captureSnapshot(): EditorSnapshot {
    const cursor = this.getCursor();
    return {
      text: this.getText(),
      cursor: { line: cursor.line, col: cursor.col },
    };
  }

  private requireRedoRestoreState(
    editor: ModalEditorInternals,
  ): { lines: string[]; cursorLine?: number; cursorCol?: number } {
    const state = editor.state;
    if (!state || !Array.isArray(state.lines)) {
      throw new Error("Redo restore prerequisite: editor state unavailable");
    }
    return state as { lines: string[]; cursorLine?: number; cursorCol?: number };
  }

  private restoreSnapshot(snapshot: EditorSnapshot): void {
    const editor = this as unknown as ModalEditorInternals;
    const state = this.requireRedoRestoreState(editor);

    const lines = snapshot.text.split("\n");
    state.lines = lines.length > 0 ? lines : [""];

    const maxLine = Math.max(0, state.lines.length - 1);
    const cursorLine = Math.max(0, Math.min(snapshot.cursor.line, maxLine));
    const line = state.lines[cursorLine] ?? "";
    const cursorCol = Math.max(0, Math.min(snapshot.cursor.col, line.length));

    state.cursorLine = cursorLine;
    if (typeof editor.setCursorCol === "function") {
      editor.setCursorCol(cursorCol);
    } else {
      state.cursorCol = cursorCol;
      editor.preferredVisualCol = null;
    }

    this.invalidateWordBoundaryCache();

    editor.historyIndex = -1;
    editor.lastAction = null;
    editor.onChange?.(this.getText());
    editor.tui?.requestRender?.();
  }

  private snapshotChanged(a: EditorSnapshot, b: EditorSnapshot): boolean {
    return a.text !== b.text
      || a.cursor.line !== b.cursor.line
      || a.cursor.col !== b.cursor.col;
  }

  private withTransition<T>(
    transition: Exclude<TransitionState, "none">,
    action: () => T,
  ): T {
    const previousTransition = this.currentTransition;
    this.currentTransition = transition;
    try {
      return action();
    } finally {
      this.currentTransition = previousTransition;
    }
  }

  private performUndo(count: number = this.takeTotalCount(1)): void {
    const maxSteps = Math.max(1, Math.min(MAX_COUNT, count));
    for (let i = 0; i < maxSteps; i++) {
      let changed = false;
      this.withTransition("undo", () => {
        const beforeUndo = this.captureSnapshot();
        super.handleInput(CTRL_UNDERSCORE);
        const afterUndo = this.captureSnapshot();

        if (this.snapshotChanged(beforeUndo, afterUndo)) {
          this.redoStack.push(beforeUndo);
          changed = true;
        }
      });
      if (!changed) break;
    }
  }

  private performRedo(count: number = this.takeTotalCount(1)): void {
    const maxSteps = Math.max(1, Math.min(MAX_COUNT, count));
    const editor = this as unknown as ModalEditorInternals;

    for (let i = 0; i < maxSteps; i++) {
      const snapshot = this.redoStack[this.redoStack.length - 1];
      if (!snapshot) break;

      this.withTransition("redo", () => {
        this.requireRedoRestoreState(editor);
        if (typeof editor.pushUndoSnapshot !== "function") {
          throw new Error(
            "Redo restore prerequisite: pushUndoSnapshot unavailable",
          );
        }
        editor.pushUndoSnapshot();
        this.restoreSnapshot(snapshot);
        this.redoStack.pop();
      });
    }
  }

  private clearRedoStack(): void {
    this.redoStack.length = 0;
  }

  private invalidateWordBoundaryCache(): void {
    this.wordBoundaryCache = new WordBoundaryCache();
  }

  private ensureOnChangeHook(): void {
    if (this.onChangeHooked) return;

    const editor = this as unknown as ModalEditorInternals;
    const originalOnChange = editor.onChange;

    editor.onChange = (text: string) => {
      originalOnChange?.(text);
      this.centralInvalidationCheck();
    };

    this.onChangeHooked = true;
  }

  private centralInvalidationCheck(): void {
    if (this.redoStack.length === 0) return;
    if (this.currentTransition !== "none") return;
    this.clearRedoStack();
  }

  private applySyntheticEdit(mutation: () => void): void {
    const editor = this as unknown as ModalEditorInternals;
    if (!editor.state || !Array.isArray(editor.state.lines)) {
      throw new Error(
        "Synthetic edit prerequisite: editor state unavailable",
      );
    }

    if (typeof editor.pushUndoSnapshot !== "function") {
      throw new Error(
        "Synthetic edit prerequisite: pushUndoSnapshot unavailable",
      );
    }

    const textBefore = this.getText();
    const preCursorLine = editor.state.cursorLine;
    const preCursorCol = editor.state.cursorCol;

    mutation();

    if (this.getText() === textBefore) return;

    // Text changed — push undo boundary for pre-mutation state.
    // Briefly swap pre-mutation state in for the snapshot, then
    // restore the post-mutation result.
    const postLines = editor.state.lines.slice();
    const postCursorLine = editor.state.cursorLine;
    const postCursorCol = editor.state.cursorCol;
    const postPreferredCol = editor.preferredVisualCol;

    const preLines = textBefore.split("\n");
    editor.state.lines = preLines.length > 0 ? preLines : [""];
    editor.state.cursorLine = preCursorLine;
    editor.state.cursorCol = preCursorCol;
    editor.pushUndoSnapshot();

    editor.state.lines = postLines;
    editor.state.cursorLine = postCursorLine;
    editor.state.cursorCol = postCursorCol;
    editor.preferredVisualCol = postPreferredCol;

    editor.onChange?.(this.getText());
    editor.tui?.requestRender?.();
  }

  private clearPendingState(): void {
    this.pendingMotion = null;
    this.pendingTextObject = null;
    this.pendingOperator = null;
    this.prefixCount = "";
    this.operatorCount = "";
    this.pendingG = false;
    this.pendingGCount = "";
  }

  private isEscapeLikeInput(data: string): boolean {
    return matchesKey(data, "escape") || matchesKey(data, "ctrl+[");
  }

  private stripBracketedPasteInNormalMode(data: string): { filtered: string | null; stripped: boolean } {
    let chunk = data;
    let stripped = false;

    while (true) {
      if (this.discardingBracketedPasteInNormalMode) {
        stripped = true;
        const end = chunk.indexOf(BRACKETED_PASTE_END);
        if (end === -1) {
          return { filtered: null, stripped };
        }
        this.discardingBracketedPasteInNormalMode = false;
        this.pendingEscWhileDiscardingBracketedPasteInNormalMode = false;
        chunk = chunk.slice(end + BRACKETED_PASTE_END.length);
        if (!chunk) return { filtered: null, stripped };
      }

      const start = chunk.indexOf(BRACKETED_PASTE_START);
      if (start === -1) {
        return { filtered: chunk, stripped };
      }

      stripped = true;
      const end = chunk.indexOf(BRACKETED_PASTE_END, start + BRACKETED_PASTE_START.length);
      if (end === -1) {
        this.discardingBracketedPasteInNormalMode = true;
        const leading = chunk.slice(0, start);
        return { filtered: leading.length > 0 ? leading : null, stripped };
      }

      chunk = chunk.slice(0, start) + chunk.slice(end + BRACKETED_PASTE_END.length);
      if (!chunk) return { filtered: null, stripped };
    }
  }

  /**
   * In normal mode, clamp cursor to the last character on the line
   * (vim-style: cursor sits ON a character, never past it).
   * Empty lines keep col 0. Insert mode is unclamped.
   */
  private clampCursorForNormalMode(): void {
    if (this.mode === "insert") return;

    const editor = this as unknown as {
      state?: { lines?: string[]; cursorLine?: number; cursorCol?: number };
      preferredVisualCol?: number | null;
      tui?: { requestRender?: () => void };
    };

    const state = editor.state;
    if (!state || !Array.isArray(state.lines)) return;

    const cursorLine = state.cursorLine ?? 0;
    const line = state.lines[cursorLine] ?? "";
    const maxCol = Math.max(0, line.length - 1);
    const cursorCol = state.cursorCol ?? 0;

    if (cursorCol > maxCol) {
      state.cursorCol = maxCol;
      editor.preferredVisualCol = maxCol;
    }
  }

  /** Emit hardware cursor shape matching the current vim mode */
  private emitCursorShape(): void {
    const shape = this.mode === "insert" ? CURSOR_BAR
      : CURSOR_BLOCK; // normal, visual, visual-line all use block
    currentCursorShape = shape;
    process.stdout.write(shape);
  }

  handleInput(data: string): void {
    try {
    this.ensureOnChangeHook();

    if (this.mode !== "insert") {
      if (this.discardingBracketedPasteInNormalMode) {
        if (this.isEscapeLikeInput(data)) {
          if (this.pendingEscWhileDiscardingBracketedPasteInNormalMode) {
            this.pendingEscWhileDiscardingBracketedPasteInNormalMode = false;
            this.discardingBracketedPasteInNormalMode = false;
            this.clearPendingState();
            return;
          } else {
            this.pendingEscWhileDiscardingBracketedPasteInNormalMode = true;
            this.clearPendingState();
            return;
          }
        } else if (this.pendingEscWhileDiscardingBracketedPasteInNormalMode) {
          if (data.startsWith(BRACKETED_PASTE_END_TAIL)) {
            this.pendingEscWhileDiscardingBracketedPasteInNormalMode = false;
            this.discardingBracketedPasteInNormalMode = false;
            data = data.slice(BRACKETED_PASTE_END_TAIL.length);
            if (data.length === 0) {
              this.clearPendingState();
              return;
            }
          } else {
            this.pendingEscWhileDiscardingBracketedPasteInNormalMode = false;
          }
        }
      }

      const { filtered, stripped } = this.stripBracketedPasteInNormalMode(data);
      if (stripped) {
        this.clearPendingState();
      }
      if (filtered === null) return;
      data = filtered;
    }

    if (this.isEscapeLikeInput(data)) {
      return this.handleEscape();
    }

    if (this.mode === "insert") {
      // Shift+Alt+A: go to end of line (like Esc -> A but stay in insert)
      if (matchesKey(data, Key.shiftAlt("a")) || data === "\x1bA") {
        return super.handleInput(CTRL_E);
      }
      // Shift+Alt+I: go to start of line (like Esc -> I but stay in insert)
      if (matchesKey(data, Key.shiftAlt("i")) || data === "\x1bI") {
        return super.handleInput(CTRL_A);
      }
      // Alt+o: open new line below (stay in insert mode)
      if (matchesKey(data, Key.alt("o")) || data === "\x1bo") {
        this.openLineBelow();
        return;
      }
      // Alt+Shift+o: open new line above (stay in insert mode)
      // \x1bO is the legacy sequence for Alt+Shift+O (VT100 SS3 prefix in non-Kitty terminals)
      if (matchesKey(data, Key.shiftAlt("o")) || data === "\x1bO") {
        this.openLineAbove();
        return;
      }
      // Alt+Enter: insert newline (stay in insert mode)
      if (matchesKey(data, "alt+enter") || matchesKey(data, "alt+return")) {
        super.handleInput(NEWLINE);
        return;
      }
      super.handleInput(data);
      return;
    }

    if (this.pendingTextObject) {
      return this.handlePendingTextObject(data);
    }

    if (this.pendingMotion) {
      return this.handlePendingMotion(data);
    }

    if (this.pendingOperator === "d") {
      return this.handlePendingDelete(data);
    }

    if (this.pendingOperator === "c") {
      return this.handlePendingChange(data);
    }

    if (this.pendingOperator === "y") {
      return this.handlePendingYank(data);
    }

    if (this.pendingOperator === "r") {
      return this.handlePendingReplaceWithRegister(data);
    }

    if (this.mode === "visual" || this.mode === "visual-line") {
      return this.handleVisualMode(data);
    }

    this.handleNormalMode(data);
    } finally {
      this.clampCursorForNormalMode();
      this.emitCursorShape();
    }
  }

  private clearUnderlyingPasteStateIfActive(): void {
    const editor = this as unknown as {
      isInPaste?: boolean;
      pasteBuffer?: string;
      pasteCounter?: number;
    };

    if (!editor.isInPaste) return;

    editor.isInPaste = false;
    if (typeof editor.pasteBuffer === "string") {
      editor.pasteBuffer = "";
    }
    if (typeof editor.pasteCounter === "number") {
      editor.pasteCounter = 0;
    }
  }

  private handleEscape(): void {
    if (
      this.pendingMotion
      || this.pendingTextObject
      || this.pendingOperator
      || this.prefixCount
      || this.operatorCount
      || this.pendingG
      || this.pendingGCount
    ) {
      this.clearPendingState();
      return;
    }
    if (this.mode === "visual" || this.mode === "visual-line") {
      this.visualAnchor = null;
      this.mode = "normal";
      return;
    }
    if (this.mode === "insert") {
      this.clearUnderlyingPasteStateIfActive();
      this.mode = "normal";
    } else {
      super.handleInput("\x1b"); // pass escape to abort agent
    }
  }

  private isPrintableChunk(data: string): boolean {
    if (data.length === 0) return false;
    for (const char of data) {
      const codePoint = char.codePointAt(0)!;
      if (codePoint < 32 || codePoint === 127) return false;
    }
    return true;
  }

  private isPrintableInput(data: string): boolean {
    return this.isPrintableChunk(data) && getLineGraphemes(data).length === 1;
  }

  private isDigit(data: string): boolean {
    return data.length === 1 && data >= "0" && data <= "9";
  }

  private isCountStarter(data: string): boolean {
    return data.length === 1 && data >= "1" && data <= "9";
  }

  private takeTotalCount(defaultValue: number = 1): number {
    const prefixRaw = this.prefixCount;
    const operatorRaw = this.operatorCount;
    this.prefixCount = "";
    this.operatorCount = "";

    if (!prefixRaw && !operatorRaw) return defaultValue;

    const parse = (raw: string): number | null => {
      if (!raw) return null;
      const parsed = Number.parseInt(raw, 10);
      if (!Number.isFinite(parsed) || parsed <= 0) return null;
      return parsed;
    };

    const prefix = parse(prefixRaw);
    const operator = parse(operatorRaw);

    if (prefix === null && operator === null) return defaultValue;

    const total = prefix !== null && operator !== null
      ? prefix * operator
      : prefix ?? operator ?? defaultValue;

    if (!Number.isFinite(total) || total <= 0) return defaultValue;
    return Math.min(MAX_COUNT, total);
  }

  private cancelPendingOperator(data: string): void {
    this.pendingOperator = null;
    this.prefixCount = "";
    this.operatorCount = "";
    if (!this.isPrintableChunk(data)) {
      super.handleInput(data);
    }
  }

  private handlePendingMotion(data: string): void {
    if (!this.isPrintableInput(data)) {
      this.pendingMotion = null;
      this.cancelPendingOperator(data);
      return;
    }

    if (this.pendingOperator === "d") {
      this.deleteWithCharMotion(this.pendingMotion!, data);
      this.pendingOperator = null;
    } else if (this.pendingOperator === "c") {
      this.deleteWithCharMotion(this.pendingMotion!, data);
      this.pendingOperator = null;
      this.mode = "insert";
    } else if (this.pendingOperator === "y") {
      this.yankWithCharMotion(this.pendingMotion!, data);
      this.pendingOperator = null;
    } else if (this.pendingOperator === "r") {
      this.replaceWithCharMotion(this.pendingMotion!, data);
      this.pendingOperator = null;
    } else {
      this.executeCharMotion(this.pendingMotion!, data);
    }

    this.pendingMotion = null;
  }

  private handlePendingTextObject(data: string): void {
    if (data !== "w") {
      this.pendingTextObject = null;
      this.cancelPendingOperator(data);
      return;
    }

    const count = this.takeTotalCount(1);
    const range = this.getWordObjectRange(this.pendingTextObject!, count);
    this.pendingTextObject = null;
    if (!range || !this.pendingOperator) {
      this.pendingOperator = null;
      return;
    }

    const { startAbs, endAbs } = range;
    if (this.pendingOperator === "d") {
      this.deleteRangeByAbsolute(startAbs, endAbs);
      this.pendingOperator = null;
      return;
    }

    if (this.pendingOperator === "c") {
      this.deleteRangeByAbsolute(startAbs, endAbs);
      this.pendingOperator = null;
      this.mode = "insert";
      return;
    }

    if (this.pendingOperator === "y") {
      this.yankRangeByAbsolute(startAbs, endAbs);
      this.pendingOperator = null;
      return;
    }

    if (this.pendingOperator === "r") {
      this.replaceRangeWithRegister(startAbs, endAbs);
      this.pendingOperator = null;
      return;
    }

    this.pendingOperator = null;
  }

  private handlePendingDelete(data: string): void {
    if (this.isDigit(data)) {
      if (this.operatorCount.length === 0) {
        if (data !== "0") {
          this.operatorCount = data;
          return;
        }
      } else {
        this.operatorCount += data;
        return;
      }
    }

    if (data === "d") {
      const count = this.takeTotalCount(1);
      this.deleteLinewiseByDelta(count - 1);
      this.pendingOperator = null;
      return;
    }

    if (data === "j" || data === "k") {
      const hasDualCount = this.prefixCount.length > 0 && this.operatorCount.length > 0;
      const count = this.takeTotalCount(1);
      const delta = hasDualCount ? Math.max(0, count - 1) : count;
      this.deleteLinewiseByDelta(data === "j" ? delta : -delta);
      this.pendingOperator = null;
      return;
    }

    if (data === "G") {
      if (this.prefixCount.length > 0 || this.operatorCount.length > 0) {
        this.cancelPendingOperator(data);
        return;
      }

      this.deleteToBufferEndLinewise();
      this.pendingOperator = null;
      return;
    }

    if (data === "_") {
      const count = this.takeTotalCount(1);
      this.deleteLinewiseByDelta(count - 1);
      this.pendingOperator = null;
      return;
    }

    if (CHAR_MOTION_KEYS.has(data)) {
      this.pendingMotion = data as PendingMotion;
      return;
    }

    const hasCount = this.prefixCount.length > 0 || this.operatorCount.length > 0;
    const supportsCountedWordMotion = (
      data === "w"
      || data === "e"
      || data === "b"
      || data === "W"
      || data === "E"
      || data === "B"
    );
    const supportsCountedTextObject = data === "i" || data === "a";

    if (hasCount && !supportsCountedWordMotion && !supportsCountedTextObject) {
      // Counted forms beyond dd, d{count}j/k, d{count}{f/F/t/T}, and
      // d{count}{w/e/b/W/E/B}/{i/a}w are out of scope.
      this.cancelPendingOperator(data);
      return;
    }

    if (supportsCountedTextObject) {
      this.pendingTextObject = data;
      return;
    }

    const motionCount = supportsCountedWordMotion ? this.takeTotalCount(1) : 1;
    if (this.deleteWithMotion(data, motionCount)) {
      this.pendingOperator = null;
      return;
    }

    // Invalid motion: cancel operator to avoid sticky surprising deletes.
    this.cancelPendingOperator(data);
  }

  private handlePendingChange(data: string): void {
    if (this.isDigit(data)) {
      if (this.operatorCount.length === 0) {
        if (data !== "0") {
          this.operatorCount = data;
          return;
        }
      } else {
        this.operatorCount += data;
        return;
      }
    }

    if (data === "c") {
      if (this.prefixCount.length > 0 || this.operatorCount.length > 0) {
        this.cancelPendingOperator(data);
        return;
      }

      this.cutLine();
      this.pendingOperator = null;
      this.mode = "insert";
      return;
    }

    if (data === "j" || data === "k") {
      const hasDualCount = this.prefixCount.length > 0 && this.operatorCount.length > 0;
      const count = this.takeTotalCount(1);
      const delta = hasDualCount ? Math.max(0, count - 1) : count;
      const currentLine = this.getCursor().line;
      const lines = this.getLines();
      const targetLine = data === "j"
        ? Math.min(currentLine + delta, lines.length - 1)
        : Math.max(currentLine - delta, 0);
      const startLine = Math.min(currentLine, targetLine);
      const endLine = Math.max(currentLine, targetLine);
      // Change linewise: delete lines and enter insert on empty line
      this.writeToRegister(this.getLinewisePayload(startLine, endLine));
      const before = lines.slice(0, startLine);
      const after = lines.slice(endLine + 1);
      const newLines = [...before, "", ...after];
      const newText = newLines.join("\n");
      const cursorAbs = before.reduce((acc, l) => acc + l.length + 1, 0);
      this.replaceTextInBuffer(newText, cursorAbs);
      this.pendingOperator = null;
      this.mode = "insert";
      return;
    }

    if (data === "G") {
      if (this.prefixCount.length > 0 || this.operatorCount.length > 0) {
        this.cancelPendingOperator(data);
        return;
      }

      const currentLine = this.getCursor().line;
      const lines = this.getLines();
      const endLine = lines.length - 1;
      this.writeToRegister(this.getLinewisePayload(currentLine, endLine));
      const before = lines.slice(0, currentLine);
      const newLines = [...before, ""];
      const newText = newLines.join("\n");
      const cursorAbs = before.reduce((acc, l) => acc + l.length + 1, 0);
      this.replaceTextInBuffer(newText, cursorAbs);
      this.pendingOperator = null;
      this.mode = "insert";
      return;
    }

    if (data === "_") {
      const count = this.takeTotalCount(1);
      if (count <= 1) {
        this.cutLine();
      } else {
        const currentLine = this.getCursor().line;
        const lines = this.getLines();
        const clampedEnd = Math.min(currentLine + count - 1, lines.length - 1);
        this.writeToRegister(this.getLinewisePayload(currentLine, clampedEnd));
        const before = lines.slice(0, currentLine);
        const after = lines.slice(clampedEnd + 1);
        const newLines = [...before, "", ...after];
        const newText = newLines.join("\n");
        const cursorAbs = before.reduce((acc, l) => acc + l.length + 1, 0);
        this.replaceTextInBuffer(newText, cursorAbs);
      }
      this.pendingOperator = null;
      this.mode = "insert";
      return;
    }

    if (CHAR_MOTION_KEYS.has(data)) {
      this.pendingMotion = data as PendingMotion;
      return;
    }

    const hasCount = this.prefixCount.length > 0 || this.operatorCount.length > 0;
    const supportsCountedWordMotion = (
      data === "w"
      || data === "e"
      || data === "b"
      || data === "W"
      || data === "E"
      || data === "B"
    );
    const supportsCountedTextObject = data === "i" || data === "a";

    if (hasCount && !supportsCountedWordMotion && !supportsCountedTextObject) {
      this.cancelPendingOperator(data);
      return;
    }

    if (supportsCountedTextObject) {
      this.pendingTextObject = data;
      return;
    }

    const motionCount = supportsCountedWordMotion ? this.takeTotalCount(1) : 1;
    const effectiveMotion = data === "W" && this.isCursorOnNonWhitespace()
      ? "E"
      : data;
    if (this.deleteWithMotion(effectiveMotion, motionCount)) {
      this.pendingOperator = null;
      this.mode = "insert";
      return;
    }

    // Invalid motion: cancel operator to avoid sticky surprising changes.
    this.cancelPendingOperator(data);
  }

  private handleNormalMode(data: string): void {
    if (this.pendingG) {
      if (this.isDigit(data)) {
        this.pendingGCount += data;
        return;
      }

      this.pendingG = false;
      const hadGCount = this.pendingGCount.length > 0;
      this.pendingGCount = "";

      if (!hadGCount) {
        if (data === "g") {
          const count = this.takeTotalCount(1);
          this.moveCursorToLineStart(count - 1);
          return;
        }

        if (data === "J") {
          this.joinLines(false);
          return;
        }
      }

      this.clearPendingState();
      return;
    }

    if (this.prefixCount.length > 0) {
      if (this.isDigit(data)) {
        this.prefixCount += data;
        return;
      }

      if (data === "d" || data === "y") {
        this.pendingOperator = data;
        return;
      }

      if (data === "c") {
        this.pendingOperator = "c";
        return;
      }

      if (data === "g") {
        this.pendingGCount = "";
        this.pendingG = true;
        return;
      }

      if (data === "G") {
        const count = this.takeTotalCount(1);
        this.moveCursorToLineStart(count - 1);
        return;
      }

      const supportsCountedStandaloneEdit = (
        data === "x"
        || data === "s"
        || data === "S"
        || data === "D"
        || data === "C"
        || data === "p"
        || data === "P"
        || data === "Y"
        || data === "u"
        || data === CTRL_UNDERSCORE
        || matchesKey(data, "ctrl+_")
        || data === CTRL_R
        || matchesKey(data, "ctrl+r")
      );
      const supportsCountedCharMotion = (
        CHAR_MOTION_KEYS.has(data)
        || data === ";"
        || data === ","
      );
      const supportsCountedWordMotion = (
        data === "w"
        || data === "e"
        || data === "b"
        || data === "W"
        || data === "E"
        || data === "B"
      );
      const supportsCountedParagraphMotion = data === "{" || data === "}";
      const supportsCountedNav = (
        data === "h"
        || data === "j"
        || data === "k"
        || data === "l"
      );
      const supportsCountedUnderscore = data === "_";

      if (supportsCountedNav) {
        const count = this.takeTotalCount(1);
        const clamped = Math.min(count, MAX_COUNT);
        if (data === "h") {
          this.moveCursorBy(-clamped);
        } else if (data === "l") {
          this.moveCursorBy(clamped);
        } else {
          const delta = data === "j" ? clamped : -clamped;
          this.moveCursorVertically(delta);
        }
        return;
      }

      if (supportsCountedParagraphMotion) {
        this.executeParagraphMotion(data === "}" ? "forward" : "backward");
        return;
      }

      if (
        !supportsCountedStandaloneEdit
        && !supportsCountedCharMotion
        && !supportsCountedWordMotion
        && !supportsCountedParagraphMotion
        && !supportsCountedUnderscore
      ) {
        // Unsupported prefixed forms: drop count and keep processing this key.
        this.prefixCount = "";
        this.operatorCount = "";
      }
    } else if (this.isCountStarter(data)) {
      this.prefixCount = data;
      return;
    }

    if (data === "J") {
      this.navigateHistoryVim(1);
      return;
    }

    if (data === "K") {
      this.navigateHistoryVim(-1);
      return;
    }

    if (data === "g") {
      this.pendingGCount = "";
      this.pendingG = true;
      return;
    }

    if (data === "G") {
      this.moveCursorToBufferEnd();
      return;
    }

    if (data === "v") {
      this.enterVisualMode("visual");
      return;
    }

    if (data === "V") {
      this.enterVisualMode("visual-line");
      return;
    }

    if (data === "r") {
      this.pendingOperator = "r";
      return;
    }

    if (data === "d") {
      this.pendingOperator = "d";
      return;
    }

    if (data === "c") {
      this.pendingOperator = "c";
      return;
    }

    if (data === "y") {
      this.pendingOperator = "y";
      return;
    }

    if (data === "p") {
      this.putAfter();
      return;
    }

    if (data === "P") {
      this.putBefore();
      return;
    }

    if (data === "Y") {
      const count = this.takeTotalCount(1);
      this.yankLinewiseByDelta(count - 1);
      return;
    }

    if (CHAR_MOTION_KEYS.has(data)) {
      this.pendingMotion = data as PendingMotion;
      return;
    }

    if (data === ";" && this.lastCharMotion) {
      this.executeCharMotion(this.lastCharMotion.motion, this.lastCharMotion.char, false);
      return;
    }
    if (data === "," && this.lastCharMotion) {
      this.executeCharMotion(
        reverseCharMotion(this.lastCharMotion.motion),
        this.lastCharMotion.char,
        false,
      );
      return;
    }

    if (data === "u" || data === CTRL_UNDERSCORE || matchesKey(data, "ctrl+_")) {
      this.performUndo();
      return;
    }

    if (data === CTRL_R || matchesKey(data, "ctrl+r")) {
      this.performRedo();
      return;
    }

    if (data === "}" || data === "{") {
      this.executeParagraphMotion(data === "}" ? "forward" : "backward");
      return;
    }

    if (data === "^") {
      this.moveCursorToFirstNonWhitespace();
      return;
    }

    if (data === "_") {
      const count = this.takeTotalCount(1);
      if (count > 1) {
        this.moveCursorVertically(count - 1);
      }
      this.moveCursorToFirstNonWhitespace();
      return;
    }

    if (data === "w") {
      const count = this.takeTotalCount(1);
      return this.moveWord("forward", "start", count, "word");
    }
    if (data === "b") return this.moveWord("backward", "start", this.takeTotalCount(1), "word");
    if (data === "e") return this.moveWord("forward", "end", this.takeTotalCount(1), "word");
    if (data === "W") return this.moveWord("forward", "start", this.takeTotalCount(1), "WORD");
    if (data === "B") return this.moveWord("backward", "start", this.takeTotalCount(1), "WORD");
    if (data === "E") return this.moveWord("forward", "end", this.takeTotalCount(1), "WORD");

    if (Object.hasOwn(NORMAL_KEYS, data)) {
      return this.handleMappedKey(data);
    }

    // Alt+Enter: insert newline (stay in normal mode)
    if (matchesKey(data, "alt+enter") || matchesKey(data, "alt+return")) {
      this.openLineBelow();
      return;
    }

    // Pass control sequences (ctrl+c, etc.) to super, ignore printable chars
    if (this.isPrintableChunk(data)) return;
    super.handleInput(data);
  }

  private openLineBelow(): void {
    super.handleInput(CTRL_E);
    super.handleInput(NEWLINE);
  }

  private openLineAbove(): void {
    super.handleInput(CTRL_A);
    super.handleInput(NEWLINE);
    super.handleInput(ESC_UP);
  }

  private handleMappedKey(key: string): void {
    const seq = NORMAL_KEYS[key];
    switch (key) {
      case "i":
        this.mode = "insert";
        break;
      case "a":
        this.mode = "insert";
        if (!this.isCursorAtOrPastEol()) {
          super.handleInput(ESC_RIGHT);
        }
        break;
      case "A":
        this.mode = "insert";
        super.handleInput(CTRL_E);
        break;
      case "I":
        this.mode = "insert";
        this.moveCursorToFirstNonWhitespace();
        break;
      case "o":
        this.openLineBelow();
        this.mode = "insert";
        break;
      case "O":
        this.openLineAbove();
        this.mode = "insert";
        break;
      case "D":
        this.takeTotalCount(1);
        this.cutToEndOfLine();
        break;
      case "C":
        this.takeTotalCount(1);
        this.cutToEndOfLine();
        this.mode = "insert";
        break;
      case "S":
        this.takeTotalCount(1);
        this.cutCurrentLineContent();
        this.mode = "insert";
        break;
      case "s":
        this.cutCharUnderCursor();
        this.mode = "insert";
        break;
      case "x":
        this.cutCharUnderCursor();
        break;
      case "j":
        this.moveCursorVertically(1);
        break;
      case "k":
        this.moveCursorVertically(-1);
        break;
      default:
        this.preferredDisplayCol = null;
        if (seq) super.handleInput(seq);
    }
  }

  private executeCharMotion(motion: CharMotion, targetChar: string, saveMotion: boolean = true): void {
    const line = this.getLines()[this.getCursor().line] ?? "";
    const col = this.getCursor().col;
    const count = this.takeTotalCount(1);
    const targetCol = findCharMotionTarget(line, col, motion, targetChar, !saveMotion, count);

    if (targetCol !== null && saveMotion) {
      this.lastCharMotion = { motion, char: targetChar };
    }

    if (targetCol !== null && targetCol !== col) {
      this.moveCursorToCol(targetCol);
    }
  }

  private executeParagraphMotion(direction: "forward" | "backward"): void {
    const lines = this.getLines();
    const fromLine = this.getCursor().line;
    const count = this.takeTotalCount(1);
    const targetLine = findParagraphMotionTarget(lines, fromLine, direction, count);
    this.moveCursorToLineStart(targetLine);
  }

  private tryMoveCursorByState(delta: number): boolean {
    if (delta === 0) return true;

    const editor = this as unknown as {
      state?: { lines?: string[]; cursorLine?: number; cursorCol?: number };
      preferredVisualCol?: number;
      tui?: { requestRender?: () => void };
    };

    const state = editor.state;
    if (!state || !Array.isArray(state.lines)) return false;
    if (!Number.isInteger(state.cursorLine) || !Number.isInteger(state.cursorCol)) return false;

    const cursorLine = state.cursorLine as number;
    const cursorCol = state.cursorCol as number;
    const line = state.lines[cursorLine] ?? "";
    if (this.hasMultiCodeUnitGraphemes(line)) return false;

    const target = cursorCol + delta;

    // Only short-circuit line-local movement when each grapheme is one code
    // unit; otherwise let the base editor keep cursor boundaries valid.
    if (target < 0 || target > line.length) return false;

    state.cursorCol = target;
    editor.preferredVisualCol = target;
    editor.tui?.requestRender?.();
    return true;
  }

  private moveCursorBy(delta: number): void {
    if (delta === 0) return;

    this.preferredDisplayCol = null;
    if (this.tryMoveCursorByState(delta)) return;

    const seq = delta > 0 ? ESC_RIGHT : ESC_LEFT;
    for (let i = 0; i < Math.abs(delta); i++) {
      super.handleInput(seq);
    }
  }

  private getDisplayRowCount(lineText: string, contentWidth: number): number {
    if (contentWidth <= 0) return 1;
    const vw = visibleWidth(lineText);
    return Math.max(1, Math.ceil((vw || 1) / contentWidth));
  }

  private moveCursorVertically(delta: number): void {
    if (delta === 0) return;

    const editor = this as unknown as {
      state?: { lines?: string[]; cursorLine?: number; cursorCol?: number };
      preferredVisualCol?: number | null;
      lastAction?: string | null;
      tui?: { requestRender?: () => void };
    };

    const state = editor.state;
    if (!state || !Array.isArray(state.lines) || state.lines.length === 0) {
      const seq = delta > 0 ? ESC_DOWN : ESC_UP;
      for (let i = 0; i < Math.abs(delta); i++) {
        super.handleInput(seq);
      }
      return;
    }

    const contentWidth = Math.max(1, this.lastKnownWidth - 2);
    const currentLine = state.cursorLine ?? 0;
    const currentCol = state.cursorCol ?? 0;
    const lineText = state.lines[currentLine] ?? "";

    // Calculate current visual column and display row
    const currentVisCol = visibleWidth(lineText.slice(0, currentCol));
    const currentDisplayRow = Math.floor(currentVisCol / contentWidth);
    const totalRows = this.getDisplayRowCount(lineText, contentWidth);

    // Use preferred display column or current position within display row
    const preferredCol = this.preferredDisplayCol ?? (currentVisCol % contentWidth);

    let targetDisplayRow = currentDisplayRow + delta;
    let targetBufferLine = currentLine;

    // Resolve across buffer lines
    if (delta > 0) {
      while (targetDisplayRow >= this.getDisplayRowCount(state.lines[targetBufferLine] ?? "", contentWidth)) {
        targetDisplayRow -= this.getDisplayRowCount(state.lines[targetBufferLine] ?? "", contentWidth);
        targetBufferLine++;
        if (targetBufferLine >= state.lines.length) {
          targetBufferLine = state.lines.length - 1;
          targetDisplayRow = this.getDisplayRowCount(state.lines[targetBufferLine] ?? "", contentWidth) - 1;
          break;
        }
      }
    } else {
      while (targetDisplayRow < 0) {
        targetBufferLine--;
        if (targetBufferLine < 0) {
          targetBufferLine = 0;
          targetDisplayRow = 0;
          break;
        }
        targetDisplayRow += this.getDisplayRowCount(state.lines[targetBufferLine] ?? "", contentWidth);
      }
    }

    // Calculate target character column from visual position
    const targetLineText = state.lines[targetBufferLine] ?? "";
    const targetVisCol = targetDisplayRow * contentWidth + preferredCol;

    // Convert visual col to char col
    let charCol = 0;
    let visCol = 0;
    for (const ch of targetLineText) {
      const cw = visibleWidth(ch);
      if (visCol + cw > targetVisCol) break;
      visCol += cw;
      charCol += ch.length;
    }
    charCol = Math.min(charCol, targetLineText.length);

    editor.lastAction = null;
    state.cursorLine = targetBufferLine;
    state.cursorCol = charCol;
    // Keep preferredVisualCol in sync for non-display-line code paths
    editor.preferredVisualCol = charCol;
    this.preferredDisplayCol = preferredCol;
    editor.tui?.requestRender?.();
  }

  private moveCursorToCol(col: number): void {
    const editor = this as unknown as {
      state?: { lines?: string[]; cursorLine?: number; cursorCol?: number };
      preferredVisualCol?: number | null;
      lastAction?: string | null;
      tui?: { requestRender?: () => void };
    };

    const state = editor.state;
    if (!state || !Array.isArray(state.lines)) return;

    editor.lastAction = null;
    state.cursorCol = col;
    editor.preferredVisualCol = col;
    this.preferredDisplayCol = null;
    editor.tui?.requestRender?.();
  }

  private moveCursorToAbsoluteIndex(abs: number): void {
    const editor = this as unknown as {
      state?: { lines?: string[]; cursorLine?: number; cursorCol?: number };
      preferredVisualCol?: number | null;
      lastAction?: string | null;
      tui?: { requestRender?: () => void };
    };

    const state = editor.state;
    if (!state || !Array.isArray(state.lines)) return;

    const { line, col } = this.getCursorFromAbsoluteIndex(this.getText(), abs);
    editor.lastAction = null;
    state.cursorLine = line;
    state.cursorCol = col;
    editor.preferredVisualCol = col;
    this.preferredDisplayCol = null;
    editor.tui?.requestRender?.();
  }

  private moveCursorToLineStart(lineIndex: number): void {
    const editor = this as unknown as {
      state?: { lines?: string[]; cursorLine?: number; cursorCol?: number };
      preferredVisualCol?: number | null;
      lastAction?: string | null;
      tui?: { requestRender?: () => void };
    };

    const state = editor.state;
    if (!state || !Array.isArray(state.lines) || state.lines.length === 0) {
      super.handleInput(CTRL_A);
      return;
    }

    const targetLine = Math.max(0, Math.min(lineIndex, state.lines.length - 1));
    editor.lastAction = null;
    state.cursorLine = targetLine;
    state.cursorCol = 0;
    editor.preferredVisualCol = null;
    this.preferredDisplayCol = null;
    editor.tui?.requestRender?.();
  }

  private moveCursorToFirstNonWhitespace(): void {
    const { line } = this.getCurrentLineAndCol();
    const targetCol = findFirstNonWhitespaceColumn(line);
    this.moveCursorToCol(targetCol);
  }

  private moveCursorToBufferEnd(): void {
    const lines = this.getLines();
    const lastLine = Math.max(0, lines.length - 1);
    const lastLineText = lines[lastLine] ?? "";
    this.moveCursorToLineStart(lastLine);
    if (lastLineText.length > 0) {
      this.moveCursorToCol(Math.max(0, lastLineText.length - 1));
    }
  }

  private joinLines(normalize: boolean): void {
    const count = this.takeTotalCount(2);
    const steps = Math.max(0, count - 1);
    if (steps === 0) return;

    this.applySyntheticEdit(() => {
      const editor = this as unknown as ModalEditorInternals;
      const state = editor.state;
      if (!state || !Array.isArray(state.lines)) return;

      const currentLine = state.cursorLine ?? 0;
      let joinPoint = state.cursorCol ?? 0;

      for (let i = 0; i < steps; i++) {
        if (currentLine >= state.lines.length - 1) break;

        const left = state.lines[currentLine]!;
        const right = state.lines[currentLine + 1]!;
        let joined: string;

        if (normalize) {
          const trimmedRight = right.trimStart();
          const leftEndsWithSpace = left.length > 0 && /\s/.test(left[left.length - 1]!);
          const needsSeparator = !leftEndsWithSpace && trimmedRight.length > 0;
          joined = needsSeparator ? `${left} ${trimmedRight}` : left + trimmedRight;
          joinPoint = left.length;
        } else {
          joined = left + right;
          joinPoint = left.length;
        }

        state.lines.splice(currentLine, 2, joined);
      }

      state.cursorLine = currentLine;
      state.cursorCol = joinPoint;
      editor.preferredVisualCol = joinPoint;
    });
  }

  /**
   * Navigate prompt history, saving/restoring the current unsent prompt.
   * direction: -1 = older (K), 1 = newer (J)
   */
  private navigateHistoryVim(direction: number): void {
    const editor = this as unknown as {
      state?: { lines?: string[]; cursorLine?: number; cursorCol?: number };
      history?: string[];
      historyIndex?: number;
      lastAction?: string | null;
      scrollOffset?: number;
      onChange?: (text: string) => void;
      tui?: { requestRender?: () => void };
    };

    const state = editor.state;
    if (!state || !Array.isArray(editor.history) || editor.history.length === 0) return;

    const currentIndex = editor.historyIndex ?? -1;
    // Up(-1) increases index into history, Down(1) decreases
    const newIndex = currentIndex - direction;
    if (newIndex < -1 || newIndex >= editor.history.length) return;

    // Save current prompt when first entering history
    if (currentIndex === -1 && newIndex >= 0) {
      this.savedPromptBeforeHistory = this.getText();
    }

    editor.historyIndex = newIndex;
    editor.lastAction = null;

    let newText: string;
    if (newIndex === -1) {
      // Returned to current — restore saved prompt
      newText = this.savedPromptBeforeHistory ?? "";
      this.savedPromptBeforeHistory = null;
    } else {
      newText = editor.history[newIndex] ?? "";
    }

    const lines = newText.replace(/\r\n/g, "\n").replace(/\r/g, "\n").split("\n");
    state.lines = lines.length > 0 ? lines : [""];
    state.cursorLine = state.lines.length - 1;
    state.cursorCol = (state.lines[state.cursorLine] ?? "").length;
    if (typeof editor.scrollOffset === "number") editor.scrollOffset = 0;

    this.invalidateWordBoundaryCache();
    editor.onChange?.(this.getText());
    editor.tui?.requestRender?.();
  }

  private isWordChar(ch: string): boolean {
    return /\w/.test(ch);
  }

  private charType(
    ch: string | undefined,
    semanticClass: WordMotionClass = "word",
  ): "space" | "word" | "other" {
    if (!ch || /\s/.test(ch)) return "space";
    if (semanticClass === "WORD") return "word";
    if (this.isWordChar(ch)) return "word";
    return "other";
  }

  private resolveWordMotion(
    motion: string,
  ): { motion: "w" | "e" | "b"; semanticClass: WordMotionClass } | null {
    if (motion === "w" || motion === "e" || motion === "b") {
      return { motion, semanticClass: "word" };
    }

    if (motion === "W" || motion === "E" || motion === "B") {
      const normalizedMotion = motion.toLowerCase() as "w" | "e" | "b";
      return { motion: normalizedMotion, semanticClass: "WORD" };
    }

    return null;
  }

  private getAbsoluteIndex(line: number, col: number): number {
    const lines = this.getLines();
    let idx = 0;
    for (let i = 0; i < line; i++) {
      idx += (lines[i] ?? "").length + 1;
    }
    return idx + col;
  }

  private getAbsoluteIndexFromCursor(): number {
    const cursor = this.getCursor();
    return this.getAbsoluteIndex(cursor.line, cursor.col);
  }

  private findWordTargetInText(
    text: string,
    abs: number,
    direction: "forward" | "backward",
    target: "start" | "end",
    count: number = 1,
    semanticClass: WordMotionClass = "word",
  ): number {
    const len = text.length;
    if (len === 0) return 0;

    const steps = Math.max(1, Math.min(MAX_COUNT, count));
    let i = Math.max(0, Math.min(abs, len));

    for (let step = 0; step < steps; step++) {
      let next = i;

      if (direction === "forward") {
        if (next >= len) {
          next = len;
        } else if (target === "start") {
          const startType = this.charType(text[next], semanticClass);
          if (startType !== "space") {
            while (next < len && this.charType(text[next], semanticClass) === startType) next++;
          }
          while (next < len && this.charType(text[next], semanticClass) === "space") next++;
        } else {
          if (next < len - 1) next++;
          while (next < len && this.charType(text[next], semanticClass) === "space") next++;
          if (next >= len) {
            next = len;
          } else {
            const t = this.charType(text[next], semanticClass);
            while (next < len - 1 && this.charType(text[next + 1], semanticClass) === t) next++;
          }
        }
      } else {
        if (next >= len) next = len - 1;
        if (next > 0) next--;
        while (next > 0 && this.charType(text[next], semanticClass) === "space") next--;
        const t = this.charType(text[next], semanticClass);
        while (next > 0 && this.charType(text[next - 1], semanticClass) === t) next--;
      }

      if (next === i) break;
      i = next;
    }

    return i;
  }

  private tryFindWordTargetInLine(
    line: string,
    col: number,
    direction: WordMotionDirection,
    target: WordMotionTarget,
    allowSameColumn: boolean = false,
    semanticClass: WordMotionClass = "word",
  ): number | null {
    if (line.length === 0) return null;
    if (col < 0 || col > line.length) return null;

    if (direction === "forward") {
      if (col >= line.length) return null;
    } else {
      if (col <= 0) return null;
      if (!/\S/.test(line.slice(0, col))) return null;
    }

    const targetCol = this.wordBoundaryCache.tryFindTarget(
      line,
      col,
      direction,
      target,
      semanticClass,
    );
    if (targetCol === null) return null;

    if (direction === "forward") {
      if (targetCol >= line.length) return null;
      if (allowSameColumn) {
        if (targetCol < col) return null;
      } else if (targetCol <= col) {
        return null;
      }
      return targetCol;
    }

    if (allowSameColumn) {
      if (targetCol > col) return null;
    } else if (targetCol >= col) {
      return null;
    }

    return targetCol;
  }

  private tryFindWordTargetLineLocal(
    direction: WordMotionDirection,
    target: WordMotionTarget,
    semanticClass: WordMotionClass = "word",
  ): number | null {
    const cursor = this.getCursor();
    const lineIndex = cursor.line;
    const col = cursor.col;
    const lineSnapshot = this.getLines()[lineIndex] ?? "";

    const targetCol = this.tryFindWordTargetInLine(
      lineSnapshot,
      col,
      direction,
      target,
      false,
      semanticClass,
    );
    if (targetCol === null) return null;

    const liveLine = this.getLines()[lineIndex] ?? "";
    const liveCol = this.getCursor().col;
    if (liveLine !== lineSnapshot || liveCol !== col) return null;

    return targetCol;
  }

  private tryMoveWordLineLocal(
    direction: "forward" | "backward",
    target: "start" | "end",
    semanticClass: WordMotionClass = "word",
  ): boolean {
    const col = this.getCursor().col;
    const targetCol = this.tryFindWordTargetLineLocal(direction, target, semanticClass);
    if (targetCol === null || targetCol === col) return false;

    this.moveCursorToCol(targetCol);
    return true;
  }

  private tryWordMotionLineLocalRange(
    motion: "w" | "e" | "b",
    count: number = 1,
    semanticClass: WordMotionClass = "word",
  ): { col: number; targetCol: number; inclusive: boolean } | null {
    const cursor = this.getCursor();
    const lineIndex = cursor.line;
    const col = cursor.col;
    const lineSnapshot = this.getLines()[lineIndex] ?? "";
    const direction: WordMotionDirection = motion === "b" ? "backward" : "forward";
    const target: WordMotionTarget = motion === "e" ? "end" : "start";
    const steps = Math.max(1, Math.min(MAX_COUNT, count));

    let currentCol = col;
    for (let step = 0; step < steps; step++) {
      const nextCol = this.tryFindWordTargetInLine(
        lineSnapshot,
        currentCol,
        direction,
        target,
        motion === "e",
        semanticClass,
      );
      if (nextCol === null) return null;
      if (nextCol === currentCol && step < steps - 1) return null;
      currentCol = nextCol;
    }

    const liveLine = this.getLines()[lineIndex] ?? "";
    const liveCol = this.getCursor().col;
    if (liveLine !== lineSnapshot || liveCol !== col) return null;

    return {
      col,
      targetCol: currentCol,
      inclusive: motion === "e",
    };
  }

  private moveWord(
    direction: "forward" | "backward",
    target: "start" | "end",
    count: number = 1,
    semanticClass: WordMotionClass = "word",
  ): void {
    let remaining = Math.max(1, Math.min(MAX_COUNT, count));

    while (remaining > 0) {
      if (this.tryMoveWordLineLocal(direction, target, semanticClass)) {
        remaining--;
        continue;
      }

      const text = this.getText();
      const currentAbs = this.getAbsoluteIndexFromCursor();
      const targetAbs = this.findWordTargetInText(
        text,
        currentAbs,
        direction,
        target,
        remaining,
        semanticClass,
      );
      if (targetAbs !== currentAbs) {
        this.moveCursorToAbsoluteIndex(targetAbs);
      }
      return;
    }
  }

  private writeToRegister(text: string): void {
    this.unnamedRegister = text;
    if (!text) return;

    void this.clipboardFn(text).catch(() => {});
  }

  private getCurrentLineAndCol(): { line: string; col: number } {
    const line = this.getLines()[this.getCursor().line] ?? "";
    const col = this.getCursor().col;
    return { line, col };
  }

  private hasMultiCodeUnitGraphemes(line: string): boolean {
    return getLineGraphemes(line).some((segment) => segment.end - segment.start > 1);
  }

  private getGraphemeRangeAtCol(
    line: string,
    col: number,
    count: number,
    clampToLine: boolean = false,
  ): { start: number; end: number } | null {
    const clampedCol = Math.max(0, Math.min(col, line.length));
    const segments = getLineGraphemes(line);
    const startIndex = segments.findIndex((segment) => clampedCol < segment.end);
    if (startIndex === -1) return null;

    let endIndex = startIndex + Math.max(1, count) - 1;
    if (endIndex >= segments.length) {
      if (!clampToLine) return null;
      endIndex = segments.length - 1;
    }

    return {
      start: segments[startIndex]!.start,
      end: segments[endIndex]!.end,
    };
  }

  private isCursorOnNonWhitespace(): boolean {
    const { line, col } = this.getCurrentLineAndCol();
    const ch = line[col];
    return ch !== undefined && !/\s/.test(ch);
  }

  private isCursorAtOrPastEol(): boolean {
    const { line, col } = this.getCurrentLineAndCol();
    return col >= line.length;
  }

  private cutCharUnderCursor(): void {
    const count = Math.max(1, Math.min(MAX_COUNT, this.takeTotalCount(1)));
    const cursor = this.getCursor();
    const line = this.getLines()[cursor.line] ?? "";
    const range = this.getGraphemeRangeAtCol(line, cursor.col, count, true);
    if (!range) return;

    const lineStartAbs = this.getAbsoluteIndex(cursor.line, 0);
    const text = this.getText();
    this.writeToRegister(line.slice(range.start, range.end));
    this.replaceTextInBuffer(
      text.slice(0, lineStartAbs + range.start) + text.slice(lineStartAbs + range.end),
      lineStartAbs + range.start,
    );
  }

  private cutToEndOfLine(): void {
    const lines = this.getLines();
    const cursorLine = this.getCursor().line;
    const { line, col } = this.getCurrentLineAndCol();

    const hasNextLine = cursorLine < lines.length - 1;
    const deleted = col < line.length ? line.slice(col) : hasNextLine ? "\n" : "";

    this.writeToRegister(deleted);
    super.handleInput(CTRL_K);
  }

  private cutCurrentLineContent(): void {
    const lines = this.getLines();
    const cursorLine = this.getCursor().line;
    const { line } = this.getCurrentLineAndCol();

    const hasNextLine = cursorLine < lines.length - 1;
    const deleted = line.length > 0 ? line : hasNextLine ? "\n" : "";

    this.writeToRegister(deleted);
    super.handleInput(CTRL_A);
    super.handleInput(CTRL_K);
  }

  private cutLine(): void {
    this.cutCurrentLineContent();
  }

  private getNormalizedLineRange(startLine: number, endLine: number): { start: number; end: number } {
    const lines = this.getLines();
    const last = Math.max(0, lines.length - 1);
    const clampedStart = Math.max(0, Math.min(startLine, last));
    const clampedEnd = Math.max(0, Math.min(endLine, last));
    return {
      start: Math.min(clampedStart, clampedEnd),
      end: Math.max(clampedStart, clampedEnd),
    };
  }

  private getLinewisePayload(startLine: number, endLine: number): string {
    const lines = this.getLines();
    const { start, end } = this.getNormalizedLineRange(startLine, endLine);
    return `${lines.slice(start, end + 1).join("\n")}\n`;
  }

  private getLineDeleteAbsoluteRange(startLine: number, endLine: number): { startAbs: number; endAbs: number } {
    const lines = this.getLines();
    const text = this.getText();
    const { start, end } = this.getNormalizedLineRange(startLine, endLine);
    const lastLine = Math.max(0, lines.length - 1);

    let startAbs = this.getAbsoluteIndex(start, 0);
    let endAbs: number;

    if (end < lastLine) {
      const endLineText = lines[end] ?? "";
      endAbs = this.getAbsoluteIndex(end, endLineText.length) + 1;
    } else {
      endAbs = text.length;
      if (start > 0) {
        startAbs = Math.max(0, startAbs - 1);
      }
    }

    return { startAbs, endAbs };
  }

  private deleteLineRange(startLine: number, endLine: number): void {
    const lines = this.getLines();
    if (lines.length === 0) return;

    const payload = this.getLinewisePayload(startLine, endLine);
    const { startAbs, endAbs } = this.getLineDeleteAbsoluteRange(startLine, endLine);

    this.writeToRegister(payload);

    if (endAbs > startAbs) {
      const text = this.getText();
      const newText = text.slice(0, startAbs) + text.slice(endAbs);
      this.replaceTextInBuffer(newText, startAbs);

      // Ensure cursor is at column 0 of the landing line
      super.handleInput(CTRL_A);
    }
  }

  private yankLineRange(startLine: number, endLine: number): void {
    if (this.getLines().length === 0) return;
    this.writeToRegister(this.getLinewisePayload(startLine, endLine));
  }

  private deleteLinewiseByDelta(delta: number): void {
    const currentLine = this.getCursor().line;
    this.deleteLineRange(currentLine, currentLine + delta);
  }

  private yankLinewiseByDelta(delta: number): void {
    const currentLine = this.getCursor().line;
    this.yankLineRange(currentLine, currentLine + delta);
  }

  private deleteToBufferEndLinewise(): void {
    this.deleteLineRange(this.getCursor().line, this.getLines().length - 1);
  }

  private yankToBufferEndLinewise(): void {
    this.yankLineRange(this.getCursor().line, this.getLines().length - 1);
  }

  private deleteWithMotion(motion: string, count: number = 1): boolean {
    const cursor = this.getCursor();
    const col = cursor.col;

    if (motion === "$") {
      // Match D/C behavior exactly, including newline kill at EOL.
      this.cutToEndOfLine();
      return true;
    }

    if (motion === "0") {
      this.deleteRange(col, 0, false);
      return true;
    }

    if (motion === "^") {
      this.deleteRange(col, findFirstNonWhitespaceColumn(this.getLines()[cursor.line] ?? ""), false);
      return true;
    }

    const wordMotion = this.resolveWordMotion(motion);
    if (wordMotion) {
      const lineLocalRange = this.tryWordMotionLineLocalRange(
        wordMotion.motion,
        count,
        wordMotion.semanticClass,
      );
      if (lineLocalRange) {
        this.deleteRange(
          lineLocalRange.col,
          lineLocalRange.targetCol,
          lineLocalRange.inclusive,
        );
        return true;
      }

      const text = this.getText();
      const currentAbs = this.getAbsoluteIndexFromCursor();
      const targetAbs = this.findWordTargetInText(
        text,
        currentAbs,
        wordMotion.motion === "b" ? "backward" : "forward",
        wordMotion.motion === "e" ? "end" : "start",
        count,
        wordMotion.semanticClass,
      );
      this.deleteRangeByAbsolute(currentAbs, targetAbs, wordMotion.motion === "e");
      return true;
    }

    return false;
  }

  private deleteWithCharMotion(motion: CharMotion, targetChar: string): void {
    const line = this.getLines()[this.getCursor().line] ?? "";
    const col = this.getCursor().col;
    const count = this.takeTotalCount(1);
    const targetCol = findCharMotionTarget(line, col, motion, targetChar, false, count);

    if (targetCol === null) return;

    this.lastCharMotion = { motion, char: targetChar };
    this.deleteRange(col, targetCol, true); // char motions are inclusive
  }

  private handlePendingYank(data: string): void {
    if (this.isDigit(data)) {
      if (this.operatorCount.length === 0) {
        if (data !== "0") {
          this.operatorCount = data;
          return;
        }
      } else {
        this.operatorCount += data;
        return;
      }
    }

    if (data === "y") {
      const count = this.takeTotalCount(1);
      this.yankLinewiseByDelta(count - 1);
      this.pendingOperator = null;
      return;
    }

    if (data === "j" || data === "k") {
      const hasDualCount = this.prefixCount.length > 0 && this.operatorCount.length > 0;
      const count = this.takeTotalCount(1);
      const delta = hasDualCount ? Math.max(0, count - 1) : count;
      this.yankLinewiseByDelta(data === "j" ? delta : -delta);
      this.pendingOperator = null;
      return;
    }

    if (data === "G") {
      if (this.prefixCount.length > 0 || this.operatorCount.length > 0) {
        this.cancelPendingOperator(data);
        return;
      }

      this.yankToBufferEndLinewise();
      this.pendingOperator = null;
      return;
    }

    if (data === "_") {
      const count = this.takeTotalCount(1);
      this.yankLinewiseByDelta(count - 1);
      this.pendingOperator = null;
      return;
    }

    if (CHAR_MOTION_KEYS.has(data)) {
      this.pendingMotion = data as PendingMotion;
      return;
    }

    if (this.prefixCount.length > 0 || this.operatorCount.length > 0) {
      // Counted forms beyond yy, y{count}j/k, and y{count}{f/F/t/T} are out of scope.
      this.cancelPendingOperator(data);
      return;
    }

    if (data === "i" || data === "a") {
      this.pendingTextObject = data;
      return;
    }

    if (this.yankWithMotion(data)) {
      this.pendingOperator = null;
    } else {
      this.cancelPendingOperator(data); // cancel on unrecognised motion
    }
  }

  private yankWithMotion(motion: string): boolean {
    const cursor = this.getCursor();
    const line = this.getLines()[cursor.line] ?? "";
    const col = cursor.col;

    if (motion === "$") {
      this.yankRange(col, line.length, false);
      return true;
    }

    if (motion === "0") {
      this.yankRange(col, 0, false);
      return true;
    }

    if (motion === "^") {
      this.yankRange(col, findFirstNonWhitespaceColumn(line), false);
      return true;
    }

    const wordMotion = this.resolveWordMotion(motion);
    if (wordMotion) {
      const lineLocalRange = this.tryWordMotionLineLocalRange(
        wordMotion.motion,
        1,
        wordMotion.semanticClass,
      );
      if (lineLocalRange) {
        this.yankRange(
          lineLocalRange.col,
          lineLocalRange.targetCol,
          lineLocalRange.inclusive,
        );
        return true;
      }

      const text = this.getText();
      const currentAbs = this.getAbsoluteIndexFromCursor();
      const targetAbs = this.findWordTargetInText(
        text,
        currentAbs,
        wordMotion.motion === "b" ? "backward" : "forward",
        wordMotion.motion === "e" ? "end" : "start",
        1,
        wordMotion.semanticClass,
      );
      this.yankRangeByAbsolute(currentAbs, targetAbs, wordMotion.motion === "e");
      return true;
    }

    return false;
  }

  private yankWithCharMotion(motion: CharMotion, targetChar: string): void {
    const line = this.getLines()[this.getCursor().line] ?? "";
    const col = this.getCursor().col;
    const count = this.takeTotalCount(1);
    const targetCol = findCharMotionTarget(line, col, motion, targetChar, false, count);

    if (targetCol === null) return;

    this.lastCharMotion = { motion, char: targetChar };
    this.yankRange(col, targetCol, true); // char motions are inclusive
  }

  private replaceWithCharMotion(motion: CharMotion, targetChar: string): void {
    const line = this.getLines()[this.getCursor().line] ?? "";
    const col = this.getCursor().col;
    const count = this.takeTotalCount(1);
    const targetCol = findCharMotionTarget(line, col, motion, targetChar, false, count);

    if (targetCol === null) return;

    this.lastCharMotion = { motion, char: targetChar };
    const start = Math.min(col, targetCol);
    const rawEnd = Math.max(col, targetCol) + 1; // inclusive
    const end = Math.min(rawEnd, line.length);
    const lineStartAbs = this.getAbsoluteIndex(this.getCursor().line, 0);
    this.replaceRangeWithRegister(lineStartAbs + start, lineStartAbs + end);
  }

  private yankRange(col: number, targetCol: number, inclusive: boolean): void {
    const line = this.getLines()[this.getCursor().line] ?? "";
    const start = Math.min(col, targetCol);
    const rawEnd = Math.max(col, targetCol) + (inclusive ? 1 : 0);
    let end = Math.min(rawEnd, line.length);

    if (inclusive) {
      const targetRange = this.getGraphemeRangeAtCol(line, Math.max(col, targetCol), 1);
      end = targetRange?.end ?? end;
    }

    if (end <= start) return;

    // Yank only — no cursor movement, no text mutation
    this.writeToRegister(line.slice(start, end));
  }

  private yankRangeByAbsolute(currentAbs: number, targetAbs: number, inclusive: boolean = false): void {
    const text = this.getText();
    const start = Math.min(currentAbs, targetAbs);
    const rawEnd = Math.max(currentAbs, targetAbs) + (inclusive ? 1 : 0);
    const end = Math.min(rawEnd, text.length);
    if (end <= start) return;
    this.writeToRegister(text.slice(start, end));
  }

  private getCursorFromAbsoluteIndex(text: string, abs: number): { line: number; col: number } {
    const lines = text.length === 0 ? [""] : text.split("\n");
    let remaining = Math.max(0, Math.min(abs, text.length));
    for (let lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      const line = lines[lineIndex] ?? "";
      if (remaining <= line.length) return { line: lineIndex, col: remaining };
      remaining -= line.length + 1;
    }
    const lastLine = Math.max(0, lines.length - 1);
    return { line: lastLine, col: (lines[lastLine] ?? "").length };
  }

  private replaceTextInBuffer(text: string, cursorAbs: number): void {
    const editor = this as unknown as {
      state?: { lines?: string[]; cursorLine?: number; cursorCol?: number };
      preferredVisualCol?: number | null;
      historyIndex?: number;
      lastAction?: string | null;
      onChange?: (text: string) => void;
      tui?: { requestRender?: () => void };
      pushUndoSnapshot?: () => void;
      autocompleteState?: unknown;
      updateAutocomplete?: () => void;
    };
    const state = editor.state;
    if (!state) return;
    const currentText = this.getText();
    if (currentText !== text) editor.pushUndoSnapshot?.();
    const nextLines = text.length === 0 ? [""] : text.split("\n");
    const { line, col } = this.getCursorFromAbsoluteIndex(text, cursorAbs);
    editor.historyIndex = -1;
    editor.lastAction = null;
    state.lines = nextLines;
    state.cursorLine = line;
    state.cursorCol = col;
    editor.preferredVisualCol = null;
    editor.onChange?.(text);
    if (editor.autocompleteState) editor.updateAutocomplete?.();
    editor.tui?.requestRender?.();
  }

  private deleteRangeByAbsolute(currentAbs: number, targetAbs: number, inclusive: boolean = false): void {
    const text = this.getText();
    const start = Math.min(currentAbs, targetAbs);
    const rawEnd = Math.max(currentAbs, targetAbs) + (inclusive ? 1 : 0);
    const end = Math.min(rawEnd, text.length);

    if (end <= start) return;

    this.writeToRegister(text.slice(start, end));

    this.replaceTextInBuffer(text.slice(0, start) + text.slice(end), start);
  }

  private getWordObjectRange(
    kind: "i" | "a",
    count: number = 1,
  ): { startAbs: number; endAbs: number } | null {
    const lines = this.getLines();
    const cursor = this.getCursor();
    const line = lines[cursor.line] ?? "";
    if (!line) return null;

    const steps = Math.max(1, Math.min(MAX_COUNT, count));
    const hasWordChar = (idx: number) => idx >= 0 && idx < line.length && this.isWordChar(line[idx]!);

    let col = Math.min(cursor.col, Math.max(0, line.length - 1));

    if (!hasWordChar(col)) {
      let right = col;
      while (right < line.length && !hasWordChar(right)) right++;
      if (right < line.length) {
        col = right;
      } else {
        let left = Math.min(col, line.length - 1);
        while (left >= 0 && !hasWordChar(left)) left--;
        if (left < 0) return null;
        col = left;
      }
    }

    let start = col;
    while (start > 0 && hasWordChar(start - 1)) start--;

    let end = col + 1;
    while (end < line.length && hasWordChar(end)) end++;

    let remaining = steps - 1;
    while (remaining > 0) {
      let nextWordStart = end;
      while (nextWordStart < line.length && !hasWordChar(nextWordStart)) nextWordStart++;
      if (nextWordStart >= line.length) break;

      let nextWordEnd = nextWordStart + 1;
      while (nextWordEnd < line.length && hasWordChar(nextWordEnd)) nextWordEnd++;

      end = nextWordEnd;
      remaining--;
    }

    if (kind === "a") {
      let aroundEnd = end;
      while (aroundEnd < line.length && /\s/.test(line[aroundEnd]!)) aroundEnd++;

      if (aroundEnd > end) {
        end = aroundEnd;
      } else {
        while (start > 0 && /\s/.test(line[start - 1]!)) start--;
      }
    }

    return {
      startAbs: this.getAbsoluteIndex(cursor.line, start),
      endAbs: this.getAbsoluteIndex(cursor.line, end),
    };
  }

  private static readonly PUT_SIZE_LIMIT = 512 * 1024; // 512 KB safety cap

  private putAfter(): void {
    const count = this.takeTotalCount(1);
    const text = this.unnamedRegister;
    if (!text) return;
    const safeCount = Math.min(count, Math.max(1, Math.floor(ModalEditor.PUT_SIZE_LIMIT / text.length)));

    if (text.endsWith("\n")) {
      const content = text.slice(0, -1);
      for (let i = 0; i < safeCount; i++) {
        // Line-wise: insert new line below and fill it
        super.handleInput(CTRL_E);
        super.handleInput(NEWLINE);
        for (const char of content) {
          super.handleInput(char === "\n" ? NEWLINE : char);
        }
      }
      return;
    }

    // Character-wise: insert after cursor
    if (!this.isCursorAtOrPastEol()) {
      super.handleInput(ESC_RIGHT);
    }
    for (let i = 0; i < safeCount; i++) {
      for (const char of text) {
        super.handleInput(char === "\n" ? NEWLINE : char);
      }
    }
  }

  private putBefore(): void {
    const count = this.takeTotalCount(1);
    const text = this.unnamedRegister;
    if (!text) return;
    const safeCount = Math.min(count, Math.max(1, Math.floor(ModalEditor.PUT_SIZE_LIMIT / text.length)));

    if (text.endsWith("\n")) {
      const content = text.slice(0, -1);
      for (let i = 0; i < safeCount; i++) {
        // Line-wise: insert new line above and fill it
        super.handleInput(CTRL_A);
        super.handleInput(NEWLINE);
        super.handleInput(ESC_UP);
        for (const char of content) {
          super.handleInput(char === "\n" ? NEWLINE : char);
        }
      }
      return;
    }

    // Character-wise: insert before cursor (just type it)
    for (let i = 0; i < safeCount; i++) {
      for (const char of text) {
        super.handleInput(char === "\n" ? NEWLINE : char);
      }
    }
  }

  private deleteRange(col: number, targetCol: number, inclusive: boolean): void {
    const cursor = this.getCursor();
    const line = this.getLines()[cursor.line] ?? "";
    const lineStartAbs = this.getAbsoluteIndex(cursor.line, 0);
    const start = Math.min(col, targetCol);
    const rawEnd = Math.max(col, targetCol) + (inclusive ? 1 : 0);
    let end = Math.min(rawEnd, line.length);

    if (inclusive) {
      const targetRange = this.getGraphemeRangeAtCol(line, Math.max(col, targetCol), 1);
      end = targetRange?.end ?? end;
    }

    this.deleteRangeByAbsolute(lineStartAbs + start, lineStartAbs + end);
  }

  // ── Visual mode ─────────────────────────────────────────────────────

  private enterVisualMode(mode: "visual" | "visual-line"): void {
    if (this.mode === mode) {
      // Toggle off
      this.visualAnchor = null;
      this.mode = "normal";
      return;
    }
    this.mode = mode;
    this.visualAnchor = { ...this.getCursor() };
    this.clearPendingState();
  }

  private getVisualRange(): { start: { line: number; col: number }; end: { line: number; col: number } } {
    const cursor = this.getCursor();
    const anchor = this.visualAnchor ?? cursor;
    const before = anchor.line < cursor.line || (anchor.line === cursor.line && anchor.col <= cursor.col);
    return {
      start: before ? { ...anchor } : { ...cursor },
      end: before ? { ...cursor } : { ...anchor },
    };
  }

  private handleVisualMode(data: string): void {
    // Toggle visual modes
    if (data === "v") {
      if (this.mode === "visual") { this.visualAnchor = null; this.mode = "normal"; }
      else { this.mode = "visual"; if (!this.visualAnchor) this.visualAnchor = { ...this.getCursor() }; }
      return;
    }
    if (data === "V") {
      if (this.mode === "visual-line") { this.visualAnchor = null; this.mode = "normal"; }
      else { this.mode = "visual-line"; if (!this.visualAnchor) this.visualAnchor = { ...this.getCursor() }; }
      return;
    }

    // Count accumulation
    if (this.isCountStarter(data) && this.prefixCount.length === 0) {
      this.prefixCount = data;
      return;
    }
    if (this.isDigit(data) && this.prefixCount.length > 0) {
      this.prefixCount += data;
      return;
    }

    // g prefix
    if (this.pendingG) {
      this.pendingG = false;
      if (data === "g") { this.moveCursorToLineStart(0); return; }
      return;
    }
    if (data === "g") { this.pendingG = true; return; }

    // Movement
    if (data === "h") { this.moveCursorBy(-this.takeTotalCount(1)); return; }
    if (data === "l") { this.moveCursorBy(this.takeTotalCount(1)); return; }
    if (data === "j") { this.moveCursorVertically(this.takeTotalCount(1)); return; }
    if (data === "k") { this.moveCursorVertically(-this.takeTotalCount(1)); return; }
    if (data === "w") { this.moveWord("forward", "start", this.takeTotalCount(1), "word"); return; }
    if (data === "b") { this.moveWord("backward", "start", this.takeTotalCount(1), "word"); return; }
    if (data === "e") { this.moveWord("forward", "end", this.takeTotalCount(1), "word"); return; }
    if (data === "W") { this.moveWord("forward", "start", this.takeTotalCount(1), "WORD"); return; }
    if (data === "B") { this.moveWord("backward", "start", this.takeTotalCount(1), "WORD"); return; }
    if (data === "E") { this.moveWord("forward", "end", this.takeTotalCount(1), "WORD"); return; }
    if (data === "0" || data === "H") { this.moveCursorToCol(0); return; }
    if (data === "$" || data === "L") { const line = this.getLines()[this.getCursor().line] ?? ""; this.moveCursorToCol(Math.max(0, line.length - 1)); return; }
    if (data === "^") { this.moveCursorToFirstNonWhitespace(); return; }
    if (data === "G") { this.moveCursorToBufferEnd(); return; }
    if (data === "{" || data === "}") { this.executeParagraphMotion(data === "}" ? "forward" : "backward"); return; }

    // Char motions
    if (CHAR_MOTION_KEYS.has(data)) { this.pendingMotion = data as PendingMotion; return; }
    if (this.pendingMotion && this.isPrintableInput(data)) {
      this.executeCharMotion(this.pendingMotion!, data);
      this.pendingMotion = null;
      return;
    }
    if (data === ";" && this.lastCharMotion) { this.executeCharMotion(this.lastCharMotion.motion, this.lastCharMotion.char, false); return; }
    if (data === "," && this.lastCharMotion) { this.executeCharMotion(reverseCharMotion(this.lastCharMotion.motion), this.lastCharMotion.char, false); return; }

    // Operators on selection
    const { start, end } = this.getVisualRange();
    const isLinewise = this.mode === "visual-line";

    if (data === "d" || data === "x") {
      if (isLinewise) {
        this.deleteLineRange(start.line, end.line);
      } else {
        const startAbs = this.getAbsoluteIndex(start.line, start.col);
        const endAbs = this.getAbsoluteIndex(end.line, end.col) + 1;
        this.deleteRangeByAbsolute(startAbs, endAbs);
      }
      this.visualAnchor = null;
      this.mode = "normal";
      return;
    }

    if (data === "c") {
      if (isLinewise) {
        this.deleteLineRange(start.line, end.line);
      } else {
        const startAbs = this.getAbsoluteIndex(start.line, start.col);
        const endAbs = this.getAbsoluteIndex(end.line, end.col) + 1;
        this.deleteRangeByAbsolute(startAbs, endAbs);
      }
      this.visualAnchor = null;
      this.mode = "insert";
      return;
    }

    if (data === "y") {
      if (isLinewise) {
        this.yankLineRange(start.line, end.line);
      } else {
        const startAbs = this.getAbsoluteIndex(start.line, start.col);
        const endAbs = this.getAbsoluteIndex(end.line, end.col) + 1;
        this.yankRangeByAbsolute(startAbs, endAbs);
      }
      this.moveCursorToCol(start.col);
      if (start.line !== this.getCursor().line) this.moveCursorToLineStart(start.line);
      this.visualAnchor = null;
      this.mode = "normal";
      return;
    }

    if (data === "r") {
      // Replace selection with register (black-hole the old text)
      this.replaceVisualWithRegister();
      return;
    }

    if (data === "J") {
      // Join selected lines
      if (start.line < end.line) {
        this.moveCursorToLineStart(start.line);
        const savedPrefixCount = this.prefixCount;
        this.prefixCount = String(end.line - start.line + 1);
        this.joinLines(true);
        this.prefixCount = savedPrefixCount;
      }
      this.visualAnchor = null;
      this.mode = "normal";
      return;
    }

    // Pass non-printable keys through
    if (!this.isPrintableChunk(data)) {
      super.handleInput(data);
    }
  }

  // ── Replace with register ───────────────────────────────────────────

  private handlePendingReplaceWithRegister(data: string): void {
    if (this.isDigit(data)) {
      if (this.operatorCount.length === 0) {
        if (data !== "0") { this.operatorCount = data; return; }
      } else { this.operatorCount += data; return; }
    }

    // rr → replace current line(s) with register
    if (data === "r") {
      const count = this.takeTotalCount(1);
      const currentLine = this.getCursor().line;
      const endLine = Math.min(currentLine + count - 1, this.getLines().length - 1);
      this.replaceLineRangeWithRegister(currentLine, endLine);
      this.pendingOperator = null;
      return;
    }

    if (CHAR_MOTION_KEYS.has(data)) {
      this.pendingMotion = data as PendingMotion;
      return;
    }

    // Text objects (iw, aw)
    const supportsTextObject = data === "i" || data === "a";
    if (supportsTextObject) {
      this.pendingTextObject = data;
      return;
    }

    // Motion-based replace with register
    const hasCount = this.prefixCount.length > 0 || this.operatorCount.length > 0;
    const supportsWordMotion = "webWEB".includes(data);

    if (hasCount && !supportsWordMotion && data !== "j" && data !== "k" && data !== "$" && data !== "0" && data !== "^") {
      this.cancelPendingOperator(data);
      return;
    }

    if (data === "$") {
      this.replaceToEndOfLineWithRegister();
      this.pendingOperator = null;
      return;
    }

    if (data === "0") {
      const cursor = this.getCursor();
      const startAbs = this.getAbsoluteIndex(cursor.line, 0);
      const endAbs = this.getAbsoluteIndex(cursor.line, cursor.col);
      if (endAbs > startAbs) this.replaceRangeWithRegister(startAbs, endAbs);
      this.pendingOperator = null;
      return;
    }

    if (data === "^") {
      const cursor = this.getCursor();
      const line = this.getLines()[cursor.line] ?? "";
      const fnw = findFirstNonWhitespaceColumn(line);
      const startAbs = this.getAbsoluteIndex(cursor.line, Math.min(fnw, cursor.col));
      const endAbs = this.getAbsoluteIndex(cursor.line, Math.max(fnw, cursor.col));
      if (endAbs > startAbs) this.replaceRangeWithRegister(startAbs, endAbs);
      this.pendingOperator = null;
      return;
    }

    const wordMotion = this.resolveWordMotion(data);
    if (wordMotion) {
      const count = this.takeTotalCount(1);
      const text = this.getText();
      const currentAbs = this.getAbsoluteIndexFromCursor();
      const targetAbs = this.findWordTargetInText(
        text, currentAbs,
        wordMotion.motion === "b" ? "backward" : "forward",
        wordMotion.motion === "e" ? "end" : "start",
        count, wordMotion.semanticClass,
      );
      const start = Math.min(currentAbs, targetAbs);
      const end = Math.max(currentAbs, targetAbs) + (wordMotion.motion === "e" ? 1 : 0);
      if (end > start) this.replaceRangeWithRegister(start, end);
      this.pendingOperator = null;
      return;
    }

    if (data === "j" || data === "k") {
      const count = this.takeTotalCount(1);
      const currentLine = this.getCursor().line;
      const targetLine = data === "j"
        ? Math.min(currentLine + count, this.getLines().length - 1)
        : Math.max(currentLine - count, 0);
      this.replaceLineRangeWithRegister(Math.min(currentLine, targetLine), Math.max(currentLine, targetLine));
      this.pendingOperator = null;
      return;
    }

    this.cancelPendingOperator(data);
  }

  /**
   * Replace text range with register contents. Old text goes to black hole.
   */
  private replaceRangeWithRegister(startAbs: number, endAbs: number): void {
    const regText = this.unnamedRegister;
    if (!regText) return;

    const text = this.getText();
    const replacement = regText.endsWith("\n") ? regText.slice(0, -1) : regText;
    const newText = text.slice(0, startAbs) + replacement + text.slice(endAbs);
    this.replaceTextInBuffer(newText, startAbs);
  }

  private replaceLineRangeWithRegister(startLine: number, endLine: number): void {
    const regText = this.unnamedRegister;
    if (!regText) return;

    const lines = this.getLines();
    const replacement = regText.endsWith("\n") ? regText.slice(0, -1) : regText;
    const newLines = [...lines.slice(0, startLine), ...replacement.split("\n"), ...lines.slice(endLine + 1)];
    const newText = newLines.join("\n");
    const cursorAbs = this.getAbsoluteIndex(startLine, 0);
    this.replaceTextInBuffer(newText, cursorAbs);
  }

  private replaceToEndOfLineWithRegister(): void {
    const cursor = this.getCursor();
    const line = this.getLines()[cursor.line] ?? "";
    const startAbs = this.getAbsoluteIndex(cursor.line, cursor.col);
    const endAbs = this.getAbsoluteIndex(cursor.line, line.length);
    if (endAbs > startAbs) this.replaceRangeWithRegister(startAbs, endAbs);
  }

  private replaceVisualWithRegister(): void {
    const regText = this.unnamedRegister;
    if (!regText) { this.visualAnchor = null; this.mode = "normal"; return; }

    const { start, end } = this.getVisualRange();
    const isLinewise = this.mode === "visual-line";

    if (isLinewise) {
      this.replaceLineRangeWithRegister(start.line, end.line);
    } else {
      const startAbs = this.getAbsoluteIndex(start.line, start.col);
      const endAbs = this.getAbsoluteIndex(end.line, end.col) + 1;
      this.replaceRangeWithRegister(startAbs, endAbs);
    }

    this.visualAnchor = null;
    this.mode = "normal";
  }

  // ── Pending motion for visual r operator ────────────────────────────

  /** Check if editor has pending state (for escape-cancel coordination) */
  hasPendingState(): boolean {
    return !!(
      this.pendingMotion
      || this.pendingTextObject
      || this.pendingOperator
      || this.prefixCount
      || this.operatorCount
      || this.pendingG
      || this.pendingGCount
    );
  }

  // ── Visual selection highlighting ───────────────────────────────────

  private applyVisualHighlighting(renderedLines: string[], width: number): void {
    if ((this.mode !== "visual" && this.mode !== "visual-line") || !this.visualAnchor) return;

    const { start, end } = this.getVisualRange();
    const editor = this as unknown as {
      scrollOffset?: number;
      paddingX?: number;
    };
    const scrollOffset = editor.scrollOffset ?? 0;
    const paddingX = editor.paddingX ?? 0;
    const BG = "\x1b[47m";
    const BG_OFF = "\x1b[49m";

    // The base editor renders: [border] [content lines...] [border]
    // Border lines match IS_BORDER_LINE. Content lines are everything else.
    // scrollOffset indexes into layout lines (buffer lines, possibly wrapped).
    // We build a buffer-line map for layout lines.
    const bufLines = this.getLines();
    const contentWidth = Math.max(1, width - paddingX * 2 - (paddingX ? 0 : 1));

    // Map: layout-line-index → { bufferLine, colOffset }
    const layoutMap: Array<{ buf: number; colOff: number }> = [];
    for (let bl = 0; bl < bufLines.length; bl++) {
      const lineVW = visibleWidth(bufLines[bl] ?? "");
      const rows = Math.max(1, Math.ceil((lineVW || 1) / contentWidth));
      for (let r = 0; r < rows; r++) {
        layoutMap.push({ buf: bl, colOff: r * contentWidth });
      }
    }

    // Walk rendered lines, tracking which layout line each content line maps to
    let layoutIdx = scrollOffset;
    for (let i = 0; i < renderedLines.length; i++) {
      const rline = renderedLines[i]!;

      // Skip border lines
      if (IS_BORDER_LINE.test(rline)) continue;

      // This is a content line
      if (layoutIdx >= layoutMap.length) break;
      const { buf: bufLine, colOff } = layoutMap[layoutIdx]!;
      layoutIdx++;

      // Check if this buffer line is in selection
      if (bufLine < start.line || bufLine > end.line) continue;

      // Strip the software cursor markup (\x1b[7m<char>\x1b[0m) before
      // applying visual highlight colours.  When BG codes land inside the
      // cursor markup they break the SOFTWARE_CURSOR regex, leaving a
      // stray \x1b[0m that resets the highlight mid-selection.  Stripping
      // first keeps the CURSOR_MARKER (\x1b_pi:c\x07) for hardware cursor
      // positioning intact and lets the later render() strip pass be a
      // harmless no-op.
      const cleaned = rline.replace(SOFTWARE_CURSOR, "$1").replace(REVERSE_ON, "");

      if (this.mode === "visual-line") {
        // V-LINE: wrap entire line in bg color
        renderedLines[i] = BG + cleaned + BG_OFF;
      } else {
        // v (char-wise): highlight only selected columns
        const bufText = bufLines[bufLine] ?? "";
        const selStart = bufLine === start.line ? start.col : 0;
        const selEnd = bufLine === end.line ? end.col + 1 : bufText.length;
        const visSelStart = Math.max(0, visibleWidth(bufText.slice(0, selStart)) - colOff);
        const visSelEnd = Math.max(0, visibleWidth(bufText.slice(0, selEnd)) - colOff);
        if (visSelEnd <= visSelStart) continue;

        // Apply highlighting, skipping paddingX leading chars
        const lp = cleaned.slice(0, paddingX);
        const content = cleaned.slice(paddingX);
        renderedLines[i] = lp + this.highlightVisualRange(content, visSelStart, visSelEnd, BG, BG_OFF);
      }
    }
  }

  private highlightVisualRange(content: string, visStart: number, visEnd: number, bgOn: string, bgOff: string): string {
    let result = "";
    let visPos = 0;
    let highlighted = false;
    let done = false;
    let i = 0;

    while (i < content.length) {
      const ch = content[i]!;
      const code = ch.charCodeAt(0);

      // Skip ANSI/control escape sequences entirely
      if (code === 0x1b) {
        const next = content[i + 1];
        if (next === "[") {
          // CSI sequence: \x1b[ ... <letter>
          let j = i + 2;
          while (j < content.length && content.charCodeAt(j) >= 0x20 && content.charCodeAt(j) <= 0x3f) j++;
          if (j < content.length) j++; // consume final byte
          result += content.slice(i, j);
          i = j;
          continue;
        }
        // OSC (\x1b]), APC (\x1b_), DCS (\x1bP), PM (\x1b^): consume until ST (\x1b\\ or \x07)
        if (next === "]" || next === "_" || next === "P" || next === "^") {
          let j = i + 2;
          while (j < content.length) {
            if (content[j] === "\x07") { j++; break; }
            if (content[j] === "\x1b" && content[j + 1] === "\\") { j += 2; break; }
            j++;
          }
          result += content.slice(i, j);
          i = j;
          continue;
        }
        // SS2/SS3 or other 2-byte escape
        result += content.slice(i, i + 2);
        i += 2;
        continue;
      }

      // Skip non-printable control characters (don't count as visible)
      if (code < 0x20 || code === 0x7f) {
        result += ch;
        i++;
        continue;
      }

      // Visible character
      if (!done && visPos >= visStart && !highlighted) {
        result += bgOn;
        highlighted = true;
      }

      result += ch;
      visPos++;

      if (visPos >= visEnd && highlighted) {
        result += bgOff;
        highlighted = false;
        done = true;
      }

      i++;
    }

    if (highlighted) result += bgOff;
    return result;
  }

  render(width: number): string[] {
    this.lastKnownWidth = width;
    const lines = super.render(width);
    if (lines.length === 0) return lines;

    // Apply visual selection highlighting (before border stripping, while │ and ─ are intact)
    this.applyVisualHighlighting(lines, width);

    // Borderless cursor: strip reverse video and replace border chars
    for (let i = 0; i < lines.length; i++) {
      let line = lines[i]!;
      if (IS_BORDER_LINE.test(line)) {
        line = line.replace(/─/g, "-");
      }
      // Strip software cursor; hardware cursor (bar/block/underline) takes over
      line = line.replace(SOFTWARE_CURSOR, "$1");
      line = line.replace(REVERSE_ON, "");
      lines[i] = line;
    }

    const rawLabel = this.getModeLabel();
    const isVisual = this.mode === "visual" || this.mode === "visual-line";
    const colorize = this.labelColorizers
      ? (this.mode === "insert" ? this.labelColorizers.insert
        : isVisual ? (this.labelColorizers as any).visual ?? this.labelColorizers.normal
        : this.labelColorizers.normal)
      : null;
    const label = colorize ? colorize(rawLabel) : rawLabel;
    const last = lines.length - 1;
    if (visibleWidth(lines[last]!) >= visibleWidth(rawLabel)) {
      lines[last] = truncateToWidth(lines[last]!, width - visibleWidth(rawLabel), "") + label;
    }
    return lines;
  }

  private getModeLabel(): string {
    if (this.mode === "insert") return " INSERT ";
    if (this.mode === "visual") return " VISUAL ";
    if (this.mode === "visual-line") return " V-LINE ";

    const prefixCount = this.prefixCount;
    const operatorCount = this.operatorCount;

    if (this.pendingOperator && this.pendingMotion) {
      return ` NORMAL ${prefixCount}${this.pendingOperator}${operatorCount}${this.pendingMotion}_ `;
    }
    if (this.pendingOperator) {
      return ` NORMAL ${prefixCount}${this.pendingOperator}${operatorCount}_ `;
    }
    if (this.pendingMotion) return ` NORMAL ${this.pendingMotion}_ `;
    if (this.pendingG) {
      return this.pendingGCount
        ? ` NORMAL g${this.pendingGCount}_ `
        : " NORMAL g_ ";
    }

    const count = `${prefixCount}${operatorCount}`;
    if (count) return ` NORMAL ${count}_ `;
    return " NORMAL ";
  }
}

/** Time window (ms) for two ESC presses to be considered a double-tap. */
const DOUBLE_TAP_WINDOW = 400;

export default function (pi: ExtensionAPI) {
  let inputUnsub: (() => void) | null = null;
  let paneHasFocus = true;
  let currentEditor: ModalEditor | null = null;

  // Escape-cancel state
  let lastEscTime = 0;
  let pendingEscTimer: ReturnType<typeof setTimeout> | null = null;

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

  pi.on("agent_start", async (_event, ctx) => {
    if (ctx.hasUI) ctx.ui.setStatus("esc-hint", "\x1b[2m ESC ESC to cancel\x1b[0m");
  });

  pi.on("agent_end", async (_event, ctx) => {
    if (ctx.hasUI) ctx.ui.setStatus("esc-hint", undefined);
  });

  pi.on("session_start", async (_event, ctx) => {
    if (!ctx.hasUI) return;

    lastEscTime = 0;

    const t = ctx.ui.theme;
    const colorizers = t ? {
      insert: (s: string) => t.fg("borderMuted", `\x1b[7m${s}\x1b[27m`),
      normal: (s: string) => t.fg("borderAccent", `\x1b[7m${s}\x1b[27m`),
      visual: (s: string) => t.fg("borderAccent", `\x1b[7m${s}\x1b[27m`),
    } : null;
    ctx.ui.setEditorComponent((tui, theme, kb) => {
      const editor = new ModalEditor(tui, theme, kb, colorizers);
      currentEditor = editor;
      return editor;
    });

    // Set initial cursor shape (insert mode = bar)
    currentCursorShape = CURSOR_BAR;
    process.stdout.write(CURSOR_BAR);
    // Enable tmux focus reporting
    process.stdout.write("\x1b[?1004h");
    paneHasFocus = true;

    if (inputUnsub) return;

    inputUnsub = ctx.ui.onTerminalInput((data: string) => {
      // Tmux focus-in: restore cursor visibility and current shape
      if (data === "\x1b[I") {
        paneHasFocus = true;
        process.stdout.write(`\x1b[?25h${currentCursorShape}`);
        return { consume: true };
      }
      // Tmux focus-out: hide cursor
      if (data === "\x1b[O") {
        paneHasFocus = false;
        process.stdout.write("\x1b[?25l");
        return { consume: true };
      }

      // Escape-cancel integration: double-tap ESC cancels running operations
      if (matchesKey(data, "escape") || matchesKey(data, "ctrl+[")) {
        const editor = currentEditor;
        if (!editor) return undefined;

        const mode = editor.getMode();

        // In insert/visual mode or with pending state: let ESC reach editor normally
        if (mode === "insert" || mode === "visual" || mode === "visual-line") return undefined;
        if (editor.hasPendingState()) return undefined;

        // Normal mode, no pending: check if something is running
        const somethingRunning = !ctx.isIdle() || hasRunningOperations();
        if (!somethingRunning) return undefined; // let ESC pass through normally

        // Double-tap detection
        const now = Date.now();
        if (now - lastEscTime < DOUBLE_TAP_WINDOW) {
          lastEscTime = 0;
          if (pendingEscTimer) { clearTimeout(pendingEscTimer); pendingEscTimer = null; }
          cancelAll(ctx);
          return { consume: true };
        }

        // First ESC while running: consume and wait for second
        lastEscTime = now;
        if (pendingEscTimer) clearTimeout(pendingEscTimer);
        pendingEscTimer = setTimeout(() => { lastEscTime = 0; pendingEscTimer = null; }, DOUBLE_TAP_WINDOW);
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
    if (inputUnsub) {
      inputUnsub();
      inputUnsub = null;
    }
    currentEditor = null;
    paneHasFocus = true;
    lastEscTime = 0;
    // Disable focus reporting, show cursor, reset cursor shape to default
    process.stdout.write("\x1b[?1004l\x1b[?25h\x1b[0 q");
  });
}
