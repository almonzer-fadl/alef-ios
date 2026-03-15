//
//  NoteService.swift
//  alef
//
//  Created by Alef on 2026-03-07.
//  API service for notes and folders.
//

import Foundation

struct NoteService {
    private let api = APIClient.shared
    
    // MARK: - Notes
    
    /// Fetch all notes with optional filters
    func fetchNotes(folderId: String? = nil, pinned: Bool? = nil, archived: Bool = false, token: String) async throws -> [Note] {
        var path = "/notes?"
        
        if let folderId = folderId {
            path += "folderId=\(folderId)&"
        }
        
        if let pinned = pinned {
            path += "pinned=\(pinned ? "true" : "false")&"
        }
        
        path += "archived=\(archived ? "true" : "false")"
        
        return try await api.request("GET", path, token: token)
    }
    
    /// Search notes by query string
    func searchNotes(query: String, token: String) async throws -> [Note] {
        let path = "/notes/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)"
        return try await api.request("GET", path, token: token)
    }
    
    /// Fetch a single note by ID
    func fetchNote(id: String, token: String) async throws -> Note {
        return try await api.request("GET", "/notes/\(id)", token: token)
    }
    
    /// Create a new note
    func createNote(request: NoteRequest, token: String) async throws -> Note {
        return try await api.request("POST", "/notes", body: request, token: token)
    }
    
    /// Update an existing note
    func updateNote(id: String, request: NoteRequest, token: String) async throws -> Note {
        return try await api.request("PATCH", "/notes/\(id)", body: request, token: token)
    }
    
    /// Delete a note
    func deleteNote(id: String, token: String) async throws {
        try await api.requestVoid("DELETE", "/notes/\(id)", token: token)
    }
    
    // MARK: - Folders
    
    /// Fetch all folders
    func fetchFolders(token: String) async throws -> [NoteFolder] {
        return try await api.request("GET", "/notes/folders", token: token)
    }
    
    /// Create a new folder
    func createFolder(request: NoteFolderRequest, token: String) async throws -> NoteFolder {
        return try await api.request("POST", "/notes/folders", body: request, token: token)
    }
    
    /// Update a folder
    func updateFolder(id: String, request: NoteFolderRequest, token: String) async throws -> NoteFolder {
        return try await api.request("PATCH", "/notes/folders/\(id)", body: request, token: token)
    }
    
    /// Delete a folder
    func deleteFolder(id: String, token: String) async throws {
        try await api.requestVoid("DELETE", "/notes/folders/\(id)", token: token)
    }
}
