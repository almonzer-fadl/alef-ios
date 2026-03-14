//
//  BookViewModel.swift
//  alef
//
//  ViewModel for the Books module.
//  Manages state for list view, search, and CRUD operations.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class BookViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var books: [MediaItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var selectedStatus: String? = nil
    
    // Search state
    @Published var searchResults: [BookSearchResult] = []
    @Published var isSearching = false
    
    // MARK: - Dependencies
    
    private let mediaService = MediaService.shared
    private let searchService = BookSearchService()
    
    // MARK: - Token (injected from view)
    
    var token: String = ""
    
    // MARK: - Fetch Books
    
    func fetchBooks() async {
        isLoading = true
        errorMessage = nil
        
        do {
            books = try await mediaService.fetchAll(
                type: "book",
                status: selectedStatus,
                token: token
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Search Books
    
    func search(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        do {
            searchResults = try await searchService.search(query: query, token: token)
        } catch {
            errorMessage = error.localizedDescription
            searchResults = []
        }
        isSearching = false
    }
    
    // MARK: - Create Book
    
    func addBook(_ result: BookSearchResult) async -> Bool {
        let body = CreateMediaBody(
            type: "book",
            status: "watchlist",
            title: result.title,
            externalId: result.olid,
            posterUrl: result.coverUrl,
            rating: nil,
            review: nil,
            progress: nil,
            startedAt: nil,
            completedAt: nil
        )
        
        do {
            let newBook = try await mediaService.create(body, token: token)
            books.insert(newBook, at: 0)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    // MARK: - Update Book
    
    func updateBook(
        id: String,
        status: String? = nil,
        rating: Int? = nil,
        review: String? = nil,
        progress: Int? = nil
    ) async -> MediaItem? {
        let body = UpdateMediaBody(
            status: status,
            rating: rating,
            review: review,
            progress: progress,
            startedAt: nil,
            completedAt: nil
        )
        
        do {
            let updated = try await mediaService.update(id: id, body, token: token)
            
            if let index = books.firstIndex(where: { $0.id == id }) {
                books[index] = updated
            }
            
            return updated
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    // MARK: - Delete Book
    
    func deleteBook(id: String) async -> Bool {
        do {
            try await mediaService.delete(id: id, token: token)
            books.removeAll { $0.id == id }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    // MARK: - Fetch Single Book
    
    func fetchBook(id: String) async -> MediaItem? {
        do {
            return try await mediaService.fetch(id: id, token: token)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
