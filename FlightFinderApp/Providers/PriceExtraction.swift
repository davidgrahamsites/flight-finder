import Foundation

struct PriceExtraction {
    struct ExtractedData: Sendable {
        let price: Double?
        let currency: String
        let departureTime: String?
        let arrivalTime: String?
        let durationText: String?
        let stops: Int?
        let confidence: Double
        let notes: String
        let loginLikely: Bool
    }

    static func extract(from html: String, preferredCurrency: String = "USD") -> ExtractedData {
        let lowered = html.lowercased()
        let loginLikely = lowered.contains("sign in") || lowered.contains("log in") || lowered.contains("captcha")

        let price = extractNumericPrice(from: html)
        let times = extractTimes(from: html)
        let duration = extractDuration(from: html)
        let stops = extractStops(from: lowered)

        let confidence: Double
        if price != nil {
            confidence = loginLikely ? 0.45 : 0.72
        } else if loginLikely {
            confidence = 0.35
        } else {
            confidence = 0.18
        }

        let notes: String
        if loginLikely {
            notes = "Provider likely requires login or human verification."
        } else if price != nil {
            notes = "Price extracted from provider page content."
        } else {
            notes = "No stable structured price detected; manual handoff recommended."
        }

        return ExtractedData(
            price: price,
            currency: preferredCurrency,
            departureTime: times.first,
            arrivalTime: times.last,
            durationText: duration,
            stops: stops,
            confidence: confidence,
            notes: notes,
            loginLikely: loginLikely
        )
    }

    private static func extractNumericPrice(from html: String) -> Double? {
        let patterns = [
            #"\$\s?([0-9]{2,5}(?:\.[0-9]{2})?)"#,
            #""price"\s*:\s*"?([0-9]{2,5}(?:\.[0-9]{1,2})?)"?"#,
            #""amount"\s*:\s*"?([0-9]{2,5}(?:\.[0-9]{1,2})?)"?"#,
            #">\s*USD\s*([0-9]{2,5}(?:\.[0-9]{2})?)"#
        ]

        var values: [Double] = []

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
            let range = NSRange(html.startIndex..., in: html)
            regex.enumerateMatches(in: html, options: [], range: range) { result, _, _ in
                guard let result,
                      result.numberOfRanges > 1,
                      let capture = Range(result.range(at: 1), in: html) else {
                    return
                }
                let raw = html[capture].replacingOccurrences(of: ",", with: "")
                if let value = Double(raw), value >= 40, value <= 10000 {
                    values.append(value)
                }
            }
        }

        return values.min()
    }

    private static func extractTimes(from html: String) -> [String] {
        let pattern = #"\b([0-1]?[0-9]:[0-5][0-9]\s?(?:AM|PM|am|pm))\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, options: [], range: range)

        return matches.compactMap { match in
            guard match.numberOfRanges > 1,
                  let capture = Range(match.range(at: 1), in: html) else {
                return nil
            }
            return String(html[capture])
        }
    }

    private static func extractDuration(from html: String) -> String? {
        let pattern = #"\b([0-9]{1,2}h\s?[0-9]{1,2}m)\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(html.startIndex..., in: html)
        guard let match = regex.firstMatch(in: html, options: [], range: range),
              match.numberOfRanges > 1,
              let capture = Range(match.range(at: 1), in: html) else {
            return nil
        }
        return String(html[capture])
    }

    private static func extractStops(from lowered: String) -> Int? {
        if lowered.contains("nonstop") || lowered.contains("non-stop") {
            return 0
        }

        let pattern = #"\b([0-3])\s*stop"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(lowered.startIndex..., in: lowered)
        guard let match = regex.firstMatch(in: lowered, options: [], range: range),
              match.numberOfRanges > 1,
              let capture = Range(match.range(at: 1), in: lowered) else {
            return nil
        }
        return Int(lowered[capture])
    }
}
