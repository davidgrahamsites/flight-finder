import { PROVIDER_KINDS } from './constants.mjs';
import { attachAffiliateParams } from './affiliate.mjs';

function formatDate(value) {
  return String(value ?? '').slice(0, 10);
}

function buildGenericSearch(provider, route, options) {
  const url = new URL(provider.homeUrl);
  url.searchParams.set('origin', route.origin);
  url.searchParams.set('destination', route.destination);
  url.searchParams.set('departureDate', formatDate(route.departureDate));
  if (options.tripType === 'roundTrip') {
    url.searchParams.set('returnDate', formatDate(route.returnDate));
  }
  url.searchParams.set('tripType', options.tripType);
  url.searchParams.set('adults', String(options.passengers.adults));
  url.searchParams.set('children', String(options.passengers.children));
  url.searchParams.set('infants', String(options.passengers.infants));
  url.searchParams.set('cabinClass', options.cabinClass);
  url.searchParams.set('checkedBags', String(options.bagPolicy.checkedBagsPerTraveler));
  url.searchParams.set('currency', options.preferredCurrency);
  return url.toString();
}

function buildSkyscanner(route, options) {
  const depart = formatDate(route.departureDate).replace(/-/g, '');
  const ret = formatDate(route.returnDate).replace(/-/g, '');
  const suffix = options.tripType === 'roundTrip' && ret ? `/${ret}` : '';
  return `https://www.skyscanner.com/transport/flights/${route.origin.toLowerCase()}/${route.destination.toLowerCase()}/${depart}${suffix}/?adultsv2=${options.passengers.adults}&childrenv2=${options.passengers.children}&infants=${options.passengers.infants}&cabinclass=${options.cabinClass}&currency=${options.preferredCurrency}`;
}

function buildKayak(route, options) {
  const depart = formatDate(route.departureDate);
  const ret = formatDate(route.returnDate);
  const path = options.tripType === 'roundTrip' && ret
    ? `${route.origin}-${route.destination}/${depart}/${ret}`
    : `${route.origin}-${route.destination}/${depart}`;
  return `https://www.kayak.com/flights/${path}?sort=bestflight_a`;
}

function buildGoogleFlights(route, options) {
  const depart = formatDate(route.departureDate);
  const ret = formatDate(route.returnDate);
  const segments = options.tripType === 'roundTrip' && ret
    ? `${route.origin}.${route.destination}.${depart}*${route.destination}.${route.origin}.${ret}`
    : `${route.origin}.${route.destination}.${depart}`;
  return `https://www.google.com/travel/flights?hl=en#flt=${segments};c:${options.preferredCurrency};e:1`;
}

function buildTripDotCom(route, options) {
  const depart = formatDate(route.departureDate);
  const ret = formatDate(route.returnDate);
  const tripType = options.tripType === 'roundTrip' ? 'RT' : 'OW';
  return `https://us.trip.com/flights/${route.origin.toLowerCase()}-${route.destination.toLowerCase()}/tickets-${route.origin.toLowerCase()}-${route.destination.toLowerCase()}?dcity=${route.origin}&acity=${route.destination}&ddate=${depart}&rdate=${ret}&tripType=${tripType}&cabin=${options.cabinClass}`;
}

function buildMomondo(route, options) {
  const depart = formatDate(route.departureDate);
  const ret = formatDate(route.returnDate);
  const path = options.tripType === 'roundTrip' && ret
    ? `${route.origin}-${route.destination}/${depart}/${ret}`
    : `${route.origin}-${route.destination}/${depart}`;
  return `https://www.momondo.com/flight-search/${path}?sort=bestflight_a`;
}

function buildKiwi(route, options) {
  const depart = formatDate(route.departureDate);
  const ret = formatDate(route.returnDate);
  const params = new URLSearchParams({
    fly_from: route.origin,
    fly_to: route.destination,
    date_from: depart,
    date_to: depart,
    curr: options.preferredCurrency,
    adults: String(options.passengers.adults),
    children: String(options.passengers.children),
    infants: String(options.passengers.infants)
  });

  if (options.tripType === 'roundTrip' && ret) {
    params.set('return_from', ret);
    params.set('return_to', ret);
  }

  return `https://www.kiwi.com/en/search/results?${params.toString()}`;
}

