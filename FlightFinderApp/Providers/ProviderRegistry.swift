import Foundation

struct ProviderRegistry {
    static func makeDefaultProviders() -> [URLTemplateFlightProvider] {
        providerSeeds().map { seed in
            URLTemplateFlightProvider(
                descriptor: seed.descriptor,
                searchMode: seed.searchMode,
                buildURL: seed.builder
            )
        }
    }

    private struct ProviderSeed {
        let descriptor: ProviderDescriptor
        let searchMode: URLTemplateFlightProvider.SearchMode
        let builder: ProviderURLBuilder
    }

    private static func providerSeeds() -> [ProviderSeed] {
        [
            // Major US carriers
            makeAirline(id: "american", name: "American Airlines", homepage: "https://www.aa.com", searchURL: "https://www.aa.com/booking/find-flights"),
            makeAirline(id: "delta", name: "Delta Air Lines", homepage: "https://www.delta.com", searchURL: "https://www.delta.com/flight-search/book-a-flight"),
            makeAirline(id: "united", name: "United Airlines", homepage: "https://www.united.com", searchURL: "https://www.united.com/en/us/fsr/choose-flights"),
            makeAirline(id: "southwest", name: "Southwest", homepage: "https://www.southwest.com", searchURL: "https://www.southwest.com/air/booking/select"),
            makeAirline(id: "alaska", name: "Alaska Airlines", homepage: "https://www.alaskaair.com", searchURL: "https://www.alaskaair.com/Shopping/Flights"),
            makeAirline(id: "jetblue", name: "JetBlue", homepage: "https://www.jetblue.com", searchURL: "https://www.jetblue.com/booking/flights"),

            // Budget carriers
            makeAirline(id: "spirit", name: "Spirit Airlines", homepage: "https://www.spirit.com", searchURL: "https://www.spirit.com/book"),
            makeAirline(id: "frontier", name: "Frontier Airlines", homepage: "https://www.flyfrontier.com", searchURL: "https://www.flyfrontier.com"),
            makeAirline(id: "allegiant", name: "Allegiant Air", homepage: "https://www.allegiantair.com", searchURL: "https://www.allegiantair.com"),
            makeAirline(id: "avelo", name: "Avelo Airlines", homepage: "https://www.aveloair.com", searchURL: "https://www.aveloair.com"),
            makeAirline(id: "breeze", name: "Breeze Airways", homepage: "https://www.flybreeze.com", searchURL: "https://www.flybreeze.com"),
            makeAirline(id: "sun-country", name: "Sun Country Airlines", homepage: "https://www.suncountry.com", searchURL: "https://www.suncountry.com"),
            makeAirline(id: "hawaiian", name: "Hawaiian Airlines", homepage: "https://www.hawaiianairlines.com", searchURL: "https://www.hawaiianairlines.com/book"),
            makeAirline(id: "silver", name: "Silver Airways", homepage: "https://www.silverairways.com", searchURL: "https://www.silverairways.com"),
            makeAirline(id: "cape-air", name: "Cape Air", homepage: "https://www.capeair.com", searchURL: "https://www.capeair.com"),
            makeAirline(id: "jsx", name: "JSX", homepage: "https://www.jsx.com", searchURL: "https://www.jsx.com"),

            // China / international airlines
            makeAirline(id: "china-eastern", name: "China Eastern", homepage: "https://us.ceair.com", searchURL: "https://us.ceair.com", chinaSeedReachability: 0.94),
            makeAirline(id: "air-china", name: "Air China", homepage: "https://www.airchina.com.cn", searchURL: "https://www.airchina.com.cn", chinaSeedReachability: 0.94),
            makeAirline(id: "china-southern", name: "China Southern", homepage: "https://www.csair.com", searchURL: "https://www.csair.com", chinaSeedReachability: 0.94),
            makeAirline(id: "hainan", name: "Hainan Airlines", homepage: "https://www.hnair.com", searchURL: "https://www.hnair.com", chinaSeedReachability: 0.93),
            makeAirline(id: "juneyao", name: "Juneyao Airlines", homepage: "https://www.juneyaoair.com", searchURL: "https://www.juneyaoair.com", chinaSeedReachability: 0.92),
            makeAirline(id: "shenzhen", name: "Shenzhen Airlines", homepage: "https://www.shenzhenair.com", searchURL: "https://www.shenzhenair.com", chinaSeedReachability: 0.93),
            makeAirline(id: "shandong", name: "Shandong Airlines", homepage: "https://www.sda.cn", searchURL: "https://www.sda.cn", chinaSeedReachability: 0.93),
            makeAirline(id: "china-united", name: "China United Airlines", homepage: "https://www.flycua.com", searchURL: "https://www.flycua.com", chinaSeedReachability: 0.92),
            makeAirline(id: "cathay", name: "Cathay Pacific", homepage: "https://www.cathaypacific.com", searchURL: "https://www.cathaypacific.com"),
            makeAirline(id: "korean-air", name: "Korean Air", homepage: "https://www.koreanair.com", searchURL: "https://www.koreanair.com"),
            makeAirline(id: "asiana", name: "Asiana Airlines", homepage: "https://www.flyasiana.com", searchURL: "https://www.flyasiana.com"),
            makeAirline(id: "eva-air", name: "EVA Air", homepage: "https://www.evaair.com", searchURL: "https://www.evaair.com"),
            makeAirline(id: "starlux", name: "STARLUX Airlines", homepage: "https://www.starlux-airlines.com", searchURL: "https://www.starlux-airlines.com"),
            makeAirline(id: "ana", name: "ANA", homepage: "https://www.ana.co.jp", searchURL: "https://www.ana.co.jp"),
            makeAirline(id: "jal", name: "Japan Airlines", homepage: "https://www.jal.co.jp", searchURL: "https://www.jal.co.jp"),
            makeAirline(id: "singapore", name: "Singapore Airlines", homepage: "https://www.singaporeair.com", searchURL: "https://www.singaporeair.com"),
            makeAirline(id: "emirates", name: "Emirates", homepage: "https://www.emirates.com", searchURL: "https://www.emirates.com"),
            makeAirline(id: "qatar", name: "Qatar Airways", homepage: "https://www.qatarairways.com", searchURL: "https://www.qatarairways.com"),
            makeAirline(id: "turkish", name: "Turkish Airlines", homepage: "https://www.turkishairlines.com", searchURL: "https://www.turkishairlines.com"),
            makeAirline(id: "air-canada", name: "Air Canada", homepage: "https://www.aircanada.com", searchURL: "https://www.aircanada.com"),
            makeAirline(id: "lufthansa", name: "Lufthansa", homepage: "https://www.lufthansa.com", searchURL: "https://www.lufthansa.com"),
            makeAirline(id: "swiss", name: "SWISS", homepage: "https://www.swiss.com", searchURL: "https://www.swiss.com"),
            makeAirline(id: "austrian", name: "Austrian Airlines", homepage: "https://www.austrian.com", searchURL: "https://www.austrian.com"),
            makeAirline(id: "ba", name: "British Airways", homepage: "https://www.ba.com", searchURL: "https://www.ba.com"),
            makeAirline(id: "air-france", name: "Air France", homepage: "https://www.airfrance.com", searchURL: "https://www.airfrance.com"),
            makeAirline(id: "klm", name: "KLM", homepage: "https://www.klm.com", searchURL: "https://www.klm.com"),
            makeAirline(id: "finnair", name: "Finnair", homepage: "https://www.finnair.com", searchURL: "https://www.finnair.com"),

            // Metasearch and aggregators
            makeMeta(id: "google-flights", name: "Google Flights", homepage: "https://www.google.com/travel/flights", chinaSeedReachability: 0.05, builder: googleFlightsBuilder),
            makeMeta(id: "kayak", name: "KAYAK", homepage: "https://www.kayak.com/flights", chinaSeedReachability: 0.35, builder: kayakBuilder),
            makeMeta(id: "skyscanner", name: "Skyscanner", homepage: "https://www.skyscanner.com", chinaSeedReachability: 0.72, builder: skyscannerBuilder),
            makeMeta(id: "momondo", name: "momondo", homepage: "https://www.momondo.com", chinaSeedReachability: 0.32, builder: momondoBuilder),
            makeMeta(id: "kiwi", name: "Kiwi.com", homepage: "https://www.kiwi.com", chinaSeedReachability: 0.5, builder: kiwiBuilder),
            makeMeta(id: "wego", name: "Wego", homepage: "https://www.wego.com/airlines", chinaSeedReachability: 0.62, builder: genericBuilder(base: URL(string: "https://www.wego.com/flights")!)),

            // OTAs
            makeOTA(id: "expedia", name: "Expedia", homepage: "https://www.expedia.com/Flights", chinaSeedReachability: 0.3, builder: genericBuilder(base: URL(string: "https://www.expedia.com/Flights")!)),
            makeOTA(id: "priceline", name: "Priceline", homepage: "https://www.priceline.com", chinaSeedReachability: 0.3, builder: genericBuilder(base: URL(string: "https://www.priceline.com")!)),
            makeOTA(id: "orbitz", name: "Orbitz", homepage: "https://www.orbitz.com", chinaSeedReachability: 0.28, builder: genericBuilder(base: URL(string: "https://www.orbitz.com")!)),
            makeOTA(id: "travelocity", name: "Travelocity", homepage: "https://www.travelocity.com", chinaSeedReachability: 0.28, builder: genericBuilder(base: URL(string: "https://www.travelocity.com")!)),
            makeOTA(id: "cheapoair", name: "CheapOair", homepage: "https://www.cheapoair.com", chinaSeedReachability: 0.35, builder: genericBuilder(base: URL(string: "https://www.cheapoair.com")!)),
            makeOTA(id: "onetravel", name: "OneTravel", homepage: "https://www.onetravel.com", chinaSeedReachability: 0.35, builder: genericBuilder(base: URL(string: "https://www.onetravel.com")!)),
            makeOTA(id: "agoda", name: "Agoda", homepage: "https://www.agoda.com/flights", chinaSeedReachability: 0.72, builder: genericBuilder(base: URL(string: "https://www.agoda.com/flights")!)),

            // China portals
            makeChinaPortal(id: "trip", name: "Trip.com", homepage: "https://us.trip.com", chinaSeedReachability: 0.98, builder: genericBuilder(base: URL(string: "https://us.trip.com/flights")!)),
            makeChinaPortal(id: "ctrip", name: "Ctrip", homepage: "https://www.ctrip.com", chinaSeedReachability: 0.99, builder: genericBuilder(base: URL(string: "https://www.ctrip.com/flights")!)),
            makeChinaPortal(id: "qunar", name: "Qunar", homepage: "https://www.qunar.com", chinaSeedReachability: 0.98, builder: genericBuilder(base: URL(string: "https://www.qunar.com")!)),
            makeChinaPortal(id: "fliggy", name: "Fliggy", homepage: "https://www.fliggy.com", chinaSeedReachability: 0.98, builder: genericBuilder(base: URL(string: "https://www.fliggy.com")!))
        ]
    }

