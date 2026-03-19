//
//  NotesViewModel.swift
//  alef
//
//  Created by Alef on 2026-03-07.
//  ViewModel for managing notes and folders state.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var folders: [NoteFolder] = []
    @Published var selectedFolderId: String?
    @Published var searchQuery: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var token: String = ""
    
    private let service = NoteService()
    
    // MARK: - Computed Properties
    
    /// Pinned notes (always at top)
    var pinnedNotes: [Note] {
        notes.filter { $0.isPinned == true }
    }
    
    /// Unpinned notes grouped by date
    var groupedNotes: [String: [Note]] {
        let unpinned = notes.filter { $0.isPinned != true }
        return Dictionary(grouping: unpinned) { note in
            dateGroup(for: note.updatedAt)
        }
    }
    
    /// Section headers in order
    var sectionHeaders: [String] {
        let headers = Set(groupedNotes.keys)
        let order = ["Today", "Yesterday", "Previous 7 Days", "Previous 30 Days"]
        
        var sorted = order.filter { headers.contains($0) }
        
        // Add month headers (e.g., "February 2026")
        let monthHeaders = headers.filter { !order.contains($0) }.sorted(by: >)
        sorted.append(contentsOf: monthHeaders)
        
        return sorted
    }
    
    // MARK: - Date Grouping
    
    private func dateGroup(for dateString: String) -> String {
        guard let date = ISO8601DateFormatter().date(from: dateString) else {
            return "Older"
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            return "Previous 7 Days"
        } else if let daysAgo = calendar.dateComponents([.day], from: date, to: now).day, daysAgo <= 30 {
            return "Previous 30 Days"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date)
        }
    }
    
    // MARK: - API Methods
    
    func loadNotes() async {
        isLoading = true
        errorMessage = nil
        
        do {
            notes = try await service.fetchNotes(folderId: selectedFolderId, token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadFolders() async {
        do {
            folders = try await service.fetchFolders(token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func searchNotes() async {
        guard !searchQuery.isEmpty else {
            await loadNotes()
            return
        }
        
        isLoading = true
        
        do {
            notes = try await service.searchNotes(query: searchQuery, token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func createNote(title: String, content: String?, completion: @escaping (Note?) -> Void) async {
        let request = NoteRequest(
            title: title,
            content: content,
            folderId: selectedFolderId,
            isPinned: false,
            isArchived: false,
            tags: nil
        )
        
        do {
            let note = try await service.createNote(request: request, token: token)
            notes.insert(note, at: 0)
            completion(note)
        } catch {
            errorMessage = error.localizedDescription
            completion(nil)
        }
    }
    
    func updateNote(id: String, title: String?, content: String?, isPinned: Bool?) async {
        guard let existingNote = notes.first(where: { $0.id == id }) else { return }
        
        let request = NoteRequest(
            title: title ?? existingNote.title,
            content: content ?? existingNote.content,
            folderId: existingNote.folderId,
            isPinned: isPinned ?? existingNote.isPinned,
            isArchived: existingNote.isArchived,
            tags: existingNote.tags
        )
        
        do {
            let updatedNote = try await service.updateNote(id: id, request: request, token: token)
            if let index = notes.firstIndex(where: { $0.id == id }) {
                notes[index] = updatedNote
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteNote(id: String) async {
        do {
            try await service.deleteNote(id: id, token: token)
            notes.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func togglePin(note: Note) async {
        let newPinState = !(note.isPinned ?? false)
        await updateNote(id: note.id, title: nil, content: nil, isPinned: newPinState)
        Haptics.light()
    }
    
    func createFolder(name: String, icon: String, color: String) async {
        let request = NoteFolderRequest(name: name, icon: icon, color: color, sortOrder: folders.count)
        
        do {
            let folder = try await service.createFolder(request: request, token: token)
            folders.append(folder)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteFolder(id: String) async {
        do {
            try await service.deleteFolder(id: id, token: token)
            folders.removeAll { $0.id == id }
            if selectedFolderId == id {
                selectedFolderId = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
