//
//  Journal.swift
//  alef
//
//  Data models for the Journal module.
//
//  Maps to the backend schema:
//  - JournalEntry → `journal_entries` table
//
//  Journal entries support mood tracking (5-point scale),
//  energy levels (1-5), and free-form tags for categorisation.
//

import Foundation
import SwiftUI

// MARK: - Mood

/// Five-point mood scale used across journal and health modules.
/// Maps directly to the `mood` enum in the database.
enum Mood: String, Codable, CaseIterable {
    case great
    case good
    case okay
    case bad
    case terrible

    var label: String {
        switch self {
        case .great:    return "Great"
        case .good:     return "Good"
        case .okay:     return "Okay"
        case .bad:      return "Bad"
        case .terrible: return "Terrible"
        }
    }

    var icon: String {
        switch self {
        case .great:    return "face.smiling.inverse"
        case .good:     return "face.smiling"
        case .okay:     return "minus.circle"
        case .bad:      return "cloud.rain"
        case .terrible: return "exclamationmark.triangle"
        }
    }

    var color: Color {
        switch self {
        case .great:    return .alefSuccess
        case .good:     return .alefHabits
        case .okay:     return .alefMovies
        case .bad:      return .alefDiet
        case .terrible: return .alefError
        }
    }
}

// MARK: - Journal Entry

struct JournalEntry: Codable, Identifiable {
    let id: String
    let userId: String
    let date: String
    var content: String
    var mood: Mood?
    var energyLevel: Int?
    var tags: [String]?
    let createdAt: String
    var updatedAt: String
}

// MARK: - API Response Wrappers

struct JournalEntriesResponse: Codable {
    let entries: [JournalEntry]
}

struct JournalEntryResponse: Codable {
    let entry: JournalEntry
}

struct JournalEntryNullable: Codable {
    let entry: JournalEntry?
}

// MARK: - Create/Update DTOs

struct CreateJournalBody: Encodable {
    let date: String
    let content: String
    var mood: Mood?
    var energyLevel: Int?
    var tags: [String]?
}
