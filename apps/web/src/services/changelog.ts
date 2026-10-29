export interface ChangelogEntry {
  text: string;
  hash: string | null;
}

export interface ChangelogSection {
  date: string;
  entries: ChangelogEntry[];
}

export interface Changelog {
  sections: ChangelogSection[];
}

/**
 * Parse the generated `CHANGELOG.md` (one `## <date>` section per day, entries
 * as `- Subject (`hash`)`).
 */
export function parseChangelog(markdown: string): Changelog {
  const sections: ChangelogSection[] = [];
  let current: ChangelogSection | null = null;

  for (const rawLine of markdown.split('\n')) {
    const line = rawLine.trim();

    const dateMatch = /^##\s+(.+)$/.exec(line);
    if (dateMatch) {
      current = { date: dateMatch[1]!, entries: [] };
      sections.push(current);
      continue;
    }

    const entryMatch = /^-\s+(.*)$/.exec(line);
    if (entryMatch && current) {
      const body = entryMatch[1]!;
      const hashMatch = /\(`?([0-9a-f]{7,40})`?\)\s*$/.exec(body);
      current.entries.push({
        text: hashMatch ? body.slice(0, hashMatch.index).trim() : body,
        hash: hashMatch ? hashMatch[1]! : null,
      });
    }
  }

  return { sections };
}

export async function fetchChangelog(): Promise<Changelog | null> {
  try {
    const response = await fetch('/CHANGELOG.md', { cache: 'no-cache' });
    if (!response.ok) return null;
    return parseChangelog(await response.text());
  } catch {
    return null;
  }
}
