import { CHINA_MODE_MIN_REACHABILITY_SCORE } from './constants.mjs';
import { estimateOffer } from './offer-estimator.mjs';
import { buildProviderSearchUrl, getProvidersByKinds } from './providers.mjs';
import { rankOffers } from './ranking.mjs';
import { validateSearchRequest } from './search-validator.mjs';

function buildRouteKey(route) {
  return `${route.origin}-${route.destination}`;
}

function buildWarnings(candidateProviders, options) {
  const warnings = [];
  if (options.siteAccessMode === 'chinaAccessible' && candidateProviders.length === 0) {
    warnings.push('China mode filtered out all providers. Relax thresholds or run a probe sweep.');
  }
  if (candidateProviders.length < 3) {
    warnings.push('Only a small provider set is active. Enable more provider kinds for wider coverage.');
  }
  return warnings;
}

function toRouteResult(route, offers) {
  const pricedOffers = offers.filter((offer) => offer.status === 'priced' && typeof offer.totalPrice === 'number');

  return {
    routeKey: buildRouteKey(route),
    route,
    offers,
    bestPrice: pricedOffers.length ? Math.min(...pricedOffers.map((offer) => offer.totalPrice)) : null
  };
}

function summarizeSession(routeResults) {
  const allOffers = routeResults.flatMap((route) => route.offers);
  const pricedOffers = allOffers.filter((offer) => offer.status === 'priced');
  const averageLatency =
    allOffers.length === 0
      ? 0
      : Math.round(allOffers.reduce((sum, offer) => sum + (offer.providerLatencyMs ?? 0), 0) / allOffers.length);

  return {
    providerAttempts: allOffers.length,
    offersCollected: allOffers.length,
    pricedOffers: pricedOffers.length,
    routeCount: routeResults.length,
    averageProviderLatencyMs: averageLatency
  };
}

export async function runSearch(payload, accessStore) {
  const validated = validateSearchRequest(payload);
  if (!validated.ok) {
    return validated;
  }

  const request = validated.value;
  const enabledProviders = getProvidersByKinds(request.enabledProviderKinds);

  const withReachability = enabledProviders.map((provider) => {
    const snapshot = accessStore.getSnapshot(provider.id, provider.kind);
    return {
      ...provider,
      reachabilitySnapshot: snapshot
    };
  });

  let candidateProviders = withReachability;
  if (request.options.siteAccessMode === 'chinaAccessible') {
    candidateProviders = withReachability.filter(
      (provider) => provider.reachabilitySnapshot.reachabilityScore >= CHINA_MODE_MIN_REACHABILITY_SCORE
    );

    if (!candidateProviders.length) {
      candidateProviders = withReachability
        .sort((a, b) => b.reachabilitySnapshot.reachabilityScore - a.reachabilitySnapshot.reachabilityScore)
        .slice(0, 6);
    }
  }

  candidateProviders = candidateProviders.slice(0, 24);

  const routeResults = request.routes.map((route) => {
    const offers = candidateProviders.map((provider) => {
      const startedAt = Date.now();
      const estimation = estimateOffer({
        provider,
        route,
        options: request.options,
        reachabilityScore: provider.reachabilitySnapshot.reachabilityScore
      });

      const offer = {
        id: `${provider.id}-${route.origin}-${route.destination}-${route.departureDate}`,
        providerId: provider.id,
        providerName: provider.name,
        providerKind: provider.kind,
        routeKey: buildRouteKey(route),
        deepLink: buildProviderSearchUrl(provider, route, request.options),
        chinaReachabilityScore: provider.reachabilitySnapshot.reachabilityScore,
        providerLatencyMs: Date.now() - startedAt,
        ...estimation
      };

      return offer;
    });

    const ranked = rankOffers(offers, request.options.rankingMode, request.options.siteAccessMode);
    return toRouteResult(route, ranked);
  });

  return {
    ok: true,
    value: {
      generatedAt: new Date().toISOString(),
      options: request.options,
      enabledProviderKinds: request.enabledProviderKinds,
      warnings: buildWarnings(candidateProviders, request.options),
      routes: routeResults,
      observability: summarizeSession(routeResults)
    }
  };
}
