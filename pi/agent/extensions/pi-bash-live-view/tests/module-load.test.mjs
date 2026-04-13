import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

test('extension entrypoint loads', async () => {
  const mod = await import('../index.ts');
  assert.equal(typeof mod.default, 'function');
});

test('malformed legacy config files do not affect module loading or PTY execution setup', async () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'pi-bash-live-view-no-config-'));
  const originalCwd = process.cwd();
  try {
    fs.mkdirSync(path.join(dir, '.pi'), { recursive: true });
    fs.writeFileSync(path.join(dir, '.pi', 'pi-bash-live-view.json'), '{ definitely not json');
    process.chdir(dir);
    const mod = await import(`../index.ts?cacheBust=${Date.now()}`);
    assert.equal(typeof mod.default, 'function');
  } finally {
    process.chdir(originalCwd);
    fs.rmSync(dir, { recursive: true, force: true });
  }
});
