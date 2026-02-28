//
//  JournalService.swift
//  alef
//
//  Network layer for the Journal module.
//  Wraps APIClient calls with typed methods for each endpoint.
//

import Foundation

struct JournalService {

    private let api = APIClient.shared

    /// Fetch recent journal entries (default 30).
    func fetchRecent(token: String, limit: Int = 30) async throws -> [JournalEntry] {
        let response: JournalEntriesResponse = try await api.request(
            "GET", "/journal?limit=\(limit)", token: token
        )
        return response.entries
    }

    /// Get entry for a specific date.
    func fetchByDate(date: String, token: String) async throws -> JournalEntry? {
        let response: JournalEntryNullable = try await api.request(
            "GET", "/journal/\(date)", token: token
        )
        return response.entry
    }

    /// Create a new entry.
    func create(_ body: CreateJournalBody, token: String) async throws -> JournalEntry {
        let response: JournalEntryResponse = try await api.request(
            "POST", "/journal", body: body, token: token
        )
        return response.entry
    }

    /// Update an existing entry.
    func update(id: String, body: CreateJournalBody, token: String) async throws -> JournalEntry {
        let response: JournalEntryResponse = try await api.request(
            "PATCH", "/journal/\(id)", body: body, token: token
        )
        return response.entry
    }

    /// Delete an entry.
    func delete(id: String, token: String) async throws {
        try await api.requestVoid("DELETE", "/journal/\(id)", token: token)
    }
}
