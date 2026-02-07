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
