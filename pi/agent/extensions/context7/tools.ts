import type { ExtensionAPI, ToolDefinition } from '@mariozechner/pi-coding-agent';
import { Type, type TSchema } from '@sinclair/typebox';
import { fetchLibraryDocs, searchLibraries } from './api';
import {
  buildDocRef,
  extractVersionInfo,
  findDocCacheCandidates,
  getDocCacheByRef,
  getResolveCache,
  loadDocCacheObject,
  putDocCache,
  putResolveCache,
} from './cache';
import { loadSettings } from './config';
import { curateDocText } from './curation';
import type {
  CacheSearchSelector,
  DocCacheIndexEntry,
  GetCachedDocRawParams,
  GetLibraryDocsParams,
  ResolveLibraryParams,
  SearchResponse,
  SearchResult,
} from './types';

function normalizeText(value?: string): string {
  return (value ?? '').trim().toLowerCase();
}

function displayTitle(result?: SearchResult): string {
  if (!result) return '';
  return result.title || result.id;
}

function snippetCount(result: SearchResult): number {
  return typeof result.totalSnippets === 'number' && result.totalSnippets > 0
    ? result.totalSnippets
    : 0;
}

function benchmarkScore(result: SearchResult): number {
  return typeof result.benchmarkScore === 'number' ? result.benchmarkScore : 0;
}

function trustScore(result: SearchResult): number {
  return typeof result.trustScore === 'number' ? result.trustScore : 0;
}

function selectBestLibrary(
  results: SearchResult[],
  libraryName: string,
): { selected?: SearchResult; ambiguous: boolean } {
  if (results.length === 0) return { ambiguous: false };
  if (results.length === 1) return { selected: results[0], ambiguous: false };

  const target = normalizeText(libraryName).replace(/^@/, '');
  const scored = results
    .map((result) => {
      const title = normalizeText(result.title);
      const id = normalizeText(result.id);
      let score =
        benchmarkScore(result) / 10 + trustScore(result) + Math.min(snippetCount(result), 100) / 20;
      if (title === target) score += 25;
      if (title.includes(target)) score += 12;
      if (id.endsWith(`/${target}`) || id.includes(`/${target}/`)) score += 12;
      return { result, score };
    })
    .sort((a, b) => b.score - a.score);

  const [top, second] = scored;
  if (!second) return { selected: top.result, ambiguous: false };

  const clearByExactMatch =
    normalizeText(top.result.title) === target ||
    normalizeText(top.result.id).endsWith(`/${target}`) ||
    top.score >= second.score + 8;

  if (clearByExactMatch) return { selected: top.result, ambiguous: false };
  return { ambiguous: true };
}

function formatResolveCandidate(result: SearchResult): string {
  const parts = [
    `- Title: ${displayTitle(result)}`,
    `  Library ID: ${result.id}`,
    `  Description: ${result.description}`,
  ];

  if (snippetCount(result) > 0) parts.push(`  Code Snippets: ${snippetCount(result)}`);
  if (trustScore(result) > 0) parts.push(`  Source Reputation Score: ${trustScore(result)}`);
  if (benchmarkScore(result) > 0) parts.push(`  Benchmark Score: ${benchmarkScore(result)}`);
  if (result.versions?.length) parts.push(`  Versions: ${result.versions.join(', ')}`);
  if (result.source) parts.push(`  Source: ${result.source}`);

  return parts.join('\n');
}

function formatResolveResults(
  response: SearchResponse,
  libraryName: string,
): { text: string; recommended?: SearchResult; ambiguous: boolean } {
  if (!response.results.length) {
    return {
      text: `No Context7 libraries matched "${libraryName}".`,
      ambiguous: false,
    };
  }

  const recommendation = selectBestLibrary(response.results, libraryName);
  const header = [
    `Context7 matches for "${libraryName}":`,
    recommendation.selected ? `Recommended library ID: ${recommendation.selected.id}` : undefined,
    recommendation.ambiguous
      ? 'Auto-resolution is ambiguous; choose one of the candidates below.'
      : undefined,
    '',
  ].filter(Boolean) as string[];

  const body = response.results.slice(0, 8).map(formatResolveCandidate).join('\n----------\n');
  return {
    text: `${header.join('\n')}${body}`,
    recommended: recommendation.selected,
    ambiguous: recommendation.ambiguous,
  };
}

