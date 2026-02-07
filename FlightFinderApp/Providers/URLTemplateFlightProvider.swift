import Foundation

typealias ProviderURLBuilder = @Sendable (_ route: RouteRequest, _ options: FlightSearchOptions) -> URL

struct URLTemplateFlightProvider: Sendable, Identifiable {
    enum SearchMode: Sendable {
        case deeplinkOnly
        case fetchAndExtract
    }

    var id: String { descriptor.id }
    let descriptor: ProviderDescriptor
    let searchMode: SearchMode
    let buildURL: ProviderURLBuilder

    func search(
        route: RouteRequest,
        options: FlightSearchOptions,
        httpClient: ProviderHTTPClient
    ) async -> FlightOffer {
        let url = buildURL(route, options)

        switch searchMode {
        case .deeplinkOnly:
            return FlightOffer(
                providerID: descriptor.id,
                providerName: descriptor.name,
                providerKind: descriptor.kind,
                route: route,
                totalPrice: nil,
                currencyCode: options.preferredCurrency,
                departureTime: nil,
                arrivalTime: nil,
                durationText: nil,
                stops: nil,
                deepLink: url,
                status: .handoffRequired,
                confidence: 0.05,
                notes: "Direct handoff link generated; provider UI interaction required.",
                collectedAt: Date(),
                baggageIncludedEstimate: options.bagPolicy.checkedBagsPerTraveler == 0
            )

        case .fetchAndExtract:
            do {
                let html = try await httpClient.fetchHTML(from: url)
                let extracted = PriceExtraction.extract(from: html, preferredCurrency: options.preferredCurrency)

                let status: FlightOffer.Status
                if extracted.loginLikely {
                    status = .loginRequired
                } else if extracted.price != nil {
                    status = .priced
                } else {
                    status = .handoffRequired
                }

                let bagEstimate = extracted.price.map {
                    estimateBaggageIncluded(price: $0, options: options)
                } ?? (options.bagPolicy.checkedBagsPerTraveler == 0)

                return FlightOffer(
                    providerID: descriptor.id,
                    providerName: descriptor.name,
                    providerKind: descriptor.kind,
                    route: route,
                    totalPrice: extracted.price,
                    currencyCode: extracted.currency,
                    departureTime: extracted.departureTime,
                    arrivalTime: extracted.arrivalTime,
                    durationText: extracted.durationText,
                    stops: extracted.stops,
                    deepLink: url,
                    status: status,
                    confidence: extracted.confidence,
                    notes: extracted.notes,
                    collectedAt: Date(),
                    baggageIncludedEstimate: bagEstimate
                )
            } catch {
                return FlightOffer(
                    providerID: descriptor.id,
                    providerName: descriptor.name,
                    providerKind: descriptor.kind,
                    route: route,
                    totalPrice: nil,
                    currencyCode: options.preferredCurrency,
                    departureTime: nil,
                    arrivalTime: nil,
                    durationText: nil,
                    stops: nil,
                    deepLink: url,
                    status: .unavailable,
                    confidence: 0,
                    notes: "Automated fetch failed: \(error.localizedDescription)",
                    collectedAt: Date(),
                    baggageIncludedEstimate: options.bagPolicy.checkedBagsPerTraveler == 0
                )
            }
        }
    }

    private func estimateBaggageIncluded(price: Double, options: FlightSearchOptions) -> Bool {
        if options.bagPolicy.checkedBagsPerTraveler == 0 {
            return true
        }

        let threshold = 120.0 + (Double(options.bagPolicy.checkedBagsPerTraveler) * 30)
        return price >= threshold
    }
}
