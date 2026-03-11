//
//  MediaService.swift
//  alef
//
//  Network service for the Media module (Movies & TV).
//

import Foundation

final class MediaService {
    
    static let shared = MediaService()
    private init() {}
    
    // MARK: - Fetch Media
    
    /// Get all media items with optional filters
    func fetchMedia(
        type: MediaType? = nil,
        status: MediaStatus? = nil,
        limit: Int = 50,
        token: String
    ) async throws -> [MediaItem] {
        var path = "/media?limit=\(limit)"
        
        if let type = type {
            path += "&type=\(type.rawValue)"
        }
        if let status = status {
            path += "&status=\(status.rawValue)"
        }
        
        let response: MediaListResponse = try await APIClient.shared.request(
            "GET",
            path,
            token: token
        )
        return response.media
    }
    
    /// Get a single media item by ID
    func fetchMediaItem(id: String, token: String) async throws -> MediaItem {
        let response: MediaResponse = try await APIClient.shared.request(
            "GET",
            "/media/\(id)",
            token: token
        )
        return response.media
    }
    
    // MARK: - Create Media
    
    func createMedia(
        type: MediaType,
        status: MediaStatus = .watchlist,
        title: String,
        externalId: String? = nil,
        posterUrl: String? = nil,
        rating: Int? = nil,
        review: String? = nil,
        progress: Int? = nil,
        token: String
    ) async throws -> MediaItem {
        let body = CreateMediaBody(
            type: type.rawValue,
            status: status.rawValue,
            title: title,
            externalId: externalId,
            posterUrl: posterUrl,
            rating: rating,
            review: review,
            progress: progress,
            startedAt: nil,
            completedAt: nil
        )
        
        let response: MediaResponse = try await APIClient.shared.request(
            "POST",
            "/media",
            body: body,
            token: token
        )
        return response.media
    }
    
    // MARK: - Update Media
    
    func updateMedia(
        id: String,
        status: MediaStatus? = nil,
        rating: Int? = nil,
        review: String? = nil,
        progress: Int? = nil,
        token: String
    ) async throws -> MediaItem {
        let body = UpdateMediaBody(
            status: status?.rawValue,
            rating: rating,
            review: review,
            progress: progress,
            startedAt: nil,
            completedAt: nil
        )
        
        let response: MediaResponse = try await APIClient.shared.request(
            "PATCH",
            "/media/\(id)",
            body: body,
            token: token
        )
        return response.media
    }
    
    // MARK: - Delete Media
    
    func deleteMedia(id: String, token: String) async throws {
        try await APIClient.shared.requestVoid(
            "DELETE",
            "/media/\(id)",
            token: token
        )
    }
    
    // MARK: - Search (TMDB Proxy)
    
    /// Search TMDB for movies or TV shows
    func search(query: String, type: MediaType, token: String) async throws -> [TMDBSearchResult] {
        guard !query.isEmpty else { return [] }
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let path = "/media/search?q=\(encodedQuery)&type=\(type.rawValue)"
        
        let response: SearchResultsResponse = try await APIClient.shared.request(
            "GET",
            path,
            token: token
        )
        return response.results
    }
    
    // MARK: - Books Compatibility Methods (String-based)
    
    /// Fetch all media with string-based type/status (for Books views)
    func fetchAll(type: String? = nil, status: String? = nil, token: String) async throws -> [MediaItem] {
        let typeEnum = type.flatMap { MediaType(rawValue: $0) }
        let statusEnum = status.flatMap { MediaStatus(rawValue: $0) }
        return try await fetchMedia(type: typeEnum, status: statusEnum, token: token)
    }
    
    /// Fetch single item (for Books views)
    func fetch(id: String, token: String) async throws -> MediaItem {
        return try await fetchMediaItem(id: id, token: token)
    }
    
    /// Create with CreateMediaBody (for Books views)
    func create(_ body: CreateMediaBody, token: String) async throws -> MediaItem {
        let type = MediaType(rawValue: body.type) ?? .book
        let status = body.status.flatMap { MediaStatus(rawValue: $0) } ?? .watchlist
        
        return try await createMedia(
            type: type,
            status: status,
            title: body.title,
            externalId: body.externalId,
            posterUrl: body.posterUrl,
            rating: body.rating,
            review: body.review,
            progress: body.progress,
            token: token
        )
    }
    
    /// Update with UpdateMediaBody (for Books views)
    func update(id: String, _ body: UpdateMediaBody, token: String) async throws -> MediaItem {
        let status = body.status.flatMap { MediaStatus(rawValue: $0) }
        
        return try await updateMedia(
            id: id,
            status: status,
            rating: body.rating,
            review: body.review,
            progress: body.progress,
            token: token
        )
    }
    
    /// Delete (for Books views)
    func delete(id: String, token: String) async throws {
        try await deleteMedia(id: id, token: token)
    }
}
