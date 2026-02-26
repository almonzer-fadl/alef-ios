//
//  HabitDetailView.swift
//  alef
//
//  Detail screen for a single habit — streak, calendar, stats.
//
//  Layout (top to bottom):
//  1. Streak card — large number with flame icon
//  2. Stats row — total done, logged, success rate
//  3. Calendar heatmap — monthly view with coloured day circles
//  4. Recent entries — last 10 log entries
//  5. Actions — edit/delete
//
//  Inspired by Grit: per-habit calendar with coloured dots,
//  streak prominently displayed, stats summary row.
//

import SwiftUI

struct HabitDetailView: View {
    let habitId: String
    let token: String

    @State private var habit: Habit?
    @State private var entries: [HabitEntry] = []
    @State private var isLoading = true
    @State private var streak = 0
    @State private var bestStreak = 0
    @State private var showDeleteAlert = false
    @State private var displayedMonth = Date()
    @Environment(\.dismiss) private var dismiss

    private let service = HabitService()

    var body: some View {
        ZStack {
            Color.alefBg.ignoresSafeArea()

            if isLoading {
                ProgressView().tint(.alefText)
            } else if let habit {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AlefLayout.sectionSpacing) {

                        // ── Streak card ──────────────────────────
                        streakCard(habit: habit)

                        // ── Stats row ────────────────────────────
                        statsRow(habit: habit)

                        // ── Monthly calendar ─────────────────────
                        calendarSection(habit: habit)

                        // ── Recent entries ───────────────────────
                        recentSection(habit: habit)

                        // ── Delete ───────────────────────────────
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Text("Delete Habit")
                                .font(AlefFont.medium(15))
                                .foregroundColor(.alefError)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.alefError.opacity(0.08))
                                .cornerRadius(12)
                        }

                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, AlefLayout.horizontalPadding)
                    .padding(.top, 16)
                }
            }
        }
        .navigationTitle(habit?.name ?? "Habit")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadData() }
        .alert("Delete this habit?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    try? await service.delete(id: habitId, token: token)
                    dismiss()
                }
            }
        } message: {
            Text("This will permanently delete the habit and all its history.")
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true
        do {
            let allHabits = try await service.fetchAll(token: token, includeArchived: true)
            habit = allHabits.first { $0.id == habitId }
            entries = try await service.fetchLogs(habitId: habitId, token: token)
            if let h = habit {
                let goalVal = h.goalValue ?? 1
                streak = HabitsViewModel.calculateStreak(entries: entries, goalValue: goalVal)
                bestStreak = calculateBestStreak(entries: entries, goalValue: goalVal)
            }
        } catch {}
        isLoading = false
    }

    // MARK: - Streak Card

    private func streakCard(habit: Habit) -> some View {
        HStack(spacing: 24) {
            // Current streak
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                    Text("\(streak)")
                        .font(AlefFont.Rounded.heavy(44))
                        .foregroundColor(.alefText)
                }
                Text("Current Streak")
                    .font(AlefFont.medium(13))
                    .foregroundColor(.alefTextSecondary)
            }

            // Divider
            Rectangle()
                .fill(Color.alefBorder)
                .frame(width: 1, height: 50)

            // Best streak
            VStack(spacing: 6) {
                Text("\(bestStreak)")
                    .font(AlefFont.Rounded.heavy(44))
                    .foregroundColor(habit.swiftUIColor)
                Text("Best Streak")
                    .font(AlefFont.medium(13))
                    .foregroundColor(.alefTextSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: AlefLayout.cardRadiusLarge)
                .fill(Color.alefSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AlefLayout.cardRadiusLarge)
                .stroke(Color.alefBorder, lineWidth: 1)
        )
    }

    // MARK: - Stats Row

    private func statsRow(habit: Habit) -> some View {
        let goalVal = habit.goalValue ?? 1
        let completed = entries.filter { $0.value >= goalVal }.count
        let rate = entries.isEmpty ? 0 : Int(Double(completed) / Double(entries.count) * 100)

        return HStack(spacing: 10) {
            statCard(value: "\(completed)", label: "Done", color: .alefSuccess)
            statCard(value: "\(entries.count)", label: "Logged", color: .alefHealth)
            statCard(value: "\(rate)%", label: "Rate", color: .alefMovies)
        }
    }

    private func statCard(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AlefFont.Rounded.bold(22))
                .foregroundColor(color)
            Text(label)
                .font(AlefFont.regular(11))
                .foregroundColor(.alefTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.alefSurface)
        .cornerRadius(12)
    }

    // MARK: - Calendar Section

    /// Monthly calendar with coloured day circles — like Grit's per-habit calendar.
    /// Navigate between months with arrow buttons.
    private func calendarSection(habit: Habit) -> some View {
        VStack(spacing: 12) {
            // Month navigator
            HStack {
                Button {
                    withAnimation { changeMonth(by: -1) }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.alefTextSecondary)
                        .frame(width: 32, height: 32)
                }

                Spacer()

                Text(monthYearString(displayedMonth))
                    .font(AlefFont.semibold(16))
                    .foregroundColor(.alefText)

                Spacer()

                Button {
                    withAnimation { changeMonth(by: 1) }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.alefTextSecondary)
                        .frame(width: 32, height: 32)
                }
            }

            // Day-of-week headers
            let dayHeaders = ["S", "M", "T", "W", "T", "F", "S"]
            HStack(spacing: 0) {
                ForEach(dayHeaders, id: \.self) { day in
                    Text(day)
                        .font(AlefFont.medium(12))
                        .foregroundColor(.alefTextTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            MonthGrid(
                month: displayedMonth,
                entries: entries,
                goalValue: habit.goalValue ?? 1,
                color: habit.swiftUIColor
            )
        }
        .padding(16)
        .background(Color.alefSurface)
        .cornerRadius(AlefLayout.cardRadius)
    }

    // MARK: - Recent Entries

    private func recentSection(habit: Habit) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent")
                .font(AlefFont.medium(13))
                .foregroundColor(.alefTextSecondary)
                .textCase(.uppercase)
                .tracking(0.8)

            if entries.isEmpty {
                Text("No entries yet")
                    .font(AlefFont.regular(14))
                    .foregroundColor(.alefTextTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(entries.prefix(10)) { entry in
                    HStack {
                        Text(formatEntryDate(entry.date))
                            .font(AlefFont.regular(14))
                            .foregroundColor(.alefTextSecondary)
                        Spacer()
                        if entry.skipped {
                            Text("Skipped")
                                .font(AlefFont.medium(13))
                                .foregroundColor(.alefTextTertiary)
                        } else {
                            let met = entry.value >= (habit.goalValue ?? 1)
                            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(met ? habit.swiftUIColor : .alefTextTertiary)
                            if habit.goalType != .boolean {
                                Text(formatValue(entry.value, habit: habit))
                                    .font(AlefFont.Rounded.medium(13))
                                    .foregroundColor(.alefText)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    if entry.id != entries.prefix(10).last?.id {
                        Divider().background(Color.alefBorder)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.alefSurface)
        .cornerRadius(AlefLayout.cardRadius)
    }

    // MARK: - Helpers

    private func changeMonth(by value: Int) {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }

    private func monthYearString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date)
    }

    private func formatEntryDate(_ dateStr: String) -> String {
        let input = DateFormatter()
        input.dateFormat = "yyyy-MM-dd"
        guard let date = input.date(from: dateStr) else { return dateStr }
        let output = DateFormatter()
        output.dateFormat = "MMM d, EEE"
        return output.string(from: date)
    }

    private func formatValue(_ value: Int, habit: Habit) -> String {
        switch habit.goalType {
        case .boolean: return value > 0 ? "Done" : ""
        case .numeric: return "\(value) \(habit.goalUnit ?? "")"
        case .timer:
            let mins = value / 60
            return mins < 60 ? "\(mins)m" : "\(mins/60)h \(mins%60)m"
        }
    }

    /// Calculate the longest streak in the entire history.
    private func calculateBestStreak(entries: [HabitEntry], goalValue: Int) -> Int {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // Sort entries by date ascending for best-streak calculation
        let sorted = entries
            .filter { !$0.skipped && $0.value >= goalValue }
            .compactMap { entry -> Date? in dateFormatter.date(from: entry.date) }
            .sorted()

        guard !sorted.isEmpty else { return 0 }

        var best = 1
        var current = 1
        let calendar = Calendar.current

        for i in 1..<sorted.count {
            let diff = calendar.dateComponents([.day], from: sorted[i-1], to: sorted[i]).day ?? 0
            if diff == 1 {
                current += 1
                best = max(best, current)
            } else if diff > 1 {
                current = 1
            }
            // diff == 0 means same day, skip
        }

        return best
    }
}

// MARK: - Month Grid

/// Monthly calendar grid with coloured circles for completed days.
/// Like Grit's per-habit calendar view.
struct MonthGrid: View {
    let month: Date
    let entries: [HabitEntry]
    let goalValue: Int
    let color: Color

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

    var body: some View {
        let calendar = Calendar.current
        let entryMap = Dictionary(grouping: entries, by: \.date).mapValues { $0.first! }

        // Get all days in this month + leading empty cells for alignment
        let components = calendar.dateComponents([.year, .month], from: month)
        guard let firstOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else {
            return AnyView(EmptyView())
        }

        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) - 1 // 0=Sun
        let today = calendar.startOfDay(for: Date())
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        return AnyView(
            LazyVGrid(columns: columns, spacing: 6) {
                // Leading empty cells
                ForEach(0..<firstWeekday, id: \.self) { _ in
                    Text("")
                        .frame(height: 36)
                }

                // Day cells
                ForEach(Array(range), id: \.self) { day in
                    let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth)!
                    let dateStr = dateFormatter.string(from: date)
                    let entry = entryMap[dateStr]
                    let completed = (entry?.value ?? 0) >= goalValue
                    let isToday = calendar.isDate(date, inSameDayAs: today)
                    let isFuture = date > today

                    ZStack {
                        // Background circle
                        Circle()
                            .fill(
                                completed ? color :
                                isToday ? color.opacity(0.15) :
                                Color.clear
                            )
                            .frame(width: 32, height: 32)

                        // Today ring
                        if isToday && !completed {
                            Circle()
                                .stroke(color.opacity(0.4), lineWidth: 1.5)
                                .frame(width: 32, height: 32)
                        }

                        // Day number
                        Text("\(day)")
                            .font(AlefFont.Rounded.medium(14))
                            .foregroundColor(
                                completed ? .alefBg :
                                isFuture ? .alefTextTertiary.opacity(0.5) :
                                isToday ? color :
                                .alefTextSecondary
                            )
                    }
                    .frame(height: 36)
                }
            }
        )
    }
}
