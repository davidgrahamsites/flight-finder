import Foundation
import Testing
@testable import FlightFinder

struct SearchAnalyticsTests {
    @Test("Dedup keeps strongest offer for identical itinerary fingerprints")
    func deduplicationPrefersHigherConfidence() {
        let route = RouteRequest(origin: "SFO", destination: "PVG", departureDate: Date())

        let weaker = FlightOffer(
            providerID: "provider-a",
            providerName: "Provider A",
            providerKind: .metasearch,
            route: route,
            totalPrice: 950,
            currencyCode: "USD",
            departureTime: "08:00",
            arrivalTime: "13:00",
            durationText: "13h",
            stops: 1,
            deepLink: URL(string: "https://a.example")!,
            status: .priced,
            confidence: 0.42,
            notes: "",
            collectedAt: Date(),
            baggageIncludedEstimate: true
        )

        let stronger = FlightOffer(
            providerID: "provider-b",
            providerName: "Provider B",
            providerKind: .ota,
            route: route,
            totalPrice: 950,
            currencyCode: "USD",
            departureTime: "08:00",
            arrivalTime: "13:00",
            durationText: "13h",
            stops: 1,
            deepLink: URL(string: "https://b.example")!,
            status: .priced,
            confidence: 0.91,
            notes: "",
            collectedAt: Date(),
            baggageIncludedEstimate: true
        )

        let unique = FlightOffer(
            providerID: "provider-c",
            providerName: "Provider C",
            providerKind: .airline,
            route: route,
            totalPrice: 990,
            currencyCode: "USD",
            departureTime: "09:10",
            arrivalTime: "14:40",
            durationText: "14h",
            stops: 1,
            deepLink: URL(string: "https://c.example")!,
            status: .priced,
            confidence: 0.88,
            notes: "",
            collectedAt: Date(),
            baggageIncludedEstimate: true
        )

        let deduped = OfferDeduplicationService().deduplicate([weaker, stronger, unique])

        #expect(deduped.droppedCount == 1)
        #expect(deduped.offers.count == 2)
        #expect(deduped.offers.contains(where: { $0.providerID == "provider-b" }))
        #expect(!deduped.offers.contains(where: { $0.providerID == "provider-a" }))
    }

    @Test("Session observability aggregates route-level metrics")
    func observabilityAggregation() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end = start.addingTimeInterval(120)

        let routeOne = RouteSearchResult(
            route: RouteRequest(origin: "SFO", destination: "LAX", departureDate: start),
            offers: [],
            startedAt: start,
            endedAt: end,
            observability: RouteObservability(
                providerAttempts: 5,
                offersCollected: 5,
                pricedOffers: 3,
                loginRequiredOffers: 1,
                handoffOffers: 1,
                unavailableOffers: 0,
                deduplicatedOffers: 2,
                averageProviderLatencyMs: 500
            )
        )

        let routeTwo = RouteSearchResult(
            route: RouteRequest(origin: "JFK", destination: "PVG", departureDate: start),
            offers: [],
            startedAt: start,
            endedAt: end,
            observability: RouteObservability(
                providerAttempts: 4,
                offersCollected: 4,
                pricedOffers: 1,
                loginRequiredOffers: 0,
                handoffOffers: 2,
                unavailableOffers: 1,
                deduplicatedOffers: 1,
                averageProviderLatencyMs: 1_000
            )
        )

        let summary = SearchSessionAnalyticsService().buildObservability(
            routeResults: [routeOne, routeTwo],
            startedAt: start,
            endedAt: end
        )

        #expect(summary.routeCount == 2)
        #expect(summary.providerAttempts == 9)
        #expect(summary.pricedOffers == 4)
        #expect(summary.loginRequiredOffers == 1)
        #expect(summary.handoffOffers == 3)
        #expect(summary.unavailableOffers == 1)
        #expect(summary.deduplicatedOffers == 3)
        #expect(abs(summary.averageProviderLatencyMs - 722.22) < 0.5)
    }

    @Test("Watchlist candidates are generated from best priced route offers")
    func watchlistCandidateGeneration() {
        let now = Date()
        let route = RouteRequest(origin: "SEA", destination: "PVG", departureDate: now)

        let best = FlightOffer(
            providerID: "trip",
            providerName: "Trip.com",
            providerKind: .chinaPortal,
            route: route,
            totalPrice: 1_000,
            currencyCode: "USD",
            departureTime: "10:00",
            arrivalTime: "17:00",
            durationText: "13h",
            stops: 1,
            deepLink: URL(string: "https://trip.com")!,
            status: .priced,
            confidence: 0.9,
            notes: "",
            collectedAt: now,
            baggageIncludedEstimate: true
        )

        let result = RouteSearchResult(
            route: route,
            offers: [best],
            startedAt: now,
            endedAt: now,
            observability: .zero
        )

        let candidates = SearchSessionAnalyticsService().buildWatchCandidates(
            routeResults: [result],
            targetDropPercent: 0.1
        )

        #expect(candidates.count == 1)
        #expect(candidates[0].providerID == "trip")
        #expect(candidates[0].observedPrice == 1_000)
        #expect(candidates[0].targetPrice == 900)
    }
}
