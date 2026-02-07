import Foundation

struct SearchSessionAnalyticsService {
    func buildRouteObservability(
        providerAttempts: Int,
        offersCollected: Int,
        deduplicatedOffers: Int,
        offers: [FlightOffer],
        providerLatenciesMs: [Double]
    ) -> RouteObservability {
        let pricedOffers = offers.count(where: { $0.status == .priced })
        let loginRequiredOffers = offers.count(where: { $0.status == .loginRequired })
        let handoffOffers = offers.count(where: { $0.status == .handoffRequired })
        let unavailableOffers = offers.count(where: { $0.status == .unavailable })

        let averageLatency: Double
        if providerLatenciesMs.isEmpty {
            averageLatency = 0
        } else {
            averageLatency = providerLatenciesMs.reduce(0, +) / Double(providerLatenciesMs.count)
        }

        return RouteObservability(
            providerAttempts: providerAttempts,
            offersCollected: offersCollected,
            pricedOffers: pricedOffers,
            loginRequiredOffers: loginRequiredOffers,
            handoffOffers: handoffOffers,
            unavailableOffers: unavailableOffers,
            deduplicatedOffers: deduplicatedOffers,
            averageProviderLatencyMs: averageLatency
        )
    }

    func buildObservability(
        routeResults: [RouteSearchResult],
        startedAt: Date,
        endedAt: Date
    ) -> SearchSessionObservability {
        let routeCount = routeResults.count
        let providerAttempts = routeResults.reduce(0) { $0 + $1.observability.providerAttempts }
        let offersCollected = routeResults.reduce(0) { $0 + $1.observability.offersCollected }
        let pricedOffers = routeResults.reduce(0) { $0 + $1.observability.pricedOffers }
        let loginRequiredOffers = routeResults.reduce(0) { $0 + $1.observability.loginRequiredOffers }
        let handoffOffers = routeResults.reduce(0) { $0 + $1.observability.handoffOffers }
        let unavailableOffers = routeResults.reduce(0) { $0 + $1.observability.unavailableOffers }
        let deduplicatedOffers = routeResults.reduce(0) { $0 + $1.observability.deduplicatedOffers }

        let weightedLatencySum = routeResults.reduce(0.0) { partial, routeResult in
            partial + (routeResult.observability.averageProviderLatencyMs * Double(routeResult.observability.providerAttempts))
        }

        let averageProviderLatencyMs = providerAttempts > 0
            ? weightedLatencySum / Double(providerAttempts)
            : 0

        return SearchSessionObservability(
            routeCount: routeCount,
            providerAttempts: providerAttempts,
            offersCollected: offersCollected,
            pricedOffers: pricedOffers,
            loginRequiredOffers: loginRequiredOffers,
            handoffOffers: handoffOffers,
            unavailableOffers: unavailableOffers,
            deduplicatedOffers: deduplicatedOffers,
            averageProviderLatencyMs: averageProviderLatencyMs,
            startedAt: startedAt,
            endedAt: endedAt
        )
    }

    func buildWatchCandidates(
        routeResults: [RouteSearchResult],
        targetDropPercent: Double = 0.08,
        observedAt: Date = Date()
    ) -> [WatchCandidate] {
        let clampedDrop = min(max(targetDropPercent, 0), 0.9)

        return routeResults.compactMap { routeResult in
            guard
                let best = routeResult.bestOffer,
                let observedPrice = best.totalPrice,
                best.status == .priced
            else {
                return nil
            }

            let targetPrice = roundToTwo(observedPrice * (1 - clampedDrop))

            return WatchCandidate(
                routeKey: routeResult.route.routeKey,
                providerID: best.providerID,
                providerName: best.providerName,
                deepLink: best.deepLink,
                currencyCode: best.currencyCode,
                observedPrice: roundToTwo(observedPrice),
                targetPrice: targetPrice,
                lastSeenAt: observedAt,
                origin: routeResult.route.origin,
                destination: routeResult.route.destination,
                departureDate: routeResult.route.departureDate,
                returnDate: routeResult.route.returnDate
            )
        }
    }

    private func roundToTwo(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }
}
