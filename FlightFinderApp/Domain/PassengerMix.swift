import Foundation

struct PassengerMix: Codable, Hashable {
    var adults: Int
    var children: Int
    var infants: Int

    init(adults: Int = 1, children: Int = 0, infants: Int = 0) {
        self.adults = max(1, adults)
        self.children = max(0, children)
        self.infants = max(0, infants)
    }

    var total: Int {
        adults + children + infants
    }
}
