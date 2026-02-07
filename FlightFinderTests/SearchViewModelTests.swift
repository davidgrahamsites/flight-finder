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
