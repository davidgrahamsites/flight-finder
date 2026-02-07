import Foundation
@preconcurrency import UserNotifications

protocol WatchlistNotificationClient {
    func notifyTargetHitAlerts(_ alerts: [WatchlistAlert])
}

final class LocalWatchlistNotificationClient: WatchlistNotificationClient {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func notifyTargetHitAlerts(_ alerts: [WatchlistAlert]) {
        guard !alerts.isEmpty else { return }
        let center = self.center
        let formattedAlerts = alerts.prefix(5).map { alert in
            FormattedWatchlistAlert(
                id: alert.id,
                providerName: alert.providerName,
                routeKey: alert.routeKey,
                observedText: LocalWatchlistNotificationClient.formatPrice(alert.observedPrice, currency: alert.currencyCode),
                targetText: LocalWatchlistNotificationClient.formatPrice(alert.targetPrice, currency: alert.currencyCode)
            )
        }

        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }

            for alert in formattedAlerts {
                let content = UNMutableNotificationContent()
                content.title = "Watchlist target hit"
                content.body = "\(alert.providerName) \(alert.routeKey): \(alert.observedText) <= \(alert.targetText)"
                content.sound = .default

                let request = UNNotificationRequest(
                    identifier: "watchlist-target-hit-\(alert.id.uuidString)",
                    content: content,
                    trigger: nil
                )

                center.add(request, withCompletionHandler: nil)
            }
        }
    }

    private static func formatPrice(_ value: Double, currency: String) -> String {
        let rounded = (value * 100).rounded() / 100
        let formatted = rounded.formatted(.number.precision(.fractionLength(2)))
        return "\(currency) \(formatted)"
    }
}

private struct FormattedWatchlistAlert {
    let id: UUID
    let providerName: String
    let routeKey: String
    let observedText: String
    let targetText: String
}