    private static func makeAirline(
        id: String,
        name: String,
        homepage: String,
        searchURL: String,
        chinaSeedReachability: Double = 0.55
    ) -> ProviderSeed {
        let base = URL(string: searchURL)!
        return ProviderSeed(
            descriptor: ProviderDescriptor(
                id: id,
                name: name,
                homepage: homepage,
                kind: .airline,
                capabilities: [.common, .loginLikely],
                supportsAutomatedExtraction: false,
                chinaSeedReachability: chinaSeedReachability
            ),
            searchMode: .deeplinkOnly,
            builder: genericBuilder(base: base)
        )
    }

    private static func makeMeta(
        id: String,
        name: String,
        homepage: String,
        chinaSeedReachability: Double = 0.6,
        builder: @escaping ProviderURLBuilder
    ) -> ProviderSeed {
        ProviderSeed(
            descriptor: ProviderDescriptor(
                id: id,
                name: name,
                homepage: homepage,
                kind: .metasearch,
                capabilities: [.common, .fetchExtraction],
                supportsAutomatedExtraction: true,
                chinaSeedReachability: chinaSeedReachability
            ),
            searchMode: .fetchAndExtract,
            builder: builder
        )
    }

    private static func makeOTA(
        id: String,
        name: String,
        homepage: String,
        chinaSeedReachability: Double = 0.45,
        builder: @escaping ProviderURLBuilder
    ) -> ProviderSeed {
        ProviderSeed(
            descriptor: ProviderDescriptor(
                id: id,
                name: name,
                homepage: homepage,
                kind: .ota,
                capabilities: [.common, .fetchExtraction, .loginLikely],
                supportsAutomatedExtraction: true,
                chinaSeedReachability: chinaSeedReachability
            ),
            searchMode: .fetchAndExtract,
            builder: builder
        )
    }

