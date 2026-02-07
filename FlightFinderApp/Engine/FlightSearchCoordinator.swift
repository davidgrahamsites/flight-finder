import Foundation

struct FlightSearchCoordinator {
    let providers: [URLTemplateFlightProvider]
    let httpClient: ProviderHTTPClient
    let ranking: OfferRankingService
    let normalizer: CurrencyNormalizer
    let chinaPlanner: ChinaAccessibilityPlanner
    let deduplication: OfferDeduplicationService
    let analytics: SearchSessionAnalyticsService
    let maxConcurrentProvidersPerRoute: Int
    let interBatchDelay: Duration

    init(
        providers: [URLTemplateFlightProvider] = ProviderRegistry.makeDefaultProviders(),
        httpClient: ProviderHTTPClient = ProviderHTTPClient(),
        ranking: OfferRankingService = OfferRankingService(),
        normalizer: CurrencyNormalizer = CurrencyNormalizer(),
        chinaPlanner: ChinaAccessibilityPlanner? = nil,
        deduplication: OfferDeduplicationService = OfferDeduplicationService(),
        analytics: SearchSessionAnalyticsService = SearchSessionAnalyticsService(),
        maxConcurrentProvidersPerRoute: Int = 8,
        interBatchDelay: Duration = .milliseconds(120)
    ) {
        self.providers = providers
        self.httpClient = httpClient
        self.ranking = ranking
        self.normalizer = normalizer
        self.chinaPlanner = chinaPlanner ?? ChinaAccessibilityPlanner(httpClient: httpClient)
        self.deduplication = deduplication
        self.analytics = analytics
        self.maxConcurrentProvidersPerRoute = maxConcurrentProvidersPerRoute
        self.interBatchDelay = interBatchDelay
    }

    func chinaAccessibilitySnapshot(
        enabledKinds: Set<ProviderKind>,
        includeAllProviders: Bool = false
    ) async -> [ChinaAccessibilityPlanner.ProviderSnapshot] {
        let selected = includeAllProviders
            ? providers
            : providers.filter { enabledKinds.contains($0.descriptor.kind) }
        return await chinaPlanner.snapshots(providers: selected)
    }

    func runChinaAccessibilitySweep(
        enabledKinds: Set<ProviderKind>,
        includeAllProviders: Bool = false
    ) async -> ChinaAccessibilityPlanner.ProbeReport {
        let selected = includeAllProviders
            ? providers
            : providers.filter { enabledKinds.contains($0.descriptor.kind) }
        return await chinaPlanner.probeAndSnapshot(providers: selected)
    }

    func search(
        request: SearchRequest,
        onProgress: @escaping @Sendable (SearchProgress) -> Void
    ) async throws -> SearchSessionResult {
        let sessionStartedAt = Date()
        let validated = try request.validated(maxRoutes: 3)

        let kindFilteredProviders = providers.filter { validated.enabledKinds.contains($0.descriptor.kind) }
        var warnings: [String] = []

        if kindFilteredProviders.isEmpty {
            warnings.append("No provider categories were enabled; no searches were run.")
            let finishedAt = Date()
            return SearchSessionResult(
                routes: [],
                warnings: warnings,
                generatedAt: finishedAt,
                observability: analytics.buildObservability(routeResults: [], startedAt: sessionStartedAt, endedAt: finishedAt),
                watchCandidates: []
            )
        }

        let selectedProviders: [URLTemplateFlightProvider]
        let chinaReachabilityScores: [String: Double]
        if validated.options.siteAccessMode == .chinaAccessible {
            let chinaSelection = await chinaPlanner.rankAndFilter(providers: kindFilteredProviders)
            selectedProviders = chinaSelection.providers
            chinaReachabilityScores = chinaSelection.scores

            if chinaSelection.filteredOutCount > 0 {
                warnings.append(
                    "China Accessible Sites Mode filtered out \(chinaSelection.filteredOutCount) low-reachability sites based on live probing plus learned history."
                )
            }
        } else {
            selectedProviders = kindFilteredProviders
            chinaReachabilityScores = [:]
        }

        if selectedProviders.isEmpty {
            warnings.append("No providers remained after accessibility filtering.")
            let finishedAt = Date()
            return SearchSessionResult(
                routes: [],
                warnings: warnings,
                generatedAt: finishedAt,
                observability: analytics.buildObservability(routeResults: [], startedAt: sessionStartedAt, endedAt: finishedAt),
                watchCandidates: []
            )
        }

        var routeResults: [RouteSearchResult] = []

        try await withThrowingTaskGroup(of: RouteSearchResult.self) { group in
            for route in validated.routes {
                group.addTask {
                    await searchRoute(
                        route,
                        options: validated.options,
                        providers: selectedProviders,
                        chinaReachabilityScores: chinaReachabilityScores,
                        onProgress: onProgress
                    )
                }
            }

            for try await routeResult in group {
                routeResults.append(routeResult)
            }
        }

        routeResults.sort { $0.route.routeKey < $1.route.routeKey }

        let sessionEndedAt = Date()
        let observability = analytics.buildObservability(
            routeResults: routeResults,
            startedAt: sessionStartedAt,
            endedAt: sessionEndedAt
        )

        let watchCandidates = analytics.buildWatchCandidates(routeResults: routeResults, observedAt: sessionEndedAt)

        return SearchSessionResult(
            routes: routeResults,
            warnings: warnings,
            generatedAt: sessionEndedAt,
            observability: observability,
            watchCandidates: watchCandidates
        )
    }

