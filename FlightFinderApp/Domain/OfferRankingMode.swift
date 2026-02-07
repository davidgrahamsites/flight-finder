import Foundation

enum OfferRankingMode: String, Codable, CaseIterable, Identifiable {
    case best
    case cheapest
    case fastest

    var id: String { rawValue }

    var title: String {
        switch self {
        case .best:
            return "Best"
        case .cheapest:
            return "Cheapest"
        case .fastest:
            return "Fastest"
        }
    }
}
