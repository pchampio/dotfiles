/**
 * Tests for plan-mode extension.
 *
 * Covers tool registration, first-message plan template injection, and tool set management.
 */

import { describe, it, expect, vi, beforeEach } from "vitest";
import planModeExtension from "./plan-mode.js";

describe("plan-mode first-message template injection", () => {
	let handlers: Map<string, Function[]>;
	let commands: Map<string, { handler: Function }>;
	let activeTools: string[] | null;
	let mockPi: any;
	let mockCtx: any;

	beforeEach(() => {
		handlers = new Map();
		commands = new Map();
		activeTools = null;

		mockPi = {
			on: (event: string, handler: Function) => {
				if (!handlers.has(event)) handlers.set(event, []);
				handlers.get(event)!.push(handler);
			},
			registerCommand: (name: string, opts: any) => {
				commands.set(name, opts);
			},
			registerTool: vi.fn(),
			setActiveTools: (tools: string[]) => { activeTools = tools; },
			getAllTools: () => [
				{ name: "read" }, { name: "write" }, { name: "edit" },
				{ name: "bash" }, { name: "grep" }, { name: "find" }, { name: "ls" },
			],
			appendEntry: vi.fn(),
		};

		mockCtx = {
			ui: {
				notify: vi.fn(),
				setStatus: vi.fn(),
				theme: { fg: (_type: string, text: string) => text },
			},
			sessionManager: {
				getEntries: () => [],
			},
		};

		planModeExtension(mockPi);
	});

	function fireEvent(event: string, data: any): Promise<any> {
		const eventHandlers = handlers.get(event) || [];
		// Return the result of the last handler (matches pi behavior)
		let result;
		for (const h of eventHandlers) {
			result = h(data, mockCtx);
		}
		return Promise.resolve(result);
	}

	async function enablePlanMode() {
		await commands.get("plan")!.handler("", mockCtx);
	}

	async function disablePlanMode() {
		await commands.get("plan")!.handler("", mockCtx);
	}

	it("registers grep, find, ls tools on startup", async () => {
		expect(mockPi.registerTool).toHaveBeenCalledTimes(3);
		const names = mockPi.registerTool.mock.calls.map((c: any[]) => c[0].name);
		expect(names).toContain("grep");
		expect(names).toContain("find");
		expect(names).toContain("ls");
	});

	it("first message injects full plan template with user prompt as $ARGUMENTS", async () => {
		await enablePlanMode();

		const result = await fireEvent("before_agent_start", {
			type: "before_agent_start",
			prompt: "add dark mode support",
			systemPrompt: "You are a helpful assistant.",
		});

		expect(result).toBeDefined();
		expect(result.systemPrompt).toContain("READ-ONLY");
		expect(result.systemPrompt).toContain("## Feature Description");
		expect(result.systemPrompt).toContain("add dark mode support");
		expect(result.systemPrompt).not.toContain("$ARGUMENTS");
		expect(result.systemPrompt).toContain("## Workflow");
		// Should clearly state write/edit don't exist
		expect(result.systemPrompt).toContain("do not exist");
	});

	it("second message injects lightweight reminder, not the full template", async () => {
		await enablePlanMode();

		// First message
		await fireEvent("before_agent_start", {
			type: "before_agent_start",
			prompt: "add dark mode support",
			systemPrompt: "You are a helpful assistant.",
		});

		// Second message
		const result = await fireEvent("before_agent_start", {
			type: "before_agent_start",
			prompt: "what about the settings file?",
			systemPrompt: "You are a helpful assistant.",
		});

		expect(result).toBeDefined();
		expect(result.systemPrompt).toContain("READ-ONLY");
		expect(result.systemPrompt).toContain("do not exist");
		expect(result.systemPrompt).not.toContain("## Feature Description");
		expect(result.systemPrompt).not.toContain("## Workflow");
		// Should include format guidance
		expect(result.systemPrompt).toContain("bullets over prose");
	});

	it("toggling plan mode off and on resets first-message tracking", async () => {
		await enablePlanMode();

		// First message - uses full template
		await fireEvent("before_agent_start", {
			type: "before_agent_start",
			prompt: "first feature",
			systemPrompt: "base",
		});

		// Toggle off then on
		await disablePlanMode();
		await enablePlanMode();

		// Should get full template again with the new prompt
		const result = await fireEvent("before_agent_start", {
			type: "before_agent_start",
			prompt: "second feature",
			systemPrompt: "base",
		});

		expect(result.systemPrompt).toContain("## Feature Description");
		expect(result.systemPrompt).toContain("second feature");
		expect(result.systemPrompt).not.toContain("first feature");
	});

	it("when plan mode is off, before_agent_start returns nothing", async () => {
		const result = await fireEvent("before_agent_start", {
			type: "before_agent_start",
			prompt: "some message",
			systemPrompt: "base",
		});

		expect(result).toBeUndefined();
	});

	it("plan mode enables read-only tools (read, grep, find, ls, bash)", async () => {
		await enablePlanMode();

		await fireEvent("before_agent_start", {
			type: "before_agent_start",
			prompt: "test",
			systemPrompt: "base",
		});

		expect(activeTools).toEqual(["read", "grep", "find", "ls", "bash"]);
	});

	it("disabling plan mode restores all tools", async () => {
		await enablePlanMode();
		await disablePlanMode();

		await fireEvent("before_agent_start", {
			type: "before_agent_start",
			prompt: "test",
			systemPrompt: "base",
		});

		expect(activeTools).toEqual(["read", "write", "edit", "bash", "grep", "find", "ls"]);
	});

	it("template tells agent to use grep/find/ls tools instead of bash", async () => {
		await enablePlanMode();

		const result = await fireEvent("before_agent_start", {
			type: "before_agent_start",
			prompt: "some feature",
			systemPrompt: "base",
		});

		expect(result.systemPrompt).toContain("grep");
		expect(result.systemPrompt).toContain("find");
		expect(result.systemPrompt).toContain("ls");
		expect(result.systemPrompt).toContain("ripgrep");
		expect(result.systemPrompt).toContain("fd");
		// Should tell agent NOT to use bash for searching/listing
		expect(result.systemPrompt).toContain("Do NOT use bash for searching files or listing directories");
	});

	it("context event injects plan mode reminder into messages", async () => {
		await enablePlanMode();

		const existingMessages = [
			{ role: "user", content: "plan the auth refactor", timestamp: 1 },
			{ role: "assistant", content: [{ type: "text", text: "Let me look..." }], timestamp: 2 },
		];

		const result = await fireEvent("context", {
			type: "context",
			messages: existingMessages,
		});

		expect(result).toBeDefined();
		expect(result.messages).toHaveLength(3);
		expect(result.messages[2].role).toBe("user");
		expect(result.messages[2].content).toContain("PLAN MODE");
		expect(result.messages[2].content).toContain("do not exist");
	});

	it("context event does not inject reminder when plan mode is off", async () => {
		const result = await fireEvent("context", {
			type: "context",
			messages: [{ role: "user", content: "hello", timestamp: 1 }],
		});

		expect(result).toBeUndefined();
	});

	it("session restore with plan mode active treats next message as first", async () => {
		// Simulate session with plan mode persisted
		mockCtx.sessionManager.getEntries = () => [
			{ type: "custom", customType: "plan-mode", data: { active: true } },
		];

		await fireEvent("session_start", { type: "session_start" });

		const result = await fireEvent("before_agent_start", {
			type: "before_agent_start",
			prompt: "continue planning the auth refactor",
			systemPrompt: "base",
		});

		expect(result).toBeDefined();
		expect(result.systemPrompt).toContain("## Feature Description");
		expect(result.systemPrompt).toContain("continue planning the auth refactor");
	});
});
