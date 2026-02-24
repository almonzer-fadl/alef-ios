//
//  HabitsListView.swift
//  alef
//
//  The daily habits checklist — the main screen of the Habits module.
//
//  Shows today's habits grouped by completion status.
//  Tap a boolean habit to toggle it. Numeric habits show a counter
//  with +/- buttons. Timer habits show elapsed time.
//
//  Pull to refresh. FAB to create new habits.
//  Empty state encourages users to create their first habit.
//

import SwiftUI

struct HabitsListView: View {
    @StateObject private var vm = HabitsViewModel()
    @AppStorage("authToken") private var authToken = ""

    var body: some View {
        ZStack {
            Color.alefBg.ignoresSafeArea()

            if vm.isLoading {
                ProgressView()
                    .tint(.alefText)
            } else if vm.todayHabits.isEmpty {
                emptyState
            } else {
                habitsList
            }

            // ── Floating action button ───────────────────────────
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

    // MARK: - Habits List

    private var habitsList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // ── Header ───────────────────────────────────────
                header
                    .padding(.horizontal, AlefLayout.horizontalPadding)
                    .padding(.top, 16)

                // ── Habit cards ──────────────────────────────────
                LazyVStack(spacing: AlefLayout.itemSpacing) {
                    ForEach(vm.todayHabits) { habit in
                        NavigationLink(destination: HabitDetailView(habitId: habit.id, token: authToken)) {
                            HabitCard(habit: habit) {
                                Task { await vm.toggleCompletion(for: habit) }
                            } onIncrement: { step in
                                Task { await vm.increment(for: habit, by: step) }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AlefLayout.horizontalPadding)
                .padding(.top, 16)
                .padding(.bottom, 100) // space for FAB
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(formattedDate)
                .font(AlefFont.regular(14))
                .foregroundColor(.alefTextSecondary)

            HStack(alignment: .firstTextBaseline) {
                Text("Today")
                    .font(AlefFont.bold(28))
                    .foregroundColor(.alefText)

                Spacer()

                // Completion counter
                let done = vm.todayHabits.filter(\.completed).count
                let total = vm.todayHabits.count
                Text("\(done)/\(total)")
                    .font(AlefFont.Rounded.bold(20))
                    .foregroundColor(done == total ? .alefSuccess : .alefTextSecondary)
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

    /// Format today's date as "Saturday, Mar 7"
    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: Date())
    }
}
