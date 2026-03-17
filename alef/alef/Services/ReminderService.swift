//
//  ReminderService.swift
//  alef
//
//  Network layer for the Reminders module.
//  Wraps APIClient calls with typed methods for each endpoint.
//
//  All methods require an auth token — the calling ViewModel
//  reads it from @AppStorage("authToken").
//

import Foundation

struct ReminderService {

    private let api = APIClient.shared

    // MARK: - Reminders

    /// Fetch all reminders with optional filters.
    func fetchAll(
        token: String,
        listId: String? = nil,
        completed: Bool? = nil,
        flagged: Bool? = nil,
        due: String? = nil
    ) async throws -> [Reminder] {
        var path = "/reminders?"
        if let listId { path += "listId=\(listId)&" }
        if let completed { path += "completed=\(completed)&" }
        if let flagged { path += "flagged=\(flagged)&" }
        if let due { path += "due=\(due)&" }

        let response: RemindersResponse = try await api.request("GET", path, token: token)
        return response.reminders
    }

    /// Fetch reminders due today.
    func fetchToday(token: String) async throws -> TodayRemindersResponse {
        try await api.request("GET", "/reminders/today", token: token)
    }

    /// Fetch reminders due in the next 7 days.
    func fetchUpcoming(token: String) async throws -> UpcomingRemindersResponse {
        try await api.request("GET", "/reminders/upcoming", token: token)
    }

    /// Fetch a single reminder by ID.
    func fetchOne(id: String, token: String) async throws -> Reminder {
        let response: ReminderResponse = try await api.request("GET", "/reminders/\(id)", token: token)
        return response.reminder
    }

    /// Create a new reminder.
    func create(_ body: CreateReminderBody, token: String) async throws -> Reminder {
        let response: CreateReminderResponse = try await api.request(
            "POST", "/reminders", body: body, token: token
        )
        return response.reminder
    }

    /// Update a reminder (including toggling completion).
    func update(id: String, body: UpdateReminderBody, token: String) async throws -> Reminder {
        let response: CreateReminderResponse = try await api.request(
            "PATCH", "/reminders/\(id)", body: body, token: token
        )
        return response.reminder
    }

    /// Toggle completion status of a reminder.
    func toggleCompletion(id: String, isCompleted: Bool, token: String) async throws -> Reminder {
        let body = UpdateReminderBody(isCompleted: isCompleted)
        return try await update(id: id, body: body, token: token)
    }

    /// Delete a reminder permanently.
    func delete(id: String, token: String) async throws {
        try await api.requestVoid("DELETE", "/reminders/\(id)", token: token)
    }

    // MARK: - Lists

    /// Fetch all reminder lists with counts.
    func fetchLists(token: String) async throws -> ListsResponse {
        try await api.request("GET", "/reminders/lists", token: token)
    }

    /// Create a new reminder list.
    func createList(_ body: CreateListBody, token: String) async throws -> ReminderList {
        let response: CreateListResponse = try await api.request(
            "POST", "/reminders/lists", body: body, token: token
        )
        return response.list
    }

    /// Update a reminder list.
    func updateList(id: String, body: UpdateListBody, token: String) async throws -> ReminderList {
        let response: CreateListResponse = try await api.request(
            "PATCH", "/reminders/lists/\(id)", body: body, token: token
        )
        return response.list
    }

    /// Delete a reminder list (cascades to reminders).
    func deleteList(id: String, token: String) async throws {
        try await api.requestVoid("DELETE", "/reminders/lists/\(id)", token: token)
    }
}
