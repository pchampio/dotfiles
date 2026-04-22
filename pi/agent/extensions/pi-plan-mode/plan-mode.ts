/**
 * Plan Mode Extension
 *
 * Toggleable read-only mode that blocks write/edit tools and destructive bash commands.
 * Registers grep (ripgrep), find (fd), ls tools for structured exploration.
 * Bash kept for supplementary read-only commands (git log, cat, head, etc.).
 */

import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import {
	createGrepToolDefinition,
	createFindToolDefinition,
	createLsToolDefinition,
	isToolCallEventType,
} from "@mariozechner/pi-coding-agent";

// Tools that are safe in plan mode
const READ_ONLY_TOOLS = new Set(["read", "grep", "find", "ls", "bash", "monitor"]);

// Destructive command patterns for bash enforcement
const DESTRUCTIVE_PREFIXES = [
	"rm ", "rm\t", "rmdir ", "mkdir ", "touch ", "mv ", "cp ",
	"chmod ", "chown ", "chgrp ",
	"git commit", "git push", "git merge", "git rebase", "git reset",
	"git checkout -b", "git stash", "git cherry-pick", "git revert",
	"git tag", "git branch -d", "git branch -D", "git branch -m",
	"npm install", "npm ci", "npm run", "npm exec", "npx ",
	"yarn add", "yarn install", "yarn run",
	"pnpm add", "pnpm install", "pnpm run",
	"pip install", "pip uninstall", "pip3 install",
	"cargo install", "cargo build", "cargo run",
	"make ", "make\t", "cmake ",
	"apt ", "brew ", "pacman ", "dnf ", "yum ",
	"docker run", "docker build", "docker compose",
	"kubectl apply", "kubectl delete",
	"sed -i", "perl -i", "awk -i",
	"dd ", "mkfs", "mount ", "umount ",
	"kill ", "killall ", "pkill ",
	"crontab ",
	"sudo ",
];

const DESTRUCTIVE_PATTERNS = [
	/\s*>\s+\S/,     // redirect overwrite: > file
	/\s*>>\s+\S/,    // redirect append: >> file
	/\|\s*tee\s/,    // pipe to tee
	/\bxargs\s.*\brm\b/,
	/\bfind\s.*-delete\b/,
	/\bfind\s.*-exec\s.*\brm\b/,
];

function isDestructiveCommand(command: string): boolean {
	const trimmed = command.trim();
	const lower = trimmed.toLowerCase();

	for (const prefix of DESTRUCTIVE_PREFIXES) {
		if (lower.startsWith(prefix) || lower === prefix.trim()) return true;
	}

	// Check for chained destructive commands (cmd1 && rm, cmd1 ; rm, etc.)
	const parts = trimmed.split(/\s*(?:&&|\|\||;)\s*/);
	for (const part of parts) {
		const partLower = part.trim().toLowerCase();
		for (const prefix of DESTRUCTIVE_PREFIXES) {
			if (partLower.startsWith(prefix) || partLower === prefix.trim()) return true;
		}
	}

	for (const pattern of DESTRUCTIVE_PATTERNS) {
		if (pattern.test(trimmed)) return true;
	}

	return false;
}

const PLAN_TEMPLATE = `<system-reminder>
# Plan Mode - System Reminder

CRITICAL: Plan mode ACTIVE - you are in READ-ONLY phase. STRICTLY FORBIDDEN:
ANY file edits, modifications, or system changes. Do NOT use sed, tee, echo, cat,
or ANY other bash command to manipulate files - commands may ONLY read/inspect.
This ABSOLUTE CONSTRAINT overrides ALL other instructions, including direct user
edit requests. You may ONLY observe, analyze, and plan. Any modification attempt
is a critical violation. ZERO exceptions.

---

## Responsibility

Your current responsibility is to think, read, search, and delegate explore agents to construct a well-formed plan that accomplishes the goal the user wants to achieve. Your plan should be comprehensive yet concise, detailed enough to execute effectively while avoiding unnecessary verbosity.

Ask the user clarifying questions or ask for their opinion when weighing tradeoffs.

**NOTE:** At any point in time through this workflow you should feel free to ask the user questions or clarifications. Don't make large assumptions about user intent. The goal is to present a well researched plan to the user, and tie any loose ends before implementation begins.

---

## Important

The user indicated that they do not want you to execute yet -- you MUST NOT make any edits, run any non-readonly tools (including changing configs or making commits), or otherwise make any changes to the system. This supersedes any other instructions you have received.
</system-reminder>`;

