import Foundation

struct OfferRankingService {
    func rank(_ offers: [FlightOffer], options: FlightSearchOptions) -> [FlightOffer] {
        offers.sorted { lhs, rhs in
            score(offer: lhs, options: options) < score(offer: rhs, options: options)
        }
    }

    private func score(offer: FlightOffer, options: FlightSearchOptions) -> Double {
        let fallback = 100_000.0
        let basePrice = offer.totalPrice ?? fallback
        let stopsPenalty = Double(offer.stops ?? 2) * 30
        let statusPenalty: Double

        switch offer.status {
        case .priced:
            statusPenalty = 0
        case .handoffRequired:
            statusPenalty = 250
        case .loginRequired:
            statusPenalty = 450
        case .unavailable:
            statusPenalty = 1_000
        }

        let baggageAdjustment: Double = {
            if options.bagPolicy.checkedBagsPerTraveler == 0 { return 0 }
            return offer.baggageIncludedEstimate ? 0 : Double(options.bagPolicy.checkedBagsPerTraveler) * 35
        }()

        let confidenceAdjustment = (1 - offer.confidence) * 40
        let reachabilityAdjustment: Double = {
            guard options.siteAccessMode == .chinaAccessible else { return 0 }
            let score = offer.chinaReachabilityScore ?? 0.5
            return (1 - score) * 110
        }()

        return basePrice + stopsPenalty + statusPenalty + baggageAdjustment + confidenceAdjustment + reachabilityAdjustment
    }
}
