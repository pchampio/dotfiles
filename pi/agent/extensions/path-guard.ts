/**
 * Path Guard Extension
 *
 * Blocks tool access to files outside the current working directory.
 * Hard-blocks read/write/edit/find/ls/grep with out-of-scope paths.
 * Soft-blocks bash via system prompt instruction.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { isToolCallEventType } from "@mariozechner/pi-coding-agent";
import { resolve } from "node:path";

export default function (pi: ExtensionAPI) {
	function isInsideCwd(cwd: string, inputPath: string): boolean {
		let p = inputPath.replace(/^@/, "");
		if (p.startsWith("~")) p = p.replace(/^~/, process.env.HOME ?? "");
		const abs = resolve(cwd, p);
		return abs === cwd || abs.startsWith(cwd + "/");
	}

	const TOOLS_WITH_PATH = ["read", "write", "edit", "find", "ls", "grep"] as const;

	pi.on("tool_call", async (event, ctx) => {
		for (const tool of TOOLS_WITH_PATH) {
			if (isToolCallEventType(tool, event)) {
				const p = (event.input as any).path;
				if (p && !isInsideCwd(ctx.cwd, p)) {
					return { block: true, reason: `Blocked: ${p} is outside the working directory.` };
				}
			}
		}
	});

	pi.on("before_agent_start", async (event) => {
		return {
			systemPrompt: event.systemPrompt +
				"\n\nIMPORTANT: Only access files within the current working directory and its subdirectories. " +
				"Do not use bash to read, list, or modify files outside this scope.",
		};
	});
}
