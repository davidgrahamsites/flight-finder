import Foundation

struct AirportOption: Identifiable, Hashable {
    let code: String
    let city: String
    let name: String
    let country: String

    var id: String { code }
}

enum AirportDirectory {
    static let all: [AirportOption] = [
        AirportOption(code: "SFO", city: "San Francisco", name: "San Francisco International", country: "USA"),
        AirportOption(code: "LAX", city: "Los Angeles", name: "Los Angeles International", country: "USA"),
        AirportOption(code: "SEA", city: "Seattle", name: "Seattle-Tacoma International", country: "USA"),
        AirportOption(code: "SAN", city: "San Diego", name: "San Diego International", country: "USA"),
        AirportOption(code: "SJC", city: "San Jose", name: "San Jose Mineta International", country: "USA"),
        AirportOption(code: "OAK", city: "Oakland", name: "Oakland International", country: "USA"),
        AirportOption(code: "LAS", city: "Las Vegas", name: "Harry Reid International", country: "USA"),
        AirportOption(code: "PHX", city: "Phoenix", name: "Phoenix Sky Harbor International", country: "USA"),
        AirportOption(code: "DEN", city: "Denver", name: "Denver International", country: "USA"),
        AirportOption(code: "DFW", city: "Dallas", name: "Dallas/Fort Worth International", country: "USA"),
        AirportOption(code: "IAH", city: "Houston", name: "George Bush Intercontinental", country: "USA"),
        AirportOption(code: "AUS", city: "Austin", name: "Austin-Bergstrom International", country: "USA"),
        AirportOption(code: "ATL", city: "Atlanta", name: "Hartsfield-Jackson Atlanta International", country: "USA"),
        AirportOption(code: "MIA", city: "Miami", name: "Miami International", country: "USA"),
        AirportOption(code: "MCO", city: "Orlando", name: "Orlando International", country: "USA"),
        AirportOption(code: "CLT", city: "Charlotte", name: "Charlotte Douglas International", country: "USA"),
        AirportOption(code: "BNA", city: "Nashville", name: "Nashville International", country: "USA"),
        AirportOption(code: "ORD", city: "Chicago", name: "O'Hare International", country: "USA"),
        AirportOption(code: "MDW", city: "Chicago", name: "Midway International", country: "USA"),
        AirportOption(code: "DTW", city: "Detroit", name: "Detroit Metropolitan Wayne County", country: "USA"),
        AirportOption(code: "MSP", city: "Minneapolis", name: "Minneapolis-St. Paul International", country: "USA"),
        AirportOption(code: "JFK", city: "New York", name: "John F. Kennedy International", country: "USA"),
        AirportOption(code: "LGA", city: "New York", name: "LaGuardia", country: "USA"),
        AirportOption(code: "EWR", city: "Newark", name: "Newark Liberty International", country: "USA"),
        AirportOption(code: "BOS", city: "Boston", name: "Logan International", country: "USA"),
        AirportOption(code: "IAD", city: "Washington", name: "Dulles International", country: "USA"),
        AirportOption(code: "DCA", city: "Washington", name: "Ronald Reagan Washington National", country: "USA"),
        AirportOption(code: "PHL", city: "Philadelphia", name: "Philadelphia International", country: "USA"),
        AirportOption(code: "RDU", city: "Raleigh", name: "Raleigh-Durham International", country: "USA"),
        AirportOption(code: "SLC", city: "Salt Lake City", name: "Salt Lake City International", country: "USA"),
        AirportOption(code: "PDX", city: "Portland", name: "Portland International", country: "USA"),
        AirportOption(code: "HNL", city: "Honolulu", name: "Daniel K. Inouye International", country: "USA"),
        AirportOption(code: "ANC", city: "Anchorage", name: "Ted Stevens Anchorage International", country: "USA"),

        AirportOption(code: "PVG", city: "Shanghai", name: "Shanghai Pudong International", country: "China"),
        AirportOption(code: "SHA", city: "Shanghai", name: "Shanghai Hongqiao International", country: "China"),
        AirportOption(code: "PEK", city: "Beijing", name: "Beijing Capital International", country: "China"),
        AirportOption(code: "PKX", city: "Beijing", name: "Beijing Daxing International", country: "China"),
        AirportOption(code: "CAN", city: "Guangzhou", name: "Guangzhou Baiyun International", country: "China"),
        AirportOption(code: "SZX", city: "Shenzhen", name: "Shenzhen Bao'an International", country: "China"),
        AirportOption(code: "CTU", city: "Chengdu", name: "Chengdu Shuangliu International", country: "China"),
        AirportOption(code: "TFU", city: "Chengdu", name: "Chengdu Tianfu International", country: "China"),
        AirportOption(code: "XIY", city: "Xi'an", name: "Xi'an Xianyang International", country: "China"),
        AirportOption(code: "HGH", city: "Hangzhou", name: "Hangzhou Xiaoshan International", country: "China"),
        AirportOption(code: "NKG", city: "Nanjing", name: "Nanjing Lukou International", country: "China"),
        AirportOption(code: "KMG", city: "Kunming", name: "Kunming Changshui International", country: "China"),
        AirportOption(code: "XMN", city: "Xiamen", name: "Xiamen Gaoqi International", country: "China"),
        AirportOption(code: "FOC", city: "Fuzhou", name: "Fuzhou Changle International", country: "China"),
        AirportOption(code: "WUH", city: "Wuhan", name: "Wuhan Tianhe International", country: "China"),
        AirportOption(code: "TSN", city: "Tianjin", name: "Tianjin Binhai International", country: "China"),
        AirportOption(code: "CGO", city: "Zhengzhou", name: "Zhengzhou Xinzheng International", country: "China"),
        AirportOption(code: "TAO", city: "Qingdao", name: "Qingdao Jiaodong International", country: "China"),
        AirportOption(code: "URC", city: "Urumqi", name: "Urumqi Diwopu International", country: "China"),
        AirportOption(code: "SYX", city: "Sanya", name: "Sanya Phoenix International", country: "China"),
        AirportOption(code: "KWE", city: "Guiyang", name: "Guiyang Longdongbao International", country: "China"),

        AirportOption(code: "HKG", city: "Hong Kong", name: "Hong Kong International", country: "Hong Kong"),
        AirportOption(code: "ICN", city: "Seoul", name: "Incheon International", country: "South Korea"),
        AirportOption(code: "GMP", city: "Seoul", name: "Gimpo International", country: "South Korea"),
        AirportOption(code: "TPE", city: "Taipei", name: "Taiwan Taoyuan International", country: "Taiwan"),
        AirportOption(code: "NRT", city: "Tokyo", name: "Narita International", country: "Japan"),
        AirportOption(code: "HND", city: "Tokyo", name: "Haneda Airport", country: "Japan"),
        AirportOption(code: "KIX", city: "Osaka", name: "Kansai International", country: "Japan"),
        AirportOption(code: "NGO", city: "Nagoya", name: "Chubu Centrair International", country: "Japan"),
        AirportOption(code: "SIN", city: "Singapore", name: "Singapore Changi", country: "Singapore"),
        AirportOption(code: "DOH", city: "Doha", name: "Hamad International", country: "Qatar"),
        AirportOption(code: "DXB", city: "Dubai", name: "Dubai International", country: "UAE"),
        AirportOption(code: "IST", city: "Istanbul", name: "Istanbul Airport", country: "Turkey"),
        AirportOption(code: "FRA", city: "Frankfurt", name: "Frankfurt Airport", country: "Germany"),
        AirportOption(code: "MUC", city: "Munich", name: "Munich Airport", country: "Germany"),
        AirportOption(code: "LHR", city: "London", name: "Heathrow Airport", country: "United Kingdom"),
        AirportOption(code: "CDG", city: "Paris", name: "Charles de Gaulle Airport", country: "France"),
        AirportOption(code: "AMS", city: "Amsterdam", name: "Amsterdam Schiphol", country: "Netherlands"),
        AirportOption(code: "YYZ", city: "Toronto", name: "Toronto Pearson International", country: "Canada"),
        AirportOption(code: "YVR", city: "Vancouver", name: "Vancouver International", country: "Canada")
    ]

    static func suggestions(matching rawQuery: String, limit: Int = 8) -> [AirportOption] {
        let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }

        let queryUpper = query.uppercased()
        let queryLower = query.lowercased()
        let safeLimit = max(1, min(limit, 20))

        return all
            .compactMap { airport -> (airport: AirportOption, score: Int)? in
                let code = airport.code
                let city = airport.city.lowercased()
                let name = airport.name.lowercased()

                if code.hasPrefix(queryUpper) { return (airport, 0) }
                if city.hasPrefix(queryLower) { return (airport, 1) }
                if name.hasPrefix(queryLower) { return (airport, 2) }
                if city.contains(queryLower) { return (airport, 3) }
                if name.contains(queryLower) { return (airport, 4) }
                if code.contains(queryUpper) { return (airport, 5) }
                return nil
            }
            .sorted {
                if $0.score != $1.score { return $0.score < $1.score }
                return $0.airport.code < $1.airport.code
            }
            .prefix(safeLimit)
            .map(\.airport)
    }
}
