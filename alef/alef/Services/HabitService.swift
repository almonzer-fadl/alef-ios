//
//  HabitService.swift
//  alef
//
//  Network layer for the Habits module.
//  Wraps APIClient calls with typed methods for each endpoint.
//
//  All methods require an auth token — the calling ViewModel
//  reads it from @AppStorage("authToken").
//

import Foundation

struct HabitService {

    private let api = APIClient.shared

    /// Fetch today's habits with completion status.
    /// This is the primary data source for the daily checklist.
    func fetchToday(token: String) async throws -> TodayResponse {
        try await api.request("GET", "/habits/today", token: token)
    }

    /// Fetch all habits (for the library/management view).
    func fetchAll(token: String, includeArchived: Bool = false) async throws -> [Habit] {
        let path = includeArchived ? "/habits?archived=true" : "/habits"
        let response: HabitsResponse = try await api.request("GET", path, token: token)
        return response.habits
    }

    /// Create a new habit.
    func create(_ body: CreateHabitBody, token: String) async throws -> Habit {
        let response: HabitResponse = try await api.request("POST", "/habits", body: body, token: token)
        return response.habit
    }

    /// Update an existing habit.
    func update(id: String, body: [String: Any], token: String) async throws -> Habit {
        // For partial updates we use JSONSerialization since the body is dynamic
        guard let url = URL(string: "\(api.baseURL)/habits/\(id)") else {
            throw APIError.network("Invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode < 400 else {
            throw APIError.server(0, "Failed to update habit")
        }
        let decoded = try api.decoder.decode(HabitResponse.self, from: data)
        return decoded.habit
    }

    /// Delete a habit permanently.
    func delete(id: String, token: String) async throws {
        try await api.requestVoid("DELETE", "/habits/\(id)", token: token)
    }

    /// Log a completion entry for a habit on a specific date.
    /// Uses upsert on the backend — safe to call multiple times.
    func log(habitId: String, body: LogEntryBody, token: String) async throws -> HabitEntry {
        let response: EntryResponse = try await api.request(
            "POST", "/habits/\(habitId)/log", body: body, token: token
        )
        return response.entry
    }

    /// Fetch log history for a habit (used for heatmap/calendar).
    func fetchLogs(habitId: String, token: String) async throws -> [HabitEntry] {
        let response: EntriesResponse = try await api.request(
            "GET", "/habits/\(habitId)/logs", token: token
        )
        return response.entries
    }
}
