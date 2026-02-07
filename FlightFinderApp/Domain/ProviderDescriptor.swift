import Foundation

struct ProviderDescriptor: Codable, Hashable, Identifiable {
    var id: String
    var name: String
    var homepage: URL
    var kind: ProviderKind
    var capabilities: ProviderCapability
    var supportsAutomatedExtraction: Bool
    var chinaSeedReachability: Double

    init(
        id: String,
        name: String,
        homepage: String,
        kind: ProviderKind,
        capabilities: ProviderCapability = .common,
        supportsAutomatedExtraction: Bool,
        chinaSeedReachability: Double = 0.5
    ) {
        self.id = id
        self.name = name
        self.homepage = URL(string: homepage)!
        self.kind = kind
        self.capabilities = capabilities
        self.supportsAutomatedExtraction = supportsAutomatedExtraction
        self.chinaSeedReachability = min(max(chinaSeedReachability, 0), 1)
    }
}
