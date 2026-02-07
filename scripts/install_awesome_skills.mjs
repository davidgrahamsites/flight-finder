#!/usr/bin/env node

import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import { parseSectionSkills } from './awesome_skills_catalog.mjs';

const DEFAULT_README_URL =
  'https://raw.githubusercontent.com/VoltAgent/awesome-agent-skills/main/README.md';
const DEFAULT_INSTALLER =
  '/Users/appleadmin/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py';
const DEFAULT_SKILLS_DIR = path.join(process.env.CODEX_HOME ?? path.join(process.env.HOME ?? '', '.codex'), 'skills');

function printHelp() {
  console.log(`
Install skills from the Awesome Agent Skills catalog.

Usage:
  node scripts/install_awesome_skills.mjs [options]

Options:
  --scope <slug|all|slug1,slug2>   Section scope (default: official-claude-skills)
  --max <n>                        Install at most n skills
  --name-style <auto|scoped|base>  Skill naming mode (default: auto)
  --readme-url <url>               Catalog README source URL
  --installer <path>               install-skill-from-github.py path
  --skills-dir <path>              Destination skills directory
  --manifest-out <path>            Write parsed selection manifest as JSON
  --strict                         Stop on first install failure
  --dry-run                        Show planned installs without running
  --help                           Show this help
`);
}

function parseArgs(argv) {
  const args = {
    scope: 'official-claude-skills',
    max: 0,
    dryRun: false,
    strict: false,
    nameStyle: 'auto',
    readmeURL: DEFAULT_README_URL,
    installerPath: DEFAULT_INSTALLER,
    skillsDir: DEFAULT_SKILLS_DIR,
    manifestOut: ''
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    const next = argv[i + 1];

    if (token === '--scope' && next) {
      args.scope = next.trim();
      i += 1;
    } else if (token === '--max' && next) {
      args.max = Number(next);
      i += 1;
    } else if (token === '--name-style' && next) {
      args.nameStyle = next.trim();
      i += 1;
    } else if (token === '--readme-url' && next) {
      args.readmeURL = next.trim();
      i += 1;
    } else if (token === '--installer' && next) {
      args.installerPath = next.trim();
      i += 1;
    } else if (token === '--skills-dir' && next) {
      args.skillsDir = next.trim();
      i += 1;
    } else if (token === '--manifest-out' && next) {
      args.manifestOut = next.trim();
      i += 1;
    } else if (token === '--strict') {
      args.strict = true;
    } else if (token === '--dry-run') {
      args.dryRun = true;
    } else if (token === '--help' || token === '-h') {
      printHelp();
      process.exit(0);
    } else {
      throw new Error(`Unknown argument: ${token}`);
    }
  }

  if (!Number.isFinite(args.max) || args.max < 0) {
    throw new Error('--max must be a non-negative number');
  }

  if (!['auto', 'scoped', 'base'].includes(args.nameStyle)) {
    throw new Error('--name-style must be auto, scoped, or base');
  }

  return args;
}

function sanitizeName(value) {
  return value
    .toLowerCase()
    .replace(/[^a-z0-9._-]+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function installNameFor(entry, nameStyle) {
  const base = sanitizeName(entry.name);
  if (nameStyle === 'base') {
    return base;
  }

  const owner = sanitizeName(entry.repo.split('/')[0] ?? 'skill');
  return sanitizeName(`${owner}-${base}`);
}

function dedupeEntries(entries) {
  const seen = new Set();
  const deduped = [];
  for (const entry of entries) {
    const key = `${entry.repo}::${entry.path}`;
    if (seen.has(key)) {
      continue;
    }
    seen.add(key);
    deduped.push(entry);
  }
  return deduped;
}

function selectEntries(sections, scopeValue) {
  const allEntries = sections.flatMap((section) => section.entries);
  if (scopeValue === 'all') {
    return allEntries;
  }

  const selectedSlugs = scopeValue
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);

  const selected = allEntries.filter((entry) => selectedSlugs.includes(entry.sectionSlug));
  return dedupeEntries(selected);
}

async function fetchReadme(url) {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Failed to fetch catalog README: HTTP ${response.status}`);
  }
  return response.text();
}

function writeManifest(manifestPath, payload) {
  const resolved = path.resolve(process.cwd(), manifestPath);
  fs.mkdirSync(path.dirname(resolved), { recursive: true });
  fs.writeFileSync(resolved, JSON.stringify(payload, null, 2) + '\n', 'utf-8');
  return resolved;
}

function runInstaller(args, entry, installName) {
  execFileSync(
    'python3',
    [
      args.installerPath,
      '--repo',
      entry.repo,
      '--path',
      entry.path,
      '--ref',
      entry.branch,
      '--dest',
      args.skillsDir,
      '--name',
      installName
    ],
    { stdio: 'inherit' }
  );
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const readme = await fetchReadme(args.readmeURL);
  const sections = parseSectionSkills(readme);
  const availableSlugs = sections.map((section) => section.slug);

  if (sections.length === 0) {
    throw new Error('No installable skills found in catalog.');
  }

  let entries = selectEntries(sections, args.scope);
  entries = dedupeEntries(entries);

  if (entries.length === 0) {
    throw new Error(
      `No skills found for scope "${args.scope}". Available scopes: ${availableSlugs.join(', ')}`
    );
  }

  if (args.max > 0) {
    entries = entries.slice(0, args.max);
  }

  const effectiveNameStyle =
    args.nameStyle === 'auto'
      ? (args.scope === 'all' ? 'scoped' : 'base')
      : args.nameStyle;

  const planned = entries.map((entry) => ({
    ...entry,
    installName: installNameFor(entry, effectiveNameStyle),
    alreadyInstalled: fs.existsSync(path.join(args.skillsDir, installNameFor(entry, effectiveNameStyle)))
  }));

  if (args.manifestOut) {
    const manifestSkills = planned.map(({ alreadyInstalled, ...rest }) => rest);
    const manifestPath = writeManifest(args.manifestOut, {
      generatedAt: new Date().toISOString(),
      sourceReadmeURL: args.readmeURL,
      scope: args.scope,
      sections: availableSlugs,
      selectedCount: manifestSkills.length,
      skills: manifestSkills
    });
    console.log(`Manifest written: ${manifestPath}`);
  }

  if (args.dryRun) {
    console.log(
      JSON.stringify(
        {
          mode: 'dry-run',
          scope: args.scope,
          effectiveNameStyle,
          skillsDir: args.skillsDir,
          selectedCount: planned.length,
          installs: planned
        },
        null,
        2
      )
    );
    return;
  }

  fs.mkdirSync(args.skillsDir, { recursive: true });

  let installed = 0;
  let skipped = 0;
  const failures = [];

  for (const entry of planned) {
    if (entry.alreadyInstalled) {
      console.log(`Skipping ${entry.installName} (already installed)`);
      skipped += 1;
      continue;
    }

    console.log(`Installing ${entry.installName} from ${entry.repo}:${entry.path}`);
    try {
      runInstaller(args, entry, entry.installName);
      installed += 1;
    } catch (error) {
      failures.push({
        installName: entry.installName,
        source: `${entry.repo}:${entry.path}`,
        error: String(error?.message ?? error)
      });
      if (args.strict) {
        break;
      }
    }
  }

  console.log(
    JSON.stringify(
        {
          scope: args.scope,
          effectiveNameStyle,
          selected: planned.length,
          installed,
          skipped,
        failed: failures.length
      },
      null,
      2
    )
  );

  if (failures.length > 0) {
    for (const failure of failures) {
      console.error(`Failed: ${failure.installName} (${failure.source})`);
    }
    process.exit(2);
  }
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
