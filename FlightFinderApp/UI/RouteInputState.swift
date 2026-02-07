import Foundation

struct RouteInputState: Identifiable, Codable, Hashable {
    var id: UUID
    var origin: String
    var destination: String
    var departureDate: Date
    var returnDate: Date

    init(
        id: UUID = UUID(),
        origin: String = "",
        destination: String = "",
        departureDate: Date = Date(),
        returnDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    ) {
        self.id = id
        self.origin = origin
        self.destination = destination
        self.departureDate = departureDate
        self.returnDate = returnDate
    }

    func toRouteRequest(tripType: TripType) -> RouteRequest {
        RouteRequest(
            id: id,
            origin: origin,
            destination: destination,
            departureDate: departureDate,
            returnDate: tripType.requiresReturnDate ? returnDate : nil
        )
    }
}