    private func searchRoute(
        _ route: RouteRequest,
        options: FlightSearchOptions,
        providers: [URLTemplateFlightProvider],
        chinaReachabilityScores: [String: Double],
        onProgress: @escaping @Sendable (SearchProgress) -> Void
    ) async -> RouteSearchResult {
        let startedAt = Date()
        let totalProviders = providers.count

        var offers: [FlightOffer] = []
        var auditTrail: [OfferAuditEntry] = []
        var providerLatenciesMs: [Double] = []
        var completed = 0

        let safeBatchSize = max(1, maxConcurrentProvidersPerRoute)
        let batches = providers.chunked(into: safeBatchSize)

        for (batchIndex, batch) in batches.enumerated() {
            await withTaskGroup(of: ProviderAttemptResult.self) { group in
                for provider in batch {
                    group.addTask {
                        await performProviderAttempt(
                            provider: provider,
                            route: route,
                            options: options
                        )
                    }
                }

                for await attempt in group {
                    completed += 1

                    var normalizedOffer = normalizeOfferCurrency(attempt.offer, targetCurrency: options.preferredCurrency)
                    if options.siteAccessMode == .chinaAccessible {
                        normalizedOffer.chinaReachabilityScore = chinaReachabilityScores[attempt.offer.providerID]
                    }

                    offers.append(normalizedOffer)
                    providerLatenciesMs.append(attempt.latencyMs)
                    auditTrail.append(
                        OfferAuditEntry(
                            providerID: attempt.provider.descriptor.id,
                            providerName: attempt.provider.descriptor.name,
                            providerKind: attempt.provider.descriptor.kind,
                            routeKey: route.routeKey,
                            searchMode: attempt.provider.searchMode.auditLabel,
                            status: normalizedOffer.status,
                            startedAt: attempt.startedAt,
                            endedAt: attempt.endedAt,
                            latencyMs: attempt.latencyMs,
                            note: normalizedOffer.notes
                        )
                    )

                    onProgress(SearchProgress(
                        completedProviders: completed,
                        totalProviders: totalProviders,
                        routeKey: route.routeKey,
                        providerName: normalizedOffer.providerName
                    ))
                }
            }

            let shouldPauseBeforeNextBatch = batchIndex < batches.count - 1
            if shouldPauseBeforeNextBatch {
                try? await Task.sleep(for: interBatchDelay)
            }
        }

        let deduplicationResult = deduplication.deduplicate(offers)
        let rankedOffers = ranking.rank(deduplicationResult.offers, options: options)
        let routeObservability = analytics.buildRouteObservability(
            providerAttempts: totalProviders,
            offersCollected: offers.count,
            deduplicatedOffers: deduplicationResult.droppedCount,
            offers: rankedOffers,
            providerLatenciesMs: providerLatenciesMs
        )

        return RouteSearchResult(
            route: route,
            offers: rankedOffers,
            startedAt: startedAt,
            endedAt: Date(),
            observability: routeObservability,
            auditTrail: auditTrail.sorted { $0.startedAt < $1.startedAt }
        )
    }

    private func performProviderAttempt(
        provider: URLTemplateFlightProvider,
        route: RouteRequest,
        options: FlightSearchOptions
    ) async -> ProviderAttemptResult {
        let startedAt = Date()
        let offer = await provider.search(route: route, options: options, httpClient: httpClient)
        let endedAt = Date()

        return ProviderAttemptResult(
            provider: provider,
            offer: offer,
            startedAt: startedAt,
            endedAt: endedAt,
            latencyMs: endedAt.timeIntervalSince(startedAt) * 1_000
        )
    }

    private func normalizeOfferCurrency(_ offer: FlightOffer, targetCurrency: String) -> FlightOffer {
        guard let price = offer.totalPrice else {
            return offer
        }

        let normalized = normalizer.convert(price, from: offer.currencyCode, to: targetCurrency)
        var copy = offer
        copy.totalPrice = normalized
        copy.currencyCode = targetCurrency
        return copy
    }
}

private struct ProviderAttemptResult {
    let provider: URLTemplateFlightProvider
    let offer: FlightOffer
    let startedAt: Date
    let endedAt: Date
    let latencyMs: Double
}

private extension URLTemplateFlightProvider.SearchMode {
    var auditLabel: String {
        switch self {
        case .deeplinkOnly:
            return "deeplink_only"
        case .fetchAndExtract:
            return "fetch_and_extract"
        }
    }
}
