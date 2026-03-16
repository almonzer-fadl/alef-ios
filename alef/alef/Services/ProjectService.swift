//
//  ProjectService.swift
//  alef
//
//  Network layer for the Projects module.
//  CRUD operations for projects and tasks.
//

import Foundation

struct ProjectService {
    
    private let api = APIClient.shared
    
    // MARK: - Projects
    
    /// Fetch all projects for the authenticated user
    func fetchProjects(token: String, status: String? = nil) async throws -> [ProjectWithStats] {
        var path = "/projects"
        if let status = status {
            path += "?status=\(status)"
        }
        let response: ProjectsResponse = try await api.request("GET", path, token: token)
        return response.projects
    }
    
    /// Fetch a single project with task counts
    func fetchProject(id: String, token: String) async throws -> ProjectDetail {
        try await api.request("GET", "/projects/\(id)", token: token)
    }
    
    /// Create a new project
    func createProject(_ body: CreateProjectBody, token: String) async throws -> Project {
        let response: ProjectResponse = try await api.request("POST", "/projects", body: body, token: token)
        return response.project
    }
    
    /// Update an existing project
    func updateProject(id: String, body: UpdateProjectBody, token: String) async throws -> Project {
        let response: ProjectResponse = try await api.request("PATCH", "/projects/\(id)", body: body, token: token)
        return response.project
    }
    
    /// Delete a project permanently (cascades tasks)
    func deleteProject(id: String, token: String) async throws {
        try await api.requestVoid("DELETE", "/projects/\(id)", token: token)
    }
    
    // MARK: - Tasks
    
    /// Fetch all tasks for a project
    func fetchProjectTasks(projectId: String, token: String) async throws -> [ProjectTask] {
        let response: TasksResponse = try await api.request("GET", "/projects/\(projectId)/tasks", token: token)
        return response.tasks
    }
    
    /// Fetch all tasks with optional filters
    func fetchTasks(token: String, status: String? = nil, priority: String? = nil, projectId: String? = nil) async throws -> [ProjectTask] {
        var path = "/projects/tasks"
        var params: [String] = []
        if let status = status { params.append("status=\(status)") }
        if let priority = priority { params.append("priority=\(priority)") }
        if let projectId = projectId { params.append("projectId=\(projectId)") }
        if !params.isEmpty {
            path += "?" + params.joined(separator: "&")
        }
        let response: TasksResponse = try await api.request("GET", path, token: token)
        return response.tasks
    }
    
    /// Create a new task
    func createTask(_ body: CreateTaskBody, token: String) async throws -> ProjectTask {
        let response: TaskResponse = try await api.request("POST", "/projects/tasks", body: body, token: token)
        return response.task
    }
    
    /// Update an existing task
    func updateTask(id: String, body: UpdateTaskBody, token: String) async throws -> ProjectTask {
        let response: TaskResponse = try await api.request("PATCH", "/projects/tasks/\(id)", body: body, token: token)
        return response.task
    }
    
    /// Delete a task permanently
    func deleteTask(id: String, token: String) async throws {
        try await api.requestVoid("DELETE", "/projects/tasks/\(id)", token: token)
    }
}

// MARK: - Request/Response Types

struct CreateProjectBody: Codable {
    let name: String
    let description: String?
    let color: String?
    let icon: String?
    let status: String?
    let sortOrder: Int?
}

struct UpdateProjectBody: Codable {
    let name: String?
    let description: String?
    let color: String?
    let icon: String?
    let status: String?
    let sortOrder: Int?
}

struct CreateTaskBody: Codable {
    let title: String
    let description: String?
    let projectId: String?
    let status: String?
    let priority: String?
    let dueDate: String?
    let tags: [String]?
    let sortOrder: Int?
}

struct UpdateTaskBody: Codable {
    let title: String?
    let description: String?
    let projectId: String?
    let status: String?
    let priority: String?
    let dueDate: String?
    let tags: [String]?
    let sortOrder: Int?
}

struct ProjectsResponse: Codable {
    let projects: [ProjectWithStats]
}

struct ProjectResponse: Codable {
    let project: Project
}

struct ProjectDetail: Codable {
    let project: Project
    let taskCounts: TaskCounts
    let totalTasks: Int
}

struct TaskCounts: Codable {
    let todo: Int
    let inProgress: Int
    let review: Int
    let done: Int
    
    enum CodingKeys: String, CodingKey {
        case todo
        case inProgress = "in_progress"
        case review
        case done
    }
}

struct TasksResponse: Codable {
    let tasks: [ProjectTask]
}

struct TaskResponse: Codable {
    let task: ProjectTask
}
