// FROM: https://github.com/tonze/pi-updater/blob/main/index.ts
import type {
  ExtensionAPI,
  ExtensionContext,
} from "@mariozechner/pi-coding-agent";
import { VERSION, BorderedLoader } from "@mariozechner/pi-coding-agent";
import { spawnSync } from "node:child_process";
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { homedir } from "node:os";

const PACKAGE_NAME = "@mariozechner/pi-coding-agent";
const REGISTRY_URL = `https://registry.npmjs.org/${PACKAGE_NAME}/latest`;
const CACHE_FILE = join(homedir(), ".pi", "agent", "update-cache.json");

const ENV_SKIP_VERSION_CHECK = "PI_SKIP_VERSION_CHECK";
const ENV_OFFLINE = "PI_OFFLINE";

interface VersionCache {
  latestVersion: string;
  dismissedVersion?: string;
  checkedAt?: string;
}

function readCache(): VersionCache | undefined {
  try {
    return JSON.parse(readFileSync(CACHE_FILE, "utf-8"));
  } catch {
    return undefined;
  }
}

function writeCache(cache: VersionCache) {
  try {
    mkdirSync(dirname(CACHE_FILE), { recursive: true });
    writeFileSync(CACHE_FILE, JSON.stringify(cache) + "\n");
  } catch {}
}

function parseVersion(v: string): [number, number, number] | undefined {
  const parts = v.trim().split(".");
  if (parts.length !== 3) return undefined;
  const nums = parts.map(Number);
  if (nums.some(isNaN)) return undefined;
  return nums as [number, number, number];
}

function isNewer(latest: string, current: string): boolean {
  const l = parseVersion(latest);
  const c = parseVersion(current);
  if (!l || !c) return false;
  if (l[0] !== c[0]) return l[0] > c[0];
  if (l[1] !== c[1]) return l[1] > c[1];
  return l[2] > c[2];
}

function isEnvSet(name: string): boolean {
  return Boolean(process.env[name]);
}

function shouldSkipAutoChecks(): boolean {
  return isEnvSet(ENV_SKIP_VERSION_CHECK) || isEnvSet(ENV_OFFLINE);
}

function isOffline(): boolean {
  return isEnvSet(ENV_OFFLINE);
}

function saveLatestToCache(latest: string) {
  const prev = readCache();
  writeCache({
    latestVersion: latest,
    dismissedVersion: prev?.dismissedVersion,
    checkedAt: new Date().toISOString(),
  });
}

async function fetchLatestVersion(): Promise<string | undefined> {
  try {
    const res = await fetch(REGISTRY_URL, {
      signal: AbortSignal.timeout(10_000),
    });
    if (!res.ok) return undefined;
    return ((await res.json()) as { version?: string }).version;
  } catch {
    return undefined;
  }
}

/** Returns a cached upgrade if available and not dismissed. */
function getCachedUpgradeVersion(): string | undefined {
  const cache = readCache();
  if (!cache) return undefined;
  if (!isNewer(cache.latestVersion, VERSION)) return undefined;
  if (cache.dismissedVersion === cache.latestVersion) return undefined;
  return cache.latestVersion;
}

/** Fetch latest from npm and refresh cache. */
async function refreshLatestVersionInCache(): Promise<string | undefined> {
  const latest = await fetchLatestVersion();
  if (!latest) return undefined;
  saveLatestToCache(latest);
  return latest;
}

function dismissVersion(version: string) {
  const cache = readCache();
  writeCache({
    latestVersion: cache?.latestVersion ?? version,
    dismissedVersion: version,
    checkedAt: cache?.checkedAt,
  });
}

function getInstallCommand(version: string): { program: string; args: string[] } {
  return {
    program: join(homedir(), "/dotfiles/install/github_app"),
    args: ["pi"],
  };
}

function fmtCmd(cmd: { program: string; args: string[] }): string {
  return `${cmd.program} ${cmd.args.join(" ")}`;
}

