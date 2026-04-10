import { createHash } from 'node:crypto';
import { existsSync } from 'node:fs';
import { mkdir, readFile, readdir, rename, rm, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { withFileMutationQueue } from '@mariozechner/pi-coding-agent';
import type {
  CacheLookup,
  CacheSearchSelector,
  Context7Settings,
  DocCacheEntry,
  DocCacheIndexEntry,
  ResolveCacheEntry,
  ResolveCacheIndexEntry,
} from './types';

type StringListMap = Record<string, string[]>;
type DocRefIndexMap = Record<string, DocCacheIndexEntry>;

type ResolvePaths = ReturnType<typeof getResolvePaths>;
type DocsPaths = ReturnType<typeof getDocsPaths>;

function hash(input: string): string {
  return createHash('sha256').update(input).digest('hex').slice(0, 24);
}

function normalizeText(value?: string): string {
  return (value ?? '').trim().toLowerCase();
}

function toIso(ms: number): string {
  return new Date(ms).toISOString();
}

function isFresh(expiresAt: string): boolean {
  return new Date(expiresAt).getTime() > Date.now();
}

async function readJsonFile<T>(path: string, fallback: T): Promise<T> {
  if (!existsSync(path)) return fallback;
  try {
    const raw = await readFile(path, 'utf8');
    return (JSON.parse(raw) as T) ?? fallback;
  } catch {
    return fallback;
  }
}

async function atomicWriteJson(path: string, value: unknown): Promise<void> {
  const tempPath = `${path}.tmp-${process.pid}-${Date.now()}`;
  await writeFile(tempPath, JSON.stringify(value, null, 2));
  await rename(tempPath, path);
}

function uniqueStrings(values: string[]): string[] {
  return Array.from(new Set(values));
}

function pushIndexValue(map: StringListMap, key: string | undefined, value: string) {
  if (!key) return;
  map[key] = uniqueStrings([...(map[key] ?? []), value]);
}

function getResolvePaths(settings: Context7Settings, objectKey: string) {
  const base = join(settings.cacheDir, 'resolve');
  const indexDir = join(base, 'index');
  return {
    base,
    objectsDir: join(base, 'objects'),
    indexDir,
    allIndexPath: join(indexDir, 'all.json'),
    byLibraryPath: join(indexDir, 'by-library.json'),
    objectPath: join(base, 'objects', `${objectKey}.json`),
  };
}

function getDocsPaths(settings: Context7Settings, objectKey: string) {
  const base = join(settings.cacheDir, 'docs');
  const indexDir = join(base, 'index');
  return {
    base,
    objectsDir: join(base, 'objects'),
    indexDir,
    allIndexPath: join(indexDir, 'all.json'),
    byRefPath: join(indexDir, 'by-ref.json'),
    byLibraryIdPath: join(indexDir, 'by-library-id.json'),
    byLibraryNamePath: join(indexDir, 'by-library-name.json'),
    byVersionPath: join(indexDir, 'by-version.json'),
    objectPath: join(base, 'objects', `${objectKey}.json`),
  };
}

async function ensureResolveCacheDirs(settings: Context7Settings, objectKey: string) {
  const paths = getResolvePaths(settings, objectKey);
  await mkdir(paths.objectsDir, { recursive: true });
  await mkdir(paths.indexDir, { recursive: true });
  return paths;
}

async function ensureDocsCacheDirs(settings: Context7Settings, objectKey: string) {
  const paths = getDocsPaths(settings, objectKey);
  await mkdir(paths.objectsDir, { recursive: true });
  await mkdir(paths.indexDir, { recursive: true });
  return paths;
}

function resolveCacheKey(libraryName: string, query: string): string {
  return `${normalizeText(libraryName)}::${normalizeText(query)}`;
}

async function pruneObjectDirectory(objectsDir: string, validObjectKeys: Set<string>) {
  if (!existsSync(objectsDir)) return;
  const files = await readdir(objectsDir);
  await Promise.all(
    files
      .filter((file) => file.endsWith('.json'))
      .filter((file) => !validObjectKeys.has(file.replace(/\.json$/, '')))
      .map((file) => rm(join(objectsDir, file), { force: true })),
  );
}

async function writeResolveIndexes(paths: ResolvePaths, all: ResolveCacheIndexEntry[]) {
  const byLibrary: StringListMap = {};
  for (const entry of all) {
    pushIndexValue(byLibrary, entry.normalizedLibraryName, entry.objectKey);
  }

  await atomicWriteJson(paths.allIndexPath, all);
  await atomicWriteJson(paths.byLibraryPath, byLibrary);
}

async function writeDocsIndexes(paths: DocsPaths, all: DocCacheIndexEntry[]) {
  const byRef: DocRefIndexMap = {};
  const byLibraryId: StringListMap = {};
  const byLibraryName: StringListMap = {};
  const byVersion: StringListMap = {};

  for (const entry of all) {
    byRef[entry.docRef] = entry;
    pushIndexValue(byLibraryId, entry.libraryId, entry.docRef);
    pushIndexValue(byLibraryName, entry.normalizedLibraryName, entry.docRef);
    pushIndexValue(byVersion, entry.libraryVersion, entry.docRef);
    pushIndexValue(byVersion, entry.libraryVersionRaw, entry.docRef);
  }

  await atomicWriteJson(paths.allIndexPath, all);
  await atomicWriteJson(paths.byRefPath, byRef);
  await atomicWriteJson(paths.byLibraryIdPath, byLibraryId);
  await atomicWriteJson(paths.byLibraryNamePath, byLibraryName);
  await atomicWriteJson(paths.byVersionPath, byVersion);
}

async function pruneResolveIndexes(paths: ResolvePaths, all: ResolveCacheIndexEntry[]) {
  const seen = new Set<string>();
  const nextAll = all
    .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
    .filter((entry) => {
      if (seen.has(entry.objectKey)) return false;
      seen.add(entry.objectKey);
      if (!isFresh(entry.expiresAt)) return false;
      return existsSync(join(paths.objectsDir, `${entry.objectKey}.json`));
    });

  await pruneObjectDirectory(paths.objectsDir, new Set(nextAll.map((entry) => entry.objectKey)));
  await writeResolveIndexes(paths, nextAll);
  return nextAll;
}

async function pruneDocsIndexes(paths: DocsPaths, all: DocCacheIndexEntry[]) {
  const seen = new Set<string>();
  const nextAll = all
    .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
    .filter((entry) => {
      if (seen.has(entry.docRef)) return false;
      seen.add(entry.docRef);
      if (!isFresh(entry.expiresAt)) return false;
      return existsSync(join(paths.objectsDir, `${entry.objectKey}.json`));
    });

  await pruneObjectDirectory(paths.objectsDir, new Set(nextAll.map((entry) => entry.objectKey)));
  await writeDocsIndexes(paths, nextAll);
  return nextAll;
}

async function readResolveIndexes(paths: ResolvePaths) {
  const all = await readJsonFile<ResolveCacheIndexEntry[]>(paths.allIndexPath, []);
  const pruned = await pruneResolveIndexes(paths, all);
  const byLibrary = await readJsonFile<StringListMap>(paths.byLibraryPath, {});
  return { all: pruned, byLibrary };
}

async function readDocsIndexes(paths: DocsPaths) {
  const all = await readJsonFile<DocCacheIndexEntry[]>(paths.allIndexPath, []);
  const pruned = await pruneDocsIndexes(paths, all);
  const byRef = await readJsonFile<DocRefIndexMap>(paths.byRefPath, {});
  const byLibraryId = await readJsonFile<StringListMap>(paths.byLibraryIdPath, {});
  const byLibraryName = await readJsonFile<StringListMap>(paths.byLibraryNamePath, {});
  const byVersion = await readJsonFile<StringListMap>(paths.byVersionPath, {});
  return { all: pruned, byRef, byLibraryId, byLibraryName, byVersion };
}

export function buildDocRef(libraryId: string, effectiveQuery: string, page: number): string {
  return `ctx7:docs:${hash(`${libraryId}::${effectiveQuery}::${page}`)}`;
}

export function extractVersionInfo(libraryId: string): { raw?: string; normalized?: string } {
  const parts = libraryId.split('/').filter(Boolean);
  if (parts.length <= 2) return {};
  const raw = parts.slice(2).join('/');
  return {
    raw,
    normalized: raw.replace(/^v/, ''),
  };
}

export async function getResolveCache(
  settings: Context7Settings,
  libraryName: string,
  query: string,
): Promise<CacheLookup<ResolveCacheEntry>> {
  const cacheKey = resolveCacheKey(libraryName, query);
  const objectKey = hash(cacheKey);
  const { objectPath } = getResolvePaths(settings, objectKey);
  if (!existsSync(objectPath)) return { fresh: false };

  const entry = await readJsonFile<ResolveCacheEntry | undefined>(objectPath, undefined);
  if (!entry) return { fresh: false };

  if (!isFresh(entry.expiresAt)) {
    await rm(objectPath, { force: true });
    return { fresh: false };
  }

  return { entry, fresh: true };
}

export async function putResolveCache(
  settings: Context7Settings,
  params: { libraryName: string; query: string; results: ResolveCacheEntry['results'] },
): Promise<ResolveCacheEntry> {
  const cacheKey = resolveCacheKey(params.libraryName, params.query);
  const objectKey = hash(cacheKey);
  const now = Date.now();
  const entry: ResolveCacheEntry = {
    kind: 'resolve',
    cacheKey,
    objectKey,
    libraryName: params.libraryName,
    normalizedLibraryName: normalizeText(params.libraryName),
    query: params.query,
    createdAt: toIso(now),
    expiresAt: toIso(now + settings.resolveTtlMs),
    results: params.results,
  };

  const paths = await ensureResolveCacheDirs(settings, objectKey);
  const lockPath = join(settings.cacheDir, '.cache-mutation-lock');

  await withFileMutationQueue(lockPath, async () => {
    const { all } = await readResolveIndexes(paths);
    const nextAll = all
      .filter((item) => item.objectKey !== objectKey)
      .concat({
        kind: 'resolve',
        cacheKey,
        objectKey,
        libraryName: entry.libraryName,
        normalizedLibraryName: entry.normalizedLibraryName,
        query: entry.query,
        createdAt: entry.createdAt,
        expiresAt: entry.expiresAt,
        resultCount: entry.results.length,
      });

    await atomicWriteJson(paths.objectPath, entry);
    await pruneResolveIndexes(paths, nextAll);
  });

  return entry;
}

export async function getDocCacheByRef(
  settings: Context7Settings,
  docRef: string,
): Promise<CacheLookup<DocCacheEntry>> {
  const objectKey = hash(docRef);
  const { objectPath } = getDocsPaths(settings, objectKey);
  if (!existsSync(objectPath)) return { fresh: false };

  const entry = await readJsonFile<DocCacheEntry | undefined>(objectPath, undefined);
  if (!entry) return { fresh: false };

  if (!isFresh(entry.expiresAt)) {
    return { entry, fresh: false };
  }

  return { entry, fresh: true };
}

export async function putDocCache(
  settings: Context7Settings,
  params: Omit<DocCacheEntry, 'kind' | 'objectKey' | 'createdAt' | 'expiresAt'>,
): Promise<DocCacheEntry> {
  const objectKey = hash(params.docRef);
  const now = Date.now();
  const entry: DocCacheEntry = {
    ...params,
    kind: 'docs',
    objectKey,
    createdAt: toIso(now),
    expiresAt: toIso(now + settings.docsTtlMs),
  };

  const paths = await ensureDocsCacheDirs(settings, objectKey);
  const lockPath = join(settings.cacheDir, '.cache-mutation-lock');

  await withFileMutationQueue(lockPath, async () => {
    const { all } = await readDocsIndexes(paths);
    const nextAll = all
      .filter((item) => item.docRef !== entry.docRef)
      .concat({
        kind: 'docs',
        docRef: entry.docRef,
        objectKey,
        libraryId: entry.libraryId,
        libraryName: entry.libraryName,
        normalizedLibraryName: entry.normalizedLibraryName,
        libraryVersion: entry.libraryVersion,
        libraryVersionRaw: entry.libraryVersionRaw,
        query: entry.query,
        topic: entry.topic,
        effectiveQuery: entry.effectiveQuery,
        page: entry.page,
        createdAt: entry.createdAt,
        expiresAt: entry.expiresAt,
        rawLength: entry.rawText.length,
        curatedLength: entry.curatedText.length,
      });

    await atomicWriteJson(paths.objectPath, entry);
    await pruneDocsIndexes(paths, nextAll);
  });

  return entry;
}

function intersectDocRefs(
  current: string[] | undefined,
  next: string[] | undefined,
): string[] | undefined {
  if (!next || next.length === 0) return current;
  if (!current) return uniqueStrings(next);
  const nextSet = new Set(next);
  return current.filter((value) => nextSet.has(value));
}

export async function findDocCacheCandidates(
  settings: Context7Settings,
  selector: CacheSearchSelector,
): Promise<DocCacheIndexEntry[]> {
  const paths = getDocsPaths(settings, 'placeholder');
  const { all, byRef, byLibraryId, byLibraryName, byVersion } = await readDocsIndexes(paths);

  if (selector.docRef) {
    const exact = byRef[selector.docRef];
    if (!exact) return [];
    return [exact];
  }

  const normalizedLibraryName = normalizeText(selector.libraryName);
  const normalizedVersion = normalizeText(selector.libraryVersion).replace(/^v/, '');
  const normalizedQuery = normalizeText(selector.query);
  const normalizedTopic = normalizeText(selector.topic);

  let seededDocRefs: string[] | undefined;
  if (selector.libraryId)
    seededDocRefs = intersectDocRefs(seededDocRefs, byLibraryId[selector.libraryId]);
  if (normalizedLibraryName)
    seededDocRefs = intersectDocRefs(seededDocRefs, byLibraryName[normalizedLibraryName]);
  if (normalizedVersion)
    seededDocRefs = intersectDocRefs(seededDocRefs, byVersion[normalizedVersion]);

  const candidatePool = seededDocRefs
    ? seededDocRefs.map((docRef) => byRef[docRef]).filter(Boolean)
    : all;

  return candidatePool
    .filter((item) => (selector.libraryId ? item.libraryId === selector.libraryId : true))
    .filter((item) => {
      if (!normalizedLibraryName) return true;
      return (
        item.normalizedLibraryName === normalizedLibraryName ||
        item.normalizedLibraryName.includes(normalizedLibraryName) ||
        normalizedLibraryName.includes(item.normalizedLibraryName)
      );
    })
    .filter((item) => {
      if (!normalizedVersion) return true;
      return (
        item.libraryVersion === normalizedVersion ||
        normalizeText(item.libraryVersionRaw).replace(/^v/, '') === normalizedVersion
      );
    })
    .filter((item) => (normalizedQuery ? normalizeText(item.query) === normalizedQuery : true))
    .filter((item) => (normalizedTopic ? normalizeText(item.topic) === normalizedTopic : true))
    .filter((item) => (typeof selector.page === 'number' ? item.page === selector.page : true))
    .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
}

export async function loadDocCacheObject(
  settings: Context7Settings,
  metadata: Pick<DocCacheIndexEntry, 'objectKey'>,
): Promise<DocCacheEntry | undefined> {
  const { objectPath } = getDocsPaths(settings, metadata.objectKey);
  return readJsonFile<DocCacheEntry | undefined>(objectPath, undefined);
}
