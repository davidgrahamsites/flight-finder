import Foundation

struct OfferRankingService {
    func rank(_ offers: [FlightOffer], options: FlightSearchOptions) -> [FlightOffer] {
        offers.sorted { lhs, rhs in
            let leftScore = score(offer: lhs, options: options)
            let rightScore = score(offer: rhs, options: options)

            if leftScore == rightScore {
                let leftPrice = lhs.totalPrice ?? 100_000
                let rightPrice = rhs.totalPrice ?? 100_000
                if leftPrice == rightPrice {
                    return lhs.providerName < rhs.providerName
                }
                return leftPrice < rightPrice
            }

            return leftScore < rightScore
        }
    }

    private func score(offer: FlightOffer, options: FlightSearchOptions) -> Double {
        switch options.rankingMode {
        case .best:
            return bestScore(offer: offer, options: options)
        case .cheapest:
            return cheapestScore(offer: offer, options: options)
        case .fastest:
            return fastestScore(offer: offer, options: options)
        }
    }

    private func bestScore(offer: FlightOffer, options: FlightSearchOptions) -> Double {
        let basePrice = offer.totalPrice ?? 100_000
        let stopsPenalty = Double(offer.stops ?? 2) * 30
        return basePrice
            + stopsPenalty
            + statusPenalty(for: offer.status)
            + baggageAdjustment(offer: offer, options: options)
            + confidenceAdjustment(for: offer.confidence)
            + reachabilityAdjustment(offer: offer, options: options)
    }

    private func cheapestScore(offer: FlightOffer, options: FlightSearchOptions) -> Double {
        let basePrice = offer.totalPrice ?? 100_000
        let stopsPenalty = Double(offer.stops ?? 2) * 15
        return basePrice
            + stopsPenalty
            + (statusPenalty(for: offer.status) * 0.9)
            + (baggageAdjustment(offer: offer, options: options) * 0.6)
            + (confidenceAdjustment(for: offer.confidence) * 0.5)
            + (reachabilityAdjustment(offer: offer, options: options) * 0.5)
    }

    private func fastestScore(offer: FlightOffer, options: FlightSearchOptions) -> Double {
        let durationMinutes = durationScore(for: offer.durationText)
        let stopsPenalty = Double(offer.stops ?? 2) * 40
        let priceAdjustment = (offer.totalPrice ?? 100_000) * 0.03
        return durationMinutes
            + stopsPenalty
            + (statusPenalty(for: offer.status) * 1.2)
            + priceAdjustment
            + (reachabilityAdjustment(offer: offer, options: options) * 0.5)
    }

    private func statusPenalty(for status: FlightOffer.Status) -> Double {
        switch status {
        case .priced:
            return 0
        case .handoffRequired:
            return 250
        case .loginRequired:
            return 450
        case .unavailable:
            return 1_000
        }
    }

    private func baggageAdjustment(offer: FlightOffer, options: FlightSearchOptions) -> Double {
        guard options.bagPolicy.checkedBagsPerTraveler > 0 else { return 0 }
        return offer.baggageIncludedEstimate ? 0 : Double(options.bagPolicy.checkedBagsPerTraveler) * 35
    }

    private func confidenceAdjustment(for confidence: Double) -> Double {
        (1 - confidence) * 40
    }

    private func reachabilityAdjustment(offer: FlightOffer, options: FlightSearchOptions) -> Double {
        guard options.siteAccessMode == .chinaAccessible else { return 0 }
        let score = offer.chinaReachabilityScore ?? 0.5
        return (1 - score) * 110
    }

    private func durationScore(for durationText: String?) -> Double {
        guard let durationText else { return 10_000 }

        let lowered = durationText.lowercased()
        let regex = try? NSRegularExpression(pattern: #"([0-9]{1,2})h(?:\s*([0-9]{1,2})m)?"#)
        let range = NSRange(lowered.startIndex..., in: lowered)
        if let match = regex?.firstMatch(in: lowered, range: range) {
            var hours = 0
            var minutes = 0
            if let hourRange = Range(match.range(at: 1), in: lowered) {
                hours = Int(lowered[hourRange]) ?? 0
            }
            if let minuteRange = Range(match.range(at: 2), in: lowered), !minuteRange.isEmpty {
                minutes = Int(lowered[minuteRange]) ?? 0
            }
            return Double((hours * 60) + minutes)
        }

        let minutesRegex = try? NSRegularExpression(pattern: #"([0-9]{2,4})m"#)
        if let minuteMatch = minutesRegex?.firstMatch(in: lowered, range: range),
           let minuteRange = Range(minuteMatch.range(at: 1), in: lowered) {
            return Double(Int(lowered[minuteRange]) ?? 10_000)
        }

        return 10_000
    }
}
