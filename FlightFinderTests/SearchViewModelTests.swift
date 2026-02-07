import Foundation
import Testing
@testable import FlightFinder

@MainActor
struct SearchViewModelTests {
    @Test("Applying USA-China preset sets China mode and expected route")
    func applyUSChinaPreset() {
        let store = InMemorySearchPreferencesStore()
        let viewModel = SearchViewModel(
            coordinator: FlightSearchCoordinator(providers: [], httpClient: ProviderHTTPClient(), ranking: OfferRankingService(), normalizer: CurrencyNormalizer()),
            preferencesStore: store
        )

        viewModel.applyPreset(.usaToShanghai)

        #expect(viewModel.options.siteAccessMode == .chinaAccessible)
        #expect(viewModel.options.tripType == .roundTrip)
        #expect(viewModel.routes.count == 1)
        #expect(viewModel.routes[0].origin == "SFO")
        #expect(viewModel.routes[0].destination == "PVG")
    }

    @Test("Saved defaults are restored when view model is recreated")
    func restoreSavedDefaults() {
        let store = InMemorySearchPreferencesStore()

        do {
            let first = SearchViewModel(
                coordinator: FlightSearchCoordinator(providers: [], httpClient: ProviderHTTPClient(), ranking: OfferRankingService(), normalizer: CurrencyNormalizer()),
                preferencesStore: store
            )
            first.routes = [
                RouteInputState(origin: "JFK", destination: "LAX"),
                RouteInputState(origin: "SFO", destination: "PVG")
            ]
            first.options.siteAccessMode = .chinaAccessible
            first.options.tripType = .oneWay
            first.enabledKinds = [.metasearch, .chinaPortal]
            first.saveDefaults()
        }

        let second = SearchViewModel(
            coordinator: FlightSearchCoordinator(providers: [], httpClient: ProviderHTTPClient(), ranking: OfferRankingService(), normalizer: CurrencyNormalizer()),
            preferencesStore: store
        )

        #expect(second.routes.count == 2)
        #expect(second.routes[0].origin == "JFK")
        #expect(second.routes[1].destination == "PVG")
        #expect(second.options.siteAccessMode == .chinaAccessible)
        #expect(second.options.tripType == .oneWay)
        #expect(second.enabledKinds == [.metasearch, .chinaPortal])
    }

    @Test("Watchlist entries are persisted and restored")
    func restoreSavedWatchlist() {
        let store = InMemorySearchPreferencesStore()
        let now = Date(timeIntervalSince1970: 1_700_100_000)

        do {
            let first = SearchViewModel(
                coordinator: FlightSearchCoordinator(providers: [], httpClient: ProviderHTTPClient(), ranking: OfferRankingService(), normalizer: CurrencyNormalizer()),
                preferencesStore: store
            )
            first.watchlist = [
                WatchCandidate(
                    routeKey: "SEA-PVG-2026-04-10",
                    providerID: "trip",
                    providerName: "Trip.com",
                    deepLink: URL(string: "https://trip.com")!,
                    currencyCode: "USD",
                    observedPrice: 1_000,
                    targetPrice: 900,
                    lastSeenAt: now
                )
            ]
            first.saveDefaults()
        }

        let second = SearchViewModel(
            coordinator: FlightSearchCoordinator(providers: [], httpClient: ProviderHTTPClient(), ranking: OfferRankingService(), normalizer: CurrencyNormalizer()),
            preferencesStore: store
        )

        #expect(second.watchlist.count == 1)
        #expect(second.watchlist[0].providerID == "trip")
        #expect(second.watchlist[0].targetPrice == 900)
    }

