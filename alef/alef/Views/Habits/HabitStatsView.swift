//
//  HabitStatsView.swift
//  alef
//
//  Stats overview for the Habits module — shows a GitHub-style
//  contribution heatmap and aggregate statistics.
//
//  Accessible from the habits list nav bar. Shows:
//  1. Heatmap grid (12 weeks of daily completion rates)
//  2. Stats row (total completed, current streak, best streak)
//  3. Per-habit completion rates
//
//  Inspired by Grit's reports screen and GitHub's contribution graph.
//

import SwiftUI

struct HabitStatsView: View {
    @AppStorage("authToken") private var authToken = ""

    @State private var habits: [TodayHabit] = []
    @State private var allLogs: [String: [HabitEntry]] = [:]  // habitId -> entries
    @State private var isLoading = true

    private let service = HabitService()
    private let calendar = Calendar.current
    private let weeksToShow = 12

    var body: some View {
        ZStack {
            Color.alefBg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AlefLayout.sectionSpacing) {

                    // ── Heatmap ──────────────────────────────────
                    heatmapSection
                        .padding(.top, 16)

                    // ── Overall stats ────────────────────────────
                    overallStats

                    // ── Per-habit breakdown ───────────────────────
                    perHabitSection

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, AlefLayout.horizontalPadding)
            }
        }
        .navigationTitle("Stats")
        .task { await loadData() }
    }

    // MARK: - Heatmap

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ACTIVITY")
                .font(AlefFont.medium(11))
                .foregroundColor(.alefTextTertiary)
                .tracking(1)

            // Day labels + grid
            HStack(alignment: .top, spacing: 4) {
                // Day-of-week labels
                VStack(spacing: 3) {
                    Text("").frame(height: 12) // spacer for month labels
                    ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { day in
                        Text(day)
                            .font(AlefFont.regular(9))
                            .foregroundColor(.alefTextTertiary)
                            .frame(width: 12, height: 12)
                    }
                }

                // Heatmap grid
                ScrollView(.horizontal, showsIndicators: false) {
                    let weeks = generateWeeks()
                    HStack(spacing: 3) {
                        ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                            VStack(spacing: 3) {
                                ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                                    heatmapCell(for: day)
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.alefSurface)
            .cornerRadius(AlefLayout.cardRadius)

            // Legend
            HStack(spacing: 4) {
                Text("Less")
                    .font(AlefFont.regular(10))
                    .foregroundColor(.alefTextTertiary)

                ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { intensity in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(intensity == 0 ? Color.alefSurfaceSecondary.opacity(0.3) : Color.alefHabits.opacity(intensity))
                        .frame(width: 12, height: 12)
                }

                Text("More")
                    .font(AlefFont.regular(10))
                    .foregroundColor(.alefTextTertiary)
            }
        }
    }

    private func heatmapCell(for day: HeatmapDay) -> some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(day.isFuture
                ? Color.clear
                : day.rate == 0
                    ? Color.alefSurfaceSecondary.opacity(0.2)
                    : Color.alefHabits.opacity(max(0.2, day.rate))
            )
            .frame(width: 12, height: 12)
    }

    // MARK: - Overall Stats

    private var overallStats: some View {
        let totalCompleted = allLogs.values.flatMap { $0 }.filter { ($0.value ?? 0) > 0 }.count
        let totalDays = Set(allLogs.values.flatMap { $0 }.map(\.date)).count

        return HStack(spacing: 12) {
            statCard(value: "\(totalCompleted)", label: "Completions", icon: "checkmark.circle.fill", color: .alefHabits)
            statCard(value: "\(totalDays)", label: "Active Days", icon: "calendar", color: .alefCalendar)
            statCard(value: "\(habits.count)", label: "Habits", icon: "list.bullet", color: .alefJournal)
        }
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)

            Text(value)
                .font(AlefFont.Rounded.bold(22))
                .foregroundColor(.alefText)

            Text(label)
                .font(AlefFont.regular(11))
                .foregroundColor(.alefTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.alefSurface)
        .cornerRadius(AlefLayout.cardRadius)
    }

    // MARK: - Per-Habit Section

    private var perHabitSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PER HABIT")
                .font(AlefFont.medium(11))
                .foregroundColor(.alefTextTertiary)
                .tracking(1)

            ForEach(habits) { habit in
                let logs = allLogs[habit.id] ?? []
                let completed = logs.filter { ($0.value ?? 0) >= (habit.goalValue ?? 1) }.count
                let total = max(logs.count, 1)
                let rate = Double(completed) / Double(total)

                HStack(spacing: 12) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(habit.swiftUIColor.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: habit.icon ?? "circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(habit.swiftUIColor)
                    }

                    // Name + rate
                    VStack(alignment: .leading, spacing: 2) {
                        Text(habit.name)
                            .font(AlefFont.medium(14))
                            .foregroundColor(.alefText)
                        Text("\(completed) of \(total) days")
                            .font(AlefFont.regular(12))
                            .foregroundColor(.alefTextTertiary)
                    }

                    Spacer()

                    // Completion rate
                    Text("\(Int(rate * 100))%")
                        .font(AlefFont.Rounded.bold(16))
                        .foregroundColor(rate >= 0.8 ? .alefSuccess : rate >= 0.5 ? .alefMovies : .alefError)
                }
                .padding(12)
                .background(Color.alefSurface)
                .cornerRadius(AlefLayout.cardRadius)
            }
        }
    }

    // MARK: - Data

    private func loadData() async {
        guard !authToken.isEmpty else { isLoading = false; return }

        do {
            // Fetch habits
            let response: TodayResponse = try await APIClient.shared.request(
                "GET", "/habits/today", token: authToken
            )
            habits = response.habits

            // Fetch logs for each habit
            for habit in habits {
                let logsResponse: HabitLogsResponse = try await APIClient.shared.request(
                    "GET", "/habits/\(habit.id)/logs?limit=100", token: authToken
                )
                allLogs[habit.id] = logsResponse.logs
            }
        } catch {}
        isLoading = false
    }

    // MARK: - Heatmap Data Generation

    private func generateWeeks() -> [[HeatmapDay]] {
        let today = Date()
        var weeks: [[HeatmapDay]] = []

        // Go back weeksToShow weeks
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let start = calendar.date(byAdding: .weekOfYear, value: -(weeksToShow - 1), to: startOfWeek)!

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        // Build a set of all completion dates across all habits
        var completionsByDate: [String: (completed: Int, total: Int)] = [:]
        let habitCount = habits.count

        for (_, logs) in allLogs {
            for log in logs {
                let date = log.date
                var existing = completionsByDate[date] ?? (0, habitCount)
                if (log.value ?? 0) > 0 {
                    existing.completed += 1
                }
                completionsByDate[date] = existing
            }
        }

        for weekOffset in 0..<weeksToShow {
            var week: [HeatmapDay] = []
            let weekStart = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: start)!

            for dayOffset in 0..<7 {
                // Monday-based week
                let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart)!
                let dateStr = formatter.string(from: day)
                let isFuture = day > today

                let rate: Double
                if let data = completionsByDate[dateStr], habitCount > 0 {
                    rate = Double(data.completed) / Double(habitCount)
                } else {
                    rate = 0
                }

                week.append(HeatmapDay(date: dateStr, rate: rate, isFuture: isFuture))
            }
            weeks.append(week)
        }

        return weeks
    }
}

// MARK: - Supporting Types

private struct HeatmapDay {
    let date: String
    let rate: Double    // 0.0 to 1.0 — completion ratio
    let isFuture: Bool
}

struct HabitLogsResponse: Codable {
    let logs: [HabitEntry]
}
