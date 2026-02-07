import Foundation

enum SiteAccessMode: String, CaseIterable, Codable, Identifiable {
    case global = "Global Sites"
    case chinaAccessible = "China Accessible Sites Mode"

    var id: String { rawValue }
}