    @Test("Watchlist merge deduplicates by route+provider and keeps stronger target")
    func mergeWatchCandidates() {
        let store = InMemorySearchPreferencesStore()
        let viewModel = SearchViewModel(
            coordinator: FlightSearchCoordinator(providers: [], httpClient: ProviderHTTPClient(), ranking: OfferRankingService(), normalizer: CurrencyNormalizer()),
            preferencesStore: store
        )

        let original = WatchCandidate(
            routeKey: "SFO-PVG-2026-04-11",
            providerID: "trip",
            providerName: "Trip.com",
            deepLink: URL(string: "https://trip.com")!,
            currencyCode: "USD",
            observedPrice: 1_050,
            targetPrice: 950,
            lastSeenAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        viewModel.watchlist = [original]

        let updated = WatchCandidate(
            routeKey: "SFO-PVG-2026-04-11",
            providerID: "trip",
            providerName: "Trip.com",
            deepLink: URL(string: "https://trip.com/new")!,
            currencyCode: "USD",
            observedPrice: 1_000,
            targetPrice: 910,
            lastSeenAt: Date(timeIntervalSince1970: 1_700_200_000)
        )
        let newCandidate = WatchCandidate(
            routeKey: "LAX-PVG-2026-04-12",
            providerID: "kayak",
            providerName: "KAYAK",
            deepLink: URL(string: "https://kayak.com")!,
            currencyCode: "USD",
            observedPrice: 1_020,
            targetPrice: 940,
            lastSeenAt: Date(timeIntervalSince1970: 1_700_200_001)
        )

        let changed = viewModel.mergeWatchCandidates([updated, newCandidate])

        #expect(changed == 2)
        #expect(viewModel.watchlist.count == 2)

        let mergedTrip = viewModel.watchlist.first { $0.providerID == "trip" }
        #expect(mergedTrip?.targetPrice == 910)
        #expect(mergedTrip?.observedPrice == 1_000)
        #expect(mergedTrip?.deepLink == URL(string: "https://trip.com/new")!)
    }

    @Test("Watchlist alert is generated when matching priced offer meets target")
    func watchlistAlertOnTargetHit() {
        let store = InMemorySearchPreferencesStore()
        let viewModel = SearchViewModel(
            coordinator: FlightSearchCoordinator(providers: [], httpClient: ProviderHTTPClient(), ranking: OfferRankingService(), normalizer: CurrencyNormalizer()),
            preferencesStore: store
        )

        let routeDate = Date(timeIntervalSince1970: 1_700_300_000)
        let observedAt = Date(timeIntervalSince1970: 1_700_350_000)
        let route = RouteRequest(origin: "SFO", destination: "PVG", departureDate: routeDate)

        let watched = WatchCandidate(
            routeKey: route.routeKey,
            providerID: "trip",
            providerName: "Trip.com",
            deepLink: URL(string: "https://trip.com/old")!,
            currencyCode: "USD",
            observedPrice: 1_000,
            targetPrice: 900,
            lastSeenAt: routeDate
        )
        viewModel.watchlist = [watched]

        let matchedOffer = FlightOffer(
            providerID: "trip",
            providerName: "Trip.com",
            providerKind: .chinaPortal,
            route: route,
            totalPrice: 880,
            currencyCode: "USD",
            departureTime: "10:00",
            arrivalTime: "15:00",
            durationText: "13h",
            stops: 1,
            deepLink: URL(string: "https://trip.com/new")!,
            status: .priced,
            confidence: 0.9,
            notes: "",
            collectedAt: observedAt,
            baggageIncludedEstimate: true
        )

        let routeResult = RouteSearchResult(
            route: route,
            offers: [matchedOffer],
            startedAt: observedAt,
            endedAt: observedAt
        )
        let session = SearchSessionResult(
            routes: [routeResult],
            warnings: [],
            generatedAt: observedAt,
            observability: .zero,
            watchCandidates: []
        )

        viewModel.processSessionResult(session, observedAt: observedAt)

        #expect(viewModel.watchlistAlerts.count == 1)
        let alert = viewModel.watchlistAlerts[0]
        #expect(alert.candidateID == watched.id)
        #expect(alert.routeKey == route.routeKey)
        #expect(alert.providerName == "Trip.com")
        #expect(alert.observedPrice == 880)
        #expect(alert.targetPrice == 900)
        #expect(alert.currencyCode == "USD")
        #expect(alert.deepLink == URL(string: "https://trip.com/new")!)

        #expect(viewModel.watchlist.count == 1)
        #expect(viewModel.watchlist[0].observedPrice == 880)
        #expect(viewModel.watchlist[0].lastSeenAt == observedAt)
        #expect(viewModel.watchlist[0].deepLink == URL(string: "https://trip.com/new")!)
    }

    @Test("Watchlist target miss updates observed price but does not create alert")
    func watchlistMissUpdatesWithoutAlert() {
        let store = InMemorySearchPreferencesStore()
        let viewModel = SearchViewModel(
            coordinator: FlightSearchCoordinator(providers: [], httpClient: ProviderHTTPClient(), ranking: OfferRankingService(), normalizer: CurrencyNormalizer()),
            preferencesStore: store
        )

        let routeDate = Date(timeIntervalSince1970: 1_700_310_000)
        let observedAt = Date(timeIntervalSince1970: 1_700_360_000)
        let route = RouteRequest(origin: "LAX", destination: "PVG", departureDate: routeDate)

        viewModel.watchlist = [
            WatchCandidate(
                routeKey: route.routeKey,
                providerID: "kayak",
                providerName: "KAYAK",
                deepLink: URL(string: "https://kayak.com/old")!,
                currencyCode: "USD",
                observedPrice: 1_050,
                targetPrice: 900,
                lastSeenAt: routeDate
            )
        ]

        let offer = FlightOffer(
            providerID: "kayak",
            providerName: "KAYAK",
            providerKind: .metasearch,
            route: route,
            totalPrice: 960,
            currencyCode: "USD",
            departureTime: "11:00",
            arrivalTime: "16:00",
            durationText: "12h",
            stops: 1,
            deepLink: URL(string: "https://kayak.com/new")!,
            status: .priced,
            confidence: 0.8,
            notes: "",
            collectedAt: observedAt,
            baggageIncludedEstimate: true
        )
        let session = SearchSessionResult(
            routes: [
                RouteSearchResult(
                    route: route,
                    offers: [offer],
                    startedAt: observedAt,
                    endedAt: observedAt
                )
            ],
            warnings: [],
            generatedAt: observedAt,
            observability: .zero,
            watchCandidates: []
        )

        viewModel.processSessionResult(session, observedAt: observedAt)

        #expect(viewModel.watchlistAlerts.isEmpty)
        #expect(viewModel.watchlist.count == 1)
        #expect(viewModel.watchlist[0].observedPrice == 960)
        #expect(viewModel.watchlist[0].lastSeenAt == observedAt)
        #expect(viewModel.watchlist[0].deepLink == URL(string: "https://kayak.com/new")!)
    }

    @Test("Dismiss watchlist alert removes only requested alert")
    func dismissWatchlistAlert() {
        let store = InMemorySearchPreferencesStore()
        let viewModel = SearchViewModel(
            coordinator: FlightSearchCoordinator(providers: [], httpClient: ProviderHTTPClient(), ranking: OfferRankingService(), normalizer: CurrencyNormalizer()),
            preferencesStore: store
        )

        let first = WatchlistAlert(
            candidateID: UUID(),
            routeKey: "SFO-PVG-2026-04-01",
            providerID: "trip",
            providerName: "Trip.com",
            observedPrice: 880,
            targetPrice: 900,
            currencyCode: "USD",
            deepLink: URL(string: "https://trip.com")!,
            hitAt: Date(timeIntervalSince1970: 1_700_000_100)
        )
        let second = WatchlistAlert(
            candidateID: UUID(),
            routeKey: "LAX-PVG-2026-04-02",
            providerID: "kayak",
            providerName: "KAYAK",
            observedPrice: 890,
            targetPrice: 910,
            currencyCode: "USD",
            deepLink: URL(string: "https://kayak.com")!,
            hitAt: Date(timeIntervalSince1970: 1_700_000_200)
        )

        viewModel.watchlistAlerts = [first, second]
        viewModel.dismissWatchlistAlert(id: first.id)

        #expect(viewModel.watchlistAlerts.count == 1)
        #expect(viewModel.watchlistAlerts[0].id == second.id)
    }
}

private final class InMemorySearchPreferencesStore: SearchPreferencesStore {
    var config: SavedSearchConfig?

    func load() -> SavedSearchConfig? {
        config
    }

    func save(_ config: SavedSearchConfig) {
        self.config = config
    }
}