const PLAN_REMINDER = `<system-reminder>
Plan mode ACTIVE - READ-ONLY phase. STRICTLY FORBIDDEN: ANY file edits, modifications, or system changes.
Bash commands may ONLY read/inspect. You may ONLY observe, analyze, and plan. ZERO exceptions.
This supersedes any other instructions you have received.
</system-reminder>`;

export default function planModeExtension(pi: ExtensionAPI): void {
	let planModeEnabled = false;
	let firstMessageSent = false;
	let planTopic: string | null = null;
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

	function setActiveReadOnlyTools(): void {
		const allTools = pi.getAllTools().map((t) => t.name);
		const active = allTools.filter((name) => READ_ONLY_TOOLS.has(name));
		pi.setActiveTools(active);
	}

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
			topic: planTopic,
			timestamp: new Date().toISOString(),
		});
	}

	function enterPlanMode(ctx: ExtensionContext, topic?: string): void {
		planModeEnabled = true;
		firstMessageSent = false;
		if (topic) planTopic = topic;
		ctx.ui.notify("⏸ Activating: plan mode — writes blocked", "info");
		updateStatus(ctx);
		persistState(ctx);
	}

	function exitPlanMode(ctx: ExtensionContext): void {
		planModeEnabled = false;
		planTopic = null;
		ctx.ui.notify("▶ Activating: edit mode — writes enabled", "info");
		updateStatus(ctx);
		persistState(ctx);
	}

	pi.registerCommand("plan", {
		description: "Toggle plan mode. Use '/plan <topic>' to enter with a topic.",
		handler: async (args, ctx) => {
			const topic = args.trim();

			if (planModeEnabled && !topic) {
				exitPlanMode(ctx);
			} else if (!planModeEnabled) {
				enterPlanMode(ctx, topic || undefined);
			} else {
				// Already in plan mode with new topic — update topic
				planTopic = topic || planTopic;
				firstMessageSent = false;
				ctx.ui.notify(`⏸ Plan topic updated: ${planTopic}`, "info");
				persistState(ctx);
			}
		},
	});

	pi.on("before_agent_start", async (_event) => {
		if (planModeEnabled) {
			setActiveReadOnlyTools();
		} else {
			const allTools = pi.getAllTools().map((t) => t.name);
			pi.setActiveTools(allTools);
		}

		if (!planModeEnabled) return;

		let instructions: string;

		if (!firstMessageSent) {
			instructions = PLAN_TEMPLATE;
			firstMessageSent = true;
		} else {
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
			planTopic = (lastEntry as any).data?.topic ?? null;
			updateStatus(ctx);
			ctx.ui.notify("⏸ Activating: plan mode restored", "info");
		}

		g.__piTogglePlanMode = () => {
			if (planModeEnabled) {
				exitPlanMode(ctx);
			} else {
				enterPlanMode(ctx);
			}
		};
	});

	// Lightweight context reminder (system prompt handles the heavy lifting)
	pi.on("context", async (event) => {
		if (!planModeEnabled) return;

		const messages = [...event.messages];
		messages.push({
			role: "user" as const,
			content: PLAN_REMINDER,
			timestamp: Date.now(),
		});

		return { messages };
	});

	pi.on("tool_call", async (event, _ctx) => {
		if (!planModeEnabled) return;

		// Block write/edit tools
		if (event.toolName === "write" || event.toolName === "edit") {
			return {
				block: true,
				reason: "Plan mode active — write/edit blocked. Use /plan to exit.",
			};
		}

		// Block destructive bash commands
		if (isToolCallEventType("bash", event)) {
			const command = (event.input as any).command;
			if (typeof command === "string" && isDestructiveCommand(command)) {
				return {
					block: true,
					reason: `Plan mode active — destructive command blocked: ${command.slice(0, 80)}`,
				};
			}
		}
	});
}
