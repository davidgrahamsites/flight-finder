function slugifyHeading(value) {
  return value
    .trim()
    .toLowerCase()
    .replace(/[`"'()[\].,!?]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-');
}

function parseSkillBullet(line) {
  const match = line.match(/^\s*-\s+\*\*\[([^\]]+)\]\(([^)]+)\)\*\*\s*-\s*(.+?)\s*$/);
  if (!match) {
    return null;
  }

  return {
    label: match[1].trim(),
    url: match[2].trim(),
    description: match[3].trim()
  };
}

export function extractGithubInstallSpec(urlString) {
  let parsedURL;
  try {
    parsedURL = new URL(urlString);
  } catch {
    return null;
  }

  if (parsedURL.hostname !== 'github.com') {
    return null;
  }

  const segments = parsedURL.pathname.split('/').filter(Boolean);
  if (segments.length < 5) {
    return null;
  }

  const [owner, repo, mode, branch, ...pathParts] = segments;
  if (!(mode === 'tree' || mode === 'blob')) {
    return null;
  }

  if (pathParts.length === 0) {
    return null;
  }

  const normalizedParts = [...pathParts];
  if (mode === 'blob') {
    const fileCandidate = normalizedParts[normalizedParts.length - 1] ?? '';
    if (fileCandidate.toLowerCase().endsWith('.md')) {
      normalizedParts.pop();
    }
  }

  if (normalizedParts.length === 0) {
    return null;
  }

  return {
    repo: `${owner}/${repo}`,
    branch,
    path: normalizedParts.join('/'),
    sourceURL: urlString
  };
}

export function parseSectionSkills(readmeMarkdown) {
  const sections = [];
  const sectionBySlug = new Map();
  let currentSection = null;

  for (const line of readmeMarkdown.split(/\r?\n/)) {
    const headingMatch = line.match(/^##\s+(.+?)\s*$/);
    if (headingMatch) {
      const title = headingMatch[1].trim();
      const slug = slugifyHeading(title);

      let section = sectionBySlug.get(slug);
      if (!section) {
        section = { slug, title, entries: [] };
        sections.push(section);
        sectionBySlug.set(slug, section);
      }

      currentSection = section;
      continue;
    }

    if (!currentSection) {
      continue;
    }

    const bullet = parseSkillBullet(line);
    if (!bullet) {
      continue;
    }

    const installSpec = extractGithubInstallSpec(bullet.url);
    if (!installSpec) {
      continue;
    }

    const skillName = bullet.label.includes('/')
      ? bullet.label.split('/').at(-1).trim()
      : bullet.label.trim();

    currentSection.entries.push({
      sectionSlug: currentSection.slug,
      sectionTitle: currentSection.title,
      label: bullet.label,
      name: skillName,
      description: bullet.description,
      ...installSpec
    });
  }

  return sections.filter((section) => section.entries.length > 0);
}

export function parseSkillsFromReadme(readmeMarkdown, options = {}) {
  const sectionSlug = (options.sectionSlug ?? 'official-claude-skills').trim();
  const sections = parseSectionSkills(readmeMarkdown);
  const section = sections.find((item) => item.slug === sectionSlug);
  return section?.entries ?? [];
}

