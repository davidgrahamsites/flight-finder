import Foundation

struct SavedSearchConfig: Codable, Hashable {
    var routes: [RouteInputState]
    var options: FlightSearchOptions
    var enabledKinds: Set<ProviderKind>
    var lastPreset: SearchPreset?
    var watchlist: [WatchCandidate]
    var autoWatchlistRecheckEnabled: Bool
    var autoWatchlistRecheckIntervalMinutes: Int
    var watchlistNotificationsEnabled: Bool

    init(
        routes: [RouteInputState],
        options: FlightSearchOptions,
        enabledKinds: Set<ProviderKind>,
        lastPreset: SearchPreset?,
        watchlist: [WatchCandidate] = [],
        autoWatchlistRecheckEnabled: Bool = false,
        autoWatchlistRecheckIntervalMinutes: Int = 30,
        watchlistNotificationsEnabled: Bool = true
    ) {
        self.routes = routes
        self.options = options
        self.enabledKinds = enabledKinds
        self.lastPreset = lastPreset
        self.watchlist = watchlist
        self.autoWatchlistRecheckEnabled = autoWatchlistRecheckEnabled
        self.autoWatchlistRecheckIntervalMinutes = autoWatchlistRecheckIntervalMinutes
        self.watchlistNotificationsEnabled = watchlistNotificationsEnabled
    }

    private enum CodingKeys: String, CodingKey {
        case routes
        case options
        case enabledKinds
        case lastPreset
        case watchlist
        case autoWatchlistRecheckEnabled
        case autoWatchlistRecheckIntervalMinutes
        case watchlistNotificationsEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.routes = try container.decode([RouteInputState].self, forKey: .routes)
        self.options = try container.decode(FlightSearchOptions.self, forKey: .options)
        self.enabledKinds = try container.decode(Set<ProviderKind>.self, forKey: .enabledKinds)
        self.lastPreset = try container.decodeIfPresent(SearchPreset.self, forKey: .lastPreset)
        self.watchlist = try container.decodeIfPresent([WatchCandidate].self, forKey: .watchlist) ?? []
        self.autoWatchlistRecheckEnabled = try container.decodeIfPresent(Bool.self, forKey: .autoWatchlistRecheckEnabled) ?? false
        self.autoWatchlistRecheckIntervalMinutes = try container.decodeIfPresent(Int.self, forKey: .autoWatchlistRecheckIntervalMinutes) ?? 30
        self.watchlistNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .watchlistNotificationsEnabled) ?? true
    }
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
