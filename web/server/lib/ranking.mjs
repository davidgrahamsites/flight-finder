const STATUS_PENALTY = {
  priced: 0,
  actionRequired: 420,
  loginRequired: 540,
  unavailable: 1000
};

function safeNumber(value, fallback) {
  const n = Number(value);
  if (Number.isFinite(n)) {
    return n;
  }
  return fallback;
}

function basePenalty(offer) {
  return STATUS_PENALTY[offer.status] ?? 900;
}

function reachabilityBonus(offer, siteAccessMode) {
  const reachability = safeNumber(offer.chinaReachabilityScore, 0.55);
  if (siteAccessMode === 'chinaAccessible') {
    return reachability * 220;
  }
  return reachability * 40;
}

function bestScore(offer, siteAccessMode) {
  const price = safeNumber(offer.totalPrice, 9999);
  const duration = safeNumber(offer.durationMinutes, 2400);
  const stops = safeNumber(offer.stops, 3);

  return basePenalty(offer) + price * 0.9 + duration * 0.2 + stops * 55 - reachabilityBonus(offer, siteAccessMode);
}

function cheapestScore(offer, siteAccessMode) {
  const price = safeNumber(offer.totalPrice, 9999);
  const duration = safeNumber(offer.durationMinutes, 2400);

  return basePenalty(offer) + price * 1.0 + duration * 0.03 - reachabilityBonus(offer, siteAccessMode) * 0.4;
}

function fastestScore(offer, siteAccessMode) {
  const price = safeNumber(offer.totalPrice, 9999);
  const duration = safeNumber(offer.durationMinutes, 2400);

  return basePenalty(offer) + duration * 1.0 + price * 0.06 - reachabilityBonus(offer, siteAccessMode) * 0.25;
}

function scoreOffer(offer, rankingMode, siteAccessMode) {
  if (rankingMode === 'cheapest') {
    return cheapestScore(offer, siteAccessMode);
  }
  if (rankingMode === 'fastest') {
    return fastestScore(offer, siteAccessMode);
  }
  return bestScore(offer, siteAccessMode);
}

export function rankOffers(offers, rankingMode, siteAccessMode = 'global') {
  return [...offers]
    .map((offer) => ({
      ...offer,
      rankingScore: scoreOffer(offer, rankingMode, siteAccessMode)
    }))
    .sort((a, b) => a.rankingScore - b.rankingScore);
}
