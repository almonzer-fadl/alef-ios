//
//  SearchView.swift
//  alef
//
//  Universal search across all modules.
//
//  Searches habits by name, journal entries by content/tags,
//  and health logs by notes. Results are grouped by module
//  with the search term highlighted.
//
//  Accessible from the Dashboard via a search bar or magnifying glass.
//

import SwiftUI

struct SearchView: View {
    @AppStorage("authToken") private var authToken = ""

    @State private var query = ""
    @State private var habits: [TodayHabit] = []
    @State private var journalEntries: [JournalEntry] = []
    @State private var isSearching = false

    @FocusState private var isSearchFocused: Bool

    private let habitService = HabitService()
    private let journalService = JournalService()

    var filteredHabits: [TodayHabit] {
        guard !query.isEmpty else { return [] }
        let q = query.lowercased()
        return habits.filter { $0.name.lowercased().contains(q) || ($0.groupName?.lowercased().contains(q) ?? false) }
    }

    var filteredJournal: [JournalEntry] {
        guard !query.isEmpty else { return [] }
        let q = query.lowercased()
        return journalEntries.filter {
            $0.content.lowercased().contains(q) ||
            ($0.tags?.joined(separator: " ").lowercased().contains(q) ?? false)
        }
    }

    var hasResults: Bool {
        !filteredHabits.isEmpty || !filteredJournal.isEmpty
    }

    var body: some View {
        ZStack {
            Color.alefBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Search bar ────────────────────────────────
                searchBar
                    .padding(.horizontal, AlefLayout.horizontalPadding)
                    .padding(.top, 8)

                if query.isEmpty {
                    // ── Recent / suggestions ─────────────────
                    recentSection
                } else if !hasResults {
                    // ── No results ───────────────────────────
                    noResultsView
                } else {
                    // ── Results ──────────────────────────────
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            if !filteredHabits.isEmpty {
                                resultSection(title: "Habits", icon: "checkmark.circle.fill", color: .alefHabits) {
                                    ForEach(filteredHabits) { habit in
                                        NavigationLink(destination: HabitDetailView(habitId: habit.id, token: authToken)) {
                                            habitResultRow(habit)
                                        }
                                    }
                                }
                            }

                            if !filteredJournal.isEmpty {
                                resultSection(title: "Journal", icon: "book.fill", color: .alefJournal) {
                                    ForEach(filteredJournal) { entry in
                                        journalResultRow(entry)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, AlefLayout.horizontalPadding)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadData() }
        .onAppear { isSearchFocused = true }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(.alefTextTertiary)

            TextField("", text: $query, prompt: Text("Search habits, journal...").foregroundColor(.alefTextTertiary))
                .font(AlefFont.regular(16))
                .foregroundColor(.alefText)
                .focused($isSearchFocused)
                .autocorrectionDisabled()

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.alefTextTertiary)
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(Color.alefSurface)
        .cornerRadius(12)
    }

    // MARK: - Result Section

    private func resultSection<Content: View>(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(color)
                Text(title.uppercased())
                    .font(AlefFont.medium(11))
                    .foregroundColor(.alefTextTertiary)
                    .tracking(1)
            }

            content()
        }
    }

    // MARK: - Habit Result Row

    private func habitResultRow(_ habit: TodayHabit) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(habit.swiftUIColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: habit.icon ?? "circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(habit.swiftUIColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(AlefFont.medium(15))
                    .foregroundColor(.alefText)
                if let group = habit.groupName {
                    Text(group)
                        .font(AlefFont.regular(12))
                        .foregroundColor(.alefTextTertiary)
                }
            }

            Spacer()

            Image(systemName: habit.completed ? "checkmark.circle.fill" : "circle")
                .foregroundColor(habit.completed ? .alefSuccess : .alefSurfaceSecondary)
        }
        .padding(12)
        .background(Color.alefSurface)
        .cornerRadius(AlefLayout.cardRadius)
    }

    // MARK: - Journal Result Row

    private func journalResultRow(_ entry: JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(formatDate(entry.date))
                    .font(AlefFont.medium(12))
                    .foregroundColor(.alefTextTertiary)
                Spacer()
                if let mood = entry.mood {
                    Image(systemName: mood.icon)
                        .font(.system(size: 12))
                        .foregroundColor(mood.color)
                }
            }

            Text(highlightedText(entry.content, query: query))
                .font(AlefFont.regular(14))
                .foregroundColor(.alefText)
                .lineLimit(3)

            if let tags = entry.tags, !tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(tags.prefix(3), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(AlefFont.regular(11))
                            .foregroundColor(.alefJournal)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.alefSurface)
        .cornerRadius(AlefLayout.cardRadius)
    }

    // MARK: - Recent Section

    private var recentSection: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(.alefTextTertiary.opacity(0.3))

            Text("Search across all your data")
                .font(AlefFont.regular(15))
                .foregroundColor(.alefTextTertiary)
            Spacer()
        }
    }

    // MARK: - No Results

    private var noResultsView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(.alefTextTertiary.opacity(0.3))

            Text("No results for \"\(query)\"")
                .font(AlefFont.medium(16))
                .foregroundColor(.alefTextSecondary)

            Text("Try a different search term")
                .font(AlefFont.regular(13))
                .foregroundColor(.alefTextTertiary)
            Spacer()
        }
    }

    // MARK: - Data

    private func loadData() async {
        guard !authToken.isEmpty else { return }

        do {
            let response = try await habitService.fetchToday(token: authToken)
            habits = response.habits
        } catch {}

        do {
            journalEntries = try await journalService.fetchRecent(token: authToken, limit: 100)
        } catch {}
    }

    // MARK: - Helpers

    private func formatDate(_ dateStr: String) -> String {
        let input = DateFormatter()
        input.dateFormat = "yyyy-MM-dd"
        guard let date = input.date(from: dateStr) else { return dateStr }
        let output = DateFormatter()
        output.dateFormat = "MMM d, yyyy"
        return output.string(from: date)
    }

    /// Returns an AttributedString with the query highlighted in gold.
    private func highlightedText(_ text: String, query: String) -> AttributedString {
        var result = AttributedString(text)
        guard !query.isEmpty else { return result }

        let lowered = text.lowercased()
        let queryLower = query.lowercased()

        var searchStart = lowered.startIndex
        while let range = lowered.range(of: queryLower, range: searchStart..<lowered.endIndex) {
            // Map String range to AttributedString range
            if let attrRange = Range(NSRange(range, in: text), in: result) {
                result[attrRange].foregroundColor = .alefGold
                result[attrRange].font = AlefFont.semibold(14)
            }
            searchStart = range.upperBound
        }

        return result
    }
}
