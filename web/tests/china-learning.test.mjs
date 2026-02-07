import test from 'node:test';
import assert from 'node:assert/strict';

import { createInMemoryAccessLearningStore } from '../server/lib/access-learning-store.mjs';

const provider = { id: 'trip-com', kind: 'chinaPortal' };

test('learning store updates reachability score over repeated probes', async () => {
  const store = createInMemoryAccessLearningStore();

  await store.recordProbeResult(provider, { reachable: true, latencyMs: 800, source: 'china-probe' });
  await store.recordProbeResult(provider, { reachable: true, latencyMs: 700, source: 'china-probe' });
  await store.recordProbeResult(provider, { reachable: false, latencyMs: 3000, source: 'china-probe' });

  const snapshot = store.getSnapshot(provider.id);

  assert.equal(snapshot.totalChecks, 3);
  assert.equal(snapshot.successfulChecks, 2);
  assert.equal(snapshot.failedChecks, 1);
  assert.ok(snapshot.reachabilityScore > 0.5);
  assert.ok(snapshot.reachabilityScore < 1);
  assert.match(snapshot.summary, /2\/3 reachable/i);
});

test('default snapshot returns seeded score by provider kind', () => {
  const store = createInMemoryAccessLearningStore();
  const snapshot = store.getSnapshot(provider.id, provider.kind);

  assert.equal(snapshot.totalChecks, 0);
  assert.ok(snapshot.reachabilityScore >= 0.65);
});
