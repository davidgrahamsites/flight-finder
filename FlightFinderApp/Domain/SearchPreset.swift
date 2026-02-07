import Foundation

enum SearchPreset: String, CaseIterable, Identifiable, Codable {
    case usWestCoast = "US West Coast"
    case usaToShanghai = "USA to Shanghai"
    case usTriangle = "US Triangle"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .usWestCoast:
            return "Fast domestic comparison across major west-coast airports."
        case .usaToShanghai:
            return "China-aware routing with PVG focus and aggregator support."
        case .usTriangle:
            return "Three simultaneous domestic routes for schedule/value checks."
        }
    }

    var defaultTripType: TripType {
        switch self {
        case .usWestCoast, .usaToShanghai:
            return .roundTrip
        case .usTriangle:
            return .oneWay
        }
    }

    var defaultSiteAccessMode: SiteAccessMode {
        switch self {
        case .usaToShanghai:
            return .chinaAccessible
        case .usWestCoast, .usTriangle:
            return .global
        }
    }

    var defaultEnabledKinds: Set<ProviderKind> {
        switch self {
        case .usaToShanghai:
            return [.airline, .metasearch, .ota, .chinaPortal]
        case .usWestCoast:
            return [.airline, .metasearch, .ota]
        case .usTriangle:
            return [.airline, .metasearch]
        }
    }

    func makeRoutes(referenceDate: Date = Date()) -> [RouteInputState] {
        let calendar = Calendar.current
        let departure = calendar.date(byAdding: .day, value: 21, to: referenceDate) ?? referenceDate
        let returnDate = calendar.date(byAdding: .day, value: 31, to: referenceDate) ?? departure

        switch self {
        case .usWestCoast:
            return [
                RouteInputState(origin: "SFO", destination: "LAX", departureDate: departure, returnDate: returnDate)
            ]

        case .usaToShanghai:
            return [
                RouteInputState(origin: "SFO", destination: "PVG", departureDate: departure, returnDate: returnDate)
            ]

        case .usTriangle:
            return [
                RouteInputState(origin: "SFO", destination: "JFK", departureDate: departure, returnDate: returnDate),
                RouteInputState(origin: "JFK", destination: "MIA", departureDate: departure, returnDate: returnDate),
                RouteInputState(origin: "MIA", destination: "SFO", departureDate: departure, returnDate: returnDate)
            ]
        }
    }
}
