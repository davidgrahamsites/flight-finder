import Foundation

struct SearchProgress: Hashable {
    var completedProviders: Int
    var totalProviders: Int
    var routeKey: String
    var providerName: String

    var fraction: Double {
        guard totalProviders > 0 else { return 0 }
        return Double(completedProviders) / Double(totalProviders)
    }
}
