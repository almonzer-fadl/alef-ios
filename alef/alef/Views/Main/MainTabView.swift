//
//  MainTabView.swift
//  alef
//
//  The main app shell with a custom bottom tab bar.
//
//  Tab structure shows 4 visible tabs + the rest accessible from
//  a "More" or settings area. The visible tabs are:
//    Home (dashboard) | Habits | Library | Settings
//
//  The dashboard aggregates data from all enabled modules.
//  Individual module screens are accessed from the dashboard cards
//  or from the Library tab (which shows all enabled modules).
//
//  TODO: Make tabs dynamic based on user's enabled modules.
//  TODO: Build actual module screens (currently placeholders).
//

import SwiftUI

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.alefBg.ignoresSafeArea()

            // ── Tab content ──────────────────────────────────────
            Group {
                switch selectedTab {
                case 0:
                    PlaceholderTab(
                        title: "Dashboard",
                        icon: "square.grid.2x2.fill",
                        subtitle: "Your daily snapshot",
                        color: .alefGold
                    )
                case 1:
                    PlaceholderTab(
                        title: "Habits",
                        icon: "checkmark.circle.fill",
                        subtitle: "Build streaks, stay consistent",
                        color: .alefHabits
                    )
                case 2:
                    PlaceholderTab(
                        title: "Library",
                        icon: "square.stack.fill",
                        subtitle: "All your modules",
                        color: .alefBooks
                    )
                case 3:
                    PlaceholderTab(
                        title: "Settings",
                        icon: "gearshape.fill",
                        subtitle: "Profile, modules, preferences",
                        color: .alefTextSecondary
                    )
                default:
                    EmptyView()
                }
            }
            .padding(.bottom, AlefLayout.tabBarHeight)

            // ── Custom tab bar ───────────────────────────────────
            customTabBar
        }
    }

    // MARK: - Custom Tab Bar

    /// A custom tab bar matching the design spec.
    /// Uses the deep navy surface colour with a subtle top border.
    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabItem(icon: "square.grid.2x2.fill", label: "Home",     index: 0)
            tabItem(icon: "checkmark.circle.fill", label: "Habits",  index: 1)
            tabItem(icon: "square.stack.fill",     label: "Library",  index: 2)
            tabItem(icon: "gearshape.fill",        label: "Settings", index: 3)
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            Color.alefSurface
                .overlay(
                    // Subtle top border line
                    Rectangle()
                        .fill(Color.alefBorder)
                        .frame(height: 0.5),
                    alignment: .top
                )
        )
    }

    /// Individual tab bar item with icon and label.
    /// Active state uses the habits accent colour (emerald).
    private func tabItem(icon: String, label: String, index: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.25)) {
                selectedTab = index
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(selectedTab == index ? .alefGold : .alefTextTertiary)
                    .scaleEffect(selectedTab == index ? 1.1 : 1.0)

                Text(label)
                    .font(AlefFont.medium(11))
                    .foregroundColor(selectedTab == index ? .alefGold : .alefTextTertiary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Placeholder Tab

/// Temporary placeholder for tabs that haven't been built yet.
/// Shows the module's icon, name, and a "coming soon" message.
/// These will be replaced with actual module views as we build them.
struct PlaceholderTab: View {
    let title: String
    let icon: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(color.opacity(0.3))

            Text(title)
                .font(AlefFont.bold(24))
                .foregroundColor(.alefText)

            Text(subtitle)
                .font(AlefFont.regular(15))
                .foregroundColor(.alefTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.alefBg)
    }
}
