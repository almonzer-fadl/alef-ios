//
//  HealthService.swift
//  alef
//
//  Network layer for the Health module.
//

import Foundation

struct HealthService {

    private let api = APIClient.shared

    /// Fetch recent health logs (default 30 days).
    func fetchRecent(token: String, limit: Int = 30) async throws -> [HealthLog] {
        let response: HealthLogsResponse = try await api.request(
            "GET", "/health?limit=\(limit)", token: token
        )
        return response.logs
    }

    /// Get log for a specific date.
    func fetchByDate(date: String, token: String) async throws -> HealthLog? {
        let response: HealthLogNullable = try await api.request(
            "GET", "/health/\(date)", token: token
        )
        return response.log
    }

    /// Create or update today's log (upsert by date on backend).
    func upsert(_ body: CreateHealthLogBody, token: String) async throws -> HealthLog {
        let response: HealthLogResponse = try await api.request(
            "POST", "/health", body: body, token: token
        )
        return response.log
    }
}
