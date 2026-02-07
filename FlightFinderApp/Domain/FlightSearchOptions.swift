import Foundation

struct FlightSearchOptions: Codable, Hashable {
    var tripType: TripType
    var rankingMode: OfferRankingMode
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
        rankingMode: .best,
        cabinClass: .economy,
        passengers: PassengerMix(),
        bagPolicy: BagPolicy(),
        siteAccessMode: .global,
        nonStopOnly: false,
        maxStops: nil,
        flexibleDays: 0,
        preferredCurrency: "USD"
    )

    init(
        tripType: TripType,
        rankingMode: OfferRankingMode,
        cabinClass: CabinClass,
        passengers: PassengerMix,
        bagPolicy: BagPolicy,
        siteAccessMode: SiteAccessMode,
        nonStopOnly: Bool,
        maxStops: Int?,
        flexibleDays: Int,
        preferredCurrency: String
    ) {
        self.tripType = tripType
        self.rankingMode = rankingMode
        self.cabinClass = cabinClass
        self.passengers = passengers
        self.bagPolicy = bagPolicy
        self.siteAccessMode = siteAccessMode
        self.nonStopOnly = nonStopOnly
        self.maxStops = maxStops
        self.flexibleDays = flexibleDays
        self.preferredCurrency = preferredCurrency
    }

    private enum CodingKeys: String, CodingKey {
        case tripType
        case rankingMode
        case cabinClass
        case passengers
        case bagPolicy
        case siteAccessMode
        case nonStopOnly
        case maxStops
        case flexibleDays
        case preferredCurrency
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.tripType = try container.decode(TripType.self, forKey: .tripType)
        self.rankingMode = try container.decodeIfPresent(OfferRankingMode.self, forKey: .rankingMode) ?? .best
        self.cabinClass = try container.decode(CabinClass.self, forKey: .cabinClass)
        self.passengers = try container.decode(PassengerMix.self, forKey: .passengers)
        self.bagPolicy = try container.decode(BagPolicy.self, forKey: .bagPolicy)
        self.siteAccessMode = try container.decode(SiteAccessMode.self, forKey: .siteAccessMode)
        self.nonStopOnly = try container.decode(Bool.self, forKey: .nonStopOnly)
        self.maxStops = try container.decodeIfPresent(Int.self, forKey: .maxStops)
        self.flexibleDays = try container.decode(Int.self, forKey: .flexibleDays)
        self.preferredCurrency = try container.decode(String.self, forKey: .preferredCurrency)
    }
}
