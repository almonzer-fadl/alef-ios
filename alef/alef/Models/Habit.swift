//
//  Habit.swift
//  alef
//
//  Data models for the Habits module.
//
//  Maps to the backend schema:
//  - Habit → `habits` table
//  - HabitEntry → `habit_entries` table
//  - TodayHabit → response from GET /habits/today (habit + today's entry)
//
//  Goal types determine how completion is tracked:
//  - boolean: tap to complete (value = 0 or 1)
//  - numeric: track a number against a target (e.g., 2500ml water)
//  - timer: track duration in seconds (e.g., 600 = 10 minutes)
//

import Foundation
import SwiftUI

// MARK: - Goal Type

/// How a habit's progress is measured.
/// Determines the UI: boolean gets a checkmark, numeric gets a counter,
/// timer gets a stopwatch.
enum GoalType: String, Codable, CaseIterable {
    case boolean
    case numeric
    case timer

    var label: String {
        switch self {
        case .boolean: return "Yes / No"
        case .numeric: return "Number"
        case .timer:   return "Timer"
        }
    }

    var icon: String {
        switch self {
        case .boolean: return "checkmark.circle"
        case .numeric: return "number"
        case .timer:   return "timer"
        }
    }
}

// MARK: - Frequency

enum HabitFrequency: String, Codable, CaseIterable {
    case daily
    case weekly
    case monthly
    case custom

    var label: String {
        switch self {
        case .daily:   return "Every day"
        case .weekly:  return "Weekly"
        case .monthly: return "Monthly"
        case .custom:  return "Custom"
        }
    }
}

// MARK: - Habit

/// A habit definition — what the user wants to track.
/// Created once, logged against daily via HabitEntry.
struct Habit: Codable, Identifiable {
    let id: String
    let userId: String
    var name: String
    var icon: String?
    var color: String?
    var goalType: GoalType
    var goalValue: Int?
    var goalUnit: String?
    var frequency: HabitFrequency
    var reminderTime: String?
    var groupName: String?
    var isArchived: Bool
    var sortOrder: Int
    let createdAt: String
    var updatedAt: String

    /// SwiftUI colour derived from the hex string.
    /// Falls back to habits accent (emerald) if no colour is set.
    var swiftUIColor: Color {
        guard let hex = color else { return .alefHabits }
        return Color(hex: hex.replacingOccurrences(of: "#", with: ""))
    }
}

// MARK: - Habit Entry

/// A single day's log for a habit.
/// One entry per habit per date.
struct HabitEntry: Codable, Identifiable {
    let id: String
    let habitId: String
    let userId: String
    let date: String
    var value: Int
    var skipped: Bool
    var note: String?
    let createdAt: String
}

// MARK: - Today Habit

/// A habit combined with today's completion status.
/// Returned by GET /habits/today — the primary endpoint for the
/// daily checklist screen.
struct TodayHabit: Codable, Identifiable {
    let id: String
    let userId: String
    let name: String
    let icon: String?
    let color: String?
    let goalType: GoalType
    let goalValue: Int?
    let goalUnit: String?
    let frequency: HabitFrequency
    let reminderTime: String?
    let groupName: String?
    let isArchived: Bool
    let sortOrder: Int
    let createdAt: String
    let updatedAt: String
    let todayEntry: HabitEntry?
    let completed: Bool

    var swiftUIColor: Color {
        guard let hex = color else { return .alefHabits }
        return Color(hex: hex.replacingOccurrences(of: "#", with: ""))
    }
}

// MARK: - API Response Wrappers

/// GET /habits/today response
struct TodayResponse: Codable {
    let habits: [TodayHabit]
    let date: String
}

/// GET /habits response
struct HabitsResponse: Codable {
    let habits: [Habit]
}

/// POST/PATCH /habits response
struct HabitResponse: Codable {
    let habit: Habit
}

/// POST /habits/:id/log response
struct EntryResponse: Codable {
    let entry: HabitEntry
}

/// GET /habits/:id/logs response
struct EntriesResponse: Codable {
    let entries: [HabitEntry]
}

// MARK: - Create/Update DTOs

/// Body for POST /habits
struct CreateHabitBody: Encodable {
    let name: String
    var icon: String?
    var color: String?
    var goalType: GoalType?
    var goalValue: Int?
    var goalUnit: String?
    var frequency: HabitFrequency?
    var reminderTime: String?
    var groupName: String?
}

/// Body for POST /habits/:id/log
struct LogEntryBody: Encodable {
    let date: String
    var value: Int?
    var skipped: Bool?
    var note: String?
}
