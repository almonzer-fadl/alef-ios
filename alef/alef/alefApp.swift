//
//  alefApp.swift
//  alef
//
//  Alef — أ — A Life Entirely Filed
//
//  A privacy-first, self-hosted life operating system.
//  Track habits, health, diet, fitness, sleep, journal,
//  movies, books, projects, and calendar — all in one native app.
//
//  Stack: SwiftUI (iOS) + Bun/Hono (backend) + PostgreSQL
//  License: MIT (open source)
//  GitHub: github.com/almonzer-fadl/alef-ios
//
//  Created by Almonzer Fadl on 7.03.2026.
//

import SwiftUI

@main
struct alefApp: App {
    @AppStorage("appearanceMode") private var appearanceMode = "dark"

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(colorScheme)
        }
    }

    /// Maps the stored appearance preference to SwiftUI's ColorScheme.
    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case "dark":   return .dark
        case "light":  return .light
        default:       return nil  // system default
        }
    }
}
