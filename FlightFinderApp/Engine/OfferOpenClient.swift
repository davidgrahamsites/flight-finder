import AppKit
import Foundation

protocol OfferOpenClient {
    func open(url: URL)
}

struct WorkspaceOfferOpenClient: OfferOpenClient {
    func open(url: URL) {
        NSWorkspace.shared.open(url)
    }
}