function buildEffectiveQuery(query?: string, topic?: string, page?: number): string {
  const parts = [query?.trim(), topic?.trim() ? `Focus: ${topic.trim()}` : undefined];
  if (typeof page === 'number' && page > 1) parts.push(`Requested page: ${page}`);
  return parts.filter(Boolean).join('\n\n') || 'overview';
}

function summarizeError(
  error: { message: string; upstreamMessage?: string },
  extra?: string,
): string {
  return [error.message, extra].filter(Boolean).join(' ');
}

async function resolveLibraries(params: ResolveLibraryParams) {
  const settings = await loadSettings();
  const query = params.query?.trim() || params.libraryName.trim();
  const cached = await getResolveCache(settings, params.libraryName, query);

  if (cached.entry && cached.fresh) {
    return {
      source: 'fresh-cache' as const,
      response: { results: cached.entry.results },
      configError: settings.configError,
    };
  }

  const network = await searchLibraries(settings, { libraryName: params.libraryName, query });
  if (network.ok) {
    const entry = await putResolveCache(settings, {
      libraryName: params.libraryName,
      query,
      results: network.data.results,
    });
    return {
      source: 'network' as const,
      response: { results: entry.results, searchFilterApplied: network.data.searchFilterApplied },
      configError: settings.configError,
    };
  }

  if (cached.entry) {
    return {
      source: 'stale-cache' as const,
      response: { results: cached.entry.results },
      configError: settings.configError,
      staleBecause: network.error,
    };
  }

  throw Object.assign(
    new Error(
      summarizeError(
        network.error,
        settings.configError ? `Config parse issue: ${settings.configError}` : undefined,
      ),
    ),
    {
      details: { upstreamError: network.error, configError: settings.configError },
    },
  );
}

function formatCacheCandidates(candidates: DocCacheIndexEntry[]): string {
  return candidates
    .slice(0, 8)
    .map((candidate) => {
      const parts = [
        `- docRef: ${candidate.docRef}`,
        `  Library: ${candidate.libraryName}`,
        `  Library ID: ${candidate.libraryId}`,
        candidate.libraryVersion ? `  Version: ${candidate.libraryVersion}` : undefined,
        candidate.topic ? `  Topic: ${candidate.topic}` : undefined,
        `  Query: ${candidate.query}`,
        `  Page: ${candidate.page}`,
        `  Cached At: ${candidate.createdAt}`,
      ].filter(Boolean);
      return parts.join('\n');
    })
    .join('\n----------\n');
}

function normalizedLibraryNameFromResult(result?: SearchResult, fallback?: string): string {
  return normalizeText(result?.title || fallback || 'unknown-library');
}

