import test from 'node:test';
import assert from 'node:assert/strict';
import {
  extractGithubInstallSpec,
  parseSectionSkills,
  parseSkillsFromReadme
} from '../awesome_skills_catalog.mjs';

const sampleReadme = `
## Official Claude Skills

- **[anthropics/docx](https://github.com/anthropics/skills/tree/main/skills/docx)** - Create and analyze Word documents
- **[anthropics/mcp-builder](https://github.com/anthropics/skills/tree/main/skills/mcp-builder)** - Create MCP servers
- **[fal-ai-community/fal-audio](https://github.com/fal-ai-community/skills/blob/main/skills/claude.ai/fal-audio/SKILL.md)** - Audio generation
- **[not-github/example](https://example.com/not-a-github-link)** - Ignore this entry

## Skills by Vercel Engineering Team

- **[vercel-labs/react-best-practices](https://github.com/vercel-labs/agent-skills/tree/main/skills/react-best-practices)** - React guidance
`;

test('extractGithubInstallSpec parses tree URLs', () => {
  const spec = extractGithubInstallSpec('https://github.com/anthropics/skills/tree/main/skills/docx');
  assert.ok(spec);
  assert.equal(spec.repo, 'anthropics/skills');
  assert.equal(spec.path, 'skills/docx');
  assert.equal(spec.branch, 'main');
});

test('extractGithubInstallSpec normalizes blob SKILL.md URLs to folder path', () => {
  const spec = extractGithubInstallSpec(
    'https://github.com/fal-ai-community/skills/blob/main/skills/claude.ai/fal-audio/SKILL.md'
  );
  assert.ok(spec);
  assert.equal(spec.repo, 'fal-ai-community/skills');
  assert.equal(spec.path, 'skills/claude.ai/fal-audio');
  assert.equal(spec.branch, 'main');
});

test('parseSkillsFromReadme returns only skills from selected section', () => {
  const entries = parseSkillsFromReadme(sampleReadme, {
    sectionSlug: 'official-claude-skills'
  });

  assert.equal(entries.length, 3);
  assert.deepEqual(
    entries.map((entry) => entry.name),
    ['docx', 'mcp-builder', 'fal-audio']
  );
  assert.equal(entries[0].repo, 'anthropics/skills');
  assert.equal(entries[2].path, 'skills/claude.ai/fal-audio');
  assert.equal(entries[2].sourceURL.includes('/blob/'), true);
});

test('parseSectionSkills groups skills by top-level section', () => {
  const sections = parseSectionSkills(sampleReadme);
  assert.equal(sections.length, 2);
  assert.equal(sections[0].slug, 'official-claude-skills');
  assert.equal(sections[0].entries.length, 3);
  assert.equal(sections[1].slug, 'skills-by-vercel-engineering-team');
  assert.equal(sections[1].entries.length, 1);
});
