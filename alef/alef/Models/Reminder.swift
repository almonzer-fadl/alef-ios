//
//  Reminder.swift
//  alef
//
//  Data models for the Reminders module.
//
//  Maps to the backend schema:
//  - Reminder → `reminders` table
//  - ReminderList → `reminder_lists` table
//  - ListsResponse → response from GET /reminders/lists (includes counts)
//
//  Priority scale: 0=none, 1=low, 2=medium, 3=high.
//  Smart lists (Today, Scheduled, All, Flagged) are computed, not stored.
//

import Foundation
import SwiftUI

// MARK: - Priority

/// Priority level for a reminder.
/// Determines visual indicator and sort order.
enum ReminderPriority: Int, Codable, CaseIterable {
    case none = 0
    case low = 1
    case medium = 2
    case high = 3

    var label: String {
        switch self {
        case .none:   return "None"
        case .low:    return "Low"
        case .medium: return "Medium"
        case .high:   return "High"
        }
    }

    var icon: String {
        switch self {
        case .none:   return ""
        case .low:    return "!"
        case .medium: return "!!"
        case .high:   return "!!!"
        }
    }

    var color: Color {
        switch self {
        case .none:   return .clear
        case .low:    return .alefHealth
        case .medium: return .alefDiet
        case .high:   return .alefError
        }
    }
}

// MARK: - Recurrence

enum ReminderRecurrence: String, Codable, CaseIterable {
    case none = ""
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"

    var label: String {
        switch self {
        case .none:    return "Never"
        case .daily:   return "Daily"
        case .weekly:  return "Weekly"
        case .monthly: return "Monthly"
        case .yearly:  return "Yearly"
        }
    }
}

// MARK: - Reminder

/// A reminder/to-do item.
/// Tracks completion, due dates, priority, flags, and recurrence.
struct Reminder: Codable, Identifiable {
    let id: String
    let userId: String
    var listId: String?
    var title: String
    var notes: String?
    var isCompleted: Bool
    var priority: Int
    var dueDate: String?
    var dueTime: String?
    var recurrence: String?
    var flagged: Bool
    var url: String?
    var completedAt: String?
    let createdAt: String
    var updatedAt: String

    /// SwiftUI-friendly priority enum.
    var priorityEnum: ReminderPriority {
        ReminderPriority(rawValue: priority) ?? .none
    }

    /// SwiftUI-friendly recurrence enum.
    var recurrenceEnum: ReminderRecurrence {
        guard let rec = recurrence, !rec.isEmpty else { return .none }
        return ReminderRecurrence(rawValue: rec) ?? .none
    }

    /// Formatted due date string (e.g., "Today", "Tomorrow", "Mar 10").
    var dueDateFormatted: String? {
        guard let dueDate else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        guard let date = formatter.date(from: dueDate) else { return dueDate }

        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let df = DateFormatter()
            df.dateFormat = "MMM d"
            return df.string(from: date)
        }
    }
}

// MARK: - Reminder List

/// A user-created reminder list (e.g., "Work", "Personal", "Shopping").
/// Does not include smart lists (Today, Scheduled, etc.) — those are UI-only.
struct ReminderList: Codable, Identifiable {
    let id: String
    let userId: String
    var name: String
    var icon: String
    var color: String
    var sortOrder: Int
    let createdAt: String

    /// SwiftUI colour derived from the hex string.
    var swiftUIColor: Color {
        Color(hex: color.replacingOccurrences(of: "#", with: ""))
    }
}

// MARK: - API Response Wrappers

/// GET /reminders response
struct RemindersResponse: Codable {
    let reminders: [Reminder]
}

/// GET /reminders/today response
struct TodayRemindersResponse: Codable {
    let reminders: [Reminder]
    let date: String
}

/// GET /reminders/upcoming response
struct UpcomingRemindersResponse: Codable {
    let reminders: [Reminder]
}

/// GET /reminders/:id response
struct ReminderResponse: Codable {
    let reminder: Reminder
}

/// GET /reminders/lists response (includes counts for each list)
struct ListsResponse: Codable {
    let lists: [ReminderListWithCount]
    let smartLists: SmartListCounts
}

struct ReminderListWithCount: Codable, Identifiable {
    let id: String
    let userId: String
    var name: String
    var icon: String
    var color: String
    var sortOrder: Int
    let createdAt: String
    let count: Int

    var swiftUIColor: Color {
        Color(hex: color.replacingOccurrences(of: "#", with: ""))
    }
}

struct SmartListCounts: Codable {
    let today: Int
    let upcoming: Int
    let all: Int
    let flagged: Int
}

/// POST/PATCH /reminders response
struct CreateReminderResponse: Codable {
    let reminder: Reminder
}

/// POST/PATCH /reminders/lists response
struct CreateListResponse: Codable {
    let list: ReminderList
}

// MARK: - Create/Update DTOs

/// Body for POST /reminders
struct CreateReminderBody: Encodable {
    let title: String
    var notes: String?
    var listId: String?
    var priority: Int?
    var dueDate: String?
    var dueTime: String?
    var recurrence: String?
    var flagged: Bool?
    var url: String?
}

/// Body for PATCH /reminders/:id
struct UpdateReminderBody: Encodable {
    var title: String?
    var notes: String?
    var listId: String?
    var priority: Int?
    var dueDate: String?
    var dueTime: String?
    var recurrence: String?
    var flagged: Bool?
    var url: String?
    var isCompleted: Bool?
}

/// Body for POST /reminders/lists
struct CreateListBody: Encodable {
    let name: String
    var icon: String?
    var color: String?
    var sortOrder: Int?
}

/// Body for PATCH /reminders/lists/:id
struct UpdateListBody: Encodable {
    var name: String?
    var icon: String?
    var color: String?
    var sortOrder: Int?
}
