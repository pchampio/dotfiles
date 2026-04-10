export interface Context7ConfigFile {
  apiKey?: string;
  cache?: {
    resolveTtlHours?: number;
    docsTtlHours?: number;
  };
}

export interface Context7Settings {
  extensionDir: string;
  configPath: string;
  cacheDir: string;
  apiKey?: string;
  resolveTtlMs: number;
  docsTtlMs: number;
  configError?: string;
}

export interface SearchResult {
  id: string;
  title: string;
  description: string;
  totalSnippets?: number;
  trustScore?: number;
  benchmarkScore?: number;
  versions?: string[];
  source?: string;
}

export interface SearchResponse {
  results: SearchResult[];
  searchFilterApplied?: boolean;
  error?: string;
}

export interface Context7ApiError {
  kind: 'auth' | 'rate_limit' | 'not_found' | 'network' | 'invalid_response' | 'unknown';
  status?: number;
  message: string;
  upstreamMessage?: string;
}

export type Context7ApiResult<T> = { ok: true; data: T } | { ok: false; error: Context7ApiError };

export interface ResolveCacheEntry {
  kind: 'resolve';
  cacheKey: string;
  objectKey: string;
  libraryName: string;
  normalizedLibraryName: string;
  query: string;
  createdAt: string;
  expiresAt: string;
  results: SearchResult[];
}

export interface ResolveCacheIndexEntry {
  kind: 'resolve';
  cacheKey: string;
  objectKey: string;
  libraryName: string;
  normalizedLibraryName: string;
  query: string;
  createdAt: string;
  expiresAt: string;
  resultCount: number;
}

export interface DocCacheEntry {
  kind: 'docs';
  docRef: string;
  objectKey: string;
  libraryId: string;
  libraryName: string;
  normalizedLibraryName: string;
  libraryVersion?: string;
  libraryVersionRaw?: string;
  query: string;
  topic?: string;
  effectiveQuery: string;
  page: number;
  createdAt: string;
  expiresAt: string;
  rawText: string;
  curatedText: string;
}

export interface DocCacheIndexEntry {
  kind: 'docs';
  docRef: string;
  objectKey: string;
  libraryId: string;
  libraryName: string;
  normalizedLibraryName: string;
  libraryVersion?: string;
  libraryVersionRaw?: string;
  query: string;
  topic?: string;
  effectiveQuery: string;
  page: number;
  createdAt: string;
  expiresAt: string;
  rawLength: number;
  curatedLength: number;
}

export interface CacheLookup<T> {
  entry?: T;
  fresh: boolean;
}

export interface CacheSearchSelector {
  docRef?: string;
  libraryId?: string;
  libraryName?: string;
  libraryVersion?: string;
  query?: string;
  topic?: string;
  page?: number;
}

export interface CuratedDocResult {
  text: string;
  truncated: boolean;
  selectedSectionCount: number;
  rawLength: number;
}

export interface ResolveLibraryParams {
  libraryName: string;
  query?: string;
}

export interface GetLibraryDocsParams {
  libraryId?: string;
  libraryName?: string;
  query?: string;
  topic?: string;
  page?: number;
}

export interface GetCachedDocRawParams extends CacheSearchSelector {}
