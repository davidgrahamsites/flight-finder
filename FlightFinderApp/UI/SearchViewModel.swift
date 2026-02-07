import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var routes: [RouteInputState]
    @Published var options: FlightSearchOptions
    @Published var enabledKinds: Set<ProviderKind>
    @Published var selectedPreset: SearchPreset?
    @Published var watchlist: [WatchCandidate]

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
        saveDefaults()
    }

    @discardableResult
    func mergeWatchCandidates(_ candidates: [WatchCandidate]) -> Int {
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
            watchlist = merged.sorted { lhs, rhs in
                if lhs.lastSeenAt == rhs.lastSeenAt {
                    return lhs.routeKey < rhs.routeKey
                }
                return lhs.lastSeenAt > rhs.lastSeenAt
            }
            saveDefaults()
        }

        return changedCount
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
            sessionResult = result
            mergeWatchCandidates(result.watchCandidates)
            saveDefaults()
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
        watchlist = saved.watchlist.sorted { lhs, rhs in
            if lhs.lastSeenAt == rhs.lastSeenAt {
                return lhs.routeKey < rhs.routeKey
            }
            return lhs.lastSeenAt > rhs.lastSeenAt
        }
    }
}
