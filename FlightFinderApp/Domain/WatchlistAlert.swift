import Foundation

struct WatchlistAlert: Hashable, Identifiable, Sendable {
    var id: UUID = UUID()
    var candidateID: UUID
    var routeKey: String
    var providerID: String
    var providerName: String
    var observedPrice: Double
    var targetPrice: Double
    var currencyCode: String
    var deepLink: URL
    var hitAt: Date

    var dedupeKey: String {
        "\(candidateID.uuidString)|\(providerID)|\(observedPrice)|\(Int(hitAt.timeIntervalSince1970))"
    }
}
