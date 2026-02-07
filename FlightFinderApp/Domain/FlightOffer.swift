import Foundation

struct FlightOffer: Identifiable, Hashable {
    enum Status: String, Hashable {
        case priced
        case handoffRequired
        case loginRequired
        case unavailable
    }

    var id: UUID = UUID()
    var providerID: String
    var providerName: String
    var providerKind: ProviderKind
    var route: RouteRequest
    var totalPrice: Double?
    var currencyCode: String
    var departureTime: String?
    var arrivalTime: String?
    var durationText: String?
    var stops: Int?
    var deepLink: URL
    var status: Status
    var confidence: Double
    var chinaReachabilityScore: Double? = nil
    var notes: String
    var collectedAt: Date
    var baggageIncludedEstimate: Bool

    var normalizedPrice: Double? {
        totalPrice
    }
}
