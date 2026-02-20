//
//  ModulePickerView.swift
//  alef
//
//  Shown after sign up — the user picks which life-tracking modules
//  they want enabled. This is the core of Alef's modular architecture.
//
//  Users must pick at least one module. Their selection determines:
//  - Which tabs appear in the main app
//  - Which cards show on the dashboard
//  - Which data gets tracked
//
//  Modules can always be enabled/disabled later from Settings.
//
//  The selection is sent to POST /api/modules/setup on the backend,
//  which stores it in the `user_modules` table.
//

import SwiftUI

// MARK: - Module Data

/// Represents a module option in the picker grid.
/// Mirrors the ALL_MODULES constant on the backend.
struct ModuleOption: Identifiable {
    let id = UUID()
    let key: String
    let label: String
    let icon: String        // SF Symbol name
    let color: Color
    let description: String
}

// MARK: - Module Picker View

struct ModulePickerView: View {
    @State private var selected: Set<String> = ["habits"] // habits pre-selected
    @State private var isLoading = false

    /// JWT token for the authenticated user (needed for API call)
    let authToken: String

    /// Called after modules are saved successfully
    var onComplete: () -> Void

    /// All available modules — order matches the recommended build priority
    private let modules: [ModuleOption] = [
        ModuleOption(key: "habits",   label: "Habits",      icon: "checkmark.circle.fill",  color: .alefHabits,   description: "Streaks, daily check-ins"),
        ModuleOption(key: "journal",  label: "Journal",     icon: "book.fill",              color: .alefJournal,  description: "Mood, reflections, thoughts"),
        ModuleOption(key: "health",   label: "Health",      icon: "heart.fill",             color: .alefHealth,   description: "Weight, water, vitals"),
        ModuleOption(key: "sleep",    label: "Sleep",       icon: "moon.fill",              color: .alefSleep,    description: "Quality, trends, score"),
        ModuleOption(key: "fitness",  label: "Fitness",     icon: "figure.run",             color: .alefFitness,  description: "Workouts, runs, PRs"),
        ModuleOption(key: "diet",     label: "Diet",        icon: "fork.knife",             color: .alefDiet,     description: "Meals, calories, macros"),
        ModuleOption(key: "movies",   label: "Movies & TV", icon: "film.fill",              color: .alefMovies,   description: "Watchlist, ratings, reviews"),
        ModuleOption(key: "books",    label: "Books",       icon: "text.book.closed.fill",  color: .alefBooks,    description: "Reading list, progress"),
        ModuleOption(key: "projects", label: "Projects",    icon: "square.grid.2x2.fill",   color: .alefProjects, description: "Tasks, boards, deadlines"),
        ModuleOption(key: "calendar", label: "Calendar",    icon: "calendar",               color: .alefCalendar, description: "Events, schedule"),
    ]

    /// Two-column grid layout
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ZStack {
            Color.alefBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Header ───────────────────────────────────────────
                VStack(spacing: 8) {
                    Text("What do you want\nto track?")
                        .font(AlefFont.bold(28))
                        .foregroundColor(.alefText)
                        .multilineTextAlignment(.center)

                    Text("Pick at least one. You can change this anytime.")
                        .font(AlefFont.regular(15))
                        .foregroundColor(.alefTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)
                .padding(.horizontal, AlefLayout.horizontalPadding)

                // ── Module grid ──────────────────────────────────────
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(modules) { module in
                            moduleCard(module)
                        }
                    }
                    .padding(.horizontal, AlefLayout.horizontalPadding)
                    .padding(.top, 24)
                    .padding(.bottom, 120) // space for the button
                }

                Spacer()
            }

            // ── Fixed bottom button ──────────────────────────────────
            VStack {
                Spacer()

                VStack(spacing: 0) {
                    // Gradient fade above the button
                    LinearGradient(
                        colors: [Color.alefBg.opacity(0), Color.alefBg],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 40)

                    VStack(spacing: 12) {
                        // Selection counter
                        Text("\(selected.count) selected")
                            .font(AlefFont.medium(14))
                            .foregroundColor(.alefTextSecondary)

                        // Continue button
                        Button {
                            Task { await saveModules() }
                        } label: {
                            if isLoading {
                                ProgressView()
                                    .tint(Color.alefBg)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.alefGold)
                                    .cornerRadius(AlefLayout.cardRadius)
                            } else {
                                Text("Continue")
                                    .font(AlefFont.semibold(17))
                                    .foregroundColor(.alefBg)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(selected.isEmpty ? Color.alefSurfaceSecondary : Color.alefGold)
                                    .cornerRadius(AlefLayout.cardRadius)
                            }
                        }
                        .disabled(selected.isEmpty || isLoading)
                        .padding(.horizontal, AlefLayout.horizontalPadding)
                    }
                    .padding(.bottom, 40)
                    .background(Color.alefBg)
                }
            }
        }
    }

    // MARK: - Module Card

    /// A tappable card representing one module.
    /// Selected state shows a filled background with the module's accent colour.
    private func moduleCard(_ module: ModuleOption) -> some View {
        let isSelected = selected.contains(module.key)

        return Button {
            withAnimation(.spring(response: 0.25)) {
                if isSelected {
                    selected.remove(module.key)
                } else {
                    selected.insert(module.key)
                }
            }
        } label: {
            VStack(spacing: 10) {
                // Icon with coloured background circle
                ZStack {
                    Circle()
                        .fill(isSelected ? module.color.opacity(0.2) : Color.alefSurfaceSecondary.opacity(0.5))
                        .frame(width: 48, height: 48)

                    Image(systemName: module.icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? module.color : .alefTextTertiary)
                }

                // Module name
                Text(module.label)
                    .font(AlefFont.semibold(14))
                    .foregroundColor(isSelected ? .alefText : .alefTextSecondary)

                // Short description
                Text(module.description)
                    .font(AlefFont.regular(11))
                    .foregroundColor(.alefTextTertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: AlefLayout.cardRadius)
                    .fill(isSelected ? module.color.opacity(0.08) : Color.alefSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AlefLayout.cardRadius)
                    .stroke(
                        isSelected ? module.color.opacity(0.4) : Color.alefBorder,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            // Checkmark badge in top-right corner when selected
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(module.color)
                        .offset(x: -8, y: 8)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - API Call

    /// Saves the user's module selection to the backend.
    /// POST /api/modules/setup with the list of enabled module keys.
    private func saveModules() async {
        guard !selected.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        let url = URL(string: "http://192.168.1.114:3002/api/modules/setup")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(
            withJSONObject: ["enabled": Array(selected)]
        )

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode < 300 {
                onComplete()
            }
        } catch {
            // Silently fail — user can configure modules later from Settings.
            // In production, show an alert or retry.
            onComplete()
        }
    }
}
