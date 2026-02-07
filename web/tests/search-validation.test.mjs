import test from 'node:test';
import assert from 'node:assert/strict';

import { validateSearchRequest } from '../server/lib/search-validator.mjs';

const baseOptions = {
  tripType: 'roundTrip',
  rankingMode: 'best',
  siteAccessMode: 'global',
  cabinClass: 'economy',
  preferredCurrency: 'USD',
  passengers: { adults: 1, children: 0, infants: 0 },
  bagPolicy: { checkedBagsPerTraveler: 0, carryOnIncluded: true },
  nonStopOnly: false,
  maxStops: null,
  flexibleDays: 0
};

test('rejects more than three routes', () => {
  const result = validateSearchRequest({
    routes: [
      { origin: 'SFO', destination: 'JFK', departureDate: '2026-04-01', returnDate: '2026-04-10' },
      { origin: 'LAX', destination: 'ORD', departureDate: '2026-04-01', returnDate: '2026-04-10' },
      { origin: 'SEA', destination: 'BOS', departureDate: '2026-04-01', returnDate: '2026-04-10' },
      { origin: 'SJC', destination: 'MIA', departureDate: '2026-04-01', returnDate: '2026-04-10' }
    ],
    options: baseOptions,
    enabledProviderKinds: ['airline']
  });

  assert.equal(result.ok, false);
  assert.match(result.error, /up to 3 routes/i);
});

test('requires return date for round trip routes', () => {
  const result = validateSearchRequest({
    routes: [{ origin: 'SFO', destination: 'PVG', departureDate: '2026-04-01', returnDate: '' }],
    options: baseOptions,
    enabledProviderKinds: ['airline', 'metasearch']
  });

  assert.equal(result.ok, false);
  assert.match(result.error, /return date/i);
});

test('normalizes valid payload', () => {
  const result = validateSearchRequest({
    routes: [{ origin: 'sfo', destination: 'pvg', departureDate: '2026-04-01', returnDate: '2026-04-18' }],
    options: {
      ...baseOptions,
      preferredCurrency: 'usd'
    },
    enabledProviderKinds: ['airline', 'metasearch']
  });

  assert.equal(result.ok, true);
  assert.equal(result.value.routes[0].origin, 'SFO');
  assert.equal(result.value.routes[0].destination, 'PVG');
  assert.equal(result.value.options.preferredCurrency, 'USD');
});
