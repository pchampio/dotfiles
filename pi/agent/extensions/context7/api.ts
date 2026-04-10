import type {
  Context7ApiError,
  Context7ApiResult,
  Context7Settings,
  SearchResponse,
} from './types';

const CONTEXT7_API_BASE_URL = process.env.CONTEXT7_API_URL || 'https://context7.com/api';

function buildHeaders(settings: Context7Settings): HeadersInit {
  const headers: Record<string, string> = {
    Accept: 'application/json, text/plain;q=0.9, */*;q=0.8',
    'X-Context7-Source': 'pi-extension',
  };

  if (settings.apiKey) headers.Authorization = `Bearer ${settings.apiKey}`;
  return headers;
}

async function parseErrorResponse(
  response: Response,
  settings: Context7Settings,
): Promise<Context7ApiError> {
  let upstreamMessage: string | undefined;

  try {
    const payload = (await response.json()) as { message?: string };
    if (typeof payload?.message === 'string' && payload.message.trim()) {
      upstreamMessage = payload.message.trim();
    }
  } catch {
    // Ignore non-JSON error bodies.
  }

  if (response.status === 429) {
    return {
      kind: 'rate_limit',
      status: response.status,
      message: settings.apiKey
        ? 'Context7 rate limit exceeded. Retry later or use a higher-limit Context7 plan.'
        : 'Context7 rate limit exceeded. Retry later or configure CONTEXT7_API_KEY for higher limits.',
      upstreamMessage,
    };
  }

  if (response.status === 401) {
    return {
      kind: 'auth',
      status: response.status,
      message: 'Context7 API key appears invalid.',
      upstreamMessage,
    };
  }

  if (response.status === 404) {
    return {
      kind: 'not_found',
      status: response.status,
      message: 'No Context7 documentation was found for that library identifier.',
      upstreamMessage,
    };
  }

  return {
    kind: 'unknown',
    status: response.status,
    message: `Context7 request failed with status ${response.status}.`,
    upstreamMessage,
  };
}

export async function searchLibraries(
  settings: Context7Settings,
  params: { libraryName: string; query: string },
): Promise<Context7ApiResult<SearchResponse>> {
  try {
    const url = new URL(`${CONTEXT7_API_BASE_URL}/v2/libs/search`);
    url.searchParams.set('query', params.query);
    url.searchParams.set('libraryName', params.libraryName);

    const response = await fetch(url, { headers: buildHeaders(settings) });
    if (!response.ok) return { ok: false, error: await parseErrorResponse(response, settings) };

    const payload = (await response.json()) as SearchResponse;
    if (!payload || !Array.isArray(payload.results)) {
      return {
        ok: false,
        error: {
          kind: 'invalid_response',
          message: 'Context7 returned an invalid search response.',
        },
      };
    }

    return { ok: true, data: payload };
  } catch (error) {
    return {
      ok: false,
      error: {
        kind: 'network',
        message: 'Unable to reach Context7 right now.',
        upstreamMessage: error instanceof Error ? error.message : String(error),
      },
    };
  }
}

export async function fetchLibraryDocs(
  settings: Context7Settings,
  params: { libraryId: string; query: string },
): Promise<Context7ApiResult<string>> {
  try {
    const url = new URL(`${CONTEXT7_API_BASE_URL}/v2/context`);
    url.searchParams.set('libraryId', params.libraryId);
    url.searchParams.set('query', params.query);

    const response = await fetch(url, { headers: buildHeaders(settings) });
    if (!response.ok) return { ok: false, error: await parseErrorResponse(response, settings) };

    const text = await response.text();
    if (!text.trim()) {
      return {
        ok: false,
        error: {
          kind: 'not_found',
          message:
            'Context7 returned an empty documentation response. Try resolving the library again or refining the query.',
        },
      };
    }

    return { ok: true, data: text };
  } catch (error) {
    return {
      ok: false,
      error: {
        kind: 'network',
        message: 'Unable to reach Context7 right now.',
        upstreamMessage: error instanceof Error ? error.message : String(error),
      },
    };
  }
}
