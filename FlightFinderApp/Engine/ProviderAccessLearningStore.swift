import Foundation

actor ProviderAccessLearningStore {
    static let shared = ProviderAccessLearningStore()

    private let fileURL: URL
    private var loaded = false
    private var statsByProviderID: [String: ProviderAccessStats] = [:]

    init(filename: String = "provider_access_stats.json") {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let bundleID = Bundle.main.bundleIdentifier ?? "com.antigravity.flightfinder"
        let container = appSupport.appendingPathComponent(bundleID, isDirectory: true)
        self.fileURL = container.appendingPathComponent(filename)
    }

    func record(providerID: String, reachable: Bool, at date: Date = Date()) async {
        await loadIfNeeded()
        var current = statsByProviderID[providerID] ?? ProviderAccessStats(providerID: providerID)
        current.record(reachable: reachable, at: date)
        statsByProviderID[providerID] = current
        persist()
    }

    func score(for providerID: String) async -> Double {
        await loadIfNeeded()
        return statsByProviderID[providerID]?.weightedChinaReachabilityScore ?? 0.5
    }

    func records(for providerIDs: [String]) async -> [String: ProviderAccessStats] {
        await loadIfNeeded()
        var output: [String: ProviderAccessStats] = [:]
        for providerID in providerIDs {
            output[providerID] = statsByProviderID[providerID] ?? ProviderAccessStats(providerID: providerID)
        }
        return output
    }

    private func loadIfNeeded() async {
        guard !loaded else { return }
        loaded = true

        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([String: ProviderAccessStats].self, from: data)
            statsByProviderID = decoded
        } catch {
            statsByProviderID = [:]
        }
    }

    private func persist() {
        do {
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(statsByProviderID)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            // Persistence failure should not break searches.
        }
    }
}
