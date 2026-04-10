/**
 * Tests for plan-mode extension whitelist functionality.
 * 
 * These tests document the current bugs where safe commands are incorrectly blocked.
 */

import { describe, it, expect } from "vitest";
import { isWhitelisted } from "./plan-mode.js";

describe("plan-mode whitelist", () => {
	describe("commands without trailing space", () => {
		it("should whitelist ls alone", () => {
			expect(isWhitelisted("ls")).toBe(true);
		});

		it("should whitelist git log", () => {
			expect(isWhitelisted("git log")).toBe(true);
		});

		it("should whitelist git status", () => {
			expect(isWhitelisted("git status")).toBe(true);
		});

		it("should whitelist git diff", () => {
			expect(isWhitelisted("git diff")).toBe(true);
		});

		it("should whitelist git show", () => {
			expect(isWhitelisted("git show")).toBe(true);
		});

		it("should whitelist git branch", () => {
			expect(isWhitelisted("git branch")).toBe(true);
		});
	});

	describe("safe pipe operations", () => {
		it("should whitelist ls piped to grep", () => {
			expect(isWhitelisted("ls -la | grep test")).toBe(true);
		});

		it("should whitelist find piped to wc", () => {
			expect(isWhitelisted("find . -name '*.ts' | wc -l")).toBe(true);
		});

		it("should whitelist cat piped to grep", () => {
			expect(isWhitelisted("cat file.ts | grep pattern")).toBe(true);
		});

		it("should whitelist find piped to grep", () => {
			expect(isWhitelisted("find . -type f | grep .ts$")).toBe(true);
		});
	});

	describe("commands that should work (baseline)", () => {
		it("should whitelist pwd", () => {
			expect(isWhitelisted("pwd")).toBe(true);
		});

		it("should whitelist env", () => {
			expect(isWhitelisted("env")).toBe(true);
		});

		it("should whitelist ls with flags", () => {
			expect(isWhitelisted("ls -la")).toBe(true);
		});

		it("should whitelist grep with arguments", () => {
			expect(isWhitelisted("grep pattern file.ts")).toBe(true);
		});

		it("should whitelist cat with file", () => {
			expect(isWhitelisted("cat file.ts")).toBe(true);
		});
	});

	describe("commands that should be blocked", () => {
		it("should block file redirects", () => {
			expect(isWhitelisted("cat file > output")).toBe(false);
		});

		it("should block append redirects", () => {
			expect(isWhitelisted("echo test >> file")).toBe(false);
		});

		it("should block command substitution", () => {
			expect(isWhitelisted("rm $(find . -name '*.log')")).toBe(false);
		});

		it("should block semicolon commands", () => {
			expect(isWhitelisted("ls; rm -rf .")).toBe(false);
		});

		it("should block unsafe pipe to rm", () => {
			// This should be blocked - piping to rm is dangerous
			expect(isWhitelisted("find . -name '*.log' | xargs rm")).toBe(false);
		});
	});
});
