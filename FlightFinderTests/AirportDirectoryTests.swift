import Testing
@testable import FlightFinder

struct AirportDirectoryTests {
    @Test("Airport suggestions match IATA prefix")
    func iataPrefixMatch() {
        let suggestions = AirportDirectory.suggestions(matching: "SF", limit: 5)
        #expect(suggestions.contains(where: { $0.code == "SFO" }))
    }

    @Test("Airport suggestions match city text")
    func cityMatch() {
        let suggestions = AirportDirectory.suggestions(matching: "Shanghai", limit: 5)
        #expect(suggestions.contains(where: { $0.code == "PVG" }))
    }

    @Test("Airport suggestions are limited")
    func limitRespected() {
        let suggestions = AirportDirectory.suggestions(matching: "A", limit: 3)
        #expect(suggestions.count <= 3)
    }
}
