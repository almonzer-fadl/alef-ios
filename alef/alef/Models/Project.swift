/**
 * Project.swift — Models for Projects Module
 *
 * ClickUp-inspired project management for Alef.
 * Projects contain tasks displayed in kanban board columns.
 */

import SwiftUI

// MARK: - Project

struct Project: Codable, Identifiable {
    let id: String
    let userId: String
    var name: String
    var description: String?
    var color: String
    var icon: String
    var status: String          // active, on_hold, completed, archived
    var sortOrder: Int
    let createdAt: String
    var updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, color, icon, status, createdAt, updatedAt
        case userId = "user_id"
        case sortOrder = "sort_order"
    }
}

// MARK: - Project with Stats (for list view)

struct ProjectWithStats: Codable, Identifiable {
    let id: String
    let userId: String
    var name: String
    var description: String?
    var color: String
    var icon: String
    var status: String
    var sortOrder: Int
    let createdAt: String
    var updatedAt: String
    let taskCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, color, icon, status, createdAt, updatedAt
        case userId = "user_id"
        case sortOrder = "sort_order"
        case taskCount = "task_count"
    }
}

// MARK: - ProjectTask

struct ProjectTask: Codable, Identifiable {
    let id: String
    let userId: String
    var projectId: String?
    var title: String
    var description: String?
    var status: String          // todo, in_progress, review, done
    var priority: String        // urgent, high, medium, low, none
    var dueDate: String?
    var tags: [String]?
    var sortOrder: Int
    var completedAt: String?
    let createdAt: String
    var updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, status, priority, tags, createdAt, updatedAt
        case userId = "user_id"
        case projectId = "project_id"
        case dueDate = "due_date"
        case sortOrder = "sort_order"
        case completedAt = "completed_at"
    }
}

// MARK: - Task Priority

enum TaskPriority: String, CaseIterable {
    case urgent
    case high
    case medium
    case low
    case none
    
    var label: String {
        switch self {
        case .urgent: return "Urgent"
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        case .none: return "None"
        }
    }
    
    var color: Color {
        switch self {
        case .urgent: return .alefError
        case .high: return .alefDiet
        case .medium: return .alefMovies
        case .low: return .alefHealth
        case .none: return .alefTextTertiary
        }
    }
    
    var icon: String {
        switch self {
        case .urgent: return "flag.fill"
        case .high: return "flag.fill"
        case .medium: return "flag"
        case .low: return "flag"
        case .none: return "minus"
        }
    }
}

// MARK: - Task Status

enum TaskStatus: String, CaseIterable {
    case todo = "todo"
    case inProgress = "in_progress"
    case review = "review"
    case done = "done"
    
    var label: String {
        switch self {
        case .todo: return "To Do"
        case .inProgress: return "In Progress"
        case .review: return "Review"
        case .done: return "Done"
        }
    }
    
    var icon: String {
        switch self {
        case .todo: return "circle"
        case .inProgress: return "circle.lefthalf.filled"
        case .review: return "eye"
        case .done: return "checkmark.circle.fill"
        }
    }
}

// MARK: - Project Status

enum ProjectStatus: String, CaseIterable {
    case active
    case onHold = "on_hold"
    case completed
    case archived
    
    var label: String {
        switch self {
        case .active: return "Active"
        case .onHold: return "On Hold"
        case .completed: return "Completed"
        case .archived: return "Archived"
        }
    }
    
    var color: Color {
        switch self {
        case .active: return .alefProjects
        case .onHold: return .alefTextSecondary
        case .completed: return .alefSuccess
        case .archived: return .alefTextTertiary
        }
    }
}
