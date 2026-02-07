import Foundation

struct RouteSearchResult: Hashable, Identifiable {
    var id: UUID = UUID()
    var route: RouteRequest
    var offers: [FlightOffer]
    var startedAt: Date
    var endedAt: Date

    var bestOffer: FlightOffer? {
        offers
            .filter { $0.status == .priced }
            .sorted { (lhs, rhs) in
                (lhs.totalPrice ?? .greatestFiniteMagnitude) < (rhs.totalPrice ?? .greatestFiniteMagnitude)
            }
            .first
    }
}

struct SearchSessionResult: Hashable {
    var routes: [RouteSearchResult]
    var warnings: [String]
    var generatedAt: Date
}
