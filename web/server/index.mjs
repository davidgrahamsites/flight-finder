import path from 'node:path';
import { fileURLToPath } from 'node:url';

import cors from 'cors';
import express from 'express';

import { createFileBackedAccessLearningStore } from './lib/access-learning-store.mjs';
import { probeProvidersFromCurrentNetwork } from './lib/china-probe.mjs';
import { getProvidersByKinds, PROVIDERS } from './lib/providers.mjs';
import { runSearch } from './lib/search-engine.mjs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, '..');
const clientDistPath = path.resolve(repoRoot, 'client/dist');
const dataFilePath = path.resolve(__dirname, 'data/provider-access-stats.json');

const PORT = Number(process.env.PORT ?? 8787);

const app = express();
app.use(cors());
app.use(express.json({ limit: '1mb' }));

const accessStore = await createFileBackedAccessLearningStore(dataFilePath);

function parseKindsFromQuery(value) {
  return String(value ?? '')
    .split(',')
    .map((kind) => kind.trim())
    .filter(Boolean);
}

app.get('/api/health', (_req, res) => {
  res.json({ ok: true, service: 'flightfinder-web-api', now: new Date().toISOString() });
});

app.get('/api/providers', (req, res) => {
  const kinds = parseKindsFromQuery(req.query.kinds);
  const providers = kinds.length ? getProvidersByKinds(kinds) : PROVIDERS;
  res.json({ providers });
});

app.get('/api/china/snapshots', (req, res) => {
  const includeAllProviders = req.query.includeAllProviders === 'true';
  const kinds = parseKindsFromQuery(req.query.kinds);
  const providers = includeAllProviders ? PROVIDERS : kinds.length ? getProvidersByKinds(kinds) : PROVIDERS;
  const snapshots = accessStore.listSnapshots(providers);

  const reachable = snapshots.filter((item) => item.reachabilityScore >= 0.5).length;
  res.json({
    snapshots,
    summary: `Reachable-weighted providers: ${reachable}/${snapshots.length}`
  });
});

app.post('/api/china/probe', async (req, res) => {
  try {
    const includeAllProviders = Boolean(req.body?.includeAllProviders ?? false);
    const enabledKinds = Array.isArray(req.body?.enabledProviderKinds) ? req.body.enabledProviderKinds : [];

    const providers = includeAllProviders ? PROVIDERS : getProvidersByKinds(enabledKinds);
    const probeResults = await probeProvidersFromCurrentNetwork(providers, accessStore, {
      timeoutMs: Number(req.body?.timeoutMs ?? 5000)
    });

    const reachable = probeResults.filter((item) => item.reachable).length;
    const blocked = probeResults.length - reachable;

    res.json({
      summary: `Probe complete: ${reachable} reachable, ${blocked} blocked/timeout from current network.`,
      probeResults,
      snapshots: accessStore.listSnapshots(providers)
    });
  } catch (error) {
    res.status(500).json({
      error: 'Failed to run provider probe sweep.',
      detail: error instanceof Error ? error.message : 'unknown error'
    });
  }
});

app.post('/api/search', async (req, res) => {
  try {
    const result = await runSearch(req.body, accessStore);
    if (!result.ok) {
      res.status(400).json({ error: result.error });
      return;
    }
    res.json(result.value);
  } catch (error) {
    res.status(500).json({
      error: 'Search failed unexpectedly.',
      detail: error instanceof Error ? error.message : 'unknown error'
    });
  }
});

if (process.env.NODE_ENV === 'production') {
  app.use(express.static(clientDistPath));

  app.get('*', (req, res, next) => {
    if (req.path.startsWith('/api/')) {
      next();
      return;
    }
    res.sendFile(path.resolve(clientDistPath, 'index.html'));
  });
}

app.listen(PORT, () => {
  // eslint-disable-next-line no-console
  console.log(`[flightfinder-web] listening on http://localhost:${PORT}`);
});
