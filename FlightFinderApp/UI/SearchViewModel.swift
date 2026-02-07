import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var routes: [RouteInputState]
    @Published var options: FlightSearchOptions
    @Published var enabledKinds: Set<ProviderKind>
    @Published var selectedPreset: SearchPreset?
    @Published var watchlist: [WatchCandidate]
    @Published var watchlistAlerts: [WatchlistAlert]
    @Published var autoWatchlistRecheckEnabled: Bool
    @Published var autoWatchlistRecheckIntervalMinutes: Int
    @Published var watchlistNotificationsEnabled: Bool
    @Published var chinaAccessSnapshots: [ChinaAccessibilityPlanner.ProviderSnapshot]
    @Published var chinaAccessSummary: String?
    @Published var isRunningChinaAccessibilitySweep: Bool
    @Published var chinaSweepIncludesAllProviders: Bool
    @Published var pendingLoginOffer: FlightOffer?
    @Published var resultStatusFilter: ResultStatusFilter
    @Published var resultMaxOffersPerRoute: Int

    @Published var isSearching = false
    @Published var progressByRoute: [String: SearchProgress] = [:]
    @Published var sessionResult: SearchSessionResult?
    @Published var searchError: String?
    @Published var watchlistRecheckSummary: String?

    private let coordinator: FlightSearchCoordinator
    private let preferencesStore: any SearchPreferencesStore
    private let notificationClient: any WatchlistNotificationClient
    private let offerOpenClient: any OfferOpenClient
    private var autoWatchlistRecheckTask: Task<Void, Never>?

    init(
        coordinator: FlightSearchCoordinator = FlightSearchCoordinator(),
        preferencesStore: any SearchPreferencesStore = UserDefaultsSearchPreferencesStore(),
        notificationClient: any WatchlistNotificationClient = LocalWatchlistNotificationClient(),
        offerOpenClient: any OfferOpenClient = WorkspaceOfferOpenClient()
    ) {
        self.coordinator = coordinator
        self.preferencesStore = preferencesStore
        self.notificationClient = notificationClient
        self.offerOpenClient = offerOpenClient
        self.options = .default
        self.enabledKinds = Set(ProviderKind.allCases)
        self.routes = [RouteInputState(origin: "SFO", destination: "LAX")]
        self.selectedPreset = nil
        self.watchlist = []
        self.watchlistAlerts = []
        self.autoWatchlistRecheckEnabled = false
        self.autoWatchlistRecheckIntervalMinutes = 30
        self.watchlistNotificationsEnabled = true
        self.chinaAccessSnapshots = []
        self.chinaAccessSummary = nil
        self.isRunningChinaAccessibilitySweep = false
        self.chinaSweepIncludesAllProviders = false
        self.pendingLoginOffer = nil
        self.resultStatusFilter = .all
        self.resultMaxOffersPerRoute = 15
        self.watchlistRecheckSummary = nil
        restoreDefaultsIfAvailable()
        restartAutoWatchlistRecheckTask()
        Task { [weak self] in
            guard let self else { return }
            await self.refreshChinaAccessibilitySnapshot()
        }
    }

    deinit {
        autoWatchlistRecheckTask?.cancel()
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

        if options.siteAccessMode == .chinaAccessible {
            Task { [weak self] in
                guard let self else { return }
                await self.refreshChinaAccessibilitySnapshot()
            }
        }
    }

    func resetResults() {
        progressByRoute = [:]
        sessionResult = nil
        searchError = nil
        watchlistRecheckSummary = nil
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

    func setAutoWatchlistRecheckEnabled(_ enabled: Bool) {
        guard autoWatchlistRecheckEnabled != enabled else { return }
        autoWatchlistRecheckEnabled = enabled
        saveDefaults()
        restartAutoWatchlistRecheckTask()
    }

    func setAutoWatchlistRecheckIntervalMinutes(_ minutes: Int) {
        let normalized = normalizedAutoWatchlistRecheckInterval(minutes)
        guard autoWatchlistRecheckIntervalMinutes != normalized else { return }
        autoWatchlistRecheckIntervalMinutes = normalized
        saveDefaults()
        restartAutoWatchlistRecheckTask()
    }

    func setWatchlistNotificationsEnabled(_ enabled: Bool) {
        guard watchlistNotificationsEnabled != enabled else { return }
        watchlistNotificationsEnabled = enabled
        saveDefaults()
    }

    func setChinaSweepIncludesAllProviders(_ enabled: Bool) {
        guard chinaSweepIncludesAllProviders != enabled else { return }
        chinaSweepIncludesAllProviders = enabled
        saveDefaults()

        if options.siteAccessMode == .chinaAccessible {
            Task { [weak self] in
                guard let self else { return }
                await self.refreshChinaAccessibilitySnapshot()
            }
        }
    }

    func setResultStatusFilter(_ filter: ResultStatusFilter) {
        guard resultStatusFilter != filter else { return }
        resultStatusFilter = filter
    }

    func setResultMaxOffersPerRoute(_ count: Int) {
        let normalized = normalizedResultMaxOffersPerRoute(count)
        guard resultMaxOffersPerRoute != normalized else { return }
        resultMaxOffersPerRoute = normalized
    }

    func displayOffers(for routeResult: RouteSearchResult) -> [FlightOffer] {
        let filtered = routeResult.offers.filter { offer in
            switch resultStatusFilter {
            case .all:
                return true
            case .priced:
                return offer.status == .priced
            case .actionRequired:
                return offer.status == .handoffRequired || offer.status == .loginRequired
            case .unavailable:
                return offer.status == .unavailable
            }
        }

        return Array(filtered.prefix(resultMaxOffersPerRoute))
    }

    func handleOfferOpenRequest(_ offer: FlightOffer) {
        if offer.status == .loginRequired {
            pendingLoginOffer = offer
            return
        }

        offerOpenClient.open(url: offer.deepLink)
    }

    func confirmLoginAndOpenPendingOffer() {
        guard let offer = pendingLoginOffer else { return }
        pendingLoginOffer = nil
        offerOpenClient.open(url: offer.deepLink)
    }

    func dismissPendingLoginOffer() {
        pendingLoginOffer = nil
    }

    func refreshChinaAccessibilitySnapshot() async {
        let snapshots = await coordinator.chinaAccessibilitySnapshot(
            enabledKinds: enabledKinds,
            includeAllProviders: chinaSweepIncludesAllProviders
        )
        chinaAccessSnapshots = Array(snapshots.prefix(12))
    }

    func runChinaAccessibilitySweep() async {
        guard !isRunningChinaAccessibilitySweep else { return }
        isRunningChinaAccessibilitySweep = true
        chinaAccessSummary = nil

        let report = await coordinator.runChinaAccessibilitySweep(
            enabledKinds: enabledKinds,
            includeAllProviders: chinaSweepIncludesAllProviders
        )
        chinaAccessSnapshots = Array(report.snapshots.prefix(12))
        chinaAccessSummary = buildChinaAccessibilitySummary(report)
        isRunningChinaAccessibilitySweep = false
    }

    @discardableResult
    func mergeWatchCandidates(_ candidates: [WatchCandidate], saveIfChanged: Bool = true) -> Int {
        guard !candidates.isEmpty else { return 0 }

        var indexByKey: [String: Int] = [:]
        var merged = watchlist
        for (index, existing) in merged.enumerated() {
            indexByKey[watchLegacyKey(routeKey: existing.routeKey, providerID: existing.providerID)] = index
        }

        var changedCount = 0
        for candidate in candidates {
            let key = watchLegacyKey(routeKey: candidate.routeKey, providerID: candidate.providerID)
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
                    lastSeenAt: max(existing.lastSeenAt, candidate.lastSeenAt),
                    origin: candidate.origin ?? existing.origin,
                    destination: candidate.destination ?? existing.destination,
                    departureDate: candidate.departureDate ?? existing.departureDate,
                    returnDate: candidate.returnDate ?? existing.returnDate
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

    func makeWatchlistRecheckPlan(maxRoutes: Int = 3) -> WatchlistRecheckPlan? {
        guard maxRoutes > 0 else { return nil }

        let descriptors = watchlist.compactMap(makeDescriptor(for:))
        guard !descriptors.isEmpty else { return nil }

        let preferred = descriptors.filter { $0.tripType == options.tripType }
        let selectedTripType: TripType
        let selectedPool: [WatchlistRouteDescriptor]
        let skippedByTripType: Int

        if !preferred.isEmpty {
            selectedTripType = options.tripType
            selectedPool = preferred.sorted { $0.lastSeenAt > $1.lastSeenAt }
            skippedByTripType = descriptors.count - preferred.count
        } else {
            let sorted = descriptors.sorted { $0.lastSeenAt > $1.lastSeenAt }
            guard let fallback = sorted.first else { return nil }
            selectedTripType = fallback.tripType
            selectedPool = sorted.filter { $0.tripType == selectedTripType }
            skippedByTripType = 0
        }

        var seenRouteKeys: Set<String> = []
        var uniqueRoutes: [RouteRequest] = []
        var uniqueCount = 0

        for descriptor in selectedPool {
            if seenRouteKeys.insert(descriptor.identityKey).inserted {
                uniqueCount += 1
                if uniqueRoutes.count < maxRoutes {
                    uniqueRoutes.append(descriptor.route)
                }
            }
        }

        guard !uniqueRoutes.isEmpty else { return nil }

        return WatchlistRecheckPlan(
            routes: uniqueRoutes,
            tripType: selectedTripType,
            skippedByTripType: skippedByTripType,
            truncatedRoutes: max(0, uniqueCount - uniqueRoutes.count)
        )
    }

    func runWatchlistRecheck() async {
        await runWatchlistRecheck(trigger: .manual)
    }

    private func runWatchlistRecheck(trigger: WatchlistRecheckTrigger) async {
        guard !watchlist.isEmpty else {
            if trigger == .manual {
                watchlistRecheckSummary = "Watchlist is empty."
            }
            return
        }

        guard !isSearching else {
            return
        }

        guard let plan = makeWatchlistRecheckPlan() else {
            if trigger == .manual {
                watchlistRecheckSummary = "No valid watchlist routes to re-check."
            }
            return
        }

        isSearching = true
        searchError = nil
        watchlistRecheckSummary = nil
        progressByRoute = [:]

        var recheckOptions = options
        recheckOptions.tripType = plan.tripType

        let request = SearchRequest(
            routes: plan.routes,
            options: recheckOptions,
            enabledKinds: enabledKinds
        )

        do {
            let result = try await coordinator.search(request: request) { [weak self] progress in
                Task { @MainActor in
                    self?.progressByRoute[progress.routeKey] = progress
                }
            }
            processSessionResult(result)
            watchlistRecheckSummary = buildWatchlistRecheckSummary(plan, trigger: trigger)
        } catch {
            searchError = error.localizedDescription
            if trigger == .manual {
                watchlistRecheckSummary = "Watchlist re-check failed."
            }
        }

        isSearching = false
    }

    func processSessionResult(_ result: SearchSessionResult, observedAt: Date = Date()) {
        sessionResult = result
        let freshAlerts = syncWatchlistToOffers(from: result, observedAt: observedAt)
        let insertedAlerts = appendWatchlistAlerts(freshAlerts)
        if watchlistNotificationsEnabled, !insertedAlerts.isEmpty {
            notificationClient.notifyTargetHitAlerts(insertedAlerts)
        }
        _ = mergeWatchCandidates(result.watchCandidates, saveIfChanged: false)
        saveDefaults()

        if options.siteAccessMode == .chinaAccessible {
            Task { [weak self] in
                guard let self else { return }
                await self.refreshChinaAccessibilitySnapshot()
            }
        }
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
            watchlist: watchlist,
            autoWatchlistRecheckEnabled: autoWatchlistRecheckEnabled,
            autoWatchlistRecheckIntervalMinutes: autoWatchlistRecheckIntervalMinutes,
            watchlistNotificationsEnabled: watchlistNotificationsEnabled,
            chinaSweepIncludesAllProviders: chinaSweepIncludesAllProviders
        )
        preferencesStore.save(config)
    }

    func runSearch() async {
        isSearching = true
        searchError = nil
        watchlistRecheckSummary = nil
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
        autoWatchlistRecheckEnabled = saved.autoWatchlistRecheckEnabled
        autoWatchlistRecheckIntervalMinutes = normalizedAutoWatchlistRecheckInterval(saved.autoWatchlistRecheckIntervalMinutes)
        watchlistNotificationsEnabled = saved.watchlistNotificationsEnabled
        chinaSweepIncludesAllProviders = saved.chinaSweepIncludesAllProviders
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
            let matchingOffer = watchKeysForCandidate(candidate).compactMap { matchedOffers[$0] }.first
            guard
                let offer = matchingOffer,
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
                lastSeenAt: nextLastSeen,
                origin: offer.route.origin,
                destination: offer.route.destination,
                departureDate: offer.route.departureDate,
                returnDate: offer.route.returnDate
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

                let keys = watchKeysForRoute(routeResult.route, providerID: offer.providerID)
                for key in keys {
                    if let existing = offersByKey[key], let existingPrice = existing.totalPrice, existingPrice <= price {
                        continue
                    }
                    offersByKey[key] = offer
                }
            }
        }

        return offersByKey
    }

    @discardableResult
    private func appendWatchlistAlerts(_ alerts: [WatchlistAlert]) -> [WatchlistAlert] {
        guard !alerts.isEmpty else { return [] }

        var knownKeys = Set(watchlistAlerts.map(\.dedupeKey))
        var merged = watchlistAlerts
        var inserted: [WatchlistAlert] = []
        for alert in alerts {
            guard !knownKeys.contains(alert.dedupeKey) else { continue }
            knownKeys.insert(alert.dedupeKey)
            merged.insert(alert, at: 0)
            inserted.append(alert)
        }
        watchlistAlerts = Array(merged.prefix(30))
        return inserted
    }

    private func sortWatchlist(_ items: [WatchCandidate]) -> [WatchCandidate] {
        items.sorted { lhs, rhs in
            if lhs.lastSeenAt == rhs.lastSeenAt {
                return lhs.routeKey < rhs.routeKey
            }
            return lhs.lastSeenAt > rhs.lastSeenAt
        }
    }

    private func watchLegacyKey(routeKey: String, providerID: String) -> String {
        "\(routeKey)|\(providerID)"
    }

    private func watchCanonicalKey(route: RouteRequest, providerID: String) -> String {
        "\(routeIdentity(route))|\(providerID)"
    }

    private func watchKeysForRoute(_ route: RouteRequest, providerID: String) -> [String] {
        [
            watchLegacyKey(routeKey: route.routeKey, providerID: providerID),
            watchCanonicalKey(route: route, providerID: providerID)
        ]
    }

    private func watchKeysForCandidate(_ candidate: WatchCandidate) -> [String] {
        var keys = [watchLegacyKey(routeKey: candidate.routeKey, providerID: candidate.providerID)]
        if let route = candidate.toRouteRequest() {
            keys.append(watchCanonicalKey(route: route, providerID: candidate.providerID))
        }
        return keys
    }

    private func routeIdentity(_ route: RouteRequest) -> String {
        let departure = DateFormatter.flightDate.string(from: route.departureDate)
        let returnValue = route.returnDate.map { DateFormatter.flightDate.string(from: $0) } ?? "oneway"
        return "\(route.origin)-\(route.destination)-\(departure)-\(returnValue)"
    }

    private func makeDescriptor(for candidate: WatchCandidate) -> WatchlistRouteDescriptor? {
        guard let route = candidate.toRouteRequest() else { return nil }
        return WatchlistRouteDescriptor(
            route: route,
            tripType: route.returnDate == nil ? .oneWay : .roundTrip,
            lastSeenAt: candidate.lastSeenAt,
            identityKey: candidate.routeIdentityKey
        )
    }

    private func buildWatchlistRecheckSummary(_ plan: WatchlistRecheckPlan, trigger: WatchlistRecheckTrigger) -> String {
        let prefix = trigger == .scheduled ? "Auto re-check complete." : "Rechecked"
        var parts = [
            trigger == .scheduled
                ? "\(prefix) \(plan.routes.count) route\(plan.routes.count == 1 ? "" : "s") as \(plan.tripType.rawValue.lowercased())."
                : "\(prefix) \(plan.routes.count) watchlist route\(plan.routes.count == 1 ? "" : "s") as \(plan.tripType.rawValue.lowercased())."
        ]

        if plan.skippedByTripType > 0 {
            parts.append("Skipped \(plan.skippedByTripType) route\(plan.skippedByTripType == 1 ? "" : "s") with a different trip type.")
        }

        if plan.truncatedRoutes > 0 {
            parts.append("Deferred \(plan.truncatedRoutes) route\(plan.truncatedRoutes == 1 ? "" : "s") due to the 3-route cap.")
        }

        return parts.joined(separator: " ")
    }

    private func normalizedAutoWatchlistRecheckInterval(_ minutes: Int) -> Int {
        min(max(minutes, 5), 180)
    }

    private func normalizedResultMaxOffersPerRoute(_ count: Int) -> Int {
        min(max(count, 5), 25)
    }

    private func buildChinaAccessibilitySummary(_ report: ChinaAccessibilityPlanner.ProbeReport) -> String {
        if report.probedCount == 0 {
            return "No providers matched the enabled provider types."
        }

        let providerNoun = report.probedCount == 1 ? "provider" : "providers"
        return "Probed \(report.probedCount) \(providerNoun). \(report.reachableCount) reachable, \(report.unreachableCount) blocked."
    }

    private func restartAutoWatchlistRecheckTask() {
        autoWatchlistRecheckTask?.cancel()
        guard autoWatchlistRecheckEnabled else { return }

        autoWatchlistRecheckTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                let intervalSeconds = max(5, self.autoWatchlistRecheckIntervalMinutes * 60)
                do {
                    try await Task.sleep(for: .seconds(intervalSeconds))
                } catch {
                    return
                }

                guard !Task.isCancelled else { return }
                await self.runWatchlistRecheck(trigger: .scheduled)
            }
        }
    }

    private func roundToTwo(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }
}

private struct WatchlistRouteDescriptor {
    let route: RouteRequest
    let tripType: TripType
    let lastSeenAt: Date
    let identityKey: String
}

private enum WatchlistRecheckTrigger {
    case manual
    case scheduled
}

enum ResultStatusFilter: String, CaseIterable, Identifiable {
    case all
    case priced
    case actionRequired
    case unavailable

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .priced:
            return "Priced"
        case .actionRequired:
            return "Action"
        case .unavailable:
            return "Unavailable"
        }
    }
}
