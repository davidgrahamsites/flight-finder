#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

async function loadPlaywright() {
  try {
    const mod = await import('playwright');
    return mod;
  } catch {
    return null;
  }
}

function parseArgs(argv) {
  const args = {
    mode: 'global',
    timeoutMs: 15000,
    out: '',
    limit: 0,
    config: path.resolve(process.cwd(), 'config/provider-smoke.targets.json')
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    const next = argv[i + 1];

    if (token === '--china-mode') {
      args.mode = 'china';
    } else if (token === '--timeout-ms' && next) {
      args.timeoutMs = Number(next);
      i += 1;
    } else if (token === '--out' && next) {
      args.out = next;
      i += 1;
    } else if (token === '--limit' && next) {
      args.limit = Number(next);
      i += 1;
    } else if (token === '--config' && next) {
      args.config = path.resolve(process.cwd(), next);
      i += 1;
    }
  }

  return args;
}

function loadTargets(configPath, mode, limit) {
  const raw = fs.readFileSync(configPath, 'utf-8');
  const parsed = JSON.parse(raw);
  const source = parsed[mode] ?? parsed.global ?? [];
  if (limit > 0) {
    return source.slice(0, limit);
  }
  return source;
}

async function checkTarget(browser, target, timeoutMs) {
  const context = await browser.newContext();
  const page = await context.newPage();
  const startedAt = Date.now();

  try {
    const response = await page.goto(target.url, {
      timeout: timeoutMs,
      waitUntil: 'domcontentloaded'
    });

    const status = response ? response.status() : null;
    const title = await page.title();
    const finalURL = page.url();

    await context.close();

    return {
      id: target.id,
      name: target.name,
      url: target.url,
      ok: status !== null && status < 400,
      httpStatus: status,
      title,
      finalURL,
      elapsedMs: Date.now() - startedAt
    };
  } catch (error) {
    await context.close();
    return {
      id: target.id,
      name: target.name,
      url: target.url,
      ok: false,
      httpStatus: null,
      title: '',
      finalURL: '',
      elapsedMs: Date.now() - startedAt,
      error: String(error?.message ?? error)
    };
  }
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const targets = loadTargets(args.config, args.mode, args.limit);

  if (targets.length === 0) {
    console.error('No targets found for selected mode.');
    process.exit(1);
  }

  const playwright = await loadPlaywright();
  if (!playwright) {
    console.error('Playwright is not installed. Run: npm i -D playwright');
    process.exit(2);
  }

  const browser = await playwright.chromium.launch({ headless: true });
  const results = [];

  for (const target of targets) {
    const result = await checkTarget(browser, target, args.timeoutMs);
    results.push(result);
  }

  await browser.close();

  const output = {
    generatedAt: new Date().toISOString(),
    mode: args.mode,
    timeoutMs: args.timeoutMs,
    summary: {
      total: results.length,
      reachable: results.filter((x) => x.ok).length,
      unreachable: results.filter((x) => !x.ok).length
    },
    results
  };

  const json = JSON.stringify(output, null, 2);

  if (args.out) {
    const resolvedOut = path.resolve(process.cwd(), args.out);
    fs.mkdirSync(path.dirname(resolvedOut), { recursive: true });
    fs.writeFileSync(resolvedOut, json + '\n', 'utf-8');
  }

  console.log(json);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
