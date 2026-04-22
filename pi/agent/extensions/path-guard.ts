/**
 * Path Guard Extension
 *
 * Blocks tool access to files outside the current working directory.
 * /tmp is always allowed. Other out-of-scope paths prompt the user
 * with an option to remember the decision for the session.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { isToolCallEventType } from "@mariozechner/pi-coding-agent";
import { resolve } from "node:path";

export default function (pi: ExtensionAPI) {
	// Paths the user has already approved or denied for this session
	const allowedPaths = new Set<string>();
	const deniedPaths = new Set<string>();

	function isInsideCwd(cwd: string, inputPath: string): boolean {
		let p = inputPath.replace(/^@/, "");
		if (p.startsWith("~")) p = p.replace(/^~/, process.env.HOME ?? "");
		const abs = resolve(cwd, p);
		return abs === cwd || abs.startsWith(cwd + "/");
	}

	function isInsideTmp(cwd: string, inputPath: string): boolean {
		let p = inputPath.replace(/^@/, "");
		if (p.startsWith("~")) p = p.replace(/^~/, process.env.HOME ?? "");
		const abs = resolve(cwd, p);
		return abs.startsWith("/tmp/") || abs === "/tmp";
	}

	/** Get a canonical key for remembering decisions (resolved absolute path or parent dir). */
	function rememberKey(cwd: string, inputPath: string): string {
		let p = inputPath.replace(/^@/, "");
		if (p.startsWith("~")) p = p.replace(/^~/, process.env.HOME ?? "");
		return resolve(cwd, p);
	}

	const TOOLS_WITH_PATH = ["read", "write", "edit", "find", "ls", "grep"] as const;

	pi.on("tool_call", async (event, ctx) => {
		for (const tool of TOOLS_WITH_PATH) {
			if (isToolCallEventType(tool, event)) {
				const p = (event.input as any).path;
				if (!p) continue;

				// Inside cwd — always allowed
				if (isInsideCwd(ctx.cwd, p)) return;

				// /tmp — always allowed
				if (isInsideTmp(ctx.cwd, p)) return;

				const key = rememberKey(ctx.cwd, p);

				// Already remembered
				if (allowedPaths.has(key)) return;
				if (deniedPaths.has(key)) {
					return { block: true, reason: `Blocked: ${p} is outside the working directory (previously denied).` };
				}

				// Ask the user
				if (!ctx.hasUI) {
					return { block: true, reason: `Blocked: ${p} is outside the working directory.` };
				}

				const choice = await ctx.ui.select(
					`Path outside working directory: ${p}`,
					[
						"Allow once",
						"Allow and remember for this session",
						"Deny once",
						"Deny and remember for this session",
					],
				);

				if (!choice || choice === "Deny once") {
					return { block: true, reason: `Blocked: ${p} is outside the working directory.` };
				}

				if (choice === "Deny and remember for this session") {
					deniedPaths.add(key);
					return { block: true, reason: `Blocked: ${p} is outside the working directory.` };
				}

				if (choice === "Allow and remember for this session") {
					allowedPaths.add(key);
				}

				// "Allow once" or "Allow and remember" — fall through
				return;
			}
		}
	});
}
