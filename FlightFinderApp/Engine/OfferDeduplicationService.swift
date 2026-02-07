import Foundation

struct OfferDeduplicationResult {
    var offers: [FlightOffer]
    var droppedCount: Int
}

struct OfferDeduplicationService {
    func deduplicate(_ offers: [FlightOffer]) -> OfferDeduplicationResult {
        guard offers.count > 1 else {
            return OfferDeduplicationResult(offers: offers, droppedCount: 0)
        }

        var deduped: [FlightOffer] = []
        var indexByKey: [DeduplicationKey: Int] = [:]
        var droppedCount = 0

        for offer in offers {
            let key = DeduplicationKey(offer: offer)
            if let existingIndex = indexByKey[key] {
                droppedCount += 1
                let existing = deduped[existingIndex]
                if isPreferred(offer, over: existing) {
                    deduped[existingIndex] = offer
                }
            } else {
                indexByKey[key] = deduped.count
                deduped.append(offer)
            }
        }

        return OfferDeduplicationResult(offers: deduped, droppedCount: droppedCount)
    }

    private func isPreferred(_ candidate: FlightOffer, over current: FlightOffer) -> Bool {
        let candidateStatusRank = statusRank(candidate.status)
        let currentStatusRank = statusRank(current.status)
        if candidateStatusRank != currentStatusRank {
            return candidateStatusRank < currentStatusRank
        }

        let candidateHasPrice = candidate.totalPrice != nil
        let currentHasPrice = current.totalPrice != nil
        if candidateHasPrice != currentHasPrice {
            return candidateHasPrice
        }

        if candidate.confidence != current.confidence {
            return candidate.confidence > current.confidence
        }

        if (candidate.totalPrice ?? .greatestFiniteMagnitude) != (current.totalPrice ?? .greatestFiniteMagnitude) {
            return (candidate.totalPrice ?? .greatestFiniteMagnitude) < (current.totalPrice ?? .greatestFiniteMagnitude)
        }

        return candidate.providerName.localizedStandardCompare(current.providerName) == .orderedAscending
    }

    private func statusRank(_ status: FlightOffer.Status) -> Int {
        switch status {
        case .priced: return 0
        case .handoffRequired: return 1
        case .loginRequired: return 2
        case .unavailable: return 3
        }
    }

    private struct DeduplicationKey: Hashable {
        let routeKey: String
        let departureTime: String
        let arrivalTime: String
        let durationText: String
        let stops: Int
        let currencyCode: String
        let priceBucket: Int

        init(offer: FlightOffer) {
            self.routeKey = offer.route.routeKey
            self.departureTime = offer.departureTime ?? ""
            self.arrivalTime = offer.arrivalTime ?? ""
            self.durationText = offer.durationText ?? ""
            self.stops = offer.stops ?? -1
            self.currencyCode = offer.currencyCode

            if let price = offer.totalPrice {
                self.priceBucket = Int((price * 2).rounded())
            } else {
                self.priceBucket = Int.min
            }
        }
    }
}
