/**
 * True Queue Extension
 *
 * Solves the "goal anchoring" problem: when an agent sees multiple future tasks,
 * it rushes through the current one. This extension lets users enqueue tasks with
 * "+" prefix — the agent never sees queued tasks until the current one is done.
 *
 * Usage:
 *   Normal input         → steer (agent sees immediately)
 *   +do something        → enqueue (starts automatically when current task ends)
 *   ++do something       → enqueue with confirm before starting
 *
 * Commands:
 *   /queue               → show queue / open edit mode
 *   /queue add <task>    → add a task
 *   /queue clear         → clear all
 *   /queue done          → mark current done, start next
 *   /queue skip          → drop current task
 *   /queue pause/resume  → pause/resume auto-dequeue
 *
 * Shortcuts:
 *   Ctrl+\\               → open queue editor overlay
 *
 * Tool:
 *   enqueue_task         → let the agent queue a task when the user explicitly asks
 */

import type { ExtensionAPI, ExtensionContext, Theme } from "@mariozechner/pi-coding-agent";
import { DynamicBorder } from "@mariozechner/pi-coding-agent";
import { CURSOR_MARKER, type Focusable, matchesKey, truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";
import { Type } from "@sinclair/typebox";

const DEQUEUE_DELAY_MS = 1000;

interface QueueItem {
	text: string;
	confirm: boolean;
}

interface QueueState {
	queue: QueueItem[];
	currentTask: string | null;
	paused: boolean;
	pauseReason?: string;
}

function emptyState(): QueueState {
	return { queue: [], currentTask: null, paused: false };
}

export default function (pi: ExtensionAPI) {
	const state: QueueState = emptyState();
	let dequeueTimer: ReturnType<typeof setTimeout> | null = null;

	function clearTimers() {
		if (dequeueTimer) clearTimeout(dequeueTimer);
		dequeueTimer = null;
	}

	function normalize(text: string) {
		return text.replace(/^\[queued task\]\s*/i, "").replace(/\s+/g, " ").trim().toLowerCase();
	}

	function isDuplicate(text: string) {
		const n = normalize(text);
		if (state.currentTask && normalize(state.currentTask) === n) return "active" as const;
		const pos = state.queue.findIndex((t) => normalize(t.text) === n);
		if (pos >= 0) return pos + 1;
		return false;
	}

	function notify(ctx: ExtensionContext, text: string, level: "info" | "warning" | "error" = "info") {
		if (ctx.hasUI) ctx.ui.notify(text, level);
	}

	function persist() {
		pi.appendEntry("true-queue-state", { ...state, queue: [...state.queue] });
	}

	function loadState(ctx: ExtensionContext) {
		const branch = ctx.sessionManager.getBranch() as any[];
		let restored = emptyState();

		for (const entry of branch) {
			if (entry.type !== "custom") continue;
			if (entry.customType !== "true-queue-state" && entry.customType !== "task-queue-state") continue;
			const d = entry.data;
			if (!d || typeof d !== "object") continue;

			restored = emptyState();
			if (Array.isArray(d.queue)) {
				restored.queue = d.queue
					.filter((t: any) => t && typeof t.text === "string" && t.text.trim())
					.map((t: any) => ({ text: t.text.trim(), confirm: Boolean(t.confirm) }));
			}
			if (typeof d.currentTask === "string") {
				restored.currentTask = d.currentTask.trim() || null;
			} else if (d.currentTask && typeof d.currentTask.text === "string") {
				restored.currentTask = d.currentTask.text.trim() || null;
			}
			restored.paused = Boolean(d.paused);
			if (typeof d.pauseReason === "string" && d.pauseReason.trim()) {
				restored.pauseReason = d.pauseReason.trim();
			}
		}

		Object.assign(state, restored);
		clearTimers();
	}

	function enqueue(text: string, confirm: boolean, ctx: ExtensionContext) {
		const trimmed = text.trim();
		if (!trimmed) return { added: false as const, reason: "empty" as const };

		const dup = isDuplicate(trimmed);
		if (dup === "active") return { added: false as const, reason: "active" as const };
		if (dup !== false) return { added: false as const, reason: "queued" as const, position: dup };

		state.queue.push({ text: trimmed, confirm });
		persist();
		updateWidget(ctx);
		return { added: true as const, position: state.queue.length };
	}

	async function startNext(ctx: ExtensionContext) {
		while (state.queue.length > 0) {
			const next = state.queue[0];

			if (next.confirm) {
				if (!ctx.hasUI) {
					state.paused = true;
					state.pauseReason = "Next task requires confirmation (no UI).";
					persist();
					updateWidget(ctx);
					return;
				}
				const preview = next.text.length > 80 ? next.text.slice(0, 80) + "…" : next.text;
				if (!(await ctx.ui.confirm("Next task", `Start this queued task?\n\n${preview}`))) {
					state.queue.shift();
					persist();
					updateWidget(ctx);
					continue;
				}
			}

			const task = state.queue.shift()!;
			state.currentTask = task.text;
			state.pauseReason = undefined;
			persist();
			updateWidget(ctx);

			const prompt = `[Queued task]\n\n${task.text}`;
			if (ctx.isIdle()) {
				pi.sendUserMessage(prompt);
			} else {
				pi.sendUserMessage(prompt, { deliverAs: "followUp" });
			}
			return;
		}

		updateWidget(ctx);
	}

	async function advance(ctx: ExtensionContext) {
		if (state.paused || state.queue.length === 0) return;
		state.currentTask = null;
		persist();
		await startNext(ctx);
	}

	function scheduleAdvance(ctx: ExtensionContext) {
		clearTimers();
		dequeueTimer = setTimeout(async () => {
			dequeueTimer = null;
			try {
				if (ctx.hasPendingMessages()) return;
				await advance(ctx);
			} catch (error) {
				console.error(`[true-queue] Advance error: ${error}`);
			}
		}, DEQUEUE_DELAY_MS);
	}

	// ── Widget ──

	function updateStatus(ctx: ExtensionContext) {
		if (!ctx.hasUI) return;
		if (state.queue.length > 0 || state.currentTask) {
			const theme = ctx.ui.theme;
			ctx.ui.setStatus("true-queue", theme.fg("dim", "ctrl+\\ queue"));
		} else {
			ctx.ui.setStatus("true-queue", undefined);
		}
	}

	function updateWidget(ctx: ExtensionContext) {
		if (!ctx.hasUI) return;
		updateStatus(ctx);

		if (!state.currentTask && state.queue.length === 0 && !state.paused) {
			ctx.ui.setWidget("true-queue", undefined);
			return;
		}

		ctx.ui.setWidget("true-queue", (_tui, theme) => {
			return {
				render: (width: number) => renderWidgetLines(theme, width),
				invalidate: () => {},
			};
		});
	}

	function renderWidgetLines(theme: Theme, width: number): string[] {
		const lines: string[] = [];

		if (state.currentTask) {
			const pauseIcon = state.paused ? theme.fg("warning", " ⏸") : "";
			lines.push(truncateToWidth(theme.fg("accent", "🎯 ") + theme.fg("toolTitle", state.currentTask) + pauseIcon, width));
		} else if (state.paused) {
			lines.push(theme.fg("warning", "⏸ Queue paused"));
		}

		if (state.queue.length > 0) {
			for (let i = 0; i < state.queue.length; i++) {
				const t = state.queue[i];
				const num = theme.fg("dim", `${i + 1}.`);
				const confirmIcon = t.confirm ? theme.fg("warning", "◉ ") : "";
				lines.push(truncateToWidth(`  ${num} ${confirmIcon}${theme.fg("muted", t.text)}`, width));
			}
		}

		if (state.paused && state.pauseReason) {
			lines.push(truncateToWidth(theme.fg("dim", `   ${state.pauseReason}`), width));
		}

		return lines;
	}

	// ── Queue Editor Overlay ──

	async function openQueueEditor(ctx: ExtensionContext) {
		if (!ctx.hasUI) return;
		if (state.queue.length === 0 && !state.currentTask) {
			notify(ctx, "Queue is empty", "info");
			return;
		}

		await ctx.ui.custom<void>(
			(tui, theme, _kb, done) => {
				const editor = new QueueEditor(theme, state, done, () => {
					persist();
					updateWidget(ctx);
					tui.requestRender();
				});
				return editor;
			},
			{ overlay: true },
		);
	}

	// ── Session lifecycle ──

	function refresh(ctx: ExtensionContext) {
		loadState(ctx);
		updateWidget(ctx);
	}

	pi.on("session_start", async (_e, ctx) => refresh(ctx));
	pi.on("session_switch", async (_e, ctx) => refresh(ctx));
	pi.on("session_fork", async (_e, ctx) => refresh(ctx));
	pi.on("session_tree", async (_e, ctx) => refresh(ctx));
	pi.on("session_shutdown", async () => clearTimers());

	// ── Input handler ──

	pi.on("input", async (event, ctx) => {
		if (event.source === "extension") return { action: "continue" as const };

		const text = event.text.trim();
		const withConfirm = text.startsWith("++");
		const queued = withConfirm ? text.slice(2).trim() : text.startsWith("+") ? text.slice(1).trim() : null;
		if (queued === null) return { action: "continue" as const };
		if (!queued) return { action: "handled" as const };

		const result = enqueue(queued, withConfirm, ctx);
		if (!result.added) {
			if (result.reason === "active") notify(ctx, "That task is already active.", "warning");
			else if (result.reason === "queued") notify(ctx, `Already queued at position ${result.position}.`, "info");
			return { action: "handled" as const };
		}

		if (ctx.isIdle() && !state.currentTask && !state.paused) {
			await advance(ctx);
		}

		return { action: "handled" as const };
	});

	// ── Agent end ──

	pi.on("agent_end", async (_event, ctx) => {
		if (state.queue.length === 0) {
			if (state.currentTask) {
				state.currentTask = null;
				persist();
				updateWidget(ctx);
			}
			return;
		}
		if (state.paused) return;
		scheduleAdvance(ctx);
	});

	// ── Shortcut ──

	pi.registerShortcut("ctrl+\\", {
		description: "Open queue editor",
		handler: async (ctx) => {
			await openQueueEditor(ctx);
		},
	});

	// ── Tool ──

	pi.registerTool({
		name: "enqueue_task",
		label: "Enqueue Task",
		description: "Add a task to the deferred task queue. Use only when the user explicitly asks you to queue or defer something for later.",
		promptSnippet: "Add a task to the deferred task queue for later execution.",
		promptGuidelines: [
			"Use enqueue_task only when the user explicitly asks to queue, defer, or save a task for later.",
			"Do not use enqueue_task for your own internal planning unless the user asked for it.",
			"Never use enqueue_task for the task that is currently active — work on that task instead.",
		],
		parameters: Type.Object({
			task: Type.String({ description: "Task text to enqueue" }),
			confirm: Type.Optional(
				Type.Boolean({ description: "Require user confirmation before starting this queued task", default: false }),
			),
		}),
		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			const result = enqueue(params.task, params.confirm ?? false, ctx);
			if (!result.added) {
				if (result.reason === "active") {
					throw new Error("This task is already active. Work on it now instead of queueing it again.");
				}
				return {
					content: [{ type: "text", text: `Already queued at position ${result.position}: ${params.task}` }],
					details: { duplicate: true, position: result.position },
				};
			}
			return {
				content: [{ type: "text", text: `Queued at position ${result.position}: ${params.task}` }],
				details: { position: result.position },
			};
		},
	});

	// ── Command ──

	pi.registerCommand("queue", {
		description: "Manage the task queue",
		handler: async (args, ctx) => {
			const parts = args.trim().split(/\s+/);
			const sub = parts[0]?.toLowerCase();

			if (!sub || sub === "edit") {
				await openQueueEditor(ctx);
				return;
			}

			if (sub === "add") {
				const task = args.trim().slice(3).trim();
				if (!task) {
					notify(ctx, "Usage: /queue add <task>", "warning");
					return;
				}
				const result = enqueue(task, false, ctx);
				if (!result.added) {
					notify(ctx, result.reason === "active" ? "Already active." : `Already queued at #${result.position}.`, "warning");
				} else {
					notify(ctx, `Queued at position ${result.position}`, "info");
				}
				return;
			}

			if (sub === "clear") {
				state.queue = [];
				persist();
				updateWidget(ctx);
				notify(ctx, "Queue cleared", "info");
				return;
			}

			if (sub === "done" || sub === "next") {
				if (!state.currentTask) {
					notify(ctx, "No current task", "warning");
					if (!state.paused && state.queue.length > 0 && ctx.isIdle()) await startNext(ctx);
					return;
				}
				const finished = state.currentTask;
				state.currentTask = null;
				persist();
				updateWidget(ctx);
				notify(ctx, `Done: "${finished.slice(0, 60)}"`, "info");
				if (!state.paused && state.queue.length > 0) await startNext(ctx);
				return;
			}

			if (sub === "skip") {
				if (!state.currentTask) {
					notify(ctx, "No current task", "warning");
					return;
				}
				state.currentTask = null;
				persist();
				updateWidget(ctx);
				notify(ctx, "Current task skipped", "info");
				return;
			}

			if (sub === "pause") {
				state.paused = true;
				state.pauseReason = "Paused by user.";
				persist();
				updateWidget(ctx);
				notify(ctx, "Queue paused", "info");
				return;
			}

			if (sub === "resume") {
				state.paused = false;
				state.pauseReason = undefined;
				persist();
				updateWidget(ctx);
				if (ctx.isIdle() && state.queue.length > 0) await advance(ctx);
				return;
			}

			notify(ctx, `Unknown subcommand: ${sub}. Try: add, clear, done, skip, pause, resume, edit`, "warning");
		},
	});
}

