//
//  Media.swift
//  alef
//
//  Data models for the Media module (Movies & TV).
//
//  Maps to the backend schema:
//  - MediaItem → `media_items` table
//  - TMDBSearchResult → TMDB API search results
//
//  Status values: watchlist, watching, completed, dropped
//  Rating: 1-10 internally, displayed as 1-5 stars (divide by 2)
//

import Foundation

// MARK: - Media Type

enum MediaType: String, Codable, CaseIterable {
    case movie
    case tv
    case book
    case podcast
    
    var label: String {
        switch self {
        case .movie: return "Movies"
        case .tv: return "TV Shows"
        case .book: return "Books"
        case .podcast: return "Podcasts"
        }
    }
    
    var icon: String {
        switch self {
        case .movie: return "film"
        case .tv: return "tv"
        case .book: return "book"
        case .podcast: return "mic"
        }
    }
}

// MARK: - Media Status

enum MediaStatus: String, Codable, CaseIterable {
    case watchlist
    case watching
    case completed
    case dropped
    
    var label: String {
        switch self {
        case .watchlist: return "Watchlist"
        case .watching: return "Watching"
        case .completed: return "Completed"
        case .dropped: return "Dropped"
        }
    }
    
    var icon: String {
        switch self {
        case .watchlist: return "bookmark"
        case .watching: return "play.circle"
        case .completed: return "checkmark.circle"
        case .dropped: return "xmark.circle"
        }
    }
}

// MARK: - Media Item

struct MediaItem: Codable, Identifiable {
    let id: String
    let userId: String
    var type: String
    var status: String
    var title: String
    var externalId: String?
    var posterUrl: String?
    var rating: Int?
    var review: String?
    var progress: Int?
    var startedAt: Date?
    var completedAt: Date?
    let createdAt: Date
    var updatedAt: Date
    
    /// Convert status string to enum (with fallback)
    var statusEnum: MediaStatus {
        MediaStatus(rawValue: status) ?? .watchlist
    }
    
    /// Convert type string to enum (with fallback)
    var typeEnum: MediaType {
        MediaType(rawValue: type) ?? .movie
    }
    
    /// Display rating as 1-5 stars (internal is 1-10)
    var displayRating: Double? {
        guard let rating = rating else { return nil }
        return Double(rating) / 2.0
    }
}

// MARK: - TMDB Search Result

struct TMDBSearchResult: Codable, Identifiable {
    let tmdbId: Int
    let title: String
    let posterUrl: String?
    let year: String?
    let overview: String?
    
    var id: Int { tmdbId }
}

// MARK: - Response DTOs

struct MediaResponse: Codable {
    let media: MediaItem
}

struct MediaListResponse: Codable {
    let media: [MediaItem]
}

struct SearchResultsResponse: Codable {
    let results: [TMDBSearchResult]
}

// MARK: - Request DTOs

struct CreateMediaBody: Codable {
    let type: String
    let status: String?
    let title: String
    let externalId: String?
    let posterUrl: String?
    let rating: Int?
    let review: String?
    let progress: Int?
    let startedAt: Date?
    let completedAt: Date?
}

struct UpdateMediaBody: Codable {
    let status: String?
    let rating: Int?
    let review: String?
    let progress: Int?
    let startedAt: Date?
    let completedAt: Date?
}
