import Foundation

struct ChinaAccessibilityPlanner {
    struct SelectionResult {
        let providers: [URLTemplateFlightProvider]
        let scores: [String: Double]
        let filteredOutCount: Int
    }

    let learningStore: ProviderAccessLearningStore
    let httpClient: ProviderHTTPClient

    init(
        learningStore: ProviderAccessLearningStore = .shared,
        httpClient: ProviderHTTPClient
    ) {
        self.learningStore = learningStore
        self.httpClient = httpClient
    }

    func rankAndFilter(
        providers: [URLTemplateFlightProvider],
        minimumScore: Double = 0.22
    ) async -> SelectionResult {
        let refreshedScores = await probeAndRefresh(providers: providers)

        let sorted = providers.sorted { lhs, rhs in
            let left = refreshedScores[lhs.descriptor.id] ?? lhs.descriptor.chinaSeedReachability
            let right = refreshedScores[rhs.descriptor.id] ?? rhs.descriptor.chinaSeedReachability

            if left == right {
                return lhs.descriptor.name < rhs.descriptor.name
            }
            return left > right
        }

        let filtered = sorted.filter { provider in
            let score = refreshedScores[provider.descriptor.id] ?? provider.descriptor.chinaSeedReachability
            return score >= minimumScore
        }

        if filtered.count >= 6 {
            return SelectionResult(
                providers: filtered,
                scores: refreshedScores,
                filteredOutCount: max(0, providers.count - filtered.count)
            )
        }

        let fallback = Array(sorted.prefix(min(12, sorted.count)))
        return SelectionResult(
            providers: fallback,
            scores: refreshedScores,
            filteredOutCount: max(0, providers.count - fallback.count)
        )
    }

    private func probeAndRefresh(providers: [URLTemplateFlightProvider]) async -> [String: Double] {
        var scores: [String: Double] = [:]

        await withTaskGroup(of: (String, Bool).self) { group in
            for provider in providers {
                group.addTask {
                    let reachable = await httpClient.probeReachability(url: provider.descriptor.homepage)
                    return (provider.descriptor.id, reachable)
                }
            }

            for await (providerID, reachable) in group {
                await learningStore.record(providerID: providerID, reachable: reachable)
            }
        }

        let records = await learningStore.records(for: providers.map { $0.descriptor.id })
        for provider in providers {
            let learned = records[provider.descriptor.id]?.weightedChinaReachabilityScore ?? 0.5
            let blended = (learned * 0.8) + (provider.descriptor.chinaSeedReachability * 0.2)
            scores[provider.descriptor.id] = blended
        }

        return scores
    }
}
