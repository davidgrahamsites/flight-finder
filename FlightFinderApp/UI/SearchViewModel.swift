import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var routes: [RouteInputState]
    @Published var options: FlightSearchOptions
    @Published var enabledKinds: Set<ProviderKind>

    @Published var isSearching = false
    @Published var progressByRoute: [String: SearchProgress] = [:]
    @Published var sessionResult: SearchSessionResult?
    @Published var searchError: String?

    private let coordinator: FlightSearchCoordinator

    init(coordinator: FlightSearchCoordinator = FlightSearchCoordinator()) {
        self.coordinator = coordinator
        self.options = .default
        self.enabledKinds = Set(ProviderKind.allCases)
        self.routes = [RouteInputState(origin: "SFO", destination: "LAX")]
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
        } catch {
            sessionResult = nil
            searchError = error.localizedDescription
        }

        isSearching = false
    }
}
