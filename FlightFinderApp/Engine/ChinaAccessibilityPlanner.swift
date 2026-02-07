import Foundation

struct ChinaAccessibilityPlanner {
    struct SelectionResult {
        let providers: [URLTemplateFlightProvider]
        let scores: [String: Double]
        let filteredOutCount: Int
    }

    struct ProviderSnapshot: Sendable, Identifiable {
        var id: String { providerID }
        let providerID: String
        let providerName: String
        let providerKind: ProviderKind
        let homepage: URL
        let blendedScore: Double
        let seedReachability: Double
        let learnedScore: Double
        let successRate: Double
        let totalChecks: Int
        let lastCheckedAt: Date?
        let lastReachableAt: Date?
    }

    struct ProbeReport: Sendable {
        let snapshots: [ProviderSnapshot]
        let outcomesByProviderID: [String: Bool]

        var probedCount: Int {
            outcomesByProviderID.count
        }

        var reachableCount: Int {
            outcomesByProviderID.values.filter { $0 }.count
        }

        var unreachableCount: Int {
            probedCount - reachableCount
        }
    }

    let learningStore: ProviderAccessLearningStore
    let reachabilityProber: any ProviderReachabilityProbing

    init(
        learningStore: ProviderAccessLearningStore = .shared,
        reachabilityProber: any ProviderReachabilityProbing
    ) {
        self.learningStore = learningStore
        self.reachabilityProber = reachabilityProber
    }

    init(
        learningStore: ProviderAccessLearningStore = .shared,
        httpClient: ProviderHTTPClient
    ) {
        self.init(learningStore: learningStore, reachabilityProber: httpClient)
    }

    func rankAndFilter(
        providers: [URLTemplateFlightProvider],
        minimumScore: Double = 0.22
    ) async -> SelectionResult {
        let report = await probeAndSnapshot(providers: providers)
        let refreshedScores = Dictionary(uniqueKeysWithValues: report.snapshots.map { ($0.providerID, $0.blendedScore) })

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

    func snapshots(providers: [URLTemplateFlightProvider]) async -> [ProviderSnapshot] {
        guard !providers.isEmpty else { return [] }
        let records = await learningStore.records(for: providers.map(\.descriptor.id))
        return makeSnapshots(providers: providers, records: records)
    }

    func probeAndSnapshot(providers: [URLTemplateFlightProvider]) async -> ProbeReport {
        guard !providers.isEmpty else {
            return ProbeReport(snapshots: [], outcomesByProviderID: [:])
        }

        var outcomes: [String: Bool] = [:]
        await withTaskGroup(of: (String, Bool).self) { group in
            for provider in providers {
                group.addTask {
                    let reachable = await reachabilityProber.probeReachability(url: provider.descriptor.homepage)
                    return (provider.descriptor.id, reachable)
                }
            }

            for await (providerID, reachable) in group {
                outcomes[providerID] = reachable
                await learningStore.record(providerID: providerID, reachable: reachable)
            }
        }

        let snapshots = await snapshots(providers: providers)
        return ProbeReport(snapshots: snapshots, outcomesByProviderID: outcomes)
    }

    private func makeSnapshots(
        providers: [URLTemplateFlightProvider],
        records: [String: ProviderAccessStats]
    ) -> [ProviderSnapshot] {
        providers.map { provider in
            let stats = records[provider.descriptor.id] ?? ProviderAccessStats(providerID: provider.descriptor.id)
            let learned = stats.weightedChinaReachabilityScore
            let blended = blendedScore(learned: learned, seed: provider.descriptor.chinaSeedReachability)

            return ProviderSnapshot(
                providerID: provider.descriptor.id,
                providerName: provider.descriptor.name,
                providerKind: provider.descriptor.kind,
                homepage: provider.descriptor.homepage,
                blendedScore: blended,
                seedReachability: provider.descriptor.chinaSeedReachability,
                learnedScore: learned,
                successRate: stats.successRate,
                totalChecks: stats.totalChecks,
                lastCheckedAt: stats.lastCheckedAt,
                lastReachableAt: stats.lastSuccessAt
            )
        }
        .sorted { lhs, rhs in
            if lhs.blendedScore == rhs.blendedScore {
                return lhs.providerName < rhs.providerName
            }
            return lhs.blendedScore > rhs.blendedScore
        }
    }

    private func blendedScore(learned: Double, seed: Double) -> Double {
        (learned * 0.8) + (seed * 0.2)
    }
}
