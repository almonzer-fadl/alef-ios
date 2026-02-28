//
//  HabitsListView.swift
//  alef
//
//  The daily habits checklist — main screen of the Habits module.
//
//  Layout (top to bottom):
//  1. Day selector — horizontal scrolling week strip with dot indicators
//  2. Progress ring — circular completion percentage for the day
//  3. Habit cards — grouped by groupName, each with streak badge
//  4. FAB — floating + button to create new habits
//
//  Inspired by Grit: day selector at top, per-habit streaks,
//  completion ring, coloured cards with satisfying tap animations.
//

import SwiftUI

struct HabitsListView: View {
    @StateObject private var vm = HabitsViewModel()
    @AppStorage("authToken") private var authToken = ""

    /// Which day is selected in the week strip.
    /// Defaults to today — tapping other days could show history (future feature).
    @State private var selectedDayOffset = 0

    var body: some View {
        ZStack {
            Color.alefBg.ignoresSafeArea()

            if vm.isLoading {
                ProgressView()
                    .tint(.alefText)
            } else if vm.todayHabits.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {

                        // ── Day selector strip ──────────────────
                        daySelectorStrip
                            .padding(.top, 8)

                        // ── Progress summary ────────────────────
                        progressHeader
                            .padding(.top, 20)
                            .padding(.horizontal, AlefLayout.horizontalPadding)

                        // ── Habit cards ──────────────────────────
                        habitSections
                            .padding(.top, 20)
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
                        vm.showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.alefBg)
                            .frame(width: 56, height: 56)
                            .background(Color.alefHabits)
                            .clipShape(Circle())
                            .shadow(color: Color.alefHabits.opacity(0.3), radius: 8, y: 4)
                    }
                    .padding(.trailing, AlefLayout.horizontalPadding)
                    .padding(.bottom, 24)
                }
            }
        }
        .task {
            vm.token = authToken
            await vm.fetchToday()
        }
        .refreshable {
            await vm.fetchToday()
        }
        .sheet(isPresented: $vm.showCreateSheet) {
            CreateHabitView(vm: vm)
        }
    }

    // MARK: - Day Selector Strip

    /// Horizontal scrolling week strip showing 7 days.
    /// Today is centered and highlighted. Each day shows a coloured dot
    /// if all habits were completed that day.
    private var daySelectorStrip: some View {
        let calendar = Calendar.current
        let today = Date()
        // Show 3 days before + today + 3 days after
        let days = (-3...3).map { offset in
            calendar.date(byAdding: .day, value: offset, to: today)!
        }

        return ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(days.enumerated()), id: \.offset) { index, date in
                        let offset = index - 3 // -3 to +3, 0 = today
                        let isSelected = offset == selectedDayOffset
                        let isToday = offset == 0

                        Button {
                            Haptics.selection()
                            withAnimation(.spring(response: 0.3)) {
                                selectedDayOffset = offset
                            }
                        } label: {
                            VStack(spacing: 6) {
                                // Day name (M, T, W...)
                                Text(dayName(date))
                                    .font(AlefFont.medium(12))
                                    .foregroundColor(isSelected ? .alefText : .alefTextTertiary)

                                // Day number
                                Text("\(calendar.component(.day, from: date))")
                                    .font(AlefFont.Rounded.bold(isSelected ? 18 : 16))
                                    .foregroundColor(isSelected ? .alefBg : .alefTextSecondary)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        Circle()
                                            .fill(isSelected ? Color.alefHabits : Color.clear)
                                    )

                                // Completion dot
                                Circle()
                                    .fill(isToday ? Color.alefHabits.opacity(0.4) : Color.clear)
                                    .frame(width: 5, height: 5)
                            }
                            .frame(width: 52)
                        }
                        .id(offset)
                    }
                }
                .padding(.horizontal, AlefLayout.horizontalPadding)
            }
            .onAppear {
                proxy.scrollTo(0, anchor: .center)
            }
        }
    }

    // MARK: - Progress Header

    /// Circular progress ring showing today's completion percentage,
    /// plus a completion counter.
    private var progressHeader: some View {
        let done = vm.todayHabits.filter(\.completed).count
        let total = vm.todayHabits.count
        let progress = total > 0 ? Double(done) / Double(total) : 0

        return HStack(spacing: 20) {
            // ── Progress ring ──────────────────
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.alefSurfaceSecondary.opacity(0.3), lineWidth: 6)
                    .frame(width: 64, height: 64)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        done == total ? Color.alefSuccess : Color.alefHabits,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6), value: progress)

                // Percentage text
                Text("\(Int(progress * 100))%")
                    .font(AlefFont.Rounded.bold(16))
                    .foregroundColor(.alefText)
            }

            // ── Text summary ───────────────────
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate)
                    .font(AlefFont.regular(13))
                    .foregroundColor(.alefTextTertiary)

                Text("Today")
                    .font(AlefFont.bold(24))
                    .foregroundColor(.alefText)

                Text("\(done) of \(total) completed")
                    .font(AlefFont.regular(14))
                    .foregroundColor(.alefTextSecondary)
            }

            Spacer()
        }
    }

    // MARK: - Habit Sections

    /// Habit cards grouped by groupName.
    /// Ungrouped habits appear in an "All Habits" section.
    private var habitSections: some View {
        let grouped = Dictionary(grouping: vm.todayHabits) { $0.groupName ?? "" }
        let sortedKeys = grouped.keys.sorted { a, b in
            if a.isEmpty { return false }
            if b.isEmpty { return true }
            return a < b
        }

        return LazyVStack(spacing: 20) {
            ForEach(sortedKeys, id: \.self) { key in
                VStack(alignment: .leading, spacing: AlefLayout.itemSpacing) {
                    // Group header (skip for ungrouped)
                    if !key.isEmpty {
                        Text(key)
                            .font(AlefFont.semibold(14))
                            .foregroundColor(.alefTextSecondary)
                            .textCase(.uppercase)
                            .tracking(0.8)
                    }

                    ForEach(grouped[key] ?? []) { habit in
                        NavigationLink(destination: HabitDetailView(habitId: habit.id, token: authToken)) {
                            HabitCard(habit: habit) {
                                Task { await vm.toggleCompletion(for: habit) }
                            } onIncrement: { step in
                                Task { await vm.increment(for: habit, by: step) }
                            }
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                Task { await vm.toggleCompletion(for: habit) }
                            } label: {
                                Label(
                                    habit.completed ? "Mark Incomplete" : "Mark Complete",
                                    systemImage: habit.completed ? "xmark.circle" : "checkmark.circle.fill"
                                )
                            }

                            Button {
                                Task { await vm.skipHabit(for: habit) }
                            } label: {
                                Label("Skip Today", systemImage: "forward.fill")
                            }

                            Divider()

                            Button(role: .destructive) {
                                Task { await vm.deleteHabit(id: habit.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 56, weight: .light))
                .foregroundColor(.alefHabits.opacity(0.3))

            Text("No habits yet")
                .font(AlefFont.bold(20))
                .foregroundColor(.alefText)

            Text("Tap + to create your first habit")
                .font(AlefFont.regular(15))
                .foregroundColor(.alefTextSecondary)
        }
    }

    // MARK: - Helpers

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: Date())
    }

    private func dayName(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: date).uppercased()
    }
}
