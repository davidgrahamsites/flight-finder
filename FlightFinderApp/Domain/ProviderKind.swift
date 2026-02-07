import Foundation

enum ProviderKind: String, CaseIterable, Codable, Identifiable {
    case airline = "Airline"
    case metasearch = "Metasearch"
    case ota = "OTA"
    case chinaPortal = "China Portal"

    var id: String { rawValue }
}