    private static func makeChinaPortal(
        id: String,
        name: String,
        homepage: String,
        chinaSeedReachability: Double = 0.92,
        builder: @escaping ProviderURLBuilder
    ) -> ProviderSeed {
        ProviderSeed(
            descriptor: ProviderDescriptor(
                id: id,
                name: name,
                homepage: homepage,
                kind: .chinaPortal,
                capabilities: [.common, .fetchExtraction, .loginLikely],
                supportsAutomatedExtraction: true,
                chinaSeedReachability: chinaSeedReachability
            ),
            searchMode: .fetchAndExtract,
            builder: builder
        )
    }

    private static func genericBuilder(base: URL) -> ProviderURLBuilder {
        { route, options in
            var query: [URLQueryItem] = [
                URLQueryItem(name: "origin", value: route.origin),
                URLQueryItem(name: "destination", value: route.destination),
                URLQueryItem(name: "departureDate", value: DateFormatter.flightDate.string(from: route.departureDate)),
                URLQueryItem(name: "tripType", value: options.tripType == .oneWay ? "oneway" : "roundtrip"),
                URLQueryItem(name: "adults", value: "\(options.passengers.adults)"),
                URLQueryItem(name: "children", value: "\(options.passengers.children)"),
                URLQueryItem(name: "infants", value: "\(options.passengers.infants)"),
                URLQueryItem(name: "cabinClass", value: options.cabinClass.queryToken),
                URLQueryItem(name: "nonstop", value: options.nonStopOnly ? "true" : "false"),
                URLQueryItem(name: "currency", value: options.preferredCurrency),
                URLQueryItem(name: "bags", value: "\(options.bagPolicy.checkedBagsPerTraveler)")
            ]

            if let returnDate = route.returnDate {
                query.append(URLQueryItem(name: "returnDate", value: DateFormatter.flightDate.string(from: returnDate)))
            }

            return base.appendingQueryItems(query)
        }
    }

