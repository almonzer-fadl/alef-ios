//
//  OnboardingView.swift
//  alef
//
//  Three-page introduction shown on first launch.
//  Explains what Alef is, why privacy matters, and what makes it special.
//
//  Uses a horizontal TabView with custom page dots.
//  The user can swipe through or tap Next/Skip.
//
//  After onboarding, the user is taken to the auth screen (sign up/in).
//  This view is only shown once — the `hasOnboarded` flag in @AppStorage
//  prevents it from appearing again.
//

import SwiftUI

/// Data model for a single onboarding page.
/// Uses SF Symbols instead of emoji — emoji look inconsistent across
/// OS versions and don't respect the app's colour scheme.
struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String   // SF Symbol name
    let color: Color   // accent colour for the icon
    let title: String
    let subtitle: String
}

struct OnboardingView: View {
    @State private var currentPage = 0
    var onGetStarted: () -> Void

    /// The three onboarding pages.
    /// Keep copy short and punchy — this is a first impression.
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "square.grid.2x2.fill",
            color: .alefHabits,
            title: "Track Everything",
            subtitle: "Habits, health, diet, workouts, books,\nmovies — all in one place."
        ),
        OnboardingPage(
            icon: "lock.shield.fill",
            color: .alefHealth,
            title: "Your Data. Your Server.",
            subtitle: "Self-hosted. No company mining your life.\nPrivacy isn't a feature — it's the point."
        ),
        OnboardingPage(
            icon: "sparkles",
            color: .alefGold,
            title: "Built for You",
            subtitle: "Beautiful. Fast. Native.\nThe life OS you actually want to open."
        ),
    ]

    var body: some View {
        ZStack {
            Color.alefBg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // ── Page content (swipeable) ─────────────────────────
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        VStack(spacing: 20) {
                            // SF Symbol icon with module accent colour
                            Image(systemName: page.icon)
                                .font(.system(size: 56, weight: .light))
                                .foregroundColor(page.color)

                            Text(page.title)
                                .font(AlefFont.bold(28))
                                .foregroundColor(.alefText)
                                .multilineTextAlignment(.center)

                            Text(page.subtitle)
                                .font(AlefFont.regular(16))
                                .foregroundColor(.alefTextSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        .tag(index)
                        .padding(.horizontal, 32)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // ── Custom page indicator ────────────────────────────
                // Capsule-style dots: active dot is wider and uses gold
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? Color.alefGold : Color.alefSurfaceSecondary)
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 32)

                Spacer()

                // ── CTA button ───────────────────────────────────────
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        onGetStarted()
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .font(AlefFont.semibold(17))
                        .foregroundColor(.alefBg)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.alefGold)
                        .cornerRadius(AlefLayout.cardRadius)
                }
                .padding(.horizontal, AlefLayout.horizontalPadding)

                // ── Skip button (hidden on last page) ────────────────
                if currentPage < pages.count - 1 {
                    Button {
                        onGetStarted()
                    } label: {
                        Text("Skip")
                            .font(AlefFont.medium(15))
                            .foregroundColor(.alefTextSecondary)
                    }
                    .padding(.top, 12)
                }

                Spacer().frame(height: 40)
            }
        }
    }
}
