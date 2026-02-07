import Foundation

struct WatchlistRecheckPlan: Hashable {
    var routes: [RouteRequest]
    var tripType: TripType
    var skippedByTripType: Int
    var truncatedRoutes: Int
}
