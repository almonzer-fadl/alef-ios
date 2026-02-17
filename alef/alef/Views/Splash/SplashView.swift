//
//  SplashView.swift
//  alef
//
//  The first thing users see when opening the app.
//  Shows the أ logo with a subtle gold glow, then transitions
//  to onboarding (first launch) or the main app (returning user).
//
//  Animation sequence:
//  1. Gold radial glow fades in
//  2. أ logo scales up with spring animation
//  3. "alef" text slides in
//  4. Tagline fades in
//  5. After 2.2 seconds, transitions to next screen
//

import SwiftUI

struct SplashView: View {
    @State private var showLogo = false
    @State private var showTagline = false
    @State private var showGlow = false

    /// Called when the splash animation completes.
    /// The parent (ContentView) decides where to navigate next.
    var onComplete: () -> Void

    var body: some View {
        ZStack {
            Color.alefBg.ignoresSafeArea()

            // Subtle radial glow behind the logo — uses brand gold
            if showGlow {
                RadialGradient(
                    colors: [Color.alefGold.opacity(0.08), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 200
                )
                .ignoresSafeArea()
                .transition(.opacity)
            }

            VStack(spacing: 24) {
                Spacer()

                // The أ logo — brand gold, the only place this colour dominates
                Text("أ")
                    .font(.system(size: 120, weight: .ultraLight))
                    .foregroundColor(.alefGold)
                    .opacity(showLogo ? 1 : 0)
                    .scaleEffect(showLogo ? 1 : 0.6)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: showLogo)

                // App name
                Text("alef")
                    .font(AlefFont.heavy(32))
                    .foregroundColor(.alefText)
                    .tracking(6)
                    .opacity(showLogo ? 1 : 0)
                    .offset(y: showLogo ? 0 : 10)
                    .animation(.easeOut(duration: 0.6).delay(0.3), value: showLogo)

                // Tagline
                Text("a life entirely filed")
                    .font(AlefFont.regular(14))
                    .foregroundColor(.alefTextSecondary)
                    .tracking(2)
                    .opacity(showTagline ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.6), value: showTagline)

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            withAnimation { showGlow = true }
            showLogo = true
            showTagline = true

            // Auto-advance after the animation plays
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                onComplete()
            }
        }
    }
}
