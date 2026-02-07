import Foundation

extension URL {
    func appendingQueryItems(_ items: [URLQueryItem]) -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }

        var existing = components.queryItems ?? []
        existing.append(contentsOf: items)
        components.queryItems = existing

        return components.url ?? self
    }
}