// ── Queue Editor Component ──

class QueueEditor implements Focusable {
	focused = false;
	private selected = 0;
	private adding = false;
	private addText = "";
	private addCursor = 0;
	private editing = -1;
	private editText = "";
	private editCursor = 0;

	constructor(
		private theme: Theme,
		private state: QueueState,
		private done: (result: void) => void,
		private onChange: () => void,
	) {}

	handleInput(data: string): void {
		// Adding mode
		if (this.adding) {
			if (matchesKey(data, "escape")) {
				this.adding = false;
				return;
			}
			if (matchesKey(data, "return")) {
				const text = this.addText.trim();
				if (text) {
					this.state.queue.push({ text, confirm: false });
					this.onChange();
				}
				this.adding = false;
				this.addText = "";
				this.addCursor = 0;
				return;
			}
			this.handleTextInput(data, "add");
			return;
		}

		// Editing mode
		if (this.editing >= 0) {
			if (matchesKey(data, "escape")) {
				this.editing = -1;
				return;
			}
			if (matchesKey(data, "return")) {
				const text = this.editText.trim();
				if (text && this.editing < this.state.queue.length) {
					this.state.queue[this.editing].text = text;
					this.onChange();
				}
				this.editing = -1;
				return;
			}
			this.handleTextInput(data, "edit");
			return;
		}

		// Normal mode
		if (matchesKey(data, "escape") || matchesKey(data, "q")) {
			this.done();
			return;
		}

		const qLen = this.state.queue.length;

		if (matchesKey(data, "up") || matchesKey(data, "k")) {
			if (this.selected > 0) this.selected--;
		} else if (matchesKey(data, "down") || matchesKey(data, "j")) {
			if (this.selected < qLen - 1) this.selected++;
		} else if (matchesKey(data, "shift+up") || matchesKey(data, "K")) {
			if (this.selected > 0 && qLen > 1) {
				const tmp = this.state.queue[this.selected];
				this.state.queue[this.selected] = this.state.queue[this.selected - 1];
				this.state.queue[this.selected - 1] = tmp;
				this.selected--;
				this.onChange();
			}
		} else if (matchesKey(data, "shift+down") || matchesKey(data, "J")) {
			if (this.selected < qLen - 1 && qLen > 1) {
				const tmp = this.state.queue[this.selected];
				this.state.queue[this.selected] = this.state.queue[this.selected + 1];
				this.state.queue[this.selected + 1] = tmp;
				this.selected++;
				this.onChange();
			}
		} else if (matchesKey(data, "d") || matchesKey(data, "backspace") || matchesKey(data, "delete")) {
			if (qLen > 0) {
				this.state.queue.splice(this.selected, 1);
				if (this.selected >= this.state.queue.length && this.selected > 0) this.selected--;
				this.onChange();
			}
		} else if (matchesKey(data, "a")) {
			this.adding = true;
			this.addText = "";
			this.addCursor = 0;
		} else if (matchesKey(data, "e") || matchesKey(data, "return")) {
			if (this.selected < qLen) {
				this.editing = this.selected;
				this.editText = this.state.queue[this.selected].text;
				this.editCursor = this.editText.length;
			}
		} else if (matchesKey(data, "c")) {
			if (this.selected < qLen) {
				this.state.queue[this.selected].confirm = !this.state.queue[this.selected].confirm;
				this.onChange();
			}
		} else if (matchesKey(data, "p")) {
			this.state.paused = !this.state.paused;
			this.state.pauseReason = this.state.paused ? "Paused by user." : undefined;
			this.onChange();
		}
	}

