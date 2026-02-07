import { seededNumber, stableHash } from './utils.mjs';

const CHINA_AIRPORTS = new Set(['PVG', 'PEK', 'PKX', 'FOC', 'CAN', 'SZX', 'CTU', 'XIY', 'HGH']);

const LOW_COST_AIRLINES = new Set(['spirit', 'frontier', 'allegiant', 'breeze', 'avelo', 'sun-country']);

function routeProfile(route) {
  const origin = route.origin;
  const destination = route.destination;

  const chinaInvolved = CHINA_AIRPORTS.has(origin) || CHINA_AIRPORTS.has(destination);
  const domesticUS = !chinaInvolved && /^[A-Z]{3}$/.test(origin) && /^[A-Z]{3}$/.test(destination);

  if (chinaInvolved) {
    return {
      category: 'transpacific',
      basePriceRange: [680, 1700],
      baseDurationRange: [700, 1220],
      defaultStopsRange: [0, 2]
    };
  }

  if (domesticUS) {
    return {
      category: 'domestic',
      basePriceRange: [110, 520],
      baseDurationRange: [85, 390],
      defaultStopsRange: [0, 1]
    };
  }

  return {
    category: 'international',
    basePriceRange: [380, 1250],
    baseDurationRange: [300, 980],
    defaultStopsRange: [0, 2]
  };
}

function providerPriceMultiplier(provider) {
  switch (provider.kind) {
    case 'airline':
      return LOW_COST_AIRLINES.has(provider.id) ? 0.9 : 1.0;
    case 'metasearch':
      return 0.95;
    case 'ota':
      return 0.92;
    case 'chinaPortal':
      return 0.93;
    default:
      return 1;
  }
}

function selectStatus(seed, siteAccessMode, reachabilityScore) {
  if (siteAccessMode === 'chinaAccessible' && reachabilityScore < 0.35) {
    return 'unavailable';
  }

  if (seed % 29 === 0) {
    return 'loginRequired';
  }

  if (seed % 23 === 0) {
    return 'actionRequired';
  }

  if (seed % 31 === 0) {
    return 'unavailable';
  }

  return 'priced';
}

export function estimateOffer({ provider, route, options, reachabilityScore }) {
  const profile = routeProfile(route);
  const seed = stableHash(`${provider.id}-${route.origin}-${route.destination}-${route.departureDate}-${route.returnDate}`);

  const basePrice = seededNumber(seed, profile.basePriceRange[0], profile.basePriceRange[1]);
  const baseDuration = seededNumber(seed >>> 3, profile.baseDurationRange[0], profile.baseDurationRange[1]);

  const stopsMin = options.nonStopOnly ? 0 : profile.defaultStopsRange[0];
  const stopsMax = options.nonStopOnly ? 0 : profile.defaultStopsRange[1];
  let stops = Math.round(seededNumber(seed >>> 5, stopsMin, stopsMax));
  if (options.maxStops !== null && options.maxStops !== undefined) {
    stops = Math.min(stops, Number(options.maxStops));
  }

  const priceMultiplier = providerPriceMultiplier(provider);
  const roundTripMultiplier = options.tripType === 'roundTrip' ? 1.72 : 1;
  const bagFee = options.bagPolicy.checkedBagsPerTraveler * (LOW_COST_AIRLINES.has(provider.id) ? 58 : 35);
  const passengerCount = options.passengers.adults + options.passengers.children + options.passengers.infants;
  const passengerMultiplier = Math.max(passengerCount, 1);

  const totalPrice = Math.round(basePrice * priceMultiplier * roundTripMultiplier * passengerMultiplier + bagFee * passengerCount);
  const durationMinutes = Math.round(baseDuration + stops * 75 + (options.flexibleDays > 0 ? 8 : 0));

  const status = selectStatus(seed, options.siteAccessMode, reachabilityScore);
  const loginRequired = status === 'loginRequired';

  return {
    totalPrice: status === 'priced' ? totalPrice : null,
    durationMinutes,
    stops,
    status,
    loginRequired,
    currencyCode: options.preferredCurrency,
    notes:
      status === 'priced'
        ? `Estimated from provider pattern and route profile (${profile.category}).`
        : status === 'loginRequired'
          ? 'Provider may require login/captcha before showing final fare.'
          : status === 'actionRequired'
            ? 'Provider returned a partial response; manual confirmation recommended.'
            : 'Provider currently appears unavailable for this route in current mode.'
  };
}
