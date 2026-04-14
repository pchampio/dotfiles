// ABOUTME: Footer widget displaying provider/model, context %, send/recv tokens, last response time, and cwd.
// ABOUTME: Plan mode shows a ⏸ plan indicator in orange.
/**
 * Footer — Status bar with provider/model · context % · tokens ↑/↓ · response time · directory.
 *
 * Tracks per-conversation token usage (input/output) and the wall-clock time
 * of the last LLM response via agent_start / turn_end / agent_end events.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";
import { basename, dirname } from "node:path";

/** Turn a model name like "Claude 4 Opus" into "opus 4" */
function shortModelName(name: string | undefined): string {
	if (!name) return "no model";
	const cleaned = name.replace(/^claude\s*/i, "").trim();
	const tokens = cleaned.split(/\s+/);
	const versions: string[] = [];
	const words: string[] = [];
	for (const token of tokens) {
		if (/^[\d.]+$/.test(token)) versions.push(token);
		else words.push(token.toLowerCase());
	}
	const parts = [...words, ...versions];
	return parts.join(" ") || name.toLowerCase();
}

/** Format a token count into compact K/M notation: 200K, 1.2M */
export function formatTokens(n: number): string {
	if (n < 1000) return String(Math.round(n));
	if (n < 1_000_000) {
		const k = n / 1000;
		return k % 1 === 0 ? `${k}K` : `${parseFloat(k.toFixed(1))}K`;
	}
	const m = n / 1_000_000;
	return m % 1 === 0 ? `${m}M` : `${parseFloat(m.toFixed(1))}M`;
}

/** Format milliseconds into a human-readable duration: "1.2s", "350ms", "2m 5s" */
function formatDuration(ms: number): string {
	if (ms < 1000) return `${Math.round(ms)}ms`;
	if (ms < 60_000) {
		const s = ms / 1000;
		return s < 10 ? `${s.toFixed(1)}s` : `${Math.round(s)}s`;
	}
	const m = Math.floor(ms / 60_000);
	const s = Math.round((ms % 60_000) / 1000);
	return `${m}m ${s}s`;
}

/** Thinking level → labeled indicator */
function thinkingIndicator(level: string | undefined, theme: any): string {
	const label = level || "off";
	const color = label === "off" ? "dim" : label === "high" || label === "xhigh" ? "warning" : "accent";
	return theme.fg("dim", "thinking: ") + theme.fg(color, theme.bold(label));
}

/** Short provider name for display */
function shortProvider(provider: string | undefined): string {
	if (!provider) return "";
	const map: Record<string, string> = {
		"github-copilot": "copilot",
		"google-gemini-cli": "gemini",
		"google-antigravity": "antigravity",
		"google-vertex": "vertex",
		"azure-openai-responses": "azure",
		"openai-codex": "codex",
		"amazon-bedrock": "bedrock",
		"vercel-ai-gateway": "vercel",
		"opencode-go": "opencode-go",
	};
	return map[provider] || provider;
}

/** Last two path components: "Github-Work/pi-vs-claude-code" */
function shortDir(cwd: string): string {
	const child = basename(cwd);
	const parent = basename(dirname(cwd));
	return parent ? `${parent}/${child}` : child;
}

/** Conversation-level token tracking state */
interface ConversationStats {
	inputTokens: number;
	outputTokens: number;
	lastResponseMs: number | null;
	agentStartTime: number | null;
	lastTurnStartTime: number | null;
}

