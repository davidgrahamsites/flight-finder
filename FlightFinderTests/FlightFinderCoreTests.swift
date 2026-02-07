import Foundation
import Testing
@testable import FlightFinder

struct FlightFinderCoreTests {
    @Test("Search request rejects more than 3 routes")
    func routeLimitValidation() throws {
        let now = Date()
        let routes = [
            RouteRequest(origin: "SFO", destination: "LAX", departureDate: now),
            RouteRequest(origin: "JFK", destination: "LHR", departureDate: now),
            RouteRequest(origin: "SEA", destination: "PVG", departureDate: now),
            RouteRequest(origin: "BOS", destination: "HND", departureDate: now)
        ]

        let request = SearchRequest(routes: routes, options: .default, enabledKinds: Set(ProviderKind.allCases))

        do {
            _ = try request.validated(maxRoutes: 3)
            Issue.record("Expected validation to fail for >3 routes")
        } catch let error as SearchValidationError {
            if case .tooManyRoutes(let maxRoutes) = error {
                #expect(maxRoutes == 3)
            } else {
                Issue.record("Unexpected validation error: \\(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \\(error)")
        }
    }

    @Test("Round trip requires return date")
    func roundTripValidation() throws {
        var options = FlightSearchOptions.default
        options.tripType = .roundTrip

        let route = RouteRequest(origin: "SFO", destination: "PVG", departureDate: Date(), returnDate: nil)
        let request = SearchRequest(routes: [route], options: options, enabledKinds: Set(ProviderKind.allCases))

        do {
            _ = try request.validated(maxRoutes: 3)
            Issue.record("Expected validation to fail for missing return date")
        } catch let error as SearchValidationError {
            if case .missingReturnDate = error {
                #expect(true)
            } else {
                Issue.record("Unexpected validation error: \\(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \\(error)")
        }
    }

    @Test("Ranking favors reachable priced option in China mode")
    func rankingChinaMode() {
        var options = FlightSearchOptions.default
        options.siteAccessMode = .chinaAccessible

        let route = RouteRequest(origin: "SFO", destination: "PVG", departureDate: Date())

        let strong = FlightOffer(
            providerID: "trip",
            providerName: "Trip.com",
            providerKind: .chinaPortal,
            route: route,
            totalPrice: 900,
            currencyCode: "USD",
            departureTime: nil,
            arrivalTime: nil,
            durationText: nil,
            stops: 1,
            deepLink: URL(string: "https://us.trip.com")!,
            status: .priced,
            confidence: 0.88,
            chinaReachabilityScore: 0.95,
            notes: "",
            collectedAt: Date(),
            baggageIncludedEstimate: true
        )

        let weak = FlightOffer(
            providerID: "google-flights",
            providerName: "Google Flights",
            providerKind: .metasearch,
            route: route,
            totalPrice: 880,
            currencyCode: "USD",
            departureTime: nil,
            arrivalTime: nil,
            durationText: nil,
            stops: 1,
            deepLink: URL(string: "https://www.google.com/travel/flights")!,
            status: .priced,
            confidence: 0.88,
            chinaReachabilityScore: 0.05,
            notes: "",
            collectedAt: Date(),
            baggageIncludedEstimate: true
        )

        let ranked = OfferRankingService().rank([weak, strong], options: options)
        #expect(ranked.first?.providerID == "trip")
    }

    @Test("Provider access stats learn from repeated checks")
    func providerAccessLearning() {
        var stats = ProviderAccessStats(providerID: "trip")
        let now = Date()

        stats.record(reachable: true, at: now)
        stats.record(reachable: true, at: now)
        stats.record(reachable: false, at: now)

        #expect(stats.totalChecks == 3)
        #expect(stats.successfulChecks == 2)
        #expect(stats.consecutiveFailures == 1)
        #expect(stats.successRate > 0.6)
        #expect(stats.weightedChinaReachabilityScore > 0.2)
    }

    @Test("China planner probe report tracks reachable and blocked providers")
    func chinaPlannerProbeReport() async {
        let reachableURL = URL(string: "https://reachable.example")!
        let blockedURL = URL(string: "https://blocked.example")!

        let providers = [
            makeProvider(
                id: "reachable-provider",
                name: "Reachable Provider",
                homepage: reachableURL,
                kind: .chinaPortal,
                seedReachability: 0.5
            ),
            makeProvider(
                id: "blocked-provider",
                name: "Blocked Provider",
                homepage: blockedURL,
                kind: .metasearch,
                seedReachability: 0.5
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

        let report = await planner.probeAndSnapshot(providers: providers)

        #expect(report.probedCount == 2)
        #expect(report.reachableCount == 1)
        #expect(report.unreachableCount == 1)
        #expect(report.snapshots.count == 2)

        let reachable = report.snapshots.first { $0.providerID == "reachable-provider" }
        let blocked = report.snapshots.first { $0.providerID == "blocked-provider" }
        #expect(reachable?.totalChecks == 1)
        #expect(blocked?.totalChecks == 1)
        #expect((reachable?.successRate ?? 0) > (blocked?.successRate ?? 1))
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
