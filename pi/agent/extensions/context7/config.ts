import { existsSync } from 'node:fs';
import { readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import type { Context7ConfigFile, Context7Settings } from './types';

export const DEFAULT_RESOLVE_TTL_HOURS = 24 * 7;
export const DEFAULT_DOCS_TTL_HOURS = 24;

const extensionDir = dirname(fileURLToPath(import.meta.url));
const configPath = join(extensionDir, 'config.json');
const cacheDir = join(extensionDir, 'cache');

function normalizePositiveNumber(value: unknown, fallback: number): number {
  if (typeof value !== 'number' || !Number.isFinite(value) || value <= 0) return fallback;
  return value;
}

async function readConfigFile(): Promise<{ config: Context7ConfigFile; error?: string }> {
  if (!existsSync(configPath)) return { config: {} };

  try {
    const raw = await readFile(configPath, 'utf8');
    const parsed = JSON.parse(raw) as Context7ConfigFile;
    return { config: parsed ?? {} };
  } catch (error) {
    return {
      config: {},
      error: error instanceof Error ? error.message : String(error),
    };
  }
}

export async function loadSettings(): Promise<Context7Settings> {
  const { config, error } = await readConfigFile();
  const apiKey = process.env.CONTEXT7_API_KEY?.trim() || config.apiKey?.trim() || undefined;
  const resolveTtlHours = normalizePositiveNumber(
    config.cache?.resolveTtlHours,
    DEFAULT_RESOLVE_TTL_HOURS,
  );
  const docsTtlHours = normalizePositiveNumber(config.cache?.docsTtlHours, DEFAULT_DOCS_TTL_HOURS);

  return {
    extensionDir,
    configPath,
    cacheDir,
    apiKey,
    resolveTtlMs: resolveTtlHours * 60 * 60 * 1000,
    docsTtlMs: docsTtlHours * 60 * 60 * 1000,
    configError: error,
  };
}
