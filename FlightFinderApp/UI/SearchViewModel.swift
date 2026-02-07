import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var routes: [RouteInputState]
    @Published var options: FlightSearchOptions
    @Published var enabledKinds: Set<ProviderKind>
    @Published var selectedPreset: SearchPreset?
    @Published var watchlist: [WatchCandidate]
    @Published var watchlistAlerts: [WatchlistAlert]

    @Published var isSearching = false
    @Published var progressByRoute: [String: SearchProgress] = [:]
    @Published var sessionResult: SearchSessionResult?
    @Published var searchError: String?

    private let coordinator: FlightSearchCoordinator
    private let preferencesStore: any SearchPreferencesStore

    init(
        coordinator: FlightSearchCoordinator = FlightSearchCoordinator(),
        preferencesStore: any SearchPreferencesStore = UserDefaultsSearchPreferencesStore()
    ) {
        self.coordinator = coordinator
        self.preferencesStore = preferencesStore
        self.options = .default
        self.enabledKinds = Set(ProviderKind.allCases)
        self.routes = [RouteInputState(origin: "SFO", destination: "LAX")]
        self.selectedPreset = nil
        self.watchlist = []
        self.watchlistAlerts = []
        restoreDefaultsIfAvailable()
    }

    func addRoute() {
        guard routes.count < 3 else { return }
        routes.append(RouteInputState())
    }

    func removeRoute(id: UUID) {
        guard routes.count > 1 else { return }
        routes.removeAll { $0.id == id }
    }

    func toggleKind(_ kind: ProviderKind) {
        if enabledKinds.contains(kind) {
            enabledKinds.remove(kind)
        } else {
            enabledKinds.insert(kind)
        }
    }

    func resetResults() {
        progressByRoute = [:]
        sessionResult = nil
        searchError = nil
    }

    func removeWatchCandidate(id: UUID) {
        watchlist.removeAll { $0.id == id }
        watchlistAlerts.removeAll { $0.candidateID == id }
        saveDefaults()
    }

    func dismissWatchlistAlert(id: UUID) {
        watchlistAlerts.removeAll { $0.id == id }
    }

    func clearWatchlistAlerts() {
        watchlistAlerts = []
    }

    @discardableResult
    func mergeWatchCandidates(_ candidates: [WatchCandidate], saveIfChanged: Bool = true) -> Int {
        guard !candidates.isEmpty else { return 0 }

        var indexByKey: [String: Int] = [:]
        var merged = watchlist
        for (index, existing) in merged.enumerated() {
            indexByKey["\(existing.routeKey)|\(existing.providerID)"] = index
        }

        var changedCount = 0
        for candidate in candidates {
            let key = "\(candidate.routeKey)|\(candidate.providerID)"
            if let existingIndex = indexByKey[key] {
                let existing = merged[existingIndex]
                let updated = WatchCandidate(
                    id: existing.id,
                    routeKey: candidate.routeKey,
                    providerID: candidate.providerID,
                    providerName: candidate.providerName,
                    deepLink: candidate.deepLink,
                    currencyCode: candidate.currencyCode,
                    observedPrice: candidate.observedPrice,
                    targetPrice: min(existing.targetPrice, candidate.targetPrice),
                    lastSeenAt: max(existing.lastSeenAt, candidate.lastSeenAt)
                )
                if updated != existing {
                    merged[existingIndex] = updated
                    changedCount += 1
                }
            } else {
                merged.append(candidate)
                indexByKey[key] = merged.count - 1
                changedCount += 1
            }
        }

        if changedCount > 0 {
            watchlist = sortWatchlist(merged)
            if saveIfChanged {
                saveDefaults()
            }
        }

        return changedCount
    }

    func processSessionResult(_ result: SearchSessionResult, observedAt: Date = Date()) {
        sessionResult = result
        let freshAlerts = syncWatchlistToOffers(from: result, observedAt: observedAt)
        appendWatchlistAlerts(freshAlerts)
        _ = mergeWatchCandidates(result.watchCandidates, saveIfChanged: false)
        saveDefaults()
    }

    func applyPreset(_ preset: SearchPreset) {
        routes = preset.makeRoutes()
        options.tripType = preset.defaultTripType
        options.siteAccessMode = preset.defaultSiteAccessMode
        enabledKinds = preset.defaultEnabledKinds
        selectedPreset = preset
        saveDefaults(lastPreset: preset)
    }

    func saveDefaults(lastPreset: SearchPreset? = nil) {
        let trimmedRoutes = Array(routes.prefix(3))
        let persistedRoutes = trimmedRoutes.isEmpty ? [RouteInputState()] : trimmedRoutes
        let config = SavedSearchConfig(
            routes: persistedRoutes,
            options: options,
            enabledKinds: enabledKinds,
            lastPreset: lastPreset ?? selectedPreset,
            watchlist: watchlist
        )
        preferencesStore.save(config)
    }

    func runSearch() async {
        isSearching = true
        searchError = nil
        progressByRoute = [:]

        let routeRequests = routes.map { $0.toRouteRequest(tripType: options.tripType) }
        let request = SearchRequest(routes: routeRequests, options: options, enabledKinds: enabledKinds)

        do {
            let result = try await coordinator.search(request: request) { [weak self] progress in
                Task { @MainActor in
                    self?.progressByRoute[progress.routeKey] = progress
                }
            }
            processSessionResult(result)
        } catch {
            sessionResult = nil
            searchError = error.localizedDescription
        }

        isSearching = false
    }

    private func restoreDefaultsIfAvailable() {
        guard let saved = preferencesStore.load() else { return }

        let restoredRoutes = Array(saved.routes.prefix(3))
        if !restoredRoutes.isEmpty {
            routes = restoredRoutes
        }

        options = saved.options
        enabledKinds = saved.enabledKinds.isEmpty ? Set(ProviderKind.allCases) : saved.enabledKinds
        selectedPreset = saved.lastPreset
        watchlist = sortWatchlist(saved.watchlist)
    }

    private func syncWatchlistToOffers(from result: SearchSessionResult, observedAt: Date) -> [WatchlistAlert] {
        guard !watchlist.isEmpty else { return [] }

        let matchedOffers = bestPricedOffersByWatchKey(from: result)
        guard !matchedOffers.isEmpty else { return [] }

        var updatedWatchlist = watchlist
        var alerts: [WatchlistAlert] = []
        var changed = false

        for index in updatedWatchlist.indices {
            let candidate = updatedWatchlist[index]
            let key = watchKey(routeKey: candidate.routeKey, providerID: candidate.providerID)
            guard
                let offer = matchedOffers[key],
                let price = offer.totalPrice
            else {
                continue
            }

            let roundedPrice = roundToTwo(price)
            let nextLastSeen = max(candidate.lastSeenAt, observedAt)
            let refreshed = WatchCandidate(
                id: candidate.id,
                routeKey: candidate.routeKey,
                providerID: candidate.providerID,
                providerName: offer.providerName,
                deepLink: offer.deepLink,
                currencyCode: offer.currencyCode,
                observedPrice: roundedPrice,
                targetPrice: candidate.targetPrice,
                lastSeenAt: nextLastSeen
            )

            if refreshed != candidate {
                updatedWatchlist[index] = refreshed
                changed = true
            }

            if roundedPrice <= candidate.targetPrice {
                alerts.append(
                    WatchlistAlert(
                        candidateID: candidate.id,
                        routeKey: candidate.routeKey,
                        providerID: candidate.providerID,
                        providerName: offer.providerName,
                        observedPrice: roundedPrice,
                        targetPrice: candidate.targetPrice,
                        currencyCode: offer.currencyCode,
                        deepLink: offer.deepLink,
                        hitAt: observedAt
                    )
                )
            }
        }

        if changed {
            watchlist = sortWatchlist(updatedWatchlist)
        }

        return alerts
    }

    private func bestPricedOffersByWatchKey(from result: SearchSessionResult) -> [String: FlightOffer] {
        var offersByKey: [String: FlightOffer] = [:]

        for routeResult in result.routes {
            for offer in routeResult.offers {
                guard
                    offer.status == .priced,
                    let price = offer.totalPrice
                else {
                    continue
                }

                let key = watchKey(routeKey: routeResult.route.routeKey, providerID: offer.providerID)
                if let existing = offersByKey[key], let existingPrice = existing.totalPrice, existingPrice <= price {
                    continue
                }

                offersByKey[key] = offer
            }
        }

        return offersByKey
    }

    private func appendWatchlistAlerts(_ alerts: [WatchlistAlert]) {
        guard !alerts.isEmpty else { return }

        var knownKeys = Set(watchlistAlerts.map(\.dedupeKey))
        var merged = watchlistAlerts
        for alert in alerts {
            guard !knownKeys.contains(alert.dedupeKey) else { continue }
            knownKeys.insert(alert.dedupeKey)
            merged.insert(alert, at: 0)
        }
        watchlistAlerts = Array(merged.prefix(30))
    }

    private func sortWatchlist(_ items: [WatchCandidate]) -> [WatchCandidate] {
        items.sorted { lhs, rhs in
            if lhs.lastSeenAt == rhs.lastSeenAt {
                return lhs.routeKey < rhs.routeKey
            }
            return lhs.lastSeenAt > rhs.lastSeenAt
        }
    }

    private func watchKey(routeKey: String, providerID: String) -> String {
        "\(routeKey)|\(providerID)"
    }

    private func roundToTwo(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }
}
