import { promises as fs } from 'node:fs';
import path from 'node:path';

import { average } from './utils.mjs';

const REACHABILITY_SEED_BY_KIND = {
  airline: 0.68,
  metasearch: 0.7,
  ota: 0.64,
  chinaPortal: 0.75
};

const PRIOR_WEIGHT = 4;

function defaultRecord(kind = 'metasearch') {
  const seededScore = REACHABILITY_SEED_BY_KIND[kind] ?? 0.68;
  return {
    totalChecks: 0,
    successfulChecks: 0,
    failedChecks: 0,
    averageLatencyMs: 0,
    seededScore,
    latencySamples: [],
    lastCheckedAt: null,
    lastSource: null
  };
}

function toSnapshot(providerId, kind, record) {
  const score =
    (record.successfulChecks + record.seededScore * PRIOR_WEIGHT) / (record.totalChecks + PRIOR_WEIGHT);

  return {
    providerId,
    totalChecks: record.totalChecks,
    successfulChecks: record.successfulChecks,
    failedChecks: record.failedChecks,
    averageLatencyMs: Math.round(record.averageLatencyMs || 0),
    reachabilityScore: Number(score.toFixed(3)),
    lastCheckedAt: record.lastCheckedAt,
    lastSource: record.lastSource,
    summary:
      record.totalChecks === 0
        ? `No checks yet, seeded at ${Math.round(record.seededScore * 100)}%`
        : `${record.successfulChecks}/${record.totalChecks} reachable, avg ${Math.round(record.averageLatencyMs || 0)}ms`
  };
}

function createCoreStore({ getState, setState }) {
  function ensureRecord(providerId, kind) {
    const state = getState();
    if (!state.providers[providerId]) {
      state.providers[providerId] = defaultRecord(kind);
      setState(state);
    }
    return state.providers[providerId];
  }

  return {
    async recordProbeResult(provider, result) {
      const providerId = provider.id;
      const kind = provider.kind;
      const state = getState();
      const record = state.providers[providerId] ?? defaultRecord(kind);

      record.totalChecks += 1;
      if (result.reachable) {
        record.successfulChecks += 1;
      } else {
        record.failedChecks += 1;
      }

      const latency = Number(result.latencyMs);
      if (Number.isFinite(latency) && latency >= 0) {
        record.latencySamples.push(latency);
        record.latencySamples = record.latencySamples.slice(-12);
        record.averageLatencyMs = average(record.latencySamples);
      }

      record.lastCheckedAt = new Date().toISOString();
      record.lastSource = result.source ?? 'unknown';

      state.providers[providerId] = record;
      setState(state);
    },

    getSnapshot(providerId, kind = 'metasearch') {
      const record = ensureRecord(providerId, kind);
      return toSnapshot(providerId, kind, record);
    },

    listSnapshots(providers) {
      return providers
        .map((provider) => ({
          providerId: provider.id,
          providerName: provider.name,
          providerKind: provider.kind,
          homeUrl: provider.homeUrl,
          ...this.getSnapshot(provider.id, provider.kind)
        }))
        .sort((a, b) => b.reachabilityScore - a.reachabilityScore);
    }
  };
}

export function createInMemoryAccessLearningStore(seedState) {
  const state = seedState ?? {
    version: 1,
    providers: {}
  };

  return createCoreStore({
    getState: () => state,
    setState: (next) => {
      Object.assign(state, next);
    }
  });
}

export async function createFileBackedAccessLearningStore(filePath) {
  const absolutePath = path.resolve(filePath);

  let state;
  try {
    const raw = await fs.readFile(absolutePath, 'utf8');
    state = JSON.parse(raw);
  } catch {
    state = { version: 1, providers: {} };
  }

  async function persist(nextState) {
    await fs.mkdir(path.dirname(absolutePath), { recursive: true });
    await fs.writeFile(absolutePath, JSON.stringify(nextState, null, 2));
  }

  const store = createCoreStore({
    getState: () => state,
    setState: (nextState) => {
      state = nextState;
    }
  });

  return {
    ...store,
    async recordProbeResult(provider, result) {
      await store.recordProbeResult(provider, result);
      await persist(state);
    }
  };
}
