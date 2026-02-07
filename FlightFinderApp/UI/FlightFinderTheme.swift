import SwiftUI

enum FlightFinderTheme {
    static let background = Color(hex: 0xFFFFFF)
    static let foreground = Color(hex: 0x111827)
    static let primary = Color(hex: 0x3B82F6)
    static let secondary = Color(hex: 0x10B981)
    static let accent = Color(hex: 0xF59E0B)
    static let muted = Color(hex: 0xF3F4F6)
    static let border = Color(hex: 0xE5E7EB)
    static let slate = Color(hex: 0x1F2937)
}

extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self = Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
