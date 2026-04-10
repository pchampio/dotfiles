import type { CuratedDocResult } from './types';

const MAX_CURATED_CHARS = 12_000;
const STOPWORDS = new Set([
  'the',
  'and',
  'for',
  'with',
  'that',
  'this',
  'from',
  'into',
  'your',
  'their',
  'about',
  'using',
  'use',
  'how',
  'what',
  'when',
  'where',
  'why',
  'are',
  'was',
  'were',
  'can',
  'you',
  'need',
  'docs',
  'doc',
  'library',
  'page',
  'requested',
  'focus',
]);

interface Section {
  text: string;
  score: number;
  index: number;
}

function normalizeWhitespace(text: string): string {
  return text
    .replace(/\r\n/g, '\n')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

function extractKeywords(query?: string, topic?: string): string[] {
  const source = `${query ?? ''} ${topic ?? ''}`.toLowerCase();
  const words = source.match(/[a-z0-9._/-]{3,}/g) ?? [];
  const unique = new Set<string>();

  for (const word of words) {
    if (STOPWORDS.has(word)) continue;
    unique.add(word);
  }

  return Array.from(unique).slice(0, 12);
}

function splitIntoSections(text: string): string[] {
  const normalized = normalizeWhitespace(text);
  if (!normalized) return [];

  const lines = normalized.split('\n');
  const sections: string[] = [];
  let buffer: string[] = [];

  const flush = () => {
    const chunk = buffer.join('\n').trim();
    if (chunk) sections.push(chunk);
    buffer = [];
  };

  for (const line of lines) {
    const isHeading =
      /^#{1,6}\s+/.test(line) || (/^[A-Z][^\n]{0,100}:$/.test(line) && line.length < 100);
    if (isHeading && buffer.length > 0) flush();
    buffer.push(line);
    if (!line.trim()) flush();
  }

  flush();
  return sections.filter(Boolean);
}

function scoreSection(section: string, keywords: string[], index: number): number {
  if (keywords.length === 0) return Math.max(0, 10 - index);

  const lower = section.toLowerCase();
  const lines = section.split('\n');
  const heading = lines[0]?.toLowerCase() ?? '';

  let score = Math.max(0, 8 - index);
  for (const keyword of keywords) {
    const occurrences = lower.split(keyword).length - 1;
    if (occurrences > 0) score += occurrences * 4;
    if (heading.includes(keyword)) score += 6;
  }

  return score;
}

function chooseSections(text: string, query?: string, topic?: string): Section[] {
  const keywords = extractKeywords(query, topic);
  const sections = splitIntoSections(text).map((section, index) => ({
    text: section,
    score: scoreSection(section, keywords, index),
    index,
  }));

  if (sections.length === 0) return [];

  const highSignal = sections
    .filter((section) => section.score > 8)
    .sort((a, b) => b.score - a.score || a.index - b.index);
  const picked = (
    highSignal.length > 0 ? highSignal : sections.slice().sort((a, b) => a.index - b.index)
  ).slice(0, 12);

  return picked.sort((a, b) => a.index - b.index);
}

export function curateDocText(input: {
  rawText: string;
  libraryId: string;
  libraryName: string;
  libraryVersion?: string;
  query?: string;
  topic?: string;
  page: number;
  docRef: string;
}): CuratedDocResult {
  const sections = chooseSections(input.rawText, input.query, input.topic);

  const headerLines = [
    `Library: ${input.libraryName}`,
    `Library ID: ${input.libraryId}`,
    input.libraryVersion ? `Version: ${input.libraryVersion}` : undefined,
    input.query ? `Query: ${input.query}` : undefined,
    input.topic ? `Topic: ${input.topic}` : undefined,
    `Page: ${input.page}`,
    '',
    'Relevant documentation:',
    '',
  ].filter(Boolean) as string[];

  const footerLines = ['', `Raw cached document available via docRef: ${input.docRef}`];

  let selectedSectionCount = 0;
  let body = '';
  let truncated = false;
  const budget = Math.max(
    2_000,
    MAX_CURATED_CHARS - headerLines.join('\n').length - footerLines.join('\n').length,
  );

  for (const section of sections) {
    const next = body ? `${body}\n\n${section.text}` : section.text;
    if (next.length > budget) {
      if (!body) {
        body = section.text.slice(0, budget);
        truncated = true;
        selectedSectionCount = 1;
      }
      break;
    }
    body = next;
    selectedSectionCount += 1;
  }

  if (!body) {
    body = normalizeWhitespace(input.rawText).slice(0, budget);
    truncated = normalizeWhitespace(input.rawText).length > budget;
    selectedSectionCount = body ? 1 : 0;
  }

  if (!truncated && normalizeWhitespace(input.rawText).length > body.length) {
    truncated = body.length < normalizeWhitespace(input.rawText).length;
  }

  const text = `${headerLines.join('\n')}${body}${footerLines.join('\n')}`.trim();

  return {
    text,
    truncated,
    selectedSectionCount,
    rawLength: normalizeWhitespace(input.rawText).length,
  };
}
