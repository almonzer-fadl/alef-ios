//
//  HabitDetailView.swift
//  alef
//
//  Detail screen for a single habit.
//  Shows streak count, completion calendar heatmap, and stats.
//
//  Accessed by tapping a habit card in the daily checklist.
//  The heatmap uses a GitHub-style contribution grid — each cell
//  represents a day, coloured by completion status.
//
//  Also provides edit and delete actions.
//

import SwiftUI

struct HabitDetailView: View {
    let habitId: String
    let token: String

    @State private var habit: Habit?
    @State private var entries: [HabitEntry] = []
    @State private var isLoading = true
    @State private var streak = 0
    @State private var showDeleteAlert = false
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

                        // ── Heatmap calendar ─────────────────────
                        heatmapSection(habit: habit)

                        // ── Recent entries ───────────────────────
                        recentEntries(habit: habit)

                        // ── Delete button ────────────────────────
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Text("Delete Habit")
                                .font(AlefFont.medium(15))
                                .foregroundColor(.alefError)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.alefError.opacity(0.1))
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
                streak = HabitsViewModel.calculateStreak(entries: entries, goalValue: h.goalValue ?? 1)
            }
        } catch {
            // Silently fail — could show error state
        }
        isLoading = false
    }

    // MARK: - Streak Card

    private func streakCard(habit: Habit) -> some View {
        VStack(spacing: 8) {
            Text("\(streak)")
                .font(AlefFont.Rounded.heavy(56))
                .foregroundColor(habit.swiftUIColor)

            Text(streak == 1 ? "day streak" : "day streak")
                .font(AlefFont.medium(15))
                .foregroundColor(.alefTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: AlefLayout.cardRadiusLarge)
                .fill(habit.swiftUIColor.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AlefLayout.cardRadiusLarge)
                .stroke(habit.swiftUIColor.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Stats Row

    private func statsRow(habit: Habit) -> some View {
        HStack(spacing: 12) {
            statCard(
                value: "\(entries.filter { $0.value >= (habit.goalValue ?? 1) }.count)",
                label: "Total Done",
                color: .alefSuccess
            )
            statCard(
                value: "\(entries.count)",
                label: "Total Logged",
                color: .alefHealth
            )
            statCard(
                value: completionRate(habit: habit),
                label: "Success Rate",
                color: .alefMovies
            )
        }
    }

    private func statCard(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AlefFont.Rounded.bold(20))
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

    // MARK: - Heatmap

    private func heatmapSection(habit: Habit) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 90 days")
                .font(AlefFont.medium(13))
                .foregroundColor(.alefTextSecondary)
                .textCase(.uppercase)
                .tracking(0.8)

            HeatmapGrid(entries: entries, goalValue: habit.goalValue ?? 1, color: habit.swiftUIColor)
        }
    }

    // MARK: - Recent Entries

    private func recentEntries(habit: Habit) -> some View {
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
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(entries.prefix(10)) { entry in
                    HStack {
                        // Date
                        Text(formatEntryDate(entry.date))
                            .font(AlefFont.regular(14))
                            .foregroundColor(.alefTextSecondary)

                        Spacer()

                        // Value
                        if entry.skipped {
                            Text("Skipped")
                                .font(AlefFont.medium(14))
                                .foregroundColor(.alefTextTertiary)
                        } else {
                            let met = entry.value >= (habit.goalValue ?? 1)
                            Image(systemName: met ? "checkmark.circle.fill" : "xmark.circle")
                                .foregroundColor(met ? habit.swiftUIColor : .alefTextTertiary)

                            if habit.goalType != .boolean {
                                Text(formatValue(entry.value, habit: habit))
                                    .font(AlefFont.Rounded.medium(14))
                                    .foregroundColor(.alefText)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .padding(16)
        .background(Color.alefSurface)
        .cornerRadius(AlefLayout.cardRadius)
    }

    // MARK: - Helpers

    private func completionRate(habit: Habit) -> String {
        guard !entries.isEmpty else { return "0%" }
        let completed = entries.filter { $0.value >= (habit.goalValue ?? 1) }.count
        let rate = Int(Double(completed) / Double(entries.count) * 100)
        return "\(rate)%"
    }

    private func formatEntryDate(_ dateStr: String) -> String {
        let input = DateFormatter()
        input.dateFormat = "yyyy-MM-dd"
        guard let date = input.date(from: dateStr) else { return dateStr }
        let output = DateFormatter()
        output.dateFormat = "MMM d"
        return output.string(from: date)
    }

    private func formatValue(_ value: Int, habit: Habit) -> String {
        switch habit.goalType {
        case .boolean: return value > 0 ? "Done" : "Missed"
        case .numeric: return "\(value) \(habit.goalUnit ?? "")"
        case .timer:
            let mins = value / 60
            return mins < 60 ? "\(mins)m" : "\(mins/60)h \(mins%60)m"
        }
    }
}

// MARK: - Heatmap Grid

/// GitHub-style contribution heatmap for the last 90 days.
/// Each cell is a day — darker colour = completed, grey = missed.
struct HeatmapGrid: View {
    let entries: [HabitEntry]
    let goalValue: Int
    let color: Color

    /// 13 columns (weeks) x 7 rows (days) = 91 days
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 13)

    var body: some View {
        let entryMap = Dictionary(grouping: entries, by: \.date)
            .mapValues { $0.first! }

        let calendar = Calendar.current
        let today = Date()
        let days = (0..<91).reversed().map { offset in
            calendar.date(byAdding: .day, value: -offset, to: today)!
        }

        LazyVGrid(columns: columns, spacing: 3) {
            ForEach(days, id: \.self) { date in
                let dateStr = formatDate(date)
                let entry = entryMap[dateStr]
                let completed = (entry?.value ?? 0) >= goalValue
                let isToday = calendar.isDateInToday(date)

                RoundedRectangle(cornerRadius: 3)
                    .fill(cellColor(completed: completed, hasEntry: entry != nil))
                    .frame(height: 14)
                    .overlay(
                        // Subtle border for today
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(isToday ? Color.alefText.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            }
        }
    }

    private func cellColor(completed: Bool, hasEntry: Bool) -> Color {
        if completed { return color }
        if hasEntry { return color.opacity(0.15) }
        return Color.alefSurfaceSecondary.opacity(0.3)
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
