import Foundation

struct WatchCandidate: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var routeKey: String
    var providerID: String
    var providerName: String
    var deepLink: URL
    var currencyCode: String
    var observedPrice: Double
    var targetPrice: Double
    var lastSeenAt: Date
}
