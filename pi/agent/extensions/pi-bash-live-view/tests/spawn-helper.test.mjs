import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

import { ensureExecutablePaths, ensureSpawnHelperExecutable, getBundledSpawnHelperPaths } from '../spawn-helper.ts';

function modeOf(file) {
  return fs.statSync(file).mode & 0o777;
}

test('ensureExecutablePaths chmods existing helper paths to 0755', () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'spawn-helper-test-'));
  const helper = path.join(dir, 'spawn-helper');
  const logs = [];
  try {
    fs.writeFileSync(helper, '#!/bin/sh\nexit 0\n');
    fs.chmodSync(helper, 0o644);

    ensureExecutablePaths([helper], (...args) => logs.push(args));

    assert.equal(modeOf(helper), 0o755);
    assert.deepEqual(logs, [['chmod', helper]]);
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
});

test('ensureExecutablePaths is idempotent and ignores missing paths', () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'spawn-helper-test-'));
  const helper = path.join(dir, 'spawn-helper');
  const missing = path.join(dir, 'does-not-exist');
  const logs = [];
  try {
    fs.writeFileSync(helper, '#!/bin/sh\nexit 0\n');
    fs.chmodSync(helper, 0o755);

    ensureExecutablePaths([missing, helper], (...args) => logs.push(args));
    ensureExecutablePaths([missing, helper], (...args) => logs.push(args));

    assert.equal(modeOf(helper), 0o755);
    assert.deepEqual(logs, []);
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
});

test('ensureSpawnHelperExecutable is safe to call repeatedly', () => {
  assert.doesNotThrow(() => ensureSpawnHelperExecutable());
  assert.doesNotThrow(() => ensureSpawnHelperExecutable());
  const bundled = getBundledSpawnHelperPaths();
  assert.equal(Array.isArray(bundled), true);
  assert.equal(bundled.length, 2);
});
