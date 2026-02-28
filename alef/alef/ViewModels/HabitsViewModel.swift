//
//  HabitsViewModel.swift
//  alef
//
//  Drives the daily habits checklist and habit management.
//
//  Responsibilities:
//  - Fetch today's habits from the API
//  - Toggle habit completion (tap to complete/uncomplete)
//  - Update numeric values (increment/decrement)
//  - Create new habits
//  - Delete habits
//  - Calculate streaks from log history (client-side)
//
//  The ViewModel is the single source of truth for habit state.
//  Views observe @Published properties and react to changes.
//

import SwiftUI
import Combine

@MainActor
final class HabitsViewModel: ObservableObject {

    // MARK: - Published State

    /// Today's habits with completion status — drives the daily checklist.
    @Published var todayHabits: [TodayHabit] = []

    /// Today's date string (YYYY-MM-DD) from the API.
    @Published var todayDate: String = ""

    /// Loading state for the initial fetch.
    @Published var isLoading = false

    /// Error message to display in the UI.
    @Published var error: String?

    /// Controls the create habit sheet presentation.
    @Published var showCreateSheet = false

    // MARK: - Dependencies

    private let service = HabitService()

    /// Auth token — injected from the view's @AppStorage.
    var token: String = ""

    // MARK: - Fetch

    /// Load today's habits from the API.
    /// Called on appear and after creating/deleting habits.
    func fetchToday() async {
        guard !token.isEmpty else { return }
        isLoading = todayHabits.isEmpty // only show spinner on first load
        error = nil

        do {
            let response = try await service.fetchToday(token: token)
            todayHabits = response.habits
            todayDate = response.date
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Toggle Completion

    /// Toggle a boolean habit's completion state.
    /// For boolean habits: flips between 0 and 1.
    /// For numeric habits: sets to goalValue (complete) or 0.
    func toggleCompletion(for habit: TodayHabit) async {
        let newValue = habit.completed ? 0 : (habit.goalValue ?? 1)
        let body = LogEntryBody(date: todayDate, value: newValue)

        do {
            _ = try await service.log(habitId: habit.id, body: body, token: token)
            // Refresh the list to get updated completion status
            await fetchToday()
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Increment a numeric habit's value by a step amount.
    /// Used for water intake, page counts, etc.
    func increment(for habit: TodayHabit, by step: Int = 1) async {
        let current = habit.todayEntry?.value ?? 0
        let body = LogEntryBody(date: todayDate, value: current + step)

        do {
            _ = try await service.log(habitId: habit.id, body: body, token: token)
            await fetchToday()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Create

    /// Create a new habit and refresh the list.
    func createHabit(_ body: CreateHabitBody) async {
        do {
            _ = try await service.create(body, token: token)
            showCreateSheet = false
            await fetchToday()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Skip

    /// Mark a habit as skipped for today.
    /// Skipped habits don't break streaks.
    func skipHabit(for habit: TodayHabit) async {
        let body = LogEntryBody(date: todayDate, skipped: true)
        do {
            _ = try await service.log(habitId: habit.id, body: body, token: token)
            await fetchToday()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Delete

    /// Delete a habit permanently. Shows in the detail view.
    func deleteHabit(id: String) async {
        do {
            try await service.delete(id: id, token: token)
            await fetchToday()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Streaks

    /// Calculate the current streak for a habit from its log entries.
    /// A streak is consecutive days with value >= goalValue.
    /// Skipped days don't break the streak.
    static func calculateStreak(entries: [HabitEntry], goalValue: Int) -> Int {
        // Entries come sorted newest-first from the API
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var streak = 0
        var expectedDate = Date()

        for entry in entries {
            guard let entryDate = dateFormatter.date(from: entry.date) else { continue }

            // Check if this entry is for the expected date (allowing for skips)
            let calendar = Calendar.current
            let dayDiff = calendar.dateComponents([.day], from: entryDate, to: expectedDate).day ?? 0

            if dayDiff > 1 {
                // Gap of more than 1 day — streak is broken
                break
            }

            if entry.skipped {
                // Skipped days don't break the streak but don't count either
                expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate)!
                continue
            }

            if entry.value >= goalValue {
                streak += 1
                expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate)!
            } else {
                break
            }
        }

        return streak
    }
}
