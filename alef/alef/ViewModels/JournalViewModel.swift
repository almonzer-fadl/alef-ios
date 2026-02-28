//
//  JournalViewModel.swift
//  alef
//
//  Drives the journal list and entry creation/editing.
//

import SwiftUI
import Combine

@MainActor
final class JournalViewModel: ObservableObject {

    @Published var entries: [JournalEntry] = []
    @Published var isLoading = false
    @Published var error: String?

    private let service = JournalService()
    var token: String = ""

    /// Load recent journal entries.
    func fetchEntries() async {
        guard !token.isEmpty else { return }
        isLoading = entries.isEmpty
        error = nil

        do {
            entries = try await service.fetchRecent(token: token)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    /// Create a new journal entry.
    func create(date: String, content: String, mood: Mood?, energy: Int?, tags: [String]) async {
        let body = CreateJournalBody(
            date: date,
            content: content,
            mood: mood,
            energyLevel: energy,
            tags: tags.isEmpty ? nil : tags
        )

        do {
            let entry = try await service.create(body, token: token)
            entries.insert(entry, at: 0)
            Haptics.success()
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Delete an entry.
    func deleteEntry(id: String) async {
        do {
            try await service.delete(id: id, token: token)
            entries.removeAll { $0.id == id }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
