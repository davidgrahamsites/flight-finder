import Foundation

struct SavedSearchConfig: Codable, Hashable {
    var routes: [RouteInputState]
    var options: FlightSearchOptions
    var enabledKinds: Set<ProviderKind>
    var lastPreset: SearchPreset?
}

protocol SearchPreferencesStore {
    func load() -> SavedSearchConfig?
    func save(_ config: SavedSearchConfig)
}

struct UserDefaultsSearchPreferencesStore: SearchPreferencesStore {
    private let defaults: UserDefaults
    private let key: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        defaults: UserDefaults = .standard,
        key: String = "com.antigravity.flightfinder.saved-search-config"
    ) {
        self.defaults = defaults
        self.key = key
    }

    func load() -> SavedSearchConfig? {
        guard let data = defaults.data(forKey: key) else { return nil }
        do {
            return try decoder.decode(SavedSearchConfig.self, from: data)
        } catch {
            return nil
        }
    }

    func save(_ config: SavedSearchConfig) {
        do {
            let data = try encoder.encode(config)
            defaults.set(data, forKey: key)
        } catch {
            // Persistence failures should not break searching.
        }
    }
}
