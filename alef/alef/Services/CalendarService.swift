//
//  CalendarService.swift
//  alef
//
//  Network layer for the Calendar module.
//  Wraps APIClient calls with typed methods for each endpoint.
//
//  All methods require an auth token — the calling ViewModel
//  reads it from @AppStorage("authToken").
//

import Foundation

struct CalendarService {

    private let api = APIClient.shared

    /// Fetch all events with optional date range filtering.
    /// - Parameters:
    ///   - from: Start date (ISO 8601 string)
    ///   - to: End date (ISO 8601 string)
    ///   - token: Auth token
    func fetchEvents(from: String? = nil, to: String? = nil, token: String) async throws -> [CalendarEvent] {
        var path = "/calendar"
        if let from = from, let to = to {
            path += "?from=\(from)&to=\(to)"
        }
        let response: CalendarEventsResponse = try await api.request("GET", path, token: token)
        return response.data
    }

    /// Fetch events for a specific date.
    /// - Parameters:
    ///   - date: Date in YYYY-MM-DD format
    ///   - token: Auth token
    func fetchDayEvents(date: String, token: String) async throws -> [CalendarEvent] {
        let response: CalendarEventsResponse = try await api.request("GET", "/calendar/day/\(date)", token: token)
        return response.data
    }

    /// Fetch a single event by ID.
    func fetchEvent(id: String, token: String) async throws -> CalendarEvent {
        let response: CalendarEventResponse = try await api.request("GET", "/calendar/\(id)", token: token)
        return response.data
    }

    /// Create a new calendar event.
    func create(_ body: CreateEventBody, token: String) async throws -> CalendarEvent {
        let response: CalendarEventResponse = try await api.request("POST", "/calendar", body: body, token: token)
        return response.data
    }

    /// Update an existing event.
    func update(id: String, body: UpdateEventBody, token: String) async throws -> CalendarEvent {
        let response: CalendarEventResponse = try await api.request("PATCH", "/calendar/\(id)", body: body, token: token)
        return response.data
    }

    /// Delete an event permanently.
    func delete(id: String, token: String) async throws {
        try await api.requestVoid("DELETE", "/calendar/\(id)", token: token)
    }
}
