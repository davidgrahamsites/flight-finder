import {
  CABIN_CLASSES,
  DEFAULT_OPTIONS,
  PROVIDER_KINDS,
  RANKING_MODES,
  SITE_ACCESS_MODES,
  TRIP_TYPES
} from './constants.mjs';
import { asArray, clamp, parseDate, toUpperIata } from './utils.mjs';

function normalizeRoute(route) {
  const origin = toUpperIata(route?.origin);
  const destination = toUpperIata(route?.destination);
  const departureDate = String(route?.departureDate ?? '').slice(0, 10);
  const returnDate = String(route?.returnDate ?? '').slice(0, 10);

  return {
    origin,
    destination,
    departureDate,
    returnDate
  };
}

function normalizeOptions(options) {
  const merged = {
    ...DEFAULT_OPTIONS,
    ...(options ?? {})
  };

  const tripType = TRIP_TYPES.includes(merged.tripType) ? merged.tripType : DEFAULT_OPTIONS.tripType;
  const rankingMode = RANKING_MODES.includes(merged.rankingMode) ? merged.rankingMode : DEFAULT_OPTIONS.rankingMode;
  const siteAccessMode = SITE_ACCESS_MODES.includes(merged.siteAccessMode)
    ? merged.siteAccessMode
    : DEFAULT_OPTIONS.siteAccessMode;
  const cabinClass = CABIN_CLASSES.includes(merged.cabinClass) ? merged.cabinClass : DEFAULT_OPTIONS.cabinClass;

  return {
    tripType,
    rankingMode,
    siteAccessMode,
    cabinClass,
    preferredCurrency: String(merged.preferredCurrency ?? 'USD').toUpperCase().slice(0, 3) || 'USD',
    passengers: {
      adults: clamp(Number(merged.passengers?.adults ?? 1), 1, 9),
      children: clamp(Number(merged.passengers?.children ?? 0), 0, 6),
      infants: clamp(Number(merged.passengers?.infants ?? 0), 0, 4)
    },
    bagPolicy: {
      checkedBagsPerTraveler: clamp(Number(merged.bagPolicy?.checkedBagsPerTraveler ?? 0), 0, 3),
      carryOnIncluded: Boolean(merged.bagPolicy?.carryOnIncluded ?? true)
    },
    nonStopOnly: Boolean(merged.nonStopOnly ?? false),
    maxStops:
      merged.maxStops === null || merged.maxStops === undefined
        ? null
        : clamp(Number(merged.maxStops), 0, 3),
    flexibleDays: clamp(Number(merged.flexibleDays ?? 0), 0, 7)
  };
}

export function validateSearchRequest(payload) {
  const routes = asArray(payload?.routes).map(normalizeRoute);

  if (!routes.length) {
    return { ok: false, error: 'At least one route is required.' };
  }

  if (routes.length > 3) {
    return { ok: false, error: 'You can search up to 3 routes per request.' };
  }

  const options = normalizeOptions(payload?.options);

  for (const route of routes) {
    if (route.origin.length !== 3 || route.destination.length !== 3) {
      return { ok: false, error: 'Each route requires valid 3-letter origin and destination airport codes.' };
    }

    if (route.origin === route.destination) {
      return { ok: false, error: 'Origin and destination cannot be the same.' };
    }

    const departure = parseDate(route.departureDate);
    if (!departure) {
      return { ok: false, error: 'Each route requires a valid departure date (YYYY-MM-DD).' };
    }

    if (options.tripType === 'roundTrip') {
      const ret = parseDate(route.returnDate);
      if (!ret) {
        return { ok: false, error: 'Round trip routes require a valid return date.' };
      }
      if (ret.getTime() < departure.getTime()) {
        return { ok: false, error: 'Return date must be on or after departure date.' };
      }
    }
  }

  const enabledProviderKinds = asArray(payload?.enabledProviderKinds)
    .map((kind) => String(kind))
    .filter((kind) => PROVIDER_KINDS.includes(kind));

  if (!enabledProviderKinds.length) {
    return { ok: false, error: 'At least one provider kind must be enabled.' };
  }

  return {
    ok: true,
    value: {
      routes,
      options,
      enabledProviderKinds
    }
  };
}