async function getDocsEntry(params: GetLibraryDocsParams) {
  const settings = await loadSettings();
  const page =
    typeof params.page === 'number' && Number.isFinite(params.page)
      ? Math.max(1, Math.floor(params.page))
      : 1;
  const effectiveQuery = buildEffectiveQuery(params.query, params.topic, page);

  let libraryId = params.libraryId?.trim();
  let libraryName = params.libraryName?.trim();
  let resolvedResult: SearchResult | undefined;
  let resolveMetadata: Record<string, unknown> | undefined;

  if (!libraryId) {
    if (!libraryName) {
      throw new Error('context7_get_library_docs requires either libraryId or libraryName.');
    }

    const resolveResult = await resolveLibraries({ libraryName, query: params.query });
    const formatted = formatResolveResults(resolveResult.response, libraryName);
    resolveMetadata = {
      source: resolveResult.source,
      staleBecause: resolveResult.staleBecause,
      configError: resolveResult.configError,
    };

    if (!formatted.recommended || formatted.ambiguous) {
      return {
        ok: false as const,
        text: `${formatted.text}\n\nUnable to safely auto-resolve before fetching docs. Call context7_resolve_library_id first or pass an exact libraryId.`,
        details: {
          needsResolution: true,
          candidates: resolveResult.response.results.slice(0, 8),
          resolve: resolveMetadata,
        },
      };
    }

    libraryId = formatted.recommended.id;
    resolvedResult = formatted.recommended;
    libraryName = displayTitle(formatted.recommended);
  }

  const docRef = buildDocRef(libraryId, effectiveQuery, page);
  const cached = await getDocCacheByRef(settings, docRef);
  if (cached.entry && cached.fresh) {
    return {
      ok: true as const,
      entry: cached.entry,
      source: 'fresh-cache' as const,
      details: {
        docRef,
        cacheStatus: 'fresh',
        resolve: resolveMetadata,
        configError: settings.configError,
      },
    };
  }

  const network = await fetchLibraryDocs(settings, { libraryId, query: effectiveQuery });
  if (network.ok) {
    const version = extractVersionInfo(libraryId);
    const curated = curateDocText({
      rawText: network.data,
      libraryId,
      libraryName: libraryName || displayTitle(resolvedResult) || libraryId,
      libraryVersion: version.normalized,
      query: params.query,
      topic: params.topic,
      page,
      docRef,
    });

    const entry = await putDocCache(settings, {
      docRef,
      libraryId,
      libraryName: libraryName || displayTitle(resolvedResult) || libraryId,
      normalizedLibraryName: normalizedLibraryNameFromResult(resolvedResult, libraryName),
      libraryVersion: version.normalized,
      libraryVersionRaw: version.raw,
      query: params.query?.trim() || 'overview',
      topic: params.topic?.trim(),
      effectiveQuery,
      page,
      rawText: network.data,
      curatedText: curated.text,
    });

    return {
      ok: true as const,
      entry,
      source: 'network' as const,
      details: {
        docRef,
        cacheStatus: 'refreshed',
        resolve: resolveMetadata,
        curation: {
          truncated: curated.truncated,
          selectedSectionCount: curated.selectedSectionCount,
          rawLength: curated.rawLength,
        },
        configError: settings.configError,
      },
    };
  }

  if (cached.entry) {
    return {
      ok: true as const,
      entry: cached.entry,
      source: 'stale-cache' as const,
      details: {
        docRef,
        cacheStatus: 'stale',
        staleBecause: network.error,
        resolve: resolveMetadata,
        configError: settings.configError,
      },
    };
  }

  throw Object.assign(
    new Error(
      summarizeError(
        network.error,
        settings.configError ? `Config parse issue: ${settings.configError}` : undefined,
      ),
    ),
    {
      details: {
        upstreamError: network.error,
        resolve: resolveMetadata,
        configError: settings.configError,
      },
    },
  );
}

function defineContext7Tool<TParams extends TSchema>(
  tool: ToolDefinition<TParams, Record<string, unknown>>,
): ToolDefinition<TParams, Record<string, unknown>> {
  return tool;
}

function createResolveTool(name: string, description: string, promptVisible: boolean) {
  return defineContext7Tool({
    name,
    label: 'Context7 Resolve Library ID',
    description,
    ...(promptVisible
      ? {
          promptSnippet:
            'Resolve a library or package name to a Context7 library ID before fetching docs when the exact ID is unknown.',
          promptGuidelines: [
            'Use this tool when the user asks for library documentation and you do not already know the exact Context7 library ID.',
          ],
        }
      : {}),
    parameters: Type.Object({
      libraryName: Type.String({ description: 'Library or package name to resolve in Context7.' }),
      query: Type.Optional(
        Type.String({
          description: 'Optional task or intent to help rank the best Context7 library match.',
        }),
      ),
    }),
    async execute(_toolCallId: string, params: ResolveLibraryParams) {
      const resolved = await resolveLibraries(params);
      const formatted = formatResolveResults(resolved.response, params.libraryName);
      return {
        content: [{ type: 'text' as const, text: formatted.text }],
        details: {
          source: resolved.source,
          staleBecause: resolved.staleBecause,
          configError: resolved.configError,
          recommendedLibraryId: formatted.recommended?.id,
          ambiguous: formatted.ambiguous,
          results: resolved.response.results,
        },
      };
    },
  });
}