    private static let googleFlightsBuilder: ProviderURLBuilder = { route, options in
        let base = URL(string: "https://www.google.com/travel/flights")!
        let depart = DateFormatter.flightDate.string(from: route.departureDate)
        let ret = route.returnDate.map { DateFormatter.flightDate.string(from: $0) } ?? ""

        let queryText = options.tripType == .oneWay
            ? "Flights from \(route.origin) to \(route.destination) on \(depart)"
            : "Flights from \(route.origin) to \(route.destination) on \(depart) returning \(ret)"

        return base.appendingQueryItems([
            URLQueryItem(name: "q", value: queryText),
            URLQueryItem(name: "curr", value: options.preferredCurrency),
            URLQueryItem(name: "hl", value: "en")
        ])
    }

    private static let kayakBuilder: ProviderURLBuilder = { route, options in
        let depart = DateFormatter.flightDate.string(from: route.departureDate)
        let basePath = "https://www.kayak.com/flights/\(route.origin)-\(route.destination)/\(depart)"
        let urlString: String
        if options.tripType == .roundTrip, let returnDate = route.returnDate {
            urlString = basePath + "/\(DateFormatter.flightDate.string(from: returnDate))"
        } else {
            urlString = basePath
        }

        let base = URL(string: urlString)!
        return base.appendingQueryItems([
            URLQueryItem(name: "sort", value: "bestflight_a"),
            URLQueryItem(name: "fs", value: options.nonStopOnly ? "stops=-1" : ""),
            URLQueryItem(name: "cabin", value: options.cabinClass.queryToken)
        ])
    }

