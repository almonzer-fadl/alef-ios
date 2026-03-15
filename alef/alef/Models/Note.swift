//
//  Note.swift
//  alef
//
//  Created by Alef on 2026-03-07.
//  Notes module models — inspired by Apple Notes.
//

import Foundation

/// A note with title, content, folder, and metadata
struct Note: Codable, Identifiable {
    let id: String
    let userId: String
    var folderId: String?
    var title: String
    var content: String?
    var isPinned: Bool?
    var isArchived: Bool?
    var tags: [String]?
    let createdAt: String
    var updatedAt: String
    
    /// First line of content for preview (2 lines max)
    var preview: String {
        guard let content = content, !content.isEmpty else {
            return "No additional text"
        }
        let lines = content.split(separator: "\n", maxSplits: 2)
        return lines.prefix(2).joined(separator: "\n")
    }
    
    /// Display-friendly relative date
    var relativeDate: String {
        guard let date = ISO8601DateFormatter().date(from: updatedAt) else {
            return ""
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE" // Day name
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

/// A folder container for organizing notes
struct NoteFolder: Codable, Identifiable {
    let id: String
    let userId: String
    var name: String
    var icon: String?
    var color: String?
    var sortOrder: Int?
    let createdAt: String
    var noteCount: Int?
}

/// API request for creating/updating notes
struct NoteRequest: Codable {
    var title: String
    var content: String?
    var folderId: String?
    var isPinned: Bool?
    var isArchived: Bool?
    var tags: [String]?
}

/// API request for creating/updating folders
struct NoteFolderRequest: Codable {
    var name: String
    var icon: String?
    var color: String?
    var sortOrder: Int?
}
