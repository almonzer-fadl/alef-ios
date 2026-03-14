//
//  CalendarEvent.swift
//  alef
//
//  Data models for the Calendar module.
//
//  Maps to the backend schema:
//  - CalendarEvent → `events` table
//
//  Inspired by Apple Calendar — supports all-day events, recurrence,
//  reminders, location, and custom colours for event dots.
//

import Foundation
import SwiftUI

// MARK: - Recurrence

enum EventRecurrence: String, Codable, CaseIterable {
    case none = ""
    case daily
    case weekly
    case monthly
    case yearly

    var label: String {
        switch self {
        case .none:    return "None"
        case .daily:   return "Every day"
        case .weekly:  return "Every week"
        case .monthly: return "Every month"
        case .yearly:  return "Every year"
        }
    }
}

// MARK: - Reminder

enum EventReminder: Int, CaseIterable {
    case none = -1
    case atTime = 0
    case fiveMin = 5
    case fifteenMin = 15
    case thirtyMin = 30
    case oneHour = 60

    var label: String {
        switch self {
        case .none:       return "None"
        case .atTime:     return "At time of event"
        case .fiveMin:    return "5 minutes before"
        case .fifteenMin: return "15 minutes before"
        case .thirtyMin:  return "30 minutes before"
        case .oneHour:    return "1 hour before"
        }
    }

    var minutes: Int? {
        self == .none ? nil : self.rawValue
    }
}

// MARK: - Calendar Event

/// A calendar event — appointment, reminder, or recurring event.
struct CalendarEvent: Codable, Identifiable {
    let id: String
    let userId: String
    var title: String
    var description: String?
    var startTime: String    // ISO 8601
    var endTime: String?     // ISO 8601
    var allDay: Bool?
    var location: String?
    var color: String?
    var recurrence: String?  // "daily", "weekly", "monthly", "yearly", or null
    var remindMinutes: Int?
    let createdAt: String
    var updatedAt: String

    /// SwiftUI colour derived from the hex string.
    /// Falls back to calendar accent (violet) if no colour is set.
    var swiftUIColor: Color {
        guard let hex = color else { return .alefCalendar }
        return Color(hex: hex.replacingOccurrences(of: "#", with: ""))
    }

    /// Start date parsed from ISO 8601 string
    var startDate: Date? {
        ISO8601DateFormatter().date(from: startTime)
    }

    /// End date parsed from ISO 8601 string
    var endDate: Date? {
        guard let endTime = endTime else { return nil }
        return ISO8601DateFormatter().date(from: endTime)
    }

    /// Whether this event is happening today
    var isToday: Bool {
        guard let start = startDate else { return false }
        return Calendar.current.isDateInToday(start)
    }

    /// Whether this is an all-day event
    var isAllDay: Bool {
        allDay ?? false
    }

    /// Formatted time range for display (e.g., "9:00 AM - 10:30 AM")
    var timeRangeString: String {
        guard let start = startDate else { return "" }

        if isAllDay {
            return "All day"
        }

        let formatter = DateFormatter()
        formatter.timeStyle = .short

        if let end = endDate {
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        } else {
            return formatter.string(from: start)
        }
    }

    /// Recurrence enum value
    var recurrenceType: EventRecurrence {
        guard let recurrence = recurrence, !recurrence.isEmpty else {
            return .none
        }
        return EventRecurrence(rawValue: recurrence) ?? .none
    }

    /// Reminder enum value
    var reminderType: EventReminder {
        guard let minutes = remindMinutes else { return .none }
        return EventReminder(rawValue: minutes) ?? .none
    }
}

// MARK: - API Response Wrappers

/// Generic success response with data
struct CalendarEventsResponse: Codable {
    let success: Bool
    let data: [CalendarEvent]
}

/// Single event response
struct CalendarEventResponse: Codable {
    let success: Bool
    let data: CalendarEvent
}

/// Delete response
struct DeleteEventResponse: Codable {
    let success: Bool
    let message: String
}

// MARK: - Create/Update DTOs

/// Body for POST /calendar (create event)
struct CreateEventBody: Encodable {
    let title: String
    var description: String?
    let startTime: String    // ISO 8601
    var endTime: String?     // ISO 8601
    var allDay: Bool?
    var location: String?
    var color: String?
    var recurrence: String?
    var remindMinutes: Int?
}

/// Body for PATCH /calendar/:id (update event)
struct UpdateEventBody: Encodable {
    var title: String?
    var description: String?
    var startTime: String?
    var endTime: String?
    var allDay: Bool?
    var location: String?
    var color: String?
    var recurrence: String?
    var remindMinutes: Int?
}
