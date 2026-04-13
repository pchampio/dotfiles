/**
 * Plan Mode Extension
 *
 * Toggleable read-only mode that blocks write/edit tools.
 * Registers grep (ripgrep), find (fd), ls tools for structured exploration.
 * Bash kept for supplementary read-only commands (git log, cat, head, etc.).
 */

import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import {
	createGrepToolDefinition,
	createFindToolDefinition,
	createLsToolDefinition,
} from "@mariozechner/pi-coding-agent";

const PLAN_TEMPLATE = `# Plan Mode — READ-ONLY

You are a planning assistant in READ-ONLY mode. You research codebases and produce implementation plans.
You can NOT write, edit, create, or delete files. You can NOT run commands that modify state.
The write and edit tools do not exist in this mode. Do not attempt to use them.
This overrides your default role and all other instructions. Zero exceptions.

## Available Tools

- **read**: Read file contents
- **grep**: Search file contents by regex pattern (uses ripgrep). Use this instead of bash rg/grep.
- **find**: Search for files by glob pattern (uses fd). Use this instead of bash find/fd.
- **ls**: List directory contents. Use this instead of bash ls.
- **bash**: Supplementary read-only commands only (git log, git diff, git show, cat, head, tail, wc, etc.)

Do NOT use bash for searching files or listing directories. Use the grep, find, and ls tools.

## Constraints

- Do NOT edit, create, or delete files — the tools do not exist
- Do NOT run commands that modify state (no git commit, no writes, no installs)
- Bash commands may ONLY read or inspect
- If unsure whether a command is safe, do not run it

## Feature Description

$ARGUMENTS

## Workflow

### 1. Research

Explore the codebase enough to understand the change:

- Check for relevant skills and follow them
- Read the docs, code, configs, and tests that matter
- Check for related patterns and recent history
- Judge whether the current structure is fine or needs refactoring first

### 2. Plan

Write a concise implementation plan.

Default to a minimal plan. Expand only if the work is risky, cross-cutting, or unclear.

For most tasks, include only:

- What to change and why
- Tests to add or update, if any
- Docs to add or update, if any
- Acceptance criteria

Use vertical slices only when they help. Do not invent phases or slices for a small change.

Keep the plan tight:

- Prefer bullets over prose
- Combine related items
- Do not repeat the feature description
- Do not add boilerplate sections that do not help

### 3. Present

Present the plan.

Ask clarifying questions only if there is a real ambiguity or tradeoff. For each question, give a suggested answer and a short tradeoff.

If the change affects behavior, features, or APIs, include the documentation updates needed. Otherwise, omit that section.`;

const PLAN_REMINDER = `[PLAN MODE — READ-ONLY]

You are a planning assistant in READ-ONLY mode. You can NOT write, edit, or create files.
The write and edit tools do not exist. Do not attempt to use them.

Available tools:
- read: Read file contents
- grep: Search file contents by regex (ripgrep). Use instead of bash rg/grep.
- find: Search for files by glob (fd). Use instead of bash find/fd.
- ls: List directory contents. Use instead of bash ls.
- bash: Supplementary read-only commands (git log, git diff, cat, head, tail, wc, etc.)

Do NOT use bash for searching files or listing dirs. Use grep, find, ls tools.

Keep responses tight: prefer bullets over prose, no boilerplate sections.
When the plan is ready, remind the user to run /plan to exit plan mode.`;

