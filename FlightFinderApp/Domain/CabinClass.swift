import Foundation

enum CabinClass: String, CaseIterable, Codable, Identifiable {
    case economy = "Economy"
    case premiumEconomy = "Premium Economy"
    case business = "Business"
    case first = "First"

    var id: String { rawValue }

    var queryToken: String {
        switch self {
        case .economy: return "economy"
        case .premiumEconomy: return "premium_economy"
        case .business: return "business"
        case .first: return "first"
        }
    }
}
