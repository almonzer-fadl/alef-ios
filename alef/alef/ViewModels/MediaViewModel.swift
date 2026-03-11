//
//  MediaViewModel.swift
//  alef
//
//  ViewModel for the Media module (Movies & TV).
//  Manages state for list view, search, and CRUD operations.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class MediaViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var items: [MediaItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var selectedType: MediaType = .movie
    @Published var selectedStatus: MediaStatus?
    
    // MARK: - Dependencies
    
    private let service = MediaService.shared
    
    // MARK: - Fetch Media
    
    func fetchMedia(token: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            items = try await service.fetchMedia(
                type: selectedType,
                status: selectedStatus,
                token: token
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Create Media
    
    func createMedia(
        type: MediaType,
        status: MediaStatus,
        title: String,
        externalId: String?,
        posterUrl: String?,
        token: String
    ) async -> Bool {
        do {
            let newItem = try await service.createMedia(
                type: type,
                status: status,
                title: title,
                externalId: externalId,
                posterUrl: posterUrl,
                token: token
            )
            items.insert(newItem, at: 0)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    // MARK: - Update Media
    
    func updateMedia(
        id: String,
        status: MediaStatus? = nil,
        rating: Int? = nil,
        review: String? = nil,
        progress: Int? = nil,
        token: String
    ) async -> Bool {
        do {
            let updated = try await service.updateMedia(
                id: id,
                status: status,
                rating: rating,
                review: review,
                progress: progress,
                token: token
            )
            
            if let index = items.firstIndex(where: { $0.id == id }) {
                items[index] = updated
            }
            
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    // MARK: - Delete Media
    
    func deleteMedia(id: String, token: String) async -> Bool {
        do {
            try await service.deleteMedia(id: id, token: token)
            items.removeAll { $0.id == id }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    // MARK: - Computed Properties
    
    var filteredItems: [MediaItem] {
        items
    }
    
    var hasItems: Bool {
        !items.isEmpty
    }
}
