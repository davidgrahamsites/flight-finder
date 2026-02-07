import SwiftUI

@main
struct FlightFinderApp: App {
    init() {
        AppFontLoader.registerFontsIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            FlightFinderView()
                .frame(minWidth: 1180, minHeight: 780)
        }
        .windowResizability(.contentSize)
    }
}
