import Foundation

struct FlightSearchCoordinator {
    let providers: [URLTemplateFlightProvider]
    let httpClient: ProviderHTTPClient
    let ranking: OfferRankingService
    let normalizer: CurrencyNormalizer
    let chinaPlanner: ChinaAccessibilityPlanner

    init(
        providers: [URLTemplateFlightProvider] = ProviderRegistry.makeDefaultProviders(),
        httpClient: ProviderHTTPClient = ProviderHTTPClient(),
        ranking: OfferRankingService = OfferRankingService(),
        normalizer: CurrencyNormalizer = CurrencyNormalizer()
    ) {
        self.providers = providers
        self.httpClient = httpClient
        self.ranking = ranking
        self.normalizer = normalizer
        self.chinaPlanner = ChinaAccessibilityPlanner(httpClient: httpClient)
    }

    func search(
        request: SearchRequest,
        onProgress: @escaping @Sendable (SearchProgress) -> Void
    ) async throws -> SearchSessionResult {
        let validated = try request.validated(maxRoutes: 3)

        let kindFilteredProviders = providers.filter { validated.enabledKinds.contains($0.descriptor.kind) }
        var warnings: [String] = []

        if kindFilteredProviders.isEmpty {
            warnings.append("No provider categories were enabled; no searches were run.")
            return SearchSessionResult(routes: [], warnings: warnings, generatedAt: Date())
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

        return SearchSessionResult(routes: routeResults, warnings: warnings, generatedAt: Date())
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
        var completed = 0

        await withTaskGroup(of: FlightOffer.self) { group in
            for provider in providers {
                group.addTask {
                    await provider.search(route: route, options: options, httpClient: httpClient)
                }
            }

            for await offer in group {
                completed += 1
                onProgress(SearchProgress(
                    completedProviders: completed,
                    totalProviders: totalProviders,
                    routeKey: route.routeKey,
                    providerName: offer.providerName
                ))

                var normalizedOffer = normalizeOfferCurrency(offer, targetCurrency: options.preferredCurrency)
                if options.siteAccessMode == .chinaAccessible {
                    normalizedOffer.chinaReachabilityScore = chinaReachabilityScores[offer.providerID]
                }
                offers.append(normalizedOffer)
            }
        }

        let rankedOffers = ranking.rank(offers, options: options)
        return RouteSearchResult(
            route: route,
            offers: rankedOffers,
            startedAt: startedAt,
            endedAt: Date()
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
