//
//  ProjectViewModel.swift
//  alef
//
//  State management for Projects module
//

import SwiftUI
import Combine

@MainActor
final class ProjectViewModel: ObservableObject {
    
    @Published var projects: [ProjectWithStats] = []
    @Published var currentProject: ProjectDetail?
    @Published var tasks: [ProjectTask] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var token: String = ""
    
    private let service = ProjectService()
    
    // MARK: - Projects
    
    func loadProjects(status: String? = nil) async {
        guard !token.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            projects = try await service.fetchProjects(token: token, status: status)
        } catch {
            errorMessage = "Failed to load projects: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadProject(id: String) async {
        guard !token.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            currentProject = try await service.fetchProject(id: id, token: token)
        } catch {
            errorMessage = "Failed to load project: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func createProject(name: String, description: String?, color: String?, icon: String?) async {
        guard !token.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let body = CreateProjectBody(
                name: name,
                description: description,
                color: color,
                icon: icon,
                status: "active",
                sortOrder: nil
            )
            _ = try await service.createProject(body, token: token)
            await loadProjects()
            Haptics.success()
        } catch {
            errorMessage = "Failed to create project: \(error.localizedDescription)"
            Haptics.error()
        }
        
        isLoading = false
    }
    
    func updateProject(id: String, name: String?, description: String?, color: String?, icon: String?, status: String?) async {
        guard !token.isEmpty else { return }
        
        do {
            let body = UpdateProjectBody(
                name: name,
                description: description,
                color: color,
                icon: icon,
                status: status,
                sortOrder: nil
            )
            _ = try await service.updateProject(id: id, body: body, token: token)
            await loadProjects()
            Haptics.success()
        } catch {
            errorMessage = "Failed to update project: \(error.localizedDescription)"
            Haptics.error()
        }
    }
    
    func deleteProject(id: String) async {
        guard !token.isEmpty else { return }
        
        do {
            try await service.deleteProject(id: id, token: token)
            await loadProjects()
            Haptics.success()
        } catch {
            errorMessage = "Failed to delete project: \(error.localizedDescription)"
            Haptics.error()
        }
    }
    
    // MARK: - Tasks
    
    func loadProjectTasks(projectId: String) async {
        guard !token.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            tasks = try await service.fetchProjectTasks(projectId: projectId, token: token)
        } catch {
            errorMessage = "Failed to load tasks: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadTasks(status: String? = nil, priority: String? = nil) async {
        guard !token.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            tasks = try await service.fetchTasks(token: token, status: status, priority: priority)
        } catch {
            errorMessage = "Failed to load tasks: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func createTask(title: String, description: String?, projectId: String?, priority: String?, dueDate: String?) async {
        guard !token.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let body = CreateTaskBody(
                title: title,
                description: description,
                projectId: projectId,
                status: "todo",
                priority: priority,
                dueDate: dueDate,
                tags: nil,
                sortOrder: nil
            )
            _ = try await service.createTask(body, token: token)
            
            if let projectId = projectId {
                await loadProjectTasks(projectId: projectId)
            } else {
                await loadTasks()
            }
            
            Haptics.success()
        } catch {
            errorMessage = "Failed to create task: \(error.localizedDescription)"
            Haptics.error()
        }
        
        isLoading = false
    }
    
    func updateTask(id: String, title: String? = nil, description: String? = nil, status: String? = nil, priority: String? = nil, dueDate: String? = nil, projectId: String? = nil) async {
        guard !token.isEmpty else { return }
        
        do {
            let body = UpdateTaskBody(
                title: title,
                description: description,
                projectId: nil,
                status: status,
                priority: priority,
                dueDate: dueDate,
                tags: nil,
                sortOrder: nil
            )
            _ = try await service.updateTask(id: id, body: body, token: token)
            
            if let projectId = projectId {
                await loadProjectTasks(projectId: projectId)
            } else {
                await loadTasks()
            }
            
            Haptics.selection()
        } catch {
            errorMessage = "Failed to update task: \(error.localizedDescription)"
            Haptics.error()
        }
    }
    
    func deleteTask(id: String, projectId: String? = nil) async {
        guard !token.isEmpty else { return }
        
        do {
            try await service.deleteTask(id: id, token: token)
            
            if let projectId = projectId {
                await loadProjectTasks(projectId: projectId)
            } else {
                await loadTasks()
            }
            
            Haptics.success()
        } catch {
            errorMessage = "Failed to delete task: \(error.localizedDescription)"
            Haptics.error()
        }
    }
}
