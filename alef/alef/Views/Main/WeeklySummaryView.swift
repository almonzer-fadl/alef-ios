//
//  WeeklySummaryView.swift
//  alef
//
//  End-of-week summary showing overall progress across all modules.
//
//  Layout:
//  1. Week range header
//  2. Radial chart with daily completion rates
//  3. Module breakdown (habits done, journal entries, health logs)
//  4. Highlights & streaks
//
//  Accessible from Dashboard via a "This Week" button.
//

import SwiftUI

struct WeeklySummaryView: View {
    @AppStorage("authToken") private var authToken = ""

    @State private var habitsData: [TodayHabit] = []
    @State private var journalEntries: [JournalEntry] = []
    @State private var healthLogs: [HealthLog] = []
    @State private var isLoading = true

    private let habitService = HabitService()
    private let journalService = JournalService()
    private let healthService = HealthService()

    var body: some View {
        ZStack {
            Color.alefBg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AlefLayout.sectionSpacing) {

                    // ── Header ───────────────────────────────────
                    weekHeader
                        .padding(.top, 16)

                    // ── Weekly bar chart ──────────────────────────
                    weeklyChart

                    // ── Module stats ─────────────────────────────
                    moduleStats

                    // ── Motivation ───────────────────────────────
                    motivationCard

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, AlefLayout.horizontalPadding)
            }
        }
        .navigationTitle("This Week")
        .task { await loadData() }
    }

    // MARK: - Header

    private var weekHeader: some View {
        let (start, end) = weekRange()
        return VStack(alignment: .leading, spacing: 4) {
            Text("WEEKLY SUMMARY")
                .font(AlefFont.medium(11))
                .foregroundColor(.alefTextTertiary)
                .tracking(1)
            Text("\(start) – \(end)")
                .font(AlefFont.bold(22))
                .foregroundColor(.alefText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Weekly Chart

    private var weeklyChart: some View {
        VStack(spacing: 16) {
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { dayOffset in
                    let rate = dayCompletionRate(offset: dayOffset)
                    VStack(spacing: 6) {
                        // Bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(rate > 0
                                ? Color.alefHabits.opacity(max(0.3, rate))
                                : Color.alefSurfaceSecondary.opacity(0.2)
                            )
                            .frame(height: max(8, CGFloat(rate) * 100))

                        // Day label
                        Text(dayLabel(offset: dayOffset))
                            .font(AlefFont.medium(11))
                            .foregroundColor(isToday(offset: dayOffset) ? .alefText : .alefTextTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 120, alignment: .bottom)

            // Average line
            let avg = averageRate()
            HStack {
                Text("Average: \(Int(avg * 100))%")
                    .font(AlefFont.Rounded.semibold(13))
                    .foregroundColor(.alefTextSecondary)
                Spacer()
                Text(ratingText(avg))
                    .font(AlefFont.medium(13))
                    .foregroundColor(ratingColor(avg))
            }
        }
        .padding(16)
        .background(Color.alefSurface)
        .cornerRadius(AlefLayout.cardRadius)
    }

    // MARK: - Module Stats

    private var moduleStats: some View {
        VStack(spacing: 12) {
            // Habits
            moduleSummaryRow(
                icon: "checkmark.circle.fill",
                name: "Habits",
                color: .alefHabits,
                value: "\(habitsData.filter(\.completed).count)/\(habitsData.count)",
                detail: "completed today"
            )

            // Journal
            moduleSummaryRow(
                icon: "book.fill",
                name: "Journal",
                color: .alefJournal,
                value: "\(journalEntries.count)",
                detail: "entries this week"
            )

            // Health
            moduleSummaryRow(
                icon: "heart.fill",
                name: "Health",
                color: .alefHealth,
                value: "\(healthLogs.count)",
                detail: "logs this week"
            )
        }
    }

    private func moduleSummaryRow(icon: String, name: String, color: Color, value: String, detail: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(AlefFont.semibold(15))
                    .foregroundColor(.alefText)
                Text(detail)
                    .font(AlefFont.regular(12))
                    .foregroundColor(.alefTextTertiary)
            }

            Spacer()

            Text(value)
                .font(AlefFont.Rounded.bold(20))
                .foregroundColor(.alefText)
        }
        .padding(14)
        .background(Color.alefSurface)
        .cornerRadius(AlefLayout.cardRadius)
    }

    // MARK: - Motivation Card

    private var motivationCard: some View {
        let avg = averageRate()
        let message: String
        if avg >= 0.9 {
            message = "Exceptional week. You're building something real."
        } else if avg >= 0.7 {
            message = "Solid week. Consistency is the compound interest of self-improvement."
        } else if avg >= 0.4 {
            message = "Progress isn't always linear. Keep showing up."
        } else {
            message = "Every day is a fresh start. Tomorrow is unwritten."
        }

        return VStack(spacing: 12) {
            Image(systemName: "quote.opening")
                .font(.system(size: 24))
                .foregroundColor(.alefGold.opacity(0.4))

            Text(message)
                .font(AlefFont.medium(15))
                .foregroundColor(.alefTextSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.alefSurface)
        .cornerRadius(AlefLayout.cardRadius)
    }

    // MARK: - Data

    private func loadData() async {
        guard !authToken.isEmpty else { isLoading = false; return }

        do {
            let response = try await habitService.fetchToday(token: authToken)
            habitsData = response.habits
        } catch {}

        do {
            journalEntries = try await journalService.fetchRecent(token: authToken, limit: 7)
        } catch {}

        do {
            healthLogs = try await healthService.fetchRecent(token: authToken, limit: 7)
        } catch {}

        isLoading = false
    }

    // MARK: - Helpers

    private func weekRange() -> (String, String) {
        let cal = Calendar.current
        let today = Date()
        let startOfWeek = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let endOfWeek = cal.date(byAdding: .day, value: 6, to: startOfWeek)!

        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return (f.string(from: startOfWeek), f.string(from: endOfWeek))
    }

    private func dayLabel(offset: Int) -> String {
        let labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return labels[offset % 7]
    }

    private func isToday(offset: Int) -> Bool {
        let cal = Calendar.current
        let today = Date()
        let startOfWeek = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let day = cal.date(byAdding: .day, value: offset, to: startOfWeek)!
        return cal.isDate(day, inSameDayAs: today)
    }

    private func dayCompletionRate(offset: Int) -> Double {
        // Simplified — uses today's data for the current day
        // Full implementation would query per-day data from the API
        if isToday(offset: offset) {
            let total = habitsData.count
            guard total > 0 else { return 0 }
            return Double(habitsData.filter(\.completed).count) / Double(total)
        }
        return 0
    }

    private func averageRate() -> Double {
        let total = habitsData.count
        guard total > 0 else { return 0 }
        return Double(habitsData.filter(\.completed).count) / Double(total)
    }

    private func ratingText(_ rate: Double) -> String {
        if rate >= 0.9 { return "Excellent" }
        if rate >= 0.7 { return "Good" }
        if rate >= 0.4 { return "Fair" }
        return "Starting"
    }

    private func ratingColor(_ rate: Double) -> Color {
        if rate >= 0.9 { return .alefSuccess }
        if rate >= 0.7 { return .alefHabits }
        if rate >= 0.4 { return .alefMovies }
        return .alefTextSecondary
    }
}
