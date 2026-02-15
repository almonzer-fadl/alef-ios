import SwiftUI

// MARK: - Alef Color Palette

extension Color {
    // Core
    static let alefBg = Color(hex: "0A0A0B")           // near-black background
    static let alefSurface = Color(hex: "141416")       // card/surface
    static let alefSurfaceLight = Color(hex: "1C1C1F")  // elevated surface
    static let alefBorder = Color(hex: "2A2A2E")        // subtle borders
    
    // Accent
    static let alefAccent = Color(hex: "10B981")        // emerald green — life, growth
    static let alefAccentSoft = Color(hex: "10B981").opacity(0.15)
    
    // Text
    static let alefText = Color(hex: "F5F5F7")          // primary text
    static let alefTextSecondary = Color(hex: "8E8E93")  // secondary
    static let alefTextTertiary = Color(hex: "48484A")   // muted
    
    // Status
    static let alefSuccess = Color(hex: "22C55E")
    static let alefWarning = Color(hex: "F59E0B")
    static let alefError = Color(hex: "EF4444")
    
    // Habit colors (for user customization)
    static let alefPalette: [Color] = [
        Color(hex: "10B981"), // emerald
        Color(hex: "3B82F6"), // blue
        Color(hex: "8B5CF6"), // violet
        Color(hex: "F59E0B"), // amber
        Color(hex: "EF4444"), // red
        Color(hex: "EC4899"), // pink
        Color(hex: "06B6D4"), // cyan
        Color(hex: "F97316"), // orange
    ]
}

// MARK: - Color Hex Init

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Fonts

struct AlefFont {
    // Using system fonts with rounded design — clean and modern
    static func regular(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
    static func medium(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
    static func semibold(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
    static func bold(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    static func heavy(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }
}