function createDocsTool(
  name: string,
  description: string,
  promptVisible: boolean,
  prepareArguments?: (args: unknown) => GetLibraryDocsParams,
) {
  return defineContext7Tool({
    name,
    label: 'Context7 Get Library Docs',
    description,
    ...(promptVisible
      ? {
          promptSnippet:
            'Fetch curated, up-to-date Context7 docs for a library by ID or by name. Equivalent to Context7 MCP get-library-docs/query-docs.',
          promptGuidelines: [
            'Prefer this tool over raw cached docs retrieval; use it first for normal documentation lookup.',
            'If you only know the library name, pass libraryName and let the tool auto-resolve it.',
          ],
        }
      : {}),
    parameters: Type.Object({
      libraryId: Type.Optional(
        Type.String({ description: 'Exact Context7 library ID, such as /vercel/next.js.' }),
      ),
      libraryName: Type.Optional(
        Type.String({
          description: 'Library or package name when an exact Context7 ID is not known.',
        }),
      ),
      query: Type.Optional(
        Type.String({ description: 'Freeform documentation request or question.' }),
      ),
      topic: Type.Optional(Type.String({ description: 'Optional focused topic inside the docs.' })),
      page: Type.Optional(
        Type.Number({
          description: 'Optional logical page number for repeated docs retrieval attempts.',
        }),
      ),
    }),
    prepareArguments,
    async execute(_toolCallId: string, params: GetLibraryDocsParams) {
      const result = await getDocsEntry(params);
      if (!result.ok) {
        return {
          content: [{ type: 'text' as const, text: result.text }],
          details: result.details,
        };
      }

      const entry = result.entry;
      const notes: string[] = [];
      if (result.source === 'stale-cache')
        notes.push('Returned stale cached docs because the network refresh failed.');
      if (result.source === 'fresh-cache') notes.push('Returned fresh cached docs.');
      if (result.source === 'network')
        notes.push('Fetched docs from Context7 and refreshed the local cache.');

      return {
        content: [
          { type: 'text' as const, text: `${entry.curatedText}\n\n${notes.join(' ')}`.trim() },
        ],
        details: {
          ...result.details,
          docRef: entry.docRef,
          libraryId: entry.libraryId,
          libraryName: entry.libraryName,
          libraryVersion: entry.libraryVersion,
          page: entry.page,
          query: entry.query,
          topic: entry.topic,
          effectiveQuery: entry.effectiveQuery,
        },
      };
    },
  });
}

function createRawDocsTool() {
  return defineContext7Tool({
    name: 'context7_get_cached_doc_raw',
    label: 'Context7 Get Cached Raw Doc',
    description:
      'Read the raw cached Context7 document for a previous docs fetch. Prefer context7_get_library_docs first.',
    promptSnippet:
      'Read the full raw cached Context7 document by docRef or semantic lookup when curated docs were insufficient.',
    promptGuidelines: [
      'Use this tool only after context7_get_library_docs when you need the full cached raw documentation.',
      'Prefer docRef from an earlier tool result. If semantic lookup matches multiple cached docs, this tool will not guess.',
    ],
    parameters: Type.Object({
      docRef: Type.Optional(
        Type.String({ description: 'Exact docRef returned by context7_get_library_docs.' }),
      ),
      libraryId: Type.Optional(
        Type.String({ description: 'Optional Context7 library ID for semantic cache lookup.' }),
      ),
      libraryName: Type.Optional(
        Type.String({ description: 'Optional library name for semantic cache lookup.' }),
      ),
      libraryVersion: Type.Optional(
        Type.String({ description: 'Optional library version for semantic cache lookup.' }),
      ),
      query: Type.Optional(
        Type.String({ description: 'Optional original query used to fetch docs.' }),
      ),
      topic: Type.Optional(
        Type.String({ description: 'Optional original topic used to fetch docs.' }),
      ),
      page: Type.Optional(Type.Number({ description: 'Optional original logical page number.' })),
    }),
    async execute(_toolCallId: string, params: GetCachedDocRawParams) {
      const settings = await loadSettings();
      const selector: CacheSearchSelector = {
        docRef: params.docRef?.trim(),
        libraryId: params.libraryId?.trim(),
        libraryName: params.libraryName?.trim(),
        libraryVersion: params.libraryVersion?.trim(),
        query: params.query?.trim(),
        topic: params.topic?.trim(),
        page: typeof params.page === 'number' ? Math.max(1, Math.floor(params.page)) : undefined,
      };

      if (selector.docRef) {
        const cached = await getDocCacheByRef(settings, selector.docRef);
        if (!cached.entry) {
          throw new Error(
            `No cached Context7 document found for docRef ${selector.docRef}. Call context7_get_library_docs first.`,
          );
        }
        return {
          content: [{ type: 'text' as const, text: cached.entry.rawText }],
          details: {
            docRef: cached.entry.docRef,
            libraryId: cached.entry.libraryId,
            libraryName: cached.entry.libraryName,
            libraryVersion: cached.entry.libraryVersion,
            cacheStatus: cached.fresh ? 'fresh' : 'stale',
            query: cached.entry.query,
            topic: cached.entry.topic,
            page: cached.entry.page,
          },
        };
      }

      if (
        !selector.libraryId &&
        !selector.libraryName &&
        !selector.libraryVersion &&
        !selector.query &&
        !selector.topic &&
        selector.page === undefined
      ) {
        throw new Error('context7_get_cached_doc_raw requires docRef or semantic lookup fields.');
      }

      const candidates = await findDocCacheCandidates(settings, selector);
      if (candidates.length === 0) {
        throw new Error(
          'No cached Context7 documents matched that lookup. Call context7_get_library_docs first.',
        );
      }

      if (candidates.length > 1) {
        return {
          content: [
            {
              type: 'text' as const,
              text: `Multiple cached Context7 documents matched that lookup. Refine the lookup or use one of these docRefs:\n\n${formatCacheCandidates(candidates)}`,
            },
          ],
          details: {
            ambiguous: true,
            candidates,
          },
        };
      }

      const entry = await loadDocCacheObject(settings, candidates[0]);
      if (!entry) {
        throw new Error(
          `Cached Context7 document metadata exists for ${candidates[0].docRef}, but the object file is missing.`,
        );
      }

      return {
        content: [{ type: 'text' as const, text: entry.rawText }],
        details: {
          docRef: entry.docRef,
          libraryId: entry.libraryId,
          libraryName: entry.libraryName,
          libraryVersion: entry.libraryVersion,
          cacheStatus: new Date(entry.expiresAt).getTime() > Date.now() ? 'fresh' : 'stale',
          query: entry.query,
          topic: entry.topic,
          page: entry.page,
        },
      };
    },
  });
}

