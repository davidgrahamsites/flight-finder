import CoreText
import Foundation

@MainActor
enum AppFontLoader {
    private static var didRegisterFonts = false

    static func registerFontsIfNeeded() {
        guard !didRegisterFonts else { return }
        didRegisterFonts = true

        let candidates = allFontURLs().filter { $0.lastPathComponent.localizedCaseInsensitiveContains("outfit") }
        for url in candidates {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    private static func allFontURLs() -> [URL] {
        let ttfAtRoot = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? []
        let ttfInResources = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: "Resources/Fonts") ?? []
        return ttfAtRoot + ttfInResources
    }
}
