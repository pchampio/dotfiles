import test from 'node:test';
import assert from 'node:assert/strict';
import { executePtyCommand, WIDGET_DELAY_MS } from '../pty-execute.ts';
import { WIDGET_PREFIX } from '../widget.ts';

async function waitFor(condition, { timeoutMs = 3000, intervalMs = 10 } = {}) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    const value = condition();
    if (value) return value;
    await new Promise((resolve) => setTimeout(resolve, intervalMs));
  }
  throw new Error(`Timed out after ${timeoutMs}ms waiting for condition`);
}

function createUiRecorder() {
  const events = [];
  return {
    events,
    ctx: {
      cwd: process.cwd(),
      hasUI: true,
      ui: {
        setWidget(key, factory) {
          events.push({ key, factory, at: Date.now() });
        },
      },
    },
  };
}

test('concurrent PTY tool calls use distinct widget keys and clean them up independently', async () => {
  const { ctx, events } = createUiRecorder();
  const startTime = Date.now();

  const firstPromise = executePtyCommand(
    `tool-a-${Date.now()}`,
    {
      command: `printf 'alpha-start\n'; sleep 0.18; printf 'alpha-end\n'; sleep 0.08`,
    },
    new AbortController().signal,
    ctx,
  );

  await new Promise((resolve) => setTimeout(resolve, 40));

  const secondPromise = executePtyCommand(
    `tool-b-${Date.now()}`,
    {
      command: `printf 'beta-start\n'; sleep 0.18; printf 'beta-end\n'; sleep 0.14`,
    },
    new AbortController().signal,
    ctx,
  );

  const showEvents = await waitFor(() => events.filter((event) => typeof event.factory === 'function').length >= 2 ? events.filter((event) => typeof event.factory === 'function') : null);

  assert.equal(showEvents.length, 2);
  assert.notEqual(showEvents[0].key, showEvents[1].key);
  assert.match(showEvents[0].key, new RegExp(`^${WIDGET_PREFIX.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}`));
  assert.match(showEvents[1].key, new RegExp(`^${WIDGET_PREFIX.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}`));
  assert.ok(showEvents[0].at - startTime >= WIDGET_DELAY_MS - 20, 'first widget should respect the delay before showing');
  assert.ok(showEvents[1].at - startTime >= WIDGET_DELAY_MS - 20, 'second widget should respect the delay before showing');
  assert.ok(showEvents[1].at >= showEvents[0].at, 'later-started session should not show before the earlier one in this deterministic test');

  const [firstResult, secondResult] = await Promise.all([firstPromise, secondPromise]);

  const hideEvents = events.filter((event) => event.factory === undefined);
  assert.deepEqual(
    hideEvents.map((event) => event.key).sort(),
    showEvents.map((event) => event.key).sort(),
    'every shown widget should later be cleaned up',
  );

  assert.equal(firstResult.content[0]?.type, 'text');
  assert.equal(secondResult.content[0]?.type, 'text');
  assert.match(firstResult.content[0]?.text ?? '', /alpha-start|alpha-end/);
  assert.match(secondResult.content[0]?.text ?? '', /beta-start|beta-end/);
});

test('short PTY commands that finish before the delay never show a widget', async () => {
  const { ctx, events } = createUiRecorder();

  const result = await executePtyCommand(
    `short-${Date.now()}`,
    {
      command: `printf 'quick\n'`,
    },
    new AbortController().signal,
    ctx,
  );

  assert.equal(result.content[0]?.type, 'text');
  assert.match(result.content[0]?.text ?? '', /quick/);
  assert.equal(events.length, 1, 'expected only the final cleanup call when no widget was shown');
  assert.equal(events[0]?.factory, undefined);
  assert.match(events[0]?.key ?? '', new RegExp(`^${WIDGET_PREFIX.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}`));
});
