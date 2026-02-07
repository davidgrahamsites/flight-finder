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
    var origin: String? = nil
    var destination: String? = nil
    var departureDate: Date? = nil
    var returnDate: Date? = nil
}

extension WatchCandidate {
    var resolvedOrigin: String? {
        origin ?? parsedRouteKey?.origin
    }

    var resolvedDestination: String? {
        destination ?? parsedRouteKey?.destination
    }

    var resolvedDepartureDate: Date? {
        departureDate ?? parsedRouteKey?.departureDate
    }

    var tripTypeHint: TripType {
        returnDate == nil ? .oneWay : .roundTrip
    }

    func toRouteRequest() -> RouteRequest? {
        guard
            let resolvedOrigin,
            let resolvedDestination,
            let resolvedDepartureDate
        else {
            return nil
        }

        return RouteRequest(
            origin: resolvedOrigin,
            destination: resolvedDestination,
            departureDate: resolvedDepartureDate,
            returnDate: returnDate
        )
    }

    var routeIdentityKey: String {
        guard
            let route = toRouteRequest()
        else {
            return "\(routeKey)|\(tripTypeHint.rawValue)"
        }

        let departure = DateFormatter.flightDate.string(from: route.departureDate)
        let returnValue = route.returnDate.map { DateFormatter.flightDate.string(from: $0) } ?? "oneway"
        return "\(route.origin)-\(route.destination)-\(departure)-\(returnValue)"
    }

    private var parsedRouteKey: ParsedRouteKey? {
        let parts = routeKey.split(separator: "-", omittingEmptySubsequences: true)
        guard parts.count >= 5 else { return nil }

        let originPart = String(parts[0])
        let destinationPart = String(parts[1])
        let dateString = "\(parts[2])-\(parts[3])-\(parts[4])"
        guard let date = DateFormatter.flightDate.date(from: dateString) else { return nil }

        return ParsedRouteKey(
            origin: RouteRequest.normalizeAirport(originPart),
            destination: RouteRequest.normalizeAirport(destinationPart),
            departureDate: date
        )
    }
}

private struct ParsedRouteKey {
    let origin: String
    let destination: String
    let departureDate: Date
}