export default function (pi: ExtensionAPI) {
  let promptOpen = false;
  const promptedVersions = new Set<string>();
  let liveCheckStarted = false;

  async function findPiBinary(): Promise<string> {
    const cmd = process.platform === "win32" ? "where" : "which";
    const result = await pi.exec(cmd, ["pi"]);
    if (result.code === 0 && result.stdout?.trim()) {
      return result.stdout.trim().split(/\r?\n/)[0];
    }
    return "pi";
  }

  function canAutoRestart(ctx: ExtensionContext): boolean {
    return ctx.hasUI && !!process.stdin.isTTY && !!process.stdout.isTTY;
  }

  async function restartPi(ctx: ExtensionContext): Promise<boolean> {
    const piBinary = await findPiBinary();
    const sessionFile = ctx.sessionManager.getSessionFile();
    const restartArgs = sessionFile ? ["--session", sessionFile] : ["-c"];

    return ctx.ui.custom<boolean>((tui, _theme, _kb, done) => {
      tui.stop();
      const result = spawnSync(piBinary, restartArgs, {
        cwd: ctx.cwd,
        env: process.env,
        stdio: "inherit",
        shell: process.platform === "win32",
        windowsHide: false,
      });
      tui.start();
      tui.requestRender(true);
      done(!result.error && (result.status === null || result.status === 0));
      return { render: () => [], invalidate: () => {} };
    });
  }

  async function doInstall(
    ctx: ExtensionContext,
    latest: string,
    cmd: { program: string; args: string[] },
  ) {
    const success = await ctx.ui.custom<boolean>((tui, theme, _kb, done) => {
      const loader = new BorderedLoader(tui, theme, `Installing ${latest}...`);
      loader.onAbort = () => done(false);

      pi.exec(cmd.program, cmd.args, { timeout: 120_000 })
        .then((result) => {
          if (result.code !== 0) {
            ctx.ui.notify(
              `Update failed (exit ${result.code}): ${result.stderr || result.stdout}`,
              "error",
            );
            done(false);
          } else {
            done(true);
          }
        })
        .catch(() => done(false));

      return loader;
    });

    if (!success) return;

    if (!canAutoRestart(ctx)) {
      ctx.ui.notify(
        `Updated to ${latest}! Please restart pi.\nTip: run \`pi -c\` to continue this session.`,
        "info",
      );
      return;
    }

    const restart = await ctx.ui.confirm(
      `Updated to ${latest}!`,
      "Restart now?",
    );

    if (!restart) return;

    const ok = await restartPi(ctx);
    if (ok) {
      ctx.shutdown();
      return;
    }

    ctx.ui.notify(
      `Updated to ${latest}! Auto-restart failed. Please restart pi manually.\nTip: run \`pi -c\` to continue this session.`,
      "error",
    );
  }

  async function showUpdatePrompt(ctx: ExtensionContext, latest: string) {
    const cmd = getInstallCommand(latest);
    const choice = await ctx.ui.select(`Update ${VERSION} → ${latest}`, [
      `Update now (${fmtCmd(cmd)})`,
      "Skip",
      "Skip this version",
    ]);

    if (!choice || choice === "Skip") return;
    if (choice === "Skip this version") {
      dismissVersion(latest);
      return;
    }
    await doInstall(ctx, latest, cmd);
  }

  function canAutoPromptVersion(latest: string): boolean {
    if (!isNewer(latest, VERSION)) return false;
    if (promptedVersions.has(latest)) return false;
    if (readCache()?.dismissedVersion === latest) return false;
    return true;
  }

  async function maybeShowAutoPrompt(ctx: ExtensionContext, latest: string) {
    if (!ctx.hasUI) return;
    if (promptOpen) return;
    if (!canAutoPromptVersion(latest)) return;

    promptOpen = true;
    promptedVersions.add(latest);
    try {
      await showUpdatePrompt(ctx, latest);
    } finally {
      promptOpen = false;
    }
  }

  function runAutoChecks(ctx: ExtensionContext) {
    if (!ctx.hasUI) return;
    if (shouldSkipAutoChecks()) return;

    const cached = getCachedUpgradeVersion();
    if (cached) void maybeShowAutoPrompt(ctx, cached);

    if (liveCheckStarted) return;
    liveCheckStarted = true;

    void refreshLatestVersionInCache()
      .then((latest) => {
        if (!latest) return;
        void maybeShowAutoPrompt(ctx, latest);
      })
      .catch(() => {});
  }

  pi.on("session_start", async (_event, ctx) => {
    runAutoChecks(ctx);
  });

  pi.on("session_switch", async (_event, ctx) => {
    runAutoChecks(ctx);
  });

  pi.registerCommand("update", {
    description: "Check for pi updates and install",
    handler: async (rawArgs, ctx) => {
      // /update --test — simulate the full UI flow without a real install
      if (rawArgs?.trim() === "--test") {
        const fakeLatest = "99.0.0";
        const cmd = getInstallCommand(fakeLatest);
        const choice = await ctx.ui.select(`Update ${VERSION} → ${fakeLatest}`, [
          `Update now (${fmtCmd(cmd)})`,
          "Skip",
          "Skip this version",
        ]);
        if (!choice || choice === "Skip" || choice === "Skip this version") return;

        await ctx.ui.custom<void>((tui, theme, _kb, done) => {
          const loader = new BorderedLoader(tui, theme, `Installing ${fakeLatest}...`);
          loader.onAbort = () => done();
          setTimeout(() => done(), 1500);
          return loader;
        });

        if (!canAutoRestart(ctx)) {
          ctx.ui.notify(`Updated to ${fakeLatest}! Please restart pi.`, "info");
          return;
        }

        const restart = await ctx.ui.confirm(`Updated to ${fakeLatest}!`, "Restart now?");
        if (!restart) return;

        const ok = await restartPi(ctx);
        if (ok) { ctx.shutdown(); return; }
        ctx.ui.notify("Test restart failed.", "error");
        return;
      }

      if (isOffline()) {
        ctx.ui.notify(
          "PI_OFFLINE is set. Disable it to check for updates.",
          "warning",
        );
        return;
      }

      const latest = await ctx.ui.custom<string | null>(
        (tui, theme, _kb, done) => {
          const loader = new BorderedLoader(
            tui,
            theme,
            "Checking for updates...",
          );
          loader.onAbort = () => done(null);
          fetchLatestVersion()
            .then((v) => done(v ?? null))
            .catch(() => done(null));
          return loader;
        },
      );

      if (!latest) {
        ctx.ui.notify("Could not reach npm registry.", "error");
        return;
      }

      saveLatestToCache(latest);

      if (!isNewer(latest, VERSION)) {
        ctx.ui.notify(`Already on latest version (${VERSION}).`, "info");
        return;
      }

      promptedVersions.add(latest);
      await showUpdatePrompt(ctx, latest);
    },
  });
}
