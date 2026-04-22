import { createBashTool, type ExtensionAPI, type ExtensionCommandContext, type ExtensionContext } from '@mariozechner/pi-coding-agent';
import { Type } from '@sinclair/typebox';
import { createPtyBashOperations, executePtyCommand, killAllActiveSessions } from './pty-execute.ts';
import { ensureSpawnHelperExecutable } from './spawn-helper.ts';

const bashLiveViewParams = Type.Object({
  command: Type.String({ description: 'Command to execute' }),
  timeout: Type.Optional(Type.Number({ description: 'Timeout in seconds' })),
  usePTY: Type.Optional(Type.Boolean({ description: 'Run inside a PTY with a live terminal widget the user can see while its running. Use this when you suspect the program being ran has interesting ansi progress output, like buildsystems.' })),
});

ensureSpawnHelperExecutable();

async function runSlashCommand(args: string, ctx: ExtensionCommandContext) {
  const command = args.trim();
  if (!command) {
    ctx.ui.notify('Usage: /bash-pty <command>', 'error');
    return;
  }
  const result = await executePtyCommand(
    `slash-${Date.now()}`,
    { command },
    new AbortController().signal,
    ctx as unknown as ExtensionContext,
  );
  const text = result.content[0]?.type === 'text' ? result.content[0].text : '(no output)';
  ctx.ui.notify(text.slice(0, 4000), 'info');
}

export default function bashLiveView(pi: ExtensionAPI) {
  const originalBash = createBashTool(process.cwd());

  pi.registerTool({
    name: 'bash',
    label: 'bash',
    description: `${originalBash.description} Supports optional usePTY=true live terminal rendering for terminal-style programs and richer progress UIs.`,
    promptSnippet: 'Execute bash commands. Set usePTY=true for build/test/compile commands, long-running processes, or anything with streaming output.',
    promptGuidelines: [
      'Set usePTY=true for any command that may take more than a few seconds or produces streaming/progress output.',
      'Always use usePTY=true for: make, cmake, cargo build, cargo run, cargo test, npm run, npm test, npx, yarn, pnpm, go build, go test, go run, docker build, docker compose, docker run, gradle, mvn, ant, bazel, pytest, python -m pytest, jest, vitest, mocha, gcc, g++, clang, rustc, javac, tsc, webpack, vite, esbuild, rollup, pip install, apt, brew, and any CI/build/test/compile commands.',
      'Use usePTY=true when chaining build commands (e.g. "cd dir && make clean && make").',
      'Use usePTY=true for long-running processes, servers, watch modes, and interactive programs.',
      'When in doubt about execution time, prefer usePTY=true — it has no downside.',
    ],
    parameters: bashLiveViewParams,
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      if (params.usePTY !== true) {
        return originalBash.execute(toolCallId, params, signal, onUpdate);
      }
      return executePtyCommand(toolCallId, params, signal, ctx);
    },
  });

  pi.on('user_bash', (_event, ctx) => {
    return {
      operations: createPtyBashOperations(ctx),
    };
  });

  pi.registerShortcut('ctrl+x', {
    description: 'Kill running live terminal',
    handler: async () => {
      killAllActiveSessions();
    },
  });

  // Inject usePTY reminder into system prompt every turn
  pi.on('before_agent_start', async (event) => {
    return {
      systemPrompt: event.systemPrompt + `\n\n<important>\nWhen using the bash tool, ALWAYS set usePTY=true for:\n- Build commands: make, cmake, cargo, go build, gcc, g++, clang, rustc, javac, tsc\n- Package managers: npm, yarn, pnpm, pip, cargo, apt, brew\n- Test runners: pytest, jest, vitest, mocha, cargo test, go test, npm test\n- Bundlers: webpack, vite, esbuild, rollup\n- Containers: docker build, docker compose, docker run\n- Any chained commands (&&, ||, ;) that include the above\n- Any command likely to take more than 3 seconds\n- When in doubt, prefer usePTY=true — it has no downside\n</important>`,
    };
  });

  pi.registerCommand('bash-pty', {
    description: 'Run a command through the PTY-backed bash path',
    handler: async (args, ctx) => {
      await runSlashCommand(args, ctx);
    },
  });
}