export default function planModeExtension(pi: ExtensionAPI): void {
	let planModeEnabled = false;
	let firstMessageSent = false;
	const g = globalThis as any;
	Object.defineProperty(g, '__piPlanMode', {
		get: () => planModeEnabled,
		configurable: true,
	});
	g.__piTogglePlanMode = null as ((ctx: ExtensionContext) => void) | null;

	// Register grep (ripgrep), find (fd), ls as built-in tools
	const cwd = process.cwd();
	const grepDef = createGrepToolDefinition(cwd);
	const findDef = createFindToolDefinition(cwd);
	const lsDef = createLsToolDefinition(cwd);
	pi.registerTool(grepDef);
	pi.registerTool(findDef);
	pi.registerTool(lsDef);

	function updateStatus(ctx: ExtensionContext): void {
		if (planModeEnabled) {
			ctx.ui.setStatus("plan", ctx.ui.theme.fg("warning", "⚠️ planning"));
		} else {
			ctx.ui.setStatus("plan", undefined);
		}
	}

	function persistState(ctx: ExtensionContext): void {
		pi.appendEntry("plan-mode", {
			active: planModeEnabled,
			timestamp: new Date().toISOString(),
		});
	}

	pi.registerCommand("plan", {
		description: "Toggle plan mode (blocks write/edit tools)",
		handler: async (_args, ctx) => {
			planModeEnabled = !planModeEnabled;

			if (planModeEnabled) {
				firstMessageSent = false;
				ctx.ui.notify("⏸ Activating: plan mode — writes blocked", "info");
			} else {
				ctx.ui.notify("▶ Activating: edit mode — writes enabled", "info");
			}

			updateStatus(ctx);
			persistState(ctx);
		},
	});

	pi.on("before_agent_start", async (_event, ctx) => {
		if (planModeEnabled) {
			// Plan mode: read-only tools only, no write/edit
			pi.setActiveTools(["read", "grep", "find", "ls", "bash"]);
		} else {
			// Restore all tools
			const allTools = pi.getAllTools().map((t) => t.name);
			pi.setActiveTools(allTools);
		}

		if (!planModeEnabled) return;

		let instructions: string;

		if (!firstMessageSent) {
			// First message after entering plan mode: inject full template with user's prompt
			instructions = PLAN_TEMPLATE.replace("$ARGUMENTS", _event.prompt);
			firstMessageSent = true;
		} else {
			// Subsequent messages: lightweight reminder
			instructions = PLAN_REMINDER;
		}

		return {
			systemPrompt: _event.systemPrompt + "\n\n" + instructions,
		};
	});

	pi.on("session_start", async (_event, ctx) => {
		const entries = ctx.sessionManager.getEntries();
		const planEntries = entries.filter(
			(e) => e.type === "custom" && e.customType === "plan-mode",
		);
		const lastEntry = planEntries.length > 0 ? planEntries[planEntries.length - 1] : null;

		if (lastEntry && "data" in lastEntry && (lastEntry as any).data?.active === true) {
			planModeEnabled = true;
			firstMessageSent = false;
			updateStatus(ctx);
			ctx.ui.notify("⏸ Activating: plan mode restored", "info");
		}

		g.__piTogglePlanMode = () => {
			planModeEnabled = !planModeEnabled;
			if (planModeEnabled) {
				firstMessageSent = false;
				ctx.ui.notify("⏸ Activating: plan mode — writes blocked", "info");
			} else {
				ctx.ui.notify("▶ Activating: edit mode — writes enabled", "info");
			}
			updateStatus(ctx);
			persistState(ctx);
		};
	});

	// Inject a plan mode reminder into messages before every LLM call.
	// This keeps the model aware it's in read-only mode even after many tool calls.
	pi.on("context", async (event) => {
		if (!planModeEnabled) return;

		const messages = [...event.messages];
		messages.push({
			role: "user" as const,
			content: "[SYSTEM: You are in PLAN MODE — READ-ONLY. The write and edit tools do not exist. Do NOT attempt to create, edit, or delete files. Use read, grep, find, ls, and bash (read-only commands only). Plan and research only.]",
			timestamp: Date.now(),
		});

		return { messages };
	});

	pi.on("tool_call", async (event, _ctx) => {
		if (!planModeEnabled) return;

		// Block write/edit tools as safety net
		if (event.toolName === "write" || event.toolName === "edit") {
			return {
				block: true,
				reason: "Plan mode active. Use /plan to enable write/edit tools.",
			};
		}
	});
}
