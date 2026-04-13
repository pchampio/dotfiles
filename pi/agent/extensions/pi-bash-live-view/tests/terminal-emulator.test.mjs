import test from 'node:test';
import assert from 'node:assert/strict';
import { createTerminalEmulator } from '../terminal-emulator.ts';
import { buildWidgetAnsiLines } from '../widget.ts';

function findCell(snapshot, ch) {
  for (const line of snapshot) {
    for (const cell of line) {
      if (cell.ch === ch) return cell;
    }
  }
  return null;
}

function snapshotToText(snapshot) {
  return snapshot
    .map((line) => line.map((cell) => cell.ch).join('').replace(/\s+$/u, ''))
    .join('\n')
    .trimEnd();
}

test('synchronized render lock survives split DECSET/DECRST 2026 sequences', async () => {
  const emulator = createTerminalEmulator({ cols: 20, rows: 4 });
  try {
    const before = await emulator.consumeProcessStdout('before\n');
    assert.equal(before.inSyncRender, false);
    assert.match(snapshotToText(before.snapshot), /before/);

    const beginA = await emulator.consumeProcessStdout('\x1b[?20');
    assert.equal(beginA.inSyncRender, false);

    const beginB = await emulator.consumeProcessStdout('26hpartial');
    assert.equal(beginB.inSyncRender, true);
    assert.match(snapshotToText(beginB.snapshot), /before/);
    assert.doesNotMatch(snapshotToText(beginB.snapshot), /partial/);
    assert.equal(emulator.getState().inSyncRender, true);

    const stillLocked = await emulator.consumeProcessStdout(' update');
    assert.equal(stillLocked.inSyncRender, true);
    assert.match(snapshotToText(stillLocked.snapshot), /before/);
    assert.doesNotMatch(snapshotToText(stillLocked.snapshot), /partial update/);

    const endA = await emulator.consumeProcessStdout('\x1b[?202');
    assert.equal(endA.inSyncRender, true);
    assert.match(snapshotToText(endA.snapshot), /before/);

    const endB = await emulator.consumeProcessStdout('6l');
    assert.equal(endB.inSyncRender, false);
    assert.match(snapshotToText(endB.snapshot), /partial update/);
    assert.equal(emulator.getState().inSyncRender, false);
    assert.match(snapshotToText(emulator.getViewportSnapshot()), /partial update/);
  } finally {
    emulator.dispose();
  }
});

test('split alt-screen private mode sequences still update terminal state tracking', async () => {
  const emulator = createTerminalEmulator({ cols: 20, rows: 4 });
  try {
    await emulator.consumeProcessStdout('\x1b[?104');
    assert.equal(emulator.getState().inAltScreen, false);

    await emulator.consumeProcessStdout('9h');
    assert.equal(emulator.getState().inAltScreen, true);

    await emulator.consumeProcessStdout('\x1b[?104');
    assert.equal(emulator.getState().inAltScreen, true);

    await emulator.consumeProcessStdout('9l');
    assert.equal(emulator.getState().inAltScreen, false);
  } finally {
    emulator.dispose();
  }
});

test('xterm-derived final text excludes split alt-screen-only output and keeps later normal output', async () => {
  const emulator = createTerminalEmulator({ cols: 30, rows: 6 });
  try {
    await emulator.consumeProcessStdout('before\n');
    await emulator.consumeProcessStdout('\x1b[?104');
    await emulator.consumeProcessStdout('9halt-screen only');
    await emulator.consumeProcessStdout('\nmore alt text');
    await emulator.consumeProcessStdout('\x1b[?104');
    await emulator.consumeProcessStdout('9lafter\n');

    assert.equal(emulator.getStrippedTextIncludingEntireScrollback(), 'before\nafter\n');
  } finally {
    emulator.dispose();
  }
});


test('xterm-derived final text returns (no output) for alt-screen-only content', async () => {
  const emulator = createTerminalEmulator({ cols: 30, rows: 6 });
  try {
    await emulator.consumeProcessStdout('\x1b[?1049halt-only');
    await emulator.consumeProcessStdout('\nmore alt-only');
    await emulator.consumeProcessStdout('\x1b[?1049l');

    assert.equal(emulator.getStrippedTextIncludingEntireScrollback(), '(no output)');
  } finally {
    emulator.dispose();
  }
});


test('xterm-derived final text reflects carriage-return repaint final state instead of repaint history', async () => {
  const emulator = createTerminalEmulator({ cols: 30, rows: 6 });
  try {
    await emulator.consumeProcessStdout('spinner 1\r');
    await emulator.consumeProcessStdout('spinner 2\r');
    await emulator.consumeProcessStdout('\x1b[2Kdone\n');

    assert.equal(emulator.getStrippedTextIncludingEntireScrollback(), 'done\n');
  } finally {
    emulator.dispose();
  }
});


test('xterm-derived final text joins wrapped buffer lines into one logical line', async () => {
  const emulator = createTerminalEmulator({ cols: 5, rows: 4 });
  try {
    await emulator.consumeProcessStdout('1234567890\nabc');

    assert.equal(emulator.getStrippedTextIncludingEntireScrollback(), '1234567890\nabc\n');
  } finally {
    emulator.dispose();
  }
});

test('snapshot and ANSI widget rendering preserve richer cell styles', async () => {
  const emulator = createTerminalEmulator({ cols: 40, rows: 4 });
  try {
    await emulator.consumeProcessStdout('\x1b[1;4;38;5;196;48;5;25mA');
    await emulator.consumeProcessStdout('\x1b[3;7;38;2;1;2;3;48;2;4;5;6mB');
    await emulator.consumeProcessStdout('\x1b[9;8mC\x1b[0m');

    const snapshot = emulator.getViewportSnapshot();
    const cellA = findCell(snapshot, 'A');
    const cellB = findCell(snapshot, 'B');
    const cellC = findCell(snapshot, 'C');

    assert.deepEqual(cellA?.style, {
      bold: true,
      dim: false,
      italic: false,
      underline: true,
      inverse: false,
      invisible: false,
      strikethrough: false,
      fgMode: 'palette',
      fg: 196,
      bgMode: 'palette',
      bg: 25,
    });

    assert.deepEqual(cellB?.style, {
      bold: true,
      dim: false,
      italic: true,
      underline: true,
      inverse: true,
      invisible: false,
      strikethrough: false,
      fgMode: 'rgb',
      fg: 0x010203,
      bgMode: 'rgb',
      bg: 0x040506,
    });

    assert.deepEqual(cellC?.style, {
      bold: true,
      dim: false,
      italic: true,
      underline: true,
      inverse: true,
      invisible: true,
      strikethrough: true,
      fgMode: 'rgb',
      fg: 0x010203,
      bgMode: 'rgb',
      bg: 0x040506,
    });

    const widgetLines = buildWidgetAnsiLines({
      snapshot: emulator.getViewportSnapshot(),
      width: 30,
      rows: 4,
    });
    const joined = widgetLines.join('\n');
    assert.match(joined, /\x1b\[0;1;4;38;5;196;48;5;25mA/);
    assert.match(joined, /\x1b\[0;1;3;4;7;38;2;1;2;3;48;2;4;5;6mB/);
    assert.match(joined, /\x1b\[0;1;3;4;7;8;9;38;2;1;2;3;48;2;4;5;6mC/);
  } finally {
    emulator.dispose();
  }
});
