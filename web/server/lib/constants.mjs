export const PROVIDER_KINDS = ['airline', 'metasearch', 'ota', 'chinaPortal'];
export const TRIP_TYPES = ['oneWay', 'roundTrip'];
export const RANKING_MODES = ['best', 'cheapest', 'fastest'];
export const SITE_ACCESS_MODES = ['global', 'chinaAccessible'];
export const CABIN_CLASSES = ['economy', 'premiumEconomy', 'business', 'first'];

export const DEFAULT_OPTIONS = {
  tripType: 'roundTrip',
  rankingMode: 'best',
  siteAccessMode: 'global',
  cabinClass: 'economy',
  preferredCurrency: 'USD',
  passengers: {
    adults: 1,
    children: 0,
    infants: 0
  },
  bagPolicy: {
    checkedBagsPerTraveler: 0,
    carryOnIncluded: true
  },
  nonStopOnly: false,
  maxStops: null,
  flexibleDays: 0
};

export const CHINA_MODE_MIN_REACHABILITY_SCORE = 0.45;
