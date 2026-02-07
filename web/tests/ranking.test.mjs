import test from 'node:test';
import assert from 'node:assert/strict';

import { rankOffers } from '../server/lib/ranking.mjs';

const sampleOffers = [
  {
    id: 'slow-cheap',
    status: 'priced',
    totalPrice: 420,
    durationMinutes: 980,
    stops: 1,
    chinaReachabilityScore: 0.75
  },
  {
    id: 'fast-expensive',
    status: 'priced',
    totalPrice: 780,
    durationMinutes: 720,
    stops: 0,
    chinaReachabilityScore: 0.8
  },
  {
    id: 'mid',
    status: 'priced',
    totalPrice: 560,
    durationMinutes: 790,
    stops: 1,
    chinaReachabilityScore: 0.95
  }
];

test('cheapest mode prioritizes lower totalPrice', () => {
  const ranked = rankOffers(sampleOffers, 'cheapest', 'global');
  assert.equal(ranked[0].id, 'slow-cheap');
});

test('fastest mode prioritizes lower durationMinutes', () => {
  const ranked = rankOffers(sampleOffers, 'fastest', 'global');
  assert.equal(ranked[0].id, 'fast-expensive');
});

test('china mode boosts reachability in best ranking', () => {
  const offers = [
    {
      id: 'better-reachability',
      status: 'priced',
      totalPrice: 599,
      durationMinutes: 760,
      stops: 1,
      chinaReachabilityScore: 0.96
    },
    {
      id: 'slightly-cheaper-poor-reachability',
      status: 'priced',
      totalPrice: 585,
      durationMinutes: 760,
      stops: 1,
      chinaReachabilityScore: 0.25
    }
  ];

  const ranked = rankOffers(offers, 'best', 'chinaAccessible');
  assert.equal(ranked[0].id, 'better-reachability');
});
