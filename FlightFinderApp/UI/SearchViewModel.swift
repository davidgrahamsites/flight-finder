import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var routes: [RouteInputState]
    @Published var options: FlightSearchOptions
    @Published var enabledKinds: Set<ProviderKind>
    @Published var selectedPreset: SearchPreset?

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
            lastPreset: lastPreset ?? selectedPreset
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
    }
}
