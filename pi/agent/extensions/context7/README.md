# pi Context7 Extension

Pi-native Context7 tools with direct HTTP integration, persistent cache, and MCP-compatible aliases.

## Public tools

Primary tools:

- `context7_resolve_library_id`
- `context7_get_library_docs`
- `context7_get_cached_doc_raw`

Compatibility aliases:

- `resolve-library-id`
- `get-library-docs`
- `query-docs`

## Configuration

Preferred:

```bash
export CONTEXT7_API_KEY=ctx7sk-...
```

Optional fallback file:

`~/.pi/agent/extensions/context7/config.json`

```json
{
  "apiKey": "ctx7sk-...",
  "cache": {
    "resolveTtlHours": 168,
    "docsTtlHours": 24
  }
}
```

## Cache

Stored under:

- `~/.pi/agent/extensions/context7/cache/resolve/`
- `~/.pi/agent/extensions/context7/cache/docs/`

The docs cache is searchable by library name, version, library ID, query, topic, and docRef.

## Reload

Once the files are in place, start pi or run:

```text
/reload
```