	private handleTextInput(data: string, mode: "add" | "edit") {
		const text = mode === "add" ? this.addText : this.editText;
		const cursor = mode === "add" ? this.addCursor : this.editCursor;

		let newText = text;
		let newCursor = cursor;

		if (matchesKey(data, "backspace")) {
			if (cursor > 0) {
				newText = text.slice(0, cursor - 1) + text.slice(cursor);
				newCursor = cursor - 1;
			}
		} else if (matchesKey(data, "delete")) {
			if (cursor < text.length) {
				newText = text.slice(0, cursor) + text.slice(cursor + 1);
			}
		} else if (matchesKey(data, "left")) {
			newCursor = Math.max(0, cursor - 1);
		} else if (matchesKey(data, "right")) {
			newCursor = Math.min(text.length, cursor + 1);
		} else if (matchesKey(data, "home")) {
			newCursor = 0;
		} else if (matchesKey(data, "end")) {
			newCursor = text.length;
		} else if (data.length === 1 && data.charCodeAt(0) >= 32) {
			newText = text.slice(0, cursor) + data + text.slice(cursor);
			newCursor = cursor + 1;
		}

		if (mode === "add") {
			this.addText = newText;
			this.addCursor = newCursor;
		} else {
			this.editText = newText;
			this.editCursor = newCursor;
		}
	}

