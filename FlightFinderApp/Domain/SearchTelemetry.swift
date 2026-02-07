import Foundation

struct OfferAuditEntry: Hashable, Identifiable {
    var id: UUID = UUID()
    var providerID: String
    var providerName: String
    var providerKind: ProviderKind
    var routeKey: String
    var searchMode: String
    var status: FlightOffer.Status
    var startedAt: Date
    var endedAt: Date
    var latencyMs: Double
    var note: String
}

struct RouteObservability: Hashable {
    var providerAttempts: Int
    var offersCollected: Int
    var pricedOffers: Int
    var loginRequiredOffers: Int
    var handoffOffers: Int
    var unavailableOffers: Int
    var deduplicatedOffers: Int
    var averageProviderLatencyMs: Double

    static let zero = RouteObservability(
        providerAttempts: 0,
        offersCollected: 0,
        pricedOffers: 0,
        loginRequiredOffers: 0,
        handoffOffers: 0,
        unavailableOffers: 0,
        deduplicatedOffers: 0,
        averageProviderLatencyMs: 0
    )
}

struct SearchSessionObservability: Hashable {
    var routeCount: Int
    var providerAttempts: Int
    var offersCollected: Int
    var pricedOffers: Int
    var loginRequiredOffers: Int
    var handoffOffers: Int
    var unavailableOffers: Int
    var deduplicatedOffers: Int
    var averageProviderLatencyMs: Double
    var startedAt: Date
    var endedAt: Date

    static let zero = SearchSessionObservability(
        routeCount: 0,
        providerAttempts: 0,
        offersCollected: 0,
        pricedOffers: 0,
        loginRequiredOffers: 0,
        handoffOffers: 0,
        unavailableOffers: 0,
        deduplicatedOffers: 0,
        averageProviderLatencyMs: 0,
        startedAt: Date.distantPast,
        endedAt: Date.distantPast
    )
}