function setupFooter(pi: ExtensionAPI, ctx: any, stats: ConversationStats, onUnsub: (unsub: () => void) => void) {
	ctx.ui.setFooter((tui: any, theme: any, footerData: any) => {
		const unsub = footerData.onBranchChange(() => tui.requestRender());
		onUnsub(unsub);
		return {
			dispose: unsub,
			invalidate() {},
			render(width: number): string[] {
				const provider = shortProvider(ctx.model?.provider);
				const model = shortModelName(ctx.model?.name);
				const usage = ctx.getContextUsage();
				const contextWindow = ctx.model?.contextWindow || 0;

				let usageStr = "–";
				if (usage?.percent != null) {
					const pct = `${Math.round(usage.percent)}%`;
					if (contextWindow > 0) {
						usageStr = `${pct} / ${formatTokens(contextWindow)}`;
					} else {
						usageStr = pct;
					}
				}

				const dir = shortDir(ctx.cwd);
				const thinking = thinkingIndicator(pi.getThinkingLevel?.(), theme);
				const sep = theme.fg("muted", " | ");

				// Plan mode indicator: ⏸ plan in orange
				const g = globalThis as any;
				const modeTag = g.__piPlanMode
					? theme.fg("warning", theme.bold("⏸ plan")) + sep
					: theme.fg("border", theme.bold("▶ edit")) + sep;

				// Provider/model
				const providerModel = provider
					? theme.fg("dim", provider + "/") + theme.fg("accent", theme.bold(model))
					: theme.fg("accent", theme.bold(model));

				// Token counts: ↑sent ↓recv
				let tokenStr = "";
				if (stats.inputTokens > 0 || stats.outputTokens > 0) {
					tokenStr = theme.fg("dim", "↑") + theme.fg("text", formatTokens(stats.inputTokens))
						+ theme.fg("dim", " ↓") + theme.fg("text", formatTokens(stats.outputTokens));
				}

				// Last response time
				let timeStr = "";
				if (stats.lastResponseMs != null) {
					timeStr = theme.fg("mdHeading", formatDuration(stats.lastResponseMs));
				}

				// Build left side: mode | provider/model | context | tokens | time | dir
				const leftParts = [modeTag + providerModel];
				leftParts.push(theme.fg("text", usageStr));
				if (tokenStr) leftParts.push(tokenStr);
				if (timeStr) leftParts.push(timeStr);
				leftParts.push(theme.fg("text", dir));
				const leftContent = leftParts.join(sep);

				const rightContent = thinking + " ";

				const leftWidth = visibleWidth(leftContent);
				const rightWidth = visibleWidth(rightContent);
				const gap = Math.max(1, width - leftWidth - rightWidth);
				const line = leftContent + " ".repeat(gap) + rightContent;

				return [truncateToWidth(line, width, "")];
			},
		};
	});
}

export default function (pi: ExtensionAPI) {
	let branchUnsub: (() => void) | null = null;

	const stats: ConversationStats = {
		inputTokens: 0,
		outputTokens: 0,
		lastResponseMs: null,
		agentStartTime: null,
		lastTurnStartTime: null,
	};

	// Track when agent loop starts (for response timing)
	pi.on("agent_start", async () => {
		stats.agentStartTime = Date.now();
		stats.lastTurnStartTime = Date.now();
	});

	// Track per-turn timing
	pi.on("turn_start", async () => {
		stats.lastTurnStartTime = Date.now();
	});

	// Accumulate tokens from each turn
	pi.on("turn_end", async (event) => {
		const msg = event.message;
		if (msg && "usage" in msg && msg.usage) {
			const usage = msg.usage as { input: number; output: number };
			stats.inputTokens += usage.input || 0;
			stats.outputTokens += usage.output || 0;
		}
		// Update response time from the last turn
		if (stats.lastTurnStartTime != null) {
			stats.lastResponseMs = Date.now() - stats.lastTurnStartTime;
		}
	});

	// When agent loop ends, compute total wall-clock time for the full response
	pi.on("agent_end", async () => {
		if (stats.agentStartTime != null) {
			stats.lastResponseMs = Date.now() - stats.agentStartTime;
			stats.agentStartTime = null;
		}
		stats.lastTurnStartTime = null;
	});

	pi.on("session_start", async (_event, ctx) => {
		// Reset conversation stats on new session
		stats.inputTokens = 0;
		stats.outputTokens = 0;
		stats.lastResponseMs = null;
		stats.agentStartTime = null;
		stats.lastTurnStartTime = null;

		// Replay existing session entries to restore token counts
		try {
			const entries = ctx.sessionManager.getEntries();
			for (const entry of entries) {
				if (entry.type === "message" && "message" in entry) {
					const msg = (entry as any).message;
					if (msg?.role === "assistant" && msg?.usage) {
						stats.inputTokens += msg.usage.input || 0;
						stats.outputTokens += msg.usage.output || 0;
					}
				}
			}
		} catch {}

		setupFooter(pi, ctx, stats, (unsub) => {
			branchUnsub = unsub;
		});
	});

	// Reset and replay when switching sessions
	pi.on("session_switch", async (_event, ctx) => {
		stats.inputTokens = 0;
		stats.outputTokens = 0;
		stats.lastResponseMs = null;
		stats.agentStartTime = null;
		stats.lastTurnStartTime = null;

		try {
			const entries = ctx.sessionManager.getEntries();
			for (const entry of entries) {
				if (entry.type === "message" && "message" in entry) {
					const msg = (entry as any).message;
					if (msg?.role === "assistant" && msg?.usage) {
						stats.inputTokens += msg.usage.input || 0;
						stats.outputTokens += msg.usage.output || 0;
					}
				}
			}
		} catch {}

		setupFooter(pi, ctx, stats, (unsub) => {
			branchUnsub = unsub;
		});
	});

	pi.on("session_shutdown", async () => {
		if (branchUnsub) {
			branchUnsub();
			branchUnsub = null;
		}
	});
}
