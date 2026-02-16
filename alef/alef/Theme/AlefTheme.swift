//
//  AlefTheme.swift
//  alef
//
//  The design system for Alef — colours, typography, and spacing.
//
//  Colour philosophy:
//  - Deep navy background (not pure black) — warmer, easier on the eyes
//  - Each module has its own accent colour for personality
//  - Brand gold is reserved for the أ logo and special moments only
//
//  Reference apps: Bevel (dark charcoal), Apple Health (data viz),
//  Letterboxd (personality), Things 3 (calm).
//
//  Full design spec: memory/gari/alef-design-spec.md
//

import SwiftUI

// MARK: - Core Colour Palette

extension Color {

    // ── Backgrounds ──────────────────────────────────────────────────
    // Deep navy, not pure black. Feels warm and premium.

    /// Primary app background
    static let alefBg = Color(hex: "111827")

    /// Card and elevated surface background
    static let alefSurface = Color(hex: "1E293B")

    /// Secondary surface for nested elements within cards
    static let alefSurfaceSecondary = Color(hex: "334155")

    /// Subtle borders and dividers
    static let alefBorder = Color(hex: "475569").opacity(0.3)

    // ── Text ─────────────────────────────────────────────────────────

    /// Primary text — near-white, high contrast
    static let alefText = Color(hex: "F8FAFC")

    /// Secondary text — labels, subtitles
    static let alefTextSecondary = Color(hex: "94A3B8")

    /// Tertiary text — timestamps, meta info, placeholders
    static let alefTextTertiary = Color(hex: "64748B")

    // ── Brand ────────────────────────────────────────────────────────

    /// Brand gold — ONLY for the أ logo and special moments.
    /// Using this everywhere would dilute its impact.
    static let alefGold = Color(hex: "D4A574")

    // ── Status ───────────────────────────────────────────────────────

    static let alefSuccess = Color(hex: "22C55E")
    static let alefWarning = Color(hex: "F59E0B")
    static let alefError = Color(hex: "EF4444")
}

// MARK: - Module Accent Colours
//
// Each module has a unique accent colour so the app feels alive,
// not monotone. These colours appear in icons, progress indicators,
// active tab states, and CTAs within each module.

extension Color {

    /// Habits — growth, completion, positive action
    static let alefHabits = Color(hex: "34D399")

    /// Journal — personal, emotional, reflective
    static let alefJournal = Color(hex: "F472B6")

    /// Health — medical, calm, trust
    static let alefHealth = Color(hex: "60A5FA")

    /// Sleep — night, calm, rest
    static let alefSleep = Color(hex: "818CF8")

    /// Fitness — energy, heart rate, intensity
    static let alefFitness = Color(hex: "F87171")

    /// Diet — food, energy, warmth
    static let alefDiet = Color(hex: "FB923C")

    /// Movies & TV — cinema, spotlight
    static let alefMovies = Color(hex: "FBBF24")

    /// Books — knowledge, depth, exploration
    static let alefBooks = Color(hex: "2DD4BF")

    /// Projects — technical, productive, clarity
    static let alefProjects = Color(hex: "22D3EE")

    /// Calendar — time, planning, structure
    static let alefCalendar = Color(hex: "A78BFA")

    /// Returns the accent colour for a module by its key string.
    /// Used when rendering dynamic module lists from the API.
    static func accent(for moduleKey: String) -> Color {
        switch moduleKey {
        case "habits":   return .alefHabits
        case "journal":  return .alefJournal
        case "health":   return .alefHealth
        case "sleep":    return .alefSleep
        case "fitness":  return .alefFitness
        case "diet":     return .alefDiet
        case "movies":   return .alefMovies
        case "books":    return .alefBooks
        case "projects": return .alefProjects
        case "calendar": return .alefCalendar
        default:         return .alefGold
        }
    }

    /// Palette array for user-customisable habit colours.
    /// Shown in the habit creation form colour picker.
    static let alefPalette: [Color] = [
        .alefHabits,    // emerald
        .alefHealth,    // blue
        .alefSleep,     // indigo
        .alefDiet,      // orange
        .alefFitness,   // coral
        .alefJournal,   // pink
        .alefProjects,  // cyan
        .alefMovies,    // amber
        .alefBooks,     // teal
        .alefCalendar,  // violet
    ]
}

// MARK: - Hex Colour Initialiser

extension Color {
    /// Create a Color from a hex string (3, 6, or 8 characters).
    /// Supports formats: "FFF", "FFFFFF", "FFFFFFFF" (with alpha).
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  // RRGGBB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  // AARRGGBB (32-bit)
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

// MARK: - Typography
//
// System fonts with two design variants:
// - `.default` for body text (SF Pro)
// - `.rounded` for numbers and stats (SF Pro Rounded — adds personality)

struct AlefFont {
    /// Body text — clean and readable
    static func regular(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular)
    }
    static func medium(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium)
    }
    static func semibold(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold)
    }
    static func bold(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold)
    }
    static func heavy(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy)
    }

    /// Rounded variant — used for numbers, stats, scores.
    /// Gives data visualisation elements a softer, friendlier feel.
    struct Rounded {
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
}

// MARK: - Spacing & Layout Constants

struct AlefLayout {
    /// Standard horizontal padding for screen content
    static let horizontalPadding: CGFloat = 20

    /// Card corner radius (16-20pt as per design spec)
    static let cardRadius: CGFloat = 16

    /// Large card corner radius (for hero elements)
    static let cardRadiusLarge: CGFloat = 20

    /// Standard spacing between cards/sections
    static let sectionSpacing: CGFloat = 24

    /// Spacing between items within a card
    static let itemSpacing: CGFloat = 12

    /// Tab bar height (including safe area padding)
    static let tabBarHeight: CGFloat = 80
}
