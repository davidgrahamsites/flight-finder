import { useEffect, useMemo, useState } from 'react';

const providerKindLabels = {
  airline: 'Airline',
  metasearch: 'Metasearch',
  ota: 'OTA',
  chinaPortal: 'China Portal'
};

const rankingLabels = {
  best: 'Best',
  cheapest: 'Cheapest',
  fastest: 'Fastest'
};

function addDays(days) {
  const value = new Date();
  value.setDate(value.getDate() + days);
  return value.toISOString().slice(0, 10);
}

function createRoute(seedOrigin, seedDestination, departureOffset, returnOffset) {
  return {
    id: crypto.randomUUID(),
    origin: seedOrigin,
    destination: seedDestination,
    departureDate: addDays(departureOffset),
    returnDate: addDays(returnOffset)
  };
}

const defaultOptions = {
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

export default function App() {
  const [routes, setRoutes] = useState([
    createRoute('SFO', 'PVG', 30, 44),
    createRoute('LAX', 'JFK', 28, 35)
  ]);

  const [options, setOptions] = useState(defaultOptions);
  const [enabledKinds, setEnabledKinds] = useState({
    airline: true,
    metasearch: true,
    ota: true,
    chinaPortal: true
  });

  const [result, setResult] = useState(null);
  const [searchError, setSearchError] = useState('');
  const [isSearching, setIsSearching] = useState(false);

  const [chinaSnapshots, setChinaSnapshots] = useState([]);
  const [chinaSummary, setChinaSummary] = useState('');
  const [isProbing, setIsProbing] = useState(false);
  const [probeAllSites, setProbeAllSites] = useState(false);

  const enabledProviderKinds = useMemo(
    () => Object.entries(enabledKinds).filter(([, enabled]) => enabled).map(([kind]) => kind),
    [enabledKinds]
  );

  const bestFare = useMemo(() => {
    if (!result) {
      return 'N/A';
    }

    const prices = result.routes
      .flatMap((route) => route.offers)
      .filter((offer) => offer.status === 'priced' && typeof offer.totalPrice === 'number')
      .map((offer) => offer.totalPrice);

    if (!prices.length) {
      return 'N/A';
    }

    const lowest = Math.min(...prices);
    return `${result.options.preferredCurrency} ${lowest.toFixed(0)}`;
  }, [result]);

  async function runSearch() {
    setIsSearching(true);
    setSearchError('');

    try {
      const response = await fetch('/api/search', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          routes: routes.map(({ id, ...route }) => route),
          options,
          enabledProviderKinds
        })
      });

      const payload = await response.json();
      if (!response.ok) {
        throw new Error(payload.error ?? 'Search request failed.');
      }

      setResult(payload);
    } catch (error) {
      setSearchError(error instanceof Error ? error.message : 'Search failed.');
    } finally {
      setIsSearching(false);
    }
  }

  async function loadChinaSnapshots() {
    const query = new URLSearchParams({
      includeAllProviders: String(probeAllSites),
      kinds: enabledProviderKinds.join(',')
    });

    const response = await fetch(`/api/china/snapshots?${query.toString()}`);
    const payload = await response.json();

    if (!response.ok) {
      throw new Error(payload.error ?? 'Failed to load China snapshots.');
    }

    setChinaSnapshots(payload.snapshots ?? []);
    setChinaSummary(payload.summary ?? '');
  }

  async function runProbe() {
    setIsProbing(true);
    setSearchError('');

    try {
      const response = await fetch('/api/china/probe', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          includeAllProviders: probeAllSites,
          enabledProviderKinds
        })
      });

      const payload = await response.json();
      if (!response.ok) {
        throw new Error(payload.error ?? 'Probe failed.');
      }

      setChinaSnapshots(payload.snapshots ?? []);
      setChinaSummary(payload.summary ?? '');
    } catch (error) {
      setSearchError(error instanceof Error ? error.message : 'Probe failed.');
    } finally {
      setIsProbing(false);
    }
  }

  useEffect(() => {
    if (options.siteAccessMode === 'chinaAccessible') {
      loadChinaSnapshots().catch((error) => {
        setSearchError(error instanceof Error ? error.message : 'Failed to load China mode data.');
      });
    }
  }, [options.siteAccessMode, probeAllSites]);

  function updateRoute(routeId, key, value) {
    setRoutes((previous) => previous.map((route) => (route.id === routeId ? { ...route, [key]: value } : route)));
  }

  function addRoute() {
    if (routes.length >= 3) {
      return;
    }

    setRoutes((previous) => [...previous, createRoute('JFK', 'LAX', 21, 28)]);
  }

  function removeRoute(routeId) {
    if (routes.length <= 1) {
      return;
    }

    setRoutes((previous) => previous.filter((route) => route.id !== routeId));
  }

  function setPassenger(key, value) {
    setOptions((previous) => ({
      ...previous,
      passengers: {
        ...previous.passengers,
        [key]: Number(value)
      }
    }));
  }

  function setBagValue(value) {
    setOptions((previous) => ({
      ...previous,
      bagPolicy: {
        ...previous.bagPolicy,
        checkedBagsPerTraveler: Number(value)
      }
    }));
  }

  return (
    <div className="app-shell">
      <div className="poster-grid">
        <section className="panel left-panel">
          <div className="hero hero-blue">
            <div className="hero-shape circle" />
            <div className="hero-shape square" />
            <p className="hero-kicker">Agentic Flight Search</p>
            <h1>FlightFinder Web</h1>
            <p>
              Compare airline sites, metasearch engines, OTAs, and China portals in one run. Three routes at once,
              with China-access-aware ranking.
            </p>
          </div>

          <div className="card">
            <div className="card-head">
              <h2>Routes</h2>
              <button className="btn-outline" onClick={addRoute} disabled={routes.length >= 3 || isSearching}>
                Add Route
              </button>
            </div>
            <p className="subtle">Configured: {routes.length}/3</p>

            {routes.map((route, index) => (
              <div key={route.id} className="route-card">
                <div className="route-head">
                  <span>Route {index + 1}</span>
                  <button
                    className="btn-inline-danger"
                    onClick={() => removeRoute(route.id)}
                    disabled={routes.length <= 1 || isSearching}
                  >
                    Remove
                  </button>
                </div>
                <div className="field-grid two-col">
                  <label>
                    <span>Origin</span>
                    <input
                      value={route.origin}
                      maxLength={3}
                      onChange={(event) => updateRoute(route.id, 'origin', event.target.value.toUpperCase())}
                    />
                  </label>
                  <label>
                    <span>Destination</span>
                    <input
                      value={route.destination}
                      maxLength={3}
                      onChange={(event) => updateRoute(route.id, 'destination', event.target.value.toUpperCase())}
                    />
                  </label>
                </div>
                <div className="field-grid two-col">
                  <label>
                    <span>Departure</span>
                    <input
                      type="date"
                      value={route.departureDate}
                      onChange={(event) => updateRoute(route.id, 'departureDate', event.target.value)}
                    />
                  </label>
                  {options.tripType === 'roundTrip' && (
                    <label>
                      <span>Return</span>
                      <input
                        type="date"
                        value={route.returnDate}
                        min={route.departureDate}
                        onChange={(event) => updateRoute(route.id, 'returnDate', event.target.value)}
                      />
                    </label>
                  )}
                </div>
              </div>
            ))}
          </div>

          <div className="card card-blue-tint">
            <h2>Search Options</h2>

            <div className="field-grid two-col">
              <label>
                <span>Trip Type</span>
                <select
                  value={options.tripType}
                  onChange={(event) => setOptions((previous) => ({ ...previous, tripType: event.target.value }))}
                >
                  <option value="oneWay">One Way</option>
                  <option value="roundTrip">Round Trip</option>
                </select>
              </label>

              <label>
                <span>Rank By</span>
                <select
                  value={options.rankingMode}
                  onChange={(event) => setOptions((previous) => ({ ...previous, rankingMode: event.target.value }))}
                >
                  <option value="best">Best</option>
                  <option value="cheapest">Cheapest</option>
                  <option value="fastest">Fastest</option>
                </select>
              </label>
            </div>

            <div className="field-grid two-col">
              <label>
                <span>Site Access</span>
                <select
                  value={options.siteAccessMode}
                  onChange={(event) => setOptions((previous) => ({ ...previous, siteAccessMode: event.target.value }))}
                >
                  <option value="global">Global Mode</option>
                  <option value="chinaAccessible">China Accessible Mode</option>
                </select>
              </label>

              <label>
                <span>Cabin</span>
                <select
                  value={options.cabinClass}
                  onChange={(event) => setOptions((previous) => ({ ...previous, cabinClass: event.target.value }))}
                >
                  <option value="economy">Economy</option>
                  <option value="premiumEconomy">Premium Economy</option>
                  <option value="business">Business</option>
                  <option value="first">First</option>
                </select>
              </label>
            </div>

            <div className="field-grid three-col">
              <label>
                <span>Adults</span>
                <input
                  type="number"
                  min={1}
                  max={9}
                  value={options.passengers.adults}
                  onChange={(event) => setPassenger('adults', event.target.value)}
                />
              </label>
              <label>
                <span>Children</span>
                <input
                  type="number"
                  min={0}
                  max={6}
                  value={options.passengers.children}
                  onChange={(event) => setPassenger('children', event.target.value)}
                />
              </label>
              <label>
                <span>Infants</span>
                <input
                  type="number"
                  min={0}
                  max={4}
                  value={options.passengers.infants}
                  onChange={(event) => setPassenger('infants', event.target.value)}
                />
              </label>
            </div>

            <div className="field-grid three-col">
              <label>
                <span>Checked Bags</span>
                <input
                  type="number"
                  min={0}
                  max={3}
                  value={options.bagPolicy.checkedBagsPerTraveler}
                  onChange={(event) => setBagValue(event.target.value)}
                />
              </label>

              <label>
                <span>Max Stops</span>
                <select
                  value={options.maxStops === null ? 'any' : options.maxStops}
                  onChange={(event) =>
                    setOptions((previous) => ({
                      ...previous,
                      maxStops: event.target.value === 'any' ? null : Number(event.target.value)
                    }))
                  }
                >
                  <option value="any">Any</option>
                  <option value={0}>0</option>
                  <option value={1}>1</option>
                  <option value={2}>2</option>
                </select>
              </label>

              <label>
                <span>Flex Days</span>
                <input
                  type="number"
                  min={0}
                  max={7}
                  value={options.flexibleDays}
                  onChange={(event) =>
                    setOptions((previous) => ({ ...previous, flexibleDays: Number(event.target.value) }))
                  }
                />
              </label>
            </div>

            <div className="toggle-row">
              <label className="checkbox-label">
                <input
                  type="checkbox"
                  checked={options.nonStopOnly}
                  onChange={(event) => setOptions((previous) => ({ ...previous, nonStopOnly: event.target.checked }))}
                />
                Nonstop only
              </label>
              <label className="checkbox-label">
                <input
                  type="checkbox"
                  checked={options.bagPolicy.carryOnIncluded}
                  onChange={(event) =>
                    setOptions((previous) => ({
                      ...previous,
                      bagPolicy: {
                        ...previous.bagPolicy,
                        carryOnIncluded: event.target.checked
                      }
                    }))
                  }
                />
                Carry-on included
              </label>
            </div>
          </div>

          <div className="card card-green-tint">
            <h2>Provider Types</h2>
            <div className="chip-row">
              {Object.entries(providerKindLabels).map(([kind, label]) => (
                <button
                  key={kind}
                  className={`chip ${enabledKinds[kind] ? 'on' : 'off'}`}
                  onClick={() => setEnabledKinds((previous) => ({ ...previous, [kind]: !previous[kind] }))}
                  disabled={isSearching}
                >
                  {label}
                </button>
              ))}
            </div>
          </div>

          {options.siteAccessMode === 'chinaAccessible' && (
            <div className="card card-amber-tint">
              <div className="card-head">
                <h2>China Accessible Sites</h2>
                <button className="btn-outline" onClick={runProbe} disabled={isProbing || isSearching}>
                  {isProbing ? 'Probing...' : 'Probe Sites'}
                </button>
              </div>
              <label className="checkbox-label">
                <input
                  type="checkbox"
                  checked={probeAllSites}
                  onChange={(event) => setProbeAllSites(event.target.checked)}
                />
                Probe all sites (ignore current provider filter)
              </label>
              {chinaSummary && <p className="summary-banner">{chinaSummary}</p>}
              <div className="snapshot-list">
                {chinaSnapshots.slice(0, 10).map((snapshot) => (
                  <article key={snapshot.providerId} className="snapshot-row">
                    <div>
                      <strong>{snapshot.providerName}</strong>
                      <p>
                        {snapshot.providerKind} · {Math.round(snapshot.reachabilityScore * 100)}% reachable
                      </p>
                    </div>
                    <p>{snapshot.summary}</p>
                  </article>
                ))}
              </div>
            </div>
          )}

          <div className="action-card">
            <button className="btn-primary" onClick={runSearch} disabled={isSearching}>
              {isSearching ? 'Searching...' : `Find ${rankingLabels[options.rankingMode]} Flights`}
            </button>
            {searchError && <p className="error-text">{searchError}</p>}
          </div>
        </section>

        <section className="panel right-panel">
          <div className="hero hero-green">
            <div className="hero-shape circle" />
            <div className="hero-shape square" />
            <p className="hero-kicker">Results</p>
            <h2>{result ? 'Ranked offers ready' : 'Run a search to load offers'}</h2>
            <p>Open any result to continue booking directly on provider websites.</p>
          </div>

          <div className="stats-strip">
            <div className="stat-block stat-blue">
              <span>Mode</span>
              <strong>{rankingLabels[options.rankingMode]}</strong>
            </div>
            <div className="stat-block stat-amber">
              <span>Best Fare</span>
              <strong>{bestFare}</strong>
            </div>
            <div className="stat-block stat-green">
              <span>Priced</span>
              <strong>
                {result
                  ? result.routes
                      .flatMap((route) => route.offers)
                      .filter((offer) => offer.status === 'priced').length
                  : 0}
              </strong>
            </div>
          </div>

          {!result && (
            <div className="card">
              <h2>Awaiting Search</h2>
              <p className="subtle">
                Configure routes and options on the left. This web release runs local orchestration and gives direct
                deep links for each provider handoff.
              </p>
            </div>
          )}

          {result?.warnings?.length > 0 && (
            <div className="card card-amber-tint">
              <h2>Warnings</h2>
              {result.warnings.map((warning) => (
                <p key={warning} className="subtle">
                  {warning}
                </p>
              ))}
            </div>
          )}

          {result?.routes?.map((routeResult) => (
            <div key={routeResult.routeKey} className="card route-result">
              <div className="card-head">
                <h2>{routeResult.routeKey}</h2>
                <span className="route-price">{routeResult.bestPrice ? `${options.preferredCurrency} ${routeResult.bestPrice}` : 'No priced fares'}</span>
              </div>

              <div className="offer-list">
                {routeResult.offers.slice(0, 12).map((offer) => (
                  <article key={offer.id} className="offer-row">
                    <div>
                      <div className="offer-top">
                        <strong>{offer.providerName}</strong>
                        <span className={`status-badge status-${offer.status}`}>{offer.status}</span>
                      </div>
                      <p>
                        {offer.totalPrice ? `${offer.currencyCode} ${offer.totalPrice}` : 'Price not available'} · {offer.durationMinutes}m · {offer.stops} stop
                        {offer.stops === 1 ? '' : 's'}
                      </p>
                      <p className="subtle">China reachability: {Math.round((offer.chinaReachabilityScore ?? 0.5) * 100)}%</p>
                      <p className="subtle">{offer.notes}</p>
                    </div>
                    <a className="btn-outline" href={offer.deepLink} target="_blank" rel="noreferrer">
                      Open
                    </a>
                  </article>
                ))}
              </div>
            </div>
          ))}
        </section>
      </div>
    </div>
  );
}
