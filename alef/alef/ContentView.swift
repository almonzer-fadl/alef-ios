//
//  ContentView.swift
//  alef
//
//  Root view — manages the app's navigation state machine.
//
//  Flow for new users:
//    Splash → Onboarding → Auth (Sign Up) → Module Picker → Main App
//
//  Flow for returning users:
//    Splash → Main App (token still valid)
//
//  State is persisted via @AppStorage so users don't re-onboard
//  or re-authenticate on every launch.
//

import SwiftUI

// MARK: - App State

/// The possible screens in the app's navigation flow.
/// Transitions are animated with .easeInOut or .spring.
enum AppState {
    case splash          // Logo animation
    case onboarding      // First-time introduction (3 pages)
    case auth            // Sign up / sign in
    case modulePicker    // Choose which modules to enable
    case main            // The actual app (tab view)
}

// MARK: - Root View

struct ContentView: View {
    @State private var appState: AppState = .splash

    // Persisted state — survives app restarts
    @AppStorage("authToken") private var authToken: String = ""
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("hasPickedModules") private var hasPickedModules = false

    var body: some View {
        ZStack {
            Color.alefBg.ignoresSafeArea()

            switch appState {

            // ── Splash ───────────────────────────────────────────
            case .splash:
                SplashView {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        // Decide where to go based on saved state
                        if !authToken.isEmpty && hasPickedModules {
                            appState = .main
                        } else if !authToken.isEmpty {
                            appState = .modulePicker
                        } else if hasOnboarded {
                            appState = .auth
                        } else {
                            appState = .onboarding
                        }
                    }
                }
                .transition(.opacity)

            // ── Onboarding ───────────────────────────────────────
            case .onboarding:
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        hasOnboarded = true
                        appState = .auth
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

            // ── Auth ─────────────────────────────────────────────
            case .auth:
                AuthView { token in
                    authToken = token
                    withAnimation(.easeInOut(duration: 0.4)) {
                        appState = .modulePicker
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

            // ── Module Picker ────────────────────────────────────
            case .modulePicker:
                ModulePickerView(authToken: authToken) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        hasPickedModules = true
                        appState = .main
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

            // ── Main App ─────────────────────────────────────────
            case .main:
                MainTabView()
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
