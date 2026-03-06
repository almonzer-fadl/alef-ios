//
//  DashboardView.swift
//  alef
//
//  The home screen — a daily snapshot of the user's life data.
//
//  Layout:
//  1. Greeting with date
//  2. Daily progress ring (overall completion across habits)
//  3. Active habits summary cards (top 4 with streaks)
//  4. Quick stats row (habits done, current streak, active modules)
//  5. Module cards — shortcuts to enabled modules
//
//  This view pulls data from the habits API to show today's progress.
//  As more modules are built, their data feeds into the dashboard too.
//

import SwiftUI
import Combine

struct DashboardView: View {
    @AppStorage("authToken") private var authToken = ""
    @State private var todayHabits: [TodayHabit] = []
    @State private var isLoading = true
    @State private var greeting = ""

    private let service = HabitService()

    var body: some View {
        ZStack {
            Color.alefBg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AlefLayout.sectionSpacing) {

                    // ── Header ───────────────────────────────────
                    HStack(alignment: .bottom) {
                        header
                        Spacer()
                        NavigationLink(destination: WeeklySummaryView()) {
                            Text("This Week")
                                .font(AlefFont.medium(13))
                                .foregroundColor(.alefGold)
                        }
                    }
                    .padding(.top, 16)

                    // ── Progress ring ────────────────────────────
                    progressCard

                    // ── Today's habits ───────────────────────────
                    if !todayHabits.isEmpty {
                        todayHabitsSection
                    }

                    // ── Quick stats ──────────────────────────────
                    if !todayHabits.isEmpty {
                        quickStats
                    }

                    // ── Module shortcuts ──────────────────────────
                    modulesSection

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, AlefLayout.horizontalPadding)
            }
        }
        .task {
            updateGreeting()
            await loadData()
        }
        .refreshable {
            await loadData()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(AlefFont.regular(14))
                .foregroundColor(.alefTextSecondary)

            Text(formattedDate)
                .font(AlefFont.bold(24))
                .foregroundColor(.alefText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Progress Card

    private var progressCard: some View {
        let done = todayHabits.filter(\.completed).count
        let total = todayHabits.count
        let progress = total > 0 ? Double(done) / Double(total) : 0

        return VStack(spacing: 16) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.alefSurfaceSecondary.opacity(0.2), lineWidth: 10)
                    .frame(width: 120, height: 120)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        progressGradient(progress: progress),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8), value: progress)

                VStack(spacing: 2) {
                    Text("\(Int(progress * 100))%")
                        .font(AlefFont.Rounded.heavy(32))
                        .foregroundColor(.alefText)
                    Text("daily")
                        .font(AlefFont.regular(12))
                        .foregroundColor(.alefTextTertiary)
                }
            }

            if total > 0 {
                Text("\(done) of \(total) habits completed")
                    .font(AlefFont.regular(14))
                    .foregroundColor(.alefTextSecondary)
            } else {
                Text("No habits yet — create one to get started")
                    .font(AlefFont.regular(14))
                    .foregroundColor(.alefTextTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: AlefLayout.cardRadiusLarge)
                .fill(Color.alefSurface)
        )
    }

    // MARK: - Today's Habits

    private var todayHabitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Focus")
                    .font(AlefFont.semibold(16))
                    .foregroundColor(.alefText)
                Spacer()
                Text("\(todayHabits.filter(\.completed).count)/\(todayHabits.count)")
                    .font(AlefFont.Rounded.semibold(14))
                    .foregroundColor(.alefTextSecondary)
            }

            ForEach(todayHabits.prefix(5)) { habit in
                HStack(spacing: 12) {
                    // Completion indicator
                    Image(systemName: habit.completed ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(habit.completed ? habit.swiftUIColor : .alefSurfaceSecondary)

                    // Habit name
                    Text(habit.name)
                        .font(AlefFont.medium(15))
                        .foregroundColor(habit.completed ? .alefTextSecondary : .alefText)
                        .strikethrough(habit.completed, color: .alefTextTertiary)

                    Spacer()

                    // Icon
                    if let iconName = habit.icon, !iconName.isEmpty {
                        Image(systemName: iconName)
                            .font(.system(size: 14))
                            .foregroundColor(habit.swiftUIColor.opacity(0.5))
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: AlefLayout.cardRadius)
                .fill(Color.alefSurface)
        )
    }

    // MARK: - Quick Stats

    private var quickStats: some View {
        HStack(spacing: 10) {
            quickStatCard(
                icon: "checkmark.circle.fill",
                value: "\(todayHabits.filter(\.completed).count)",
                label: "Done Today",
                color: .alefSuccess
            )
            quickStatCard(
                icon: "flame.fill",
                value: "\(todayHabits.count)",
                label: "Active",
                color: .orange
            )
            quickStatCard(
                icon: "square.grid.2x2.fill",
                value: "3",
                label: "Modules",
                color: .alefCalendar
            )
        }
    }

    private func quickStatCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)

            Text(value)
                .font(AlefFont.Rounded.bold(20))
                .foregroundColor(.alefText)

            Text(label)
                .font(AlefFont.regular(11))
                .foregroundColor(.alefTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.alefSurface)
        .cornerRadius(AlefLayout.cardRadius)
    }

    // MARK: - Module Shortcuts

    /// Quick-access cards for the main modules.
    /// Tapping navigates to the module's screen.
    private var modulesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Modules")
                .font(AlefFont.semibold(16))
                .foregroundColor(.alefText)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                NavigationLink(destination: HabitsListView()) {
                    moduleCard(icon: "checkmark.circle.fill", name: "Habits", color: .alefHabits, subtitle: "Daily tracking")
                }
                NavigationLink(destination: JournalListView()) {
                    moduleCard(icon: "book.fill", name: "Journal", color: .alefJournal, subtitle: "Write & reflect")
                }
                NavigationLink(destination: HealthLogView()) {
                    moduleCard(icon: "heart.fill", name: "Health", color: .alefHealth, subtitle: "Vitals & mood")
                }
                moduleCard(icon: "moon.fill", name: "Sleep", color: .alefSleep, subtitle: "Coming soon")
            }
        }
    }

    private func moduleCard(icon: String, name: String, color: Color, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)

            Text(name)
                .font(AlefFont.semibold(15))
                .foregroundColor(.alefText)

            Text(subtitle)
                .font(AlefFont.regular(12))
                .foregroundColor(.alefTextTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: AlefLayout.cardRadius)
                .fill(Color.alefSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AlefLayout.cardRadius)
                .stroke(Color.alefBorder, lineWidth: 1)
        )
    }

    // MARK: - Data

    private func loadData() async {
        guard !authToken.isEmpty else { isLoading = false; return }
        do {
            let response = try await service.fetchToday(token: authToken)
            todayHabits = response.habits
        } catch {}
        isLoading = false
    }

    // MARK: - Helpers

    private func updateGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  greeting = "Good morning"
        case 12..<17: greeting = "Good afternoon"
        case 17..<21: greeting = "Good evening"
        default:      greeting = "Good night"
        }
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: Date())
    }

    private func progressGradient(progress: Double) -> AngularGradient {
        let color: Color = progress >= 1.0 ? .alefSuccess : .alefHabits
        return AngularGradient(
            colors: [color.opacity(0.6), color],
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360 * progress)
        )
    }
}