	render(width: number): string[] {
		const th = this.theme;
		const innerW = width - 4;
		const lines: string[] = [];

		const pad = (s: string, w: number) => {
			const vis = visibleWidth(s);
			return s + " ".repeat(Math.max(0, w - vis));
		};
		const row = (content: string) => "  " + truncateToWidth(content, innerW);

		// Header
		lines.push(row(th.fg("border", "─".repeat(Math.min(innerW, 50)))));
		const pauseLabel = this.state.paused ? th.fg("warning", " [PAUSED]") : "";
		lines.push(row(th.fg("accent", th.bold("📋 Queue Editor")) + pauseLabel));
		lines.push(row(""));

		// Current task
		if (this.state.currentTask) {
			lines.push(row(th.fg("dim", "Current: ") + th.fg("toolTitle", this.state.currentTask)));
			lines.push(row(""));
		}

		// Queue items
		if (this.state.queue.length === 0) {
			lines.push(row(th.fg("dim", "  (empty queue)")));
		} else {
			for (let i = 0; i < this.state.queue.length; i++) {
				const item = this.state.queue[i];
				const isSelected = i === this.selected && !this.adding;
				const prefix = isSelected ? th.fg("accent", "▸ ") : "  ";
				const num = th.fg("dim", `${i + 1}.`);
				const confirmIcon = item.confirm ? th.fg("warning", "◉ ") : "";

				if (this.editing === i) {
					const marker = this.focused ? CURSOR_MARKER : "";
					const before = this.editText.slice(0, this.editCursor);
					const cursorChar = this.editCursor < this.editText.length ? this.editText[this.editCursor]! : " ";
					const after = this.editText.slice(this.editCursor + 1);
					lines.push(row(`${prefix}${num} ${confirmIcon}${before}${marker}\x1b[7m${cursorChar}\x1b[27m${after}`));
				} else {
					const textColor = isSelected ? "text" : "muted";
					lines.push(row(`${prefix}${num} ${confirmIcon}${th.fg(textColor, item.text)}`));
				}
			}
		}

		// Add input
		if (this.adding) {
			lines.push(row(""));
			const marker = this.focused ? CURSOR_MARKER : "";
			const before = this.addText.slice(0, this.addCursor);
			const cursorChar = this.addCursor < this.addText.length ? this.addText[this.addCursor]! : " ";
			const after = this.addText.slice(this.addCursor + 1);
			lines.push(row(th.fg("accent", "  + ") + `${before}${marker}\x1b[7m${cursorChar}\x1b[27m${after}`));
		}

		// Help
		lines.push(row(""));
		if (this.adding || this.editing >= 0) {
			lines.push(row(th.fg("dim", "enter confirm • esc cancel")));
		} else {
			lines.push(row(th.fg("dim", "↑↓ navigate • ⇧↑↓ reorder • a add • e edit • d delete")));
			lines.push(row(th.fg("dim", "c toggle confirm • p pause • esc close")));
		}
		lines.push(row(th.fg("border", "─".repeat(Math.min(innerW, 50)))));

		return lines;
	}

	invalidate(): void {}
}