export const PROVIDERS = [
  { id: 'aa', name: 'American Airlines', kind: 'airline', homeUrl: 'https://www.aa.com' },
  { id: 'delta', name: 'Delta Air Lines', kind: 'airline', homeUrl: 'https://www.delta.com' },
  { id: 'united', name: 'United Airlines', kind: 'airline', homeUrl: 'https://www.united.com' },
  { id: 'southwest', name: 'Southwest', kind: 'airline', homeUrl: 'https://www.southwest.com' },
  { id: 'alaska', name: 'Alaska Airlines', kind: 'airline', homeUrl: 'https://www.alaskaair.com' },
  { id: 'jetblue', name: 'JetBlue', kind: 'airline', homeUrl: 'https://www.jetblue.com' },
  { id: 'spirit', name: 'Spirit Airlines', kind: 'airline', homeUrl: 'https://www.spirit.com' },
  { id: 'frontier', name: 'Frontier Airlines', kind: 'airline', homeUrl: 'https://www.flyfrontier.com' },
  { id: 'allegiant', name: 'Allegiant Air', kind: 'airline', homeUrl: 'https://www.allegiantair.com' },
  { id: 'avelo', name: 'Avelo Airlines', kind: 'airline', homeUrl: 'https://www.aveloair.com' },
  { id: 'breeze', name: 'Breeze Airways', kind: 'airline', homeUrl: 'https://www.flybreeze.com' },
  { id: 'sun-country', name: 'Sun Country', kind: 'airline', homeUrl: 'https://www.suncountry.com' },
  { id: 'hawaiian', name: 'Hawaiian Airlines', kind: 'airline', homeUrl: 'https://www.hawaiianairlines.com' },
  { id: 'cape-air', name: 'Cape Air', kind: 'airline', homeUrl: 'https://www.capeair.com' },
  { id: 'jsx', name: 'JSX', kind: 'airline', homeUrl: 'https://www.jsx.com' },

  { id: 'google-flights', name: 'Google Flights', kind: 'metasearch', homeUrl: 'https://www.google.com/travel/flights', deepLinkBuilder: buildGoogleFlights },
  {
    id: 'kayak',
    name: 'KAYAK',
    kind: 'metasearch',
    homeUrl: 'https://www.kayak.com/flights',
    deepLinkBuilder: buildKayak,
    affiliateParams: [{ param: 'aid', env: 'AFFILIATE_KAYAK_AID' }]
  },
  {
    id: 'skyscanner',
    name: 'Skyscanner',
    kind: 'metasearch',
    homeUrl: 'https://www.skyscanner.com',
    deepLinkBuilder: buildSkyscanner,
    affiliateParams: [{ param: 'associateid', env: 'AFFILIATE_SKYSCANNER_ASSOCIATE_ID' }]
  },
  { id: 'momondo', name: 'momondo', kind: 'metasearch', homeUrl: 'https://www.momondo.com', deepLinkBuilder: buildMomondo },
  {
    id: 'kiwi',
    name: 'Kiwi.com',
    kind: 'metasearch',
    homeUrl: 'https://www.kiwi.com',
    deepLinkBuilder: buildKiwi,
    affiliateParams: [{ param: 'affilid', env: 'AFFILIATE_KIWI_AFFILID' }]
  },
  { id: 'wego', name: 'Wego', kind: 'metasearch', homeUrl: 'https://www.wego.com/airlines' },

  {
    id: 'expedia',
    name: 'Expedia',
    kind: 'ota',
    homeUrl: 'https://www.expedia.com/Flights',
    affiliateParams: [{ param: 'affcid', env: 'AFFILIATE_EXPEDIA_AFFCID' }]
  },
  { id: 'priceline', name: 'Priceline', kind: 'ota', homeUrl: 'https://www.priceline.com' },
  { id: 'orbitz', name: 'Orbitz', kind: 'ota', homeUrl: 'https://www.orbitz.com' },
  { id: 'travelocity', name: 'Travelocity', kind: 'ota', homeUrl: 'https://www.travelocity.com' },
  { id: 'cheapoair', name: 'CheapOair', kind: 'ota', homeUrl: 'https://www.cheapoair.com' },
  { id: 'onetravel', name: 'OneTravel', kind: 'ota', homeUrl: 'https://www.onetravel.com' },

  {
    id: 'trip-com',
    name: 'Trip.com',
    kind: 'chinaPortal',
    homeUrl: 'https://us.trip.com',
    deepLinkBuilder: buildTripDotCom,
    affiliateParams: [
      { param: 'Allianceid', env: 'AFFILIATE_TRIP_ALLIANCE_ID' },
      { param: 'sid', env: 'AFFILIATE_TRIP_SID' }
    ]
  },
  { id: 'ctrip', name: 'Ctrip', kind: 'chinaPortal', homeUrl: 'https://www.ctrip.com' },
  { id: 'qunar', name: 'Qunar', kind: 'chinaPortal', homeUrl: 'https://www.qunar.com' },
  { id: 'fliggy', name: 'Fliggy', kind: 'chinaPortal', homeUrl: 'https://www.fliggy.com' },

  { id: 'china-eastern', name: 'China Eastern', kind: 'chinaPortal', homeUrl: 'https://us.ceair.com' },
  { id: 'air-china', name: 'Air China', kind: 'chinaPortal', homeUrl: 'https://www.airchina.com.cn' },
  { id: 'china-southern', name: 'China Southern', kind: 'chinaPortal', homeUrl: 'https://www.csair.com' },
  { id: 'hainan', name: 'Hainan Airlines', kind: 'chinaPortal', homeUrl: 'https://www.hnair.com' },
  { id: 'cathay', name: 'Cathay Pacific', kind: 'chinaPortal', homeUrl: 'https://www.cathaypacific.com' },
  { id: 'korean-air', name: 'Korean Air', kind: 'chinaPortal', homeUrl: 'https://www.koreanair.com' },
  { id: 'eva', name: 'EVA Air', kind: 'chinaPortal', homeUrl: 'https://www.evaair.com' },
  { id: 'ana', name: 'ANA', kind: 'chinaPortal', homeUrl: 'https://www.ana.co.jp' },
  { id: 'japan-airlines', name: 'Japan Airlines', kind: 'chinaPortal', homeUrl: 'https://www.jal.co.jp' },
  { id: 'emirates', name: 'Emirates', kind: 'chinaPortal', homeUrl: 'https://www.emirates.com' }
];

export function getProvidersByKinds(enabledKinds) {
  const kinds = Array.isArray(enabledKinds) ? enabledKinds.filter((kind) => PROVIDER_KINDS.includes(kind)) : [];
  if (!kinds.length) {
    return [];
  }
  return PROVIDERS.filter((provider) => kinds.includes(provider.kind));
}

export function buildProviderSearchUrl(provider, route, options) {
  let url;
  if (typeof provider.deepLinkBuilder === 'function') {
    url = provider.deepLinkBuilder(route, options);
  } else {
    url = buildGenericSearch(provider, route, options);
  }
  return attachAffiliateParams(url, provider);
}
