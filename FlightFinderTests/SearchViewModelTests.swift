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

    @Test("Watchlist recheck plan uses preferred trip type and enforces three-route cap")
    func watchlistRecheckPlanPreferredTripType() {
        let store = InMemorySearchPreferencesStore()
        let viewModel = SearchViewModel(
            coordinator: FlightSearchCoordinator(providers: [], httpClient: ProviderHTTPClient(), ranking: OfferRankingService(), normalizer: CurrencyNormalizer()),
            preferencesStore: store
        )

        viewModel.options.tripType = .oneWay
        let base = Date(timeIntervalSince1970: 1_700_400_000)

        viewModel.watchlist = [
            WatchCandidate(
                routeKey: "JFK-PVG-2026-04-10",
                providerID: "trip",
                providerName: "Trip.com",
                deepLink: URL(string: "https://trip.com")!,
                currencyCode: "USD",
                observedPrice: 980,
                targetPrice: 900,
                lastSeenAt: base.addingTimeInterval(50),
                origin: "JFK",
                destination: "PVG",
                departureDate: base,
                returnDate: base.addingTimeInterval(86_400 * 7)
            ),
            WatchCandidate(
                routeKey: "SFO-PVG-2026-04-10",
                providerID: "kayak",
                providerName: "KAYAK",
                deepLink: URL(string: "https://kayak.com")!,
                currencyCode: "USD",
                observedPrice: 1_050,
                targetPrice: 930,
                lastSeenAt: base.addingTimeInterval(40),
                origin: "SFO",
                destination: "PVG",
                departureDate: base
            ),
            WatchCandidate(
                routeKey: "SEA-PVG-2026-04-11",
                providerID: "trip",
                providerName: "Trip.com",
                deepLink: URL(string: "https://trip.com/2")!,
                currencyCode: "USD",
                observedPrice: 1_040,
                targetPrice: 920,
                lastSeenAt: base.addingTimeInterval(30),
                origin: "SEA",
                destination: "PVG",
                departureDate: base.addingTimeInterval(86_400)
            ),
            WatchCandidate(
                routeKey: "LAX-PVG-2026-04-12",
                providerID: "trip",
                providerName: "Trip.com",
                deepLink: URL(string: "https://trip.com/3")!,
                currencyCode: "USD",
                observedPrice: 1_030,
                targetPrice: 910,
                lastSeenAt: base.addingTimeInterval(20),
                origin: "LAX",
                destination: "PVG",
                departureDate: base.addingTimeInterval(86_400 * 2)
            ),
            WatchCandidate(
                routeKey: "BOS-PVG-2026-04-13",
                providerID: "trip",
                providerName: "Trip.com",
                deepLink: URL(string: "https://trip.com/4")!,
                currencyCode: "USD",
                observedPrice: 1_020,
                targetPrice: 900,
                lastSeenAt: base.addingTimeInterval(10),
                origin: "BOS",
                destination: "PVG",
                departureDate: base.addingTimeInterval(86_400 * 3)
            )
        ]

        let plan = viewModel.makeWatchlistRecheckPlan()

        #expect(plan != nil)
        #expect(plan?.tripType == .oneWay)
        #expect(plan?.routes.count == 3)
        #expect(plan?.skippedByTripType == 1)
        #expect(plan?.truncatedRoutes == 1)
        #expect(plan?.routes[0].origin == "SFO")
        #expect(plan?.routes[1].origin == "SEA")
        #expect(plan?.routes[2].origin == "LAX")
    }

    @Test("Watchlist recheck plan falls back when preferred trip type has no candidates")
    func watchlistRecheckPlanFallbackTripType() {
        let store = InMemorySearchPreferencesStore()
        let viewModel = SearchViewModel(
            coordinator: FlightSearchCoordinator(providers: [], httpClient: ProviderHTTPClient(), ranking: OfferRankingService(), normalizer: CurrencyNormalizer()),
            preferencesStore: store
        )

        viewModel.options.tripType = .roundTrip
        let base = Date(timeIntervalSince1970: 1_700_500_000)
        viewModel.watchlist = [
            WatchCandidate(
                routeKey: "SFO-PVG-2026-05-01",
                providerID: "trip",
                providerName: "Trip.com",
                deepLink: URL(string: "https://trip.com")!,
                currencyCode: "USD",
                observedPrice: 1_200,
                targetPrice: 1_100,
                lastSeenAt: base.addingTimeInterval(30),
                origin: "SFO",
                destination: "PVG",
                departureDate: base
            ),
            WatchCandidate(
                routeKey: "JFK-PVG-2026-05-02",
                providerID: "kayak",
                providerName: "KAYAK",
                deepLink: URL(string: "https://kayak.com")!,
                currencyCode: "USD",
                observedPrice: 1_180,
                targetPrice: 1_070,
                lastSeenAt: base.addingTimeInterval(20),
                origin: "JFK",
                destination: "PVG",
                departureDate: base.addingTimeInterval(86_400)
            )
        ]

        let plan = viewModel.makeWatchlistRecheckPlan()

        #expect(plan != nil)
        #expect(plan?.tripType == .oneWay)
        #expect(plan?.routes.count == 2)
        #expect(plan?.skippedByTripType == 0)
        #expect(plan?.truncatedRoutes == 0)
    }

    @Test("Running watchlist recheck with empty watchlist reports summary")
    func runWatchlistRecheckEmpty() async {
        let store = InMemorySearchPreferencesStore()
        let viewModel = SearchViewModel(
            coordinator: FlightSearchCoordinator(providers: [], httpClient: ProviderHTTPClient(), ranking: OfferRankingService(), normalizer: CurrencyNormalizer()),
            preferencesStore: store
        )

        viewModel.watchlist = []
        await viewModel.runWatchlistRecheck()

        #expect(viewModel.watchlistRecheckSummary == "Watchlist is empty.")
        #expect(viewModel.isSearching == false)
    }

    @Test("Auto recheck preferences are persisted and restored")
    func autoRecheckPreferencesPersist() {
        let store = InMemorySearchPreferencesStore()

        do {
            let first = SearchViewModel(
                coordinator: FlightSearchCoordinator(providers: [], httpClient: ProviderHTTPClient(), ranking: OfferRankingService(), normalizer: CurrencyNormalizer()),
                preferencesStore: store
            )
            first.setAutoWatchlistRecheckEnabled(true)
            first.setAutoWatchlistRecheckIntervalMinutes(45)
            first.setWatchlistNotificationsEnabled(false)
            first.saveDefaults()
        }

        let second = SearchViewModel(
            coordinator: FlightSearchCoordinator(providers: [], httpClient: ProviderHTTPClient(), ranking: OfferRankingService(), normalizer: CurrencyNormalizer()),
            preferencesStore: store
        )

        #expect(second.autoWatchlistRecheckEnabled == true)
        #expect(second.autoWatchlistRecheckIntervalMinutes == 45)
        #expect(second.watchlistNotificationsEnabled == false)
    }

    @Test("Auto recheck interval is clamped to supported range")
    func autoRecheckIntervalClamped() {
        let store = InMemorySearchPreferencesStore()
        let viewModel = SearchViewModel(
            coordinator: FlightSearchCoordinator(providers: [], httpClient: ProviderHTTPClient(), ranking: OfferRankingService(), normalizer: CurrencyNormalizer()),
            preferencesStore: store
        )

        viewModel.setAutoWatchlistRecheckIntervalMinutes(1)
        #expect(viewModel.autoWatchlistRecheckIntervalMinutes == 5)

        viewModel.setAutoWatchlistRecheckIntervalMinutes(999)
        #expect(viewModel.autoWatchlistRecheckIntervalMinutes == 180)
    }

    @Test("Target hit notifications are emitted only for newly inserted alerts when enabled")
    func notificationsOnlyForNewAlerts() {
        let store = InMemorySearchPreferencesStore()
        let notificationClient = RecordingWatchlistNotificationClient()
        let viewModel = SearchViewModel(
            coordinator: FlightSearchCoordinator(providers: [], httpClient: ProviderHTTPClient(), ranking: OfferRankingService(), normalizer: CurrencyNormalizer()),
            preferencesStore: store,
            notificationClient: notificationClient
        )

        let routeDate = Date(timeIntervalSince1970: 1_700_800_000)
        let observedAt = Date(timeIntervalSince1970: 1_700_810_000)
        let route = RouteRequest(origin: "SFO", destination: "PVG", departureDate: routeDate)
        viewModel.watchlist = [
            WatchCandidate(
                routeKey: route.routeKey,
                providerID: "trip",
                providerName: "Trip.com",
                deepLink: URL(string: "https://trip.com")!,
                currencyCode: "USD",
                observedPrice: 1_000,
                targetPrice: 900,
                lastSeenAt: routeDate,
                origin: route.origin,
                destination: route.destination,
                departureDate: route.departureDate
            )
        ]

        let offer = FlightOffer(
            providerID: "trip",
            providerName: "Trip.com",
            providerKind: .chinaPortal,
            route: route,
            totalPrice: 880,
            currencyCode: "USD",
            departureTime: nil,
            arrivalTime: nil,
            durationText: nil,
            stops: 1,
            deepLink: URL(string: "https://trip.com/deal")!,
            status: .priced,
            confidence: 0.9,
            notes: "",
            collectedAt: observedAt,
            baggageIncludedEstimate: true
        )
        let session = SearchSessionResult(
            routes: [RouteSearchResult(route: route, offers: [offer], startedAt: observedAt, endedAt: observedAt)],
            warnings: [],
            generatedAt: observedAt,
            observability: .zero,
            watchCandidates: []
        )

        viewModel.setWatchlistNotificationsEnabled(true)
        viewModel.processSessionResult(session, observedAt: observedAt)
        #expect(notificationClient.capturedAlerts.count == 1)

        viewModel.processSessionResult(session, observedAt: observedAt)
        #expect(notificationClient.capturedAlerts.count == 1)

        viewModel.setWatchlistNotificationsEnabled(false)
        let later = observedAt.addingTimeInterval(120)
        viewModel.processSessionResult(session, observedAt: later)
        #expect(notificationClient.capturedAlerts.count == 1)
    }

    @Test("China accessibility sweep updates summary and snapshots for enabled kinds")
    func chinaAccessibilitySweepUpdatesViewModelState() async {
        let store = InMemorySearchPreferencesStore()
        let reachableURL = URL(string: "https://reachable.example")!
        let blockedURL = URL(string: "https://blocked.example")!

        let providers = [
            makeProvider(
                id: "reachable-provider",
                name: "Reachable Provider",
                homepage: reachableURL,
                kind: .chinaPortal,
                seedReachability: 0.9
            ),
            makeProvider(
                id: "blocked-provider",
                name: "Blocked Provider",
                homepage: blockedURL,
                kind: .metasearch,
                seedReachability: 0.1
            )
        ]

        let planner = ChinaAccessibilityPlanner(
            learningStore: ProviderAccessLearningStore(filename: "provider_access_stats_test_\(UUID().uuidString).json"),
            reachabilityProber: StubReachabilityProber(
                resultsByURL: [
                    reachableURL: true,
                    blockedURL: false
                ]
            )
        )
        let coordinator = FlightSearchCoordinator(
            providers: providers,
            httpClient: ProviderHTTPClient(),
            ranking: OfferRankingService(),
            normalizer: CurrencyNormalizer(),
            chinaPlanner: planner
        )
        let viewModel = SearchViewModel(
            coordinator: coordinator,
            preferencesStore: store
        )

        viewModel.enabledKinds = [.chinaPortal]
        await viewModel.runChinaAccessibilitySweep()

        #expect(viewModel.isRunningChinaAccessibilitySweep == false)
        #expect(viewModel.chinaAccessSnapshots.count == 1)
        #expect(viewModel.chinaAccessSnapshots.first?.providerID == "reachable-provider")
        #expect(viewModel.chinaAccessSummary?.contains("Probed 1 provider") == true)
        #expect(viewModel.chinaAccessSummary?.contains("1 reachable") == true)
        #expect(viewModel.chinaAccessSummary?.contains("0 blocked") == true)
    }

    @Test("China accessibility sweep can include full provider catalog")
    func chinaAccessibilitySweepIncludesAllProvidersWhenEnabled() async {
        let store = InMemorySearchPreferencesStore()
        let reachableURL = URL(string: "https://reachable.example")!
        let blockedURL = URL(string: "https://blocked.example")!

        let providers = [
            makeProvider(
                id: "reachable-provider",
                name: "Reachable Provider",
                homepage: reachableURL,
                kind: .chinaPortal,
                seedReachability: 0.9
            ),
            makeProvider(
                id: "blocked-provider",
                name: "Blocked Provider",
                homepage: blockedURL,
                kind: .metasearch,
                seedReachability: 0.1
            )
        ]

        let planner = ChinaAccessibilityPlanner(
            learningStore: ProviderAccessLearningStore(filename: "provider_access_stats_test_\(UUID().uuidString).json"),
            reachabilityProber: StubReachabilityProber(
                resultsByURL: [
                    reachableURL: true,
                    blockedURL: false
                ]
            )
        )
        let coordinator = FlightSearchCoordinator(
            providers: providers,
            httpClient: ProviderHTTPClient(),
            ranking: OfferRankingService(),
            normalizer: CurrencyNormalizer(),
            chinaPlanner: planner
        )
        let viewModel = SearchViewModel(
            coordinator: coordinator,
            preferencesStore: store
        )

        viewModel.enabledKinds = [.chinaPortal]
        viewModel.setChinaSweepIncludesAllProviders(true)
        await viewModel.runChinaAccessibilitySweep()

        #expect(viewModel.chinaAccessSnapshots.count == 2)
        #expect(viewModel.chinaAccessSummary?.contains("Probed 2 providers") == true)
        #expect(viewModel.chinaAccessSummary?.contains("1 reachable") == true)
        #expect(viewModel.chinaAccessSummary?.contains("1 blocked") == true)
    }

    @Test("China sweep scope preference is persisted and restored")
    func chinaSweepScopePersists() {
        let store = InMemorySearchPreferencesStore()

        do {
            let first = SearchViewModel(
                coordinator: FlightSearchCoordinator(providers: [], httpClient: ProviderHTTPClient(), ranking: OfferRankingService(), normalizer: CurrencyNormalizer()),
                preferencesStore: store
            )
            first.setChinaSweepIncludesAllProviders(true)
            first.saveDefaults()
        }

        let second = SearchViewModel(
            coordinator: FlightSearchCoordinator(providers: [], httpClient: ProviderHTTPClient(), ranking: OfferRankingService(), normalizer: CurrencyNormalizer()),
            preferencesStore: store
        )

        #expect(second.chinaSweepIncludesAllProviders == true)
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

private final class RecordingWatchlistNotificationClient: WatchlistNotificationClient {
    var capturedAlerts: [WatchlistAlert] = []

    func notifyTargetHitAlerts(_ alerts: [WatchlistAlert]) {
        capturedAlerts.append(contentsOf: alerts)
    }
}

private func makeProvider(
    id: String,
    name: String,
    homepage: URL,
    kind: ProviderKind,
    seedReachability: Double
) -> URLTemplateFlightProvider {
    URLTemplateFlightProvider(
        descriptor: ProviderDescriptor(
            id: id,
            name: name,
            homepage: homepage.absoluteString,
            kind: kind,
            supportsAutomatedExtraction: false,
            chinaSeedReachability: seedReachability
        ),
        searchMode: .deeplinkOnly
    ) { _, _ in
        homepage
    }
}

private struct StubReachabilityProber: ProviderReachabilityProbing {
    let resultsByURL: [URL: Bool]

    func probeReachability(url: URL) async -> Bool {
        resultsByURL[url] ?? false
    }
}
