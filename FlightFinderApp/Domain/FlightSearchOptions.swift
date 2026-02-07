import Foundation

struct FlightSearchOptions: Codable, Hashable {
    var tripType: TripType
    var cabinClass: CabinClass
    var passengers: PassengerMix
    var bagPolicy: BagPolicy
    var siteAccessMode: SiteAccessMode
    var nonStopOnly: Bool
    var maxStops: Int?
    var flexibleDays: Int
    var preferredCurrency: String

    static let `default` = FlightSearchOptions(
        tripType: .roundTrip,
        cabinClass: .economy,
        passengers: PassengerMix(),
        bagPolicy: BagPolicy(),
        siteAccessMode: .global,
        nonStopOnly: false,
        maxStops: nil,
        flexibleDays: 0,
        preferredCurrency: "USD"
    )
}
