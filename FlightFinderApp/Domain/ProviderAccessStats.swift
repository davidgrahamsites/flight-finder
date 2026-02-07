import Foundation

struct ProviderAccessStats: Codable, Hashable {
    var providerID: String
    var totalChecks: Int
    var successfulChecks: Int
    var consecutiveFailures: Int
    var lastCheckedAt: Date?
    var lastSuccessAt: Date?

    init(
        providerID: String,
        totalChecks: Int = 0,
        successfulChecks: Int = 0,
        consecutiveFailures: Int = 0,
        lastCheckedAt: Date? = nil,
        lastSuccessAt: Date? = nil
    ) {
        self.providerID = providerID
        self.totalChecks = totalChecks
        self.successfulChecks = successfulChecks
        self.consecutiveFailures = consecutiveFailures
        self.lastCheckedAt = lastCheckedAt
        self.lastSuccessAt = lastSuccessAt
    }

    var successRate: Double {
        guard totalChecks > 0 else { return 0.5 }
        return Double(successfulChecks) / Double(totalChecks)
    }

    var weightedChinaReachabilityScore: Double {
        let reliabilityPenalty = min(Double(consecutiveFailures) * 0.08, 0.4)
        return max(0, successRate - reliabilityPenalty)
    }

    mutating func record(reachable: Bool, at date: Date) {
        totalChecks += 1
        lastCheckedAt = date

        if reachable {
            successfulChecks += 1
            consecutiveFailures = 0
            lastSuccessAt = date
        } else {
            consecutiveFailures += 1
        }
    }
}
