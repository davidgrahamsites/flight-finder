import Foundation

protocol ProviderReachabilityProbing: Sendable {
    func probeReachability(url: URL) async -> Bool
}

struct ProviderHTTPClient: Sendable {
    private let session: URLSession

    init(timeout: TimeInterval = 20) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.waitsForConnectivity = false
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        configuration.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        ]
        self.session = URLSession(configuration: configuration)
    }

    func fetchHTML(from url: URL, retries: Int = 1) async throws -> String {
        var attempt = 0
        var lastError: Error?

        while attempt <= retries {
            do {
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                let (data, _) = try await session.data(for: request)
                return String(decoding: data, as: UTF8.self)
            } catch {
                lastError = error
                attempt += 1
                if attempt <= retries {
                    try await Task.sleep(for: .milliseconds(350 * attempt))
                }
            }
        }

        throw lastError ?? URLError(.unknown)
    }

    func probeReachability(url: URL) async -> Bool {
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 8
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return data.count > 128
            }

            let statusOK = (200...399).contains(httpResponse.statusCode)
            return statusOK && data.count > 128
        } catch {
            return false
        }
    }
}

extension ProviderHTTPClient: ProviderReachabilityProbing {}
