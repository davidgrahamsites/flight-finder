import Foundation

struct BagPolicy: Codable, Hashable {
    var checkedBagsPerTraveler: Int
    var carryOnIncluded: Bool

    init(checkedBagsPerTraveler: Int = 0, carryOnIncluded: Bool = true) {
        self.checkedBagsPerTraveler = max(0, checkedBagsPerTraveler)
        self.carryOnIncluded = carryOnIncluded
    }
}
