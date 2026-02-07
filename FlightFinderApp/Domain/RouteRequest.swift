import Foundation

struct RouteRequest: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var origin: String
    var destination: String
    var departureDate: Date
    var returnDate: Date?

    init(
        id: UUID = UUID(),
        origin: String,
        destination: String,
        departureDate: Date,
        returnDate: Date? = nil
    ) {
        self.id = id
        self.origin = RouteRequest.normalizeAirport(origin)
        self.destination = RouteRequest.normalizeAirport(destination)
        self.departureDate = departureDate
        self.returnDate = returnDate
    }

    var routeKey: String {
        "\(origin)-\(destination)-\(DateFormatter.flightDate.string(from: departureDate))"
    }

    static func normalizeAirport(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
    }
}
