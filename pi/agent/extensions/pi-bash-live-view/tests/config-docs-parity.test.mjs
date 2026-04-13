import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const readme = readFileSync(new URL('../README.md', import.meta.url), 'utf8');

test('README no longer documents removed runtime config files or keys', () => {
  assert.doesNotMatch(readme, /pi-bash-live-view\.json/);
  assert.doesNotMatch(readme, /widgetDelayMs/);
  assert.doesNotMatch(readme, /testWidth/);
  assert.doesNotMatch(readme, /scrollbackLines/);
});
