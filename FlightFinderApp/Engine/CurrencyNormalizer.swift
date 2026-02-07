import Foundation

struct CurrencyNormalizer {
    private static let fallbackRatesToUSD: [String: Double] = [
        "USD": 1.0,
        "CNY": 0.139,
        "EUR": 1.08,
        "GBP": 1.27,
        "JPY": 0.0067,
        "CAD": 0.74,
        "KRW": 0.00074
    ]

    func convert(_ amount: Double, from: String, to: String) -> Double {
        let fromRate = Self.fallbackRatesToUSD[from.uppercased()] ?? 1
        let toRate = Self.fallbackRatesToUSD[to.uppercased()] ?? 1
        let usdValue = amount * fromRate
        return usdValue / toRate
    }
}
