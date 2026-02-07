import Foundation

enum TripType: String, CaseIterable, Codable, Identifiable {
    case oneWay = "One Way"
    case roundTrip = "Round Trip"

    var id: String { rawValue }

    var requiresReturnDate: Bool {
        self == .roundTrip
    }
}
