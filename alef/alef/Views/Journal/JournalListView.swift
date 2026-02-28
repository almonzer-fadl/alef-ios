//
//  JournalListView.swift
//  alef
//
//  The journal timeline — shows recent entries in a vertical feed.
//
//  Layout:
//  1. Mood filter bar (all / great / good / okay / bad / terrible)
//  2. Scrollable list of entry cards with mood, date, preview, tags
//  3. FAB to compose a new entry
//
//  Inspired by Bevel's journal: clean dark cards, mood indicators,
//  quick scan of recent days.
//

import SwiftUI

struct JournalListView: View {
    @StateObject private var vm = JournalViewModel()
    @AppStorage("authToken") private var authToken = ""

    @State private var showCompose = false
    @State private var selectedMoodFilter: Mood?

    var filteredEntries: [JournalEntry] {
        guard let mood = selectedMoodFilter else { return vm.entries }
        return vm.entries.filter { $0.mood == mood }
    }

    var body: some View {
        ZStack {
            Color.alefBg.ignoresSafeArea()

            if vm.isLoading {
                ProgressView().tint(.alefText)
            } else if vm.entries.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // ── Mood filter ──────────────────────────
                        moodFilter
                            .padding(.top, 8)
                            .padding(.bottom, 16)

                        // ── Entries ──────────────────────────────
                        LazyVStack(spacing: AlefLayout.itemSpacing) {
                            ForEach(filteredEntries) { entry in
                                JournalEntryCard(entry: entry)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            Task { await vm.deleteEntry(id: entry.id) }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, AlefLayout.horizontalPadding)
                        .padding(.bottom, 100)
                    }
                }
            }

            // ── FAB ──────────────────────────────────────────────
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        Haptics.medium()
                        showCompose = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.alefBg)
                            .frame(width: 56, height: 56)
                            .background(Color.alefJournal)
                            .clipShape(Circle())
                            .shadow(color: Color.alefJournal.opacity(0.3), radius: 8, y: 4)
                    }
                    .padding(.trailing, AlefLayout.horizontalPadding)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("Journal")
        .task {
            vm.token = authToken
            await vm.fetchEntries()
        }
        .refreshable { await vm.fetchEntries() }
        .sheet(isPresented: $showCompose) {
            ComposeJournalView(vm: vm)
        }
    }

    // MARK: - Mood Filter

    private var moodFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" filter
                filterChip(label: "All", isSelected: selectedMoodFilter == nil) {
                    selectedMoodFilter = nil
                }

                ForEach(Mood.allCases, id: \.self) { mood in
                    filterChip(
                        label: mood.label,
                        color: mood.color,
                        isSelected: selectedMoodFilter == mood
                    ) {
                        selectedMoodFilter = selectedMoodFilter == mood ? nil : mood
                    }
                }
            }
            .padding(.horizontal, AlefLayout.horizontalPadding)
        }
    }

    private func filterChip(label: String, color: Color = .alefTextSecondary, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            withAnimation(.spring(response: 0.25)) { action() }
        } label: {
            Text(label)
                .font(AlefFont.medium(13))
                .foregroundColor(isSelected ? .alefBg : .alefTextSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(isSelected ? color : Color.alefSurface)
                )
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book")
                .font(.system(size: 56, weight: .light))
                .foregroundColor(.alefJournal.opacity(0.3))

            Text("No entries yet")
                .font(AlefFont.bold(20))
                .foregroundColor(.alefText)

            Text("Tap the pen to write your first entry")
                .font(AlefFont.regular(15))
                .foregroundColor(.alefTextSecondary)
        }
    }
}

// MARK: - Journal Entry Card

struct JournalEntryCard: View {
    let entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // ── Header: date + mood ──────────────────────────
            HStack {
                Text(formatDate(entry.date))
                    .font(AlefFont.medium(13))
                    .foregroundColor(.alefTextSecondary)

                Spacer()

                if let mood = entry.mood {
                    HStack(spacing: 4) {
                        Image(systemName: mood.icon)
                            .font(.system(size: 12))
                        Text(mood.label)
                            .font(AlefFont.medium(12))
                    }
                    .foregroundColor(mood.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(mood.color.opacity(0.1))
                    .clipShape(Capsule())
                }
            }

            // ── Content preview ──────────────────────────────
            Text(entry.content)
                .font(AlefFont.regular(15))
                .foregroundColor(.alefText)
                .lineLimit(4)
                .multilineTextAlignment(.leading)

            // ── Tags ─────────────────────────────────────────
            if let tags = entry.tags, !tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(AlefFont.regular(12))
                            .foregroundColor(.alefJournal)
                    }
                }
            }

            // ── Energy bar ───────────────────────────────────
            if let energy = entry.energyLevel {
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { level in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(level <= energy ? Color.alefDiet : Color.alefSurfaceSecondary.opacity(0.3))
                            .frame(height: 4)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: AlefLayout.cardRadius)
                .fill(Color.alefSurface)
        )
        .overlay(
            // Left accent bar for mood
            HStack {
                if let mood = entry.mood {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(mood.color)
                        .frame(width: 3)
                        .padding(.vertical, 8)
                }
                Spacer()
            }
            .padding(.leading, 4)
        )
    }

    private func formatDate(_ dateStr: String) -> String {
        let input = DateFormatter()
        input.dateFormat = "yyyy-MM-dd"
        guard let date = input.date(from: dateStr) else { return dateStr }
        let output = DateFormatter()
        output.dateFormat = "EEEE, MMM d"
        return output.string(from: date)
    }
}