    private static let momondoBuilder: ProviderURLBuilder = { route, options in
        let depart = DateFormatter.flightDate.string(from: route.departureDate)
        let basePath = "https://www.momondo.com/flight-search/\(route.origin)-\(route.destination)/\(depart)"
        let urlString: String
        if options.tripType == .roundTrip, let returnDate = route.returnDate {
            urlString = basePath + "/\(DateFormatter.flightDate.string(from: returnDate))"
        } else {
            urlString = basePath
        }

        return URL(string: urlString)!.appendingQueryItems([
            URLQueryItem(name: "sort", value: "bestflight_a"),
            URLQueryItem(name: "cabin", value: options.cabinClass.queryToken)
        ])
    }

    private static let skyscannerBuilder: ProviderURLBuilder = { route, options in
        let origin = route.origin.lowercased()
        let destination = route.destination.lowercased()
        let depart = DateFormatter.compactFlightDate.string(from: route.departureDate)

        let path: String
        if options.tripType == .roundTrip, let returnDate = route.returnDate {
            let ret = DateFormatter.compactFlightDate.string(from: returnDate)
            path = "https://www.skyscanner.com/transport/flights/\(origin)/\(destination)/\(depart)/\(ret)/"
        } else {
            path = "https://www.skyscanner.com/transport/flights/\(origin)/\(destination)/\(depart)/"
        }

        return URL(string: path)!.appendingQueryItems([
            URLQueryItem(name: "adults", value: "\(options.passengers.adults)"),
            URLQueryItem(name: "children", value: "\(options.passengers.children)"),
            URLQueryItem(name: "infants", value: "\(options.passengers.infants)"),
            URLQueryItem(name: "cabinclass", value: options.cabinClass.queryToken),
            URLQueryItem(name: "preferdirects", value: options.nonStopOnly ? "true" : "false"),
            URLQueryItem(name: "currency", value: options.preferredCurrency)
        ])
    }

    private static let kiwiBuilder: ProviderURLBuilder = { route, options in
        URL(string: "https://www.kiwi.com/en/search/results")!.appendingQueryItems([
            URLQueryItem(name: "flyFrom", value: route.origin),
            URLQueryItem(name: "to", value: route.destination),
            URLQueryItem(name: "dateFrom", value: DateFormatter.flightDate.string(from: route.departureDate)),
            URLQueryItem(name: "dateTo", value: DateFormatter.flightDate.string(from: route.departureDate)),
            URLQueryItem(name: "returnFrom", value: route.returnDate.map { DateFormatter.flightDate.string(from: $0) }),
            URLQueryItem(name: "returnTo", value: route.returnDate.map { DateFormatter.flightDate.string(from: $0) }),
            URLQueryItem(name: "adults", value: "\(options.passengers.adults)"),
            URLQueryItem(name: "children", value: "\(options.passengers.children)"),
            URLQueryItem(name: "infants", value: "\(options.passengers.infants)"),
            URLQueryItem(name: "cabinClass", value: options.cabinClass.queryToken),
            URLQueryItem(name: "selectedStopTypes", value: options.nonStopOnly ? "0" : nil)
        ])
    }
}
