import Foundation

struct SearchRequest: Codable, Hashable {
    var routes: [RouteRequest]
    var options: FlightSearchOptions
    var enabledKinds: Set<ProviderKind>

    func validated(maxRoutes: Int = 3) throws -> SearchRequest {
        let activeRoutes = routes.filter { !$0.origin.isEmpty && !$0.destination.isEmpty }

        guard !activeRoutes.isEmpty else {
            throw SearchValidationError.emptyRoutes
        }

        guard activeRoutes.count <= maxRoutes else {
            throw SearchValidationError.tooManyRoutes(maxRoutes: maxRoutes)
        }

        let normalizedRoutes = activeRoutes.map { route in
            RouteRequest(
                id: route.id,
                origin: route.origin,
                destination: route.destination,
                departureDate: route.departureDate,
                returnDate: options.tripType.requiresReturnDate ? route.returnDate : nil
            )
        }

        guard normalizedRoutes.allSatisfy({ !$0.origin.isEmpty && !$0.destination.isEmpty }) else {
            throw SearchValidationError.invalidAirportCode
        }

        if options.tripType.requiresReturnDate {
            let missingReturn = normalizedRoutes.contains { $0.returnDate == nil }
            if missingReturn {
                throw SearchValidationError.missingReturnDate
            }
        }

        return SearchRequest(routes: normalizedRoutes, options: options, enabledKinds: enabledKinds)
    }
}

enum SearchValidationError: LocalizedError {
    case emptyRoutes
    case tooManyRoutes(maxRoutes: Int)
    case invalidAirportCode
    case missingReturnDate

    var errorDescription: String? {
        switch self {
        case .emptyRoutes:
            return "Add at least one valid route to search."
        case .tooManyRoutes(let maxRoutes):
            return "You can search up to \(maxRoutes) routes simultaneously."
        case .invalidAirportCode:
            return "A route is missing an origin or destination airport code."
        case .missingReturnDate:
            return "Round-trip searches require a return date for each route."
        }
    }
}
