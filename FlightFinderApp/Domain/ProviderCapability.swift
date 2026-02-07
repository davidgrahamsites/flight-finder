import Foundation

struct ProviderCapability: OptionSet, Codable, Hashable {
    let rawValue: Int

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    static let oneWay = ProviderCapability(rawValue: 1 << 0)
    static let roundTrip = ProviderCapability(rawValue: 1 << 1)
    static let bags = ProviderCapability(rawValue: 1 << 2)
    static let cabinClass = ProviderCapability(rawValue: 1 << 3)
    static let passengerMix = ProviderCapability(rawValue: 1 << 4)
    static let nonStop = ProviderCapability(rawValue: 1 << 5)
    static let fetchExtraction = ProviderCapability(rawValue: 1 << 6)
    static let loginLikely = ProviderCapability(rawValue: 1 << 7)

    static let common: ProviderCapability = [.oneWay, .roundTrip, .bags, .cabinClass, .passengerMix, .nonStop]
}
