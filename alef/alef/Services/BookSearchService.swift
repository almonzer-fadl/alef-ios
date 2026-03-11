//
//  BookSearchService.swift
//  alef
//
//  Open Library search client for the Books module.
//
//  Endpoints:
//  - GET /books/search?q=query — search Open Library
//

import Foundation
import Combine

// MARK: - Search Result Models

struct BookSearchResult: Codable, Identifiable {
    let olid: String?
    let title: String
    let author: String?
    let year: Int?
    let coverUrl: String?
    let isbn: String?
    
    var id: String { olid ?? title }
}

struct BookSearchResponse: Codable {
    let results: [BookSearchResult]
}

// MARK: - Service

final class BookSearchService: ObservableObject {
    
    /// Search Open Library for books.
    func search(query: String, token: String) async throws -> [BookSearchResult] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        
        let response: BookSearchResponse = try await APIClient.shared.request(
            "GET", "/books/search?q=\(encodedQuery)", token: token
        )
        return response.results
    }
}