function normalizeGetLibraryDocsAlias(args: unknown): GetLibraryDocsParams {
  if (!args || typeof args !== 'object') return {};

  const input = args as Record<string, unknown>;
  const normalized: GetLibraryDocsParams = {};

  if (typeof input.libraryId === 'string') normalized.libraryId = input.libraryId;
  else if (typeof input.context7CompatibleLibraryID === 'string') {
    normalized.libraryId = input.context7CompatibleLibraryID;
  }

  if (typeof input.libraryName === 'string') normalized.libraryName = input.libraryName;

  if (typeof input.query === 'string') normalized.query = input.query;
  else if (typeof input.topic === 'string') normalized.query = input.topic;

  if (typeof input.query === 'string' && typeof input.topic === 'string') {
    normalized.topic = input.topic;
  }

  if (typeof input.page === 'number' && Number.isFinite(input.page)) {
    normalized.page = input.page;
  }

  return normalized;
}

export function registerContext7Tools(pi: ExtensionAPI) {
  pi.registerTool(
    createResolveTool(
      'context7_resolve_library_id',
      'Resolve a library or package name to a Context7 library ID. Pi-native equivalent of Context7 MCP resolve-library-id.',
      true,
    ),
  );

  pi.registerTool(
    createDocsTool(
      'context7_get_library_docs',
      'Fetch curated, up-to-date Context7 docs by library ID or library name. Pi-native equivalent of Context7 MCP get-library-docs / query-docs.',
      true,
    ),
  );

  pi.registerTool(createRawDocsTool());

  pi.registerTool(
    createResolveTool(
      'resolve-library-id',
      'Compatibility alias for context7_resolve_library_id.',
      false,
    ),
  );

  pi.registerTool(
    createDocsTool(
      'get-library-docs',
      'Compatibility alias for context7_get_library_docs.',
      false,
      normalizeGetLibraryDocsAlias,
    ),
  );

  pi.registerTool(
    createDocsTool(
      'query-docs',
      'Compatibility alias for context7_get_library_docs.',
      false,
      normalizeGetLibraryDocsAlias,
    ),
  );
}
