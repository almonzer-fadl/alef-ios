//
//  CalendarViewModel.swift
//  alef
//
//  Drives the calendar month view and event management.
//
//  Responsibilities:
//  - Fetch events for the current month
//  - Track selected date and filter events by day
//  - Navigate between months
//  - Create, update, and delete events
//  - Generate calendar grid with day numbers and event indicators
//
//  The ViewModel is the single source of truth for calendar state.
//  Views observe @Published properties and react to changes.
//

import SwiftUI
import Combine

@MainActor
final class CalendarViewModel: ObservableObject {

    // MARK: - Published State

    /// All events for the current month
    @Published var events: [CalendarEvent] = []

    /// Currently selected date (highlighted in the calendar)
    @Published var selectedDate: Date = Date()

    /// Current month being displayed
    @Published var currentMonth: Date = Date()

    /// Events for the selected day
    @Published var selectedDayEvents: [CalendarEvent] = []

    /// Loading state
    @Published var isLoading = false

    /// Error message
    @Published var error: String?

    /// Controls the create event sheet
    @Published var showCreateSheet = false

    /// Event being edited (for detail view)
    @Published var selectedEvent: CalendarEvent?

    // MARK: - Dependencies

    private let service = CalendarService()

    /// Auth token — injected from the view's @AppStorage
    var token: String = ""

    // MARK: - Computed Properties

    /// Month name for display (e.g., "March 2026")
    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    /// Days in the current month (for calendar grid)
    var daysInMonth: [Date?] {
        let calendar = Calendar.current
        let monthInterval = calendar.dateInterval(of: .month, for: currentMonth)!
        let monthFirstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)!.count

        // Calculate leading blank spaces (days before the 1st)
        let leadingDays = (monthFirstWeekday - calendar.firstWeekday + 7) % 7

        // Generate array: nils for leading blanks, then dates for each day
        var days: [Date?] = Array(repeating: nil, count: leadingDays)

        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start) {
                days.append(date)
            }
        }

        // Pad to full weeks (42 cells = 6 rows)
        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }

    /// Check if a date has events
    func hasEvents(on date: Date) -> Bool {
        let calendar = Calendar.current
        return events.contains { event in
            guard let eventDate = event.startDate else { return false }
            return calendar.isDate(eventDate, inSameDayAs: date)
        }
    }

    /// Get events for a specific date
    func events(for date: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        return events.filter { event in
            guard let eventDate = event.startDate else { return false }
            return calendar.isDate(eventDate, inSameDayAs: date)
        }.sorted { ($0.startDate ?? Date()) < ($1.startDate ?? Date()) }
    }

    /// Get the colour for the first event on a given date (for dot indicator)
    func eventColor(for date: Date) -> Color {
        events(for: date).first?.swiftUIColor ?? .alefCalendar
    }

    // MARK: - Fetch

    /// Load events for the current month
    func fetchMonth() async {
        guard !token.isEmpty else { return }
        isLoading = events.isEmpty
        error = nil

        let calendar = Calendar.current
        let monthInterval = calendar.dateInterval(of: .month, for: currentMonth)!

        let formatter = ISO8601DateFormatter()
        let fromString = formatter.string(from: monthInterval.start)
        let toString = formatter.string(from: monthInterval.end)

        do {
            events = try await service.fetchEvents(from: fromString, to: toString, token: token)
            updateSelectedDayEvents()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Navigation

    /// Move to the previous month
    func previousMonth() {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
            Task { await fetchMonth() }
        }
    }

    /// Move to the next month
    func nextMonth() {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
            Task { await fetchMonth() }
        }
    }

    /// Select a day and update the events list
    func selectDay(_ date: Date) {
        selectedDate = date
        updateSelectedDayEvents()
        Haptics.selection()
    }

    /// Update the selected day's events
    private func updateSelectedDayEvents() {
        selectedDayEvents = events(for: selectedDate)
            .sorted { event1, event2 in
                // All-day events first, then by start time
                if event1.isAllDay != event2.isAllDay {
                    return event1.isAllDay
                }
                return (event1.startDate ?? Date()) < (event2.startDate ?? Date())
            }
    }

    // MARK: - Create

    /// Create a new event and refresh
    func createEvent(_ body: CreateEventBody) async {
        do {
            _ = try await service.create(body, token: token)
            showCreateSheet = false
            Haptics.success()
            await fetchMonth()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Update

    /// Update an existing event
    func updateEvent(id: String, body: UpdateEventBody) async {
        do {
            _ = try await service.update(id: id, body: body, token: token)
            Haptics.success()
            await fetchMonth()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Delete

    /// Delete an event permanently
    func deleteEvent(id: String) async {
        do {
            try await service.delete(id: id, token: token)
            Haptics.success()
            selectedEvent = nil
            await fetchMonth()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
