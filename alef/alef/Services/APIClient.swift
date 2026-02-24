//
//  APIClient.swift
//  alef
//
//  Centralised HTTP client for all Alef API calls.
//
//  Handles:
//  - Base URL configuration (local dev vs production)
//  - Bearer token injection from @AppStorage
//  - JSON encoding/decoding with snake_case conversion
//  - Typed error responses from the backend
//
//  Every module route file (HabitService, etc.) uses this client
//  instead of making raw URLSession calls. This keeps networking
//  logic in one place and makes it easy to swap base URLs.
//

import Foundation

// MARK: - API Error

/// Errors returned by the Alef backend or the network layer.
enum APIError: Error, LocalizedError {
    case network(String)
    case server(Int, String)    // status code + error message
    case decode(String)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .network(let msg):     return msg
        case .server(_, let msg):   return msg
        case .decode(let msg):      return msg
        case .unauthorized:         return "Session expired — please sign in again"
        }
    }
}

// MARK: - API Client

final class APIClient {

    /// Shared singleton — used across the app.
    static let shared = APIClient()

    /// Base URL for the Alef backend.
    /// In development this points to the local machine.
    /// In production, users configure their own server URL.
    var baseURL = "http://192.168.1.114:3002/api"

    /// JSON decoder configured for the backend's snake_case convention.
    let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    /// JSON encoder configured for the backend's snake_case convention.
    let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }()

    private init() {}

    // MARK: - Core Request

    /// Perform an authenticated API request and decode the response.
    ///
    /// - Parameters:
    ///   - method: HTTP method (GET, POST, PATCH, DELETE)
    ///   - path: API path relative to baseURL (e.g., "/habits")
    ///   - body: Optional encodable body (for POST/PATCH)
    ///   - token: JWT auth token
    /// - Returns: Decoded response of type T
    func request<T: Decodable>(
        _ method: String,
        _ path: String,
        body: (any Encodable)? = nil,
        token: String
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.network("Invalid URL: \(path)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        if let body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.network("Network error — is the server running?")
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.network("Invalid response")
        }

        // Handle auth failures globally
        if http.statusCode == 401 {
            throw APIError.unauthorized
        }

        // Handle server errors
        if http.statusCode >= 400 {
            // Try to extract error message from response body
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = json["error"] as? String {
                throw APIError.server(http.statusCode, msg)
            }
            throw APIError.server(http.statusCode, "Request failed (\(http.statusCode))")
        }

        // Decode response
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decode("Failed to decode response: \(error.localizedDescription)")
        }
    }

    /// Fire-and-forget request that doesn't need a decoded response.
    /// Used for DELETE endpoints that return { message: "..." }.
    func requestVoid(
        _ method: String,
        _ path: String,
        body: (any Encodable)? = nil,
        token: String
    ) async throws {
        let _: [String: String] = try await request(method, path, body: body, token: token)
    }
}

// MARK: - Type-Erased Encodable

/// Wrapper to encode any Encodable value.
/// Needed because `any Encodable` can't be directly encoded.
private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init(_ value: any Encodable) {
        _encode = { try value.encode(to: $0) }
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
