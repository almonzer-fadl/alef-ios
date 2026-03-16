//
//  ProjectsListView.swift
//  alef
//
//  Main screen for Projects module — list of projects as cards
//

import SwiftUI

struct ProjectsListView: View {
    
    @AppStorage("authToken") private var authToken = ""
    @StateObject private var viewModel = ProjectViewModel()
    @State private var showCreateProject = false
    @State private var selectedStatus: ProjectStatus = .active
    
    var body: some View {
        ZStack {
            Color.alefBg.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                header
                
                // Status Filter
                statusFilter
                
                // Projects List
                if viewModel.isLoading && viewModel.projects.isEmpty {
                    Spacer()
                    ProgressView()
                        .tint(.alefProjects)
                    Spacer()
                } else if viewModel.projects.isEmpty {
                    emptyState
                } else {
                    projectsList
                }
            }
            
            // FAB
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        Haptics.selection()
                        showCreateProject = true
                    } label: {
                        Image(systemName: "plus")
                            .font(AlefFont.bold(20))
                            .foregroundColor(.alefBg)
                            .frame(width: 60, height: 60)
                            .background(Color.alefProjects)
                            .clipShape(Circle())
                            .shadow(color: Color.alefProjects.opacity(0.4), radius: 12, x: 0, y: 4)
                    }
                    .padding(.trailing, AlefLayout.horizontalPadding)
                    .padding(.bottom, 30)
                }
            }
        }
        .sheet(isPresented: $showCreateProject) {
            CreateProjectView(viewModel: viewModel)
        }
        .task {
            viewModel.token = authToken
            await viewModel.loadProjects(status: selectedStatus == .active ? nil : selectedStatus.rawValue)
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Text("Projects")
                .font(AlefFont.Rounded.bold(34))
                .foregroundColor(.alefText)
            
            Spacer()
        }
        .padding(.horizontal, AlefLayout.horizontalPadding)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }
    
    // MARK: - Status Filter
    
    private var statusFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach([ProjectStatus.active, .onHold, .completed], id: \.self) { status in
                    filterChip(status)
                }
            }
            .padding(.horizontal, AlefLayout.horizontalPadding)
        }
        .padding(.bottom, AlefLayout.sectionSpacing)
    }
    
    private func filterChip(_ status: ProjectStatus) -> some View {
        Button {
            Haptics.selection()
            selectedStatus = status
            Task {
                await viewModel.loadProjects(status: status == .active ? nil : status.rawValue)
            }
        } label: {
            Text(status.label)
                .font(AlefFont.medium(15))
                .foregroundColor(selectedStatus == status ? .alefBg : .alefTextSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedStatus == status ? Color.alefProjects : Color.alefSurface)
                .cornerRadius(20)
        }
    }
    
    // MARK: - Projects List
    
    private var projectsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.projects) { project in
                    NavigationLink {
                        ProjectBoardView(projectId: project.id, projectName: project.name, viewModel: viewModel)
                    } label: {
                        ProjectCard(project: project)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AlefLayout.horizontalPadding)
            .padding(.bottom, 100) // Space for FAB
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(.alefTextTertiary)
            
            Text("No projects yet")
                .font(AlefFont.semibold(20))
                .foregroundColor(.alefText)
            
            Text("Tap + to create your first project")
                .font(AlefFont.regular(15))
                .foregroundColor(.alefTextSecondary)
            
            Spacer()
        }
    }
}

// MARK: - Project Card

struct ProjectCard: View {
    let project: ProjectWithStats
    
    private var projectColor: Color {
        Color(hex: project.color) ?? .alefProjects
    }
    
    private var progress: Double {
        guard project.taskCount > 0 else { return 0 }
        // Note: We don't have done count in ProjectWithStats, just total
        // In a real implementation, backend should return completed count
        return 0.0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: project.icon)
                    .font(.system(size: 24))
                    .foregroundColor(projectColor)
                    .frame(width: 48, height: 48)
                    .background(projectColor.opacity(0.15))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(AlefFont.semibold(18))
                        .foregroundColor(.alefText)
                    
                    if let description = project.description, !description.isEmpty {
                        Text(description)
                            .font(AlefFont.regular(14))
                            .foregroundColor(.alefTextSecondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Task Count
                VStack(spacing: 2) {
                    Text("\(project.taskCount)")
                        .font(AlefFont.Rounded.bold(20))
                        .foregroundColor(.alefText)
                    Text("tasks")
                        .font(AlefFont.regular(11))
                        .foregroundColor(.alefTextTertiary)
                }
            }
            
            // Progress Bar (placeholder for now)
            if project.taskCount > 0 {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.alefSurface)
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(projectColor)
                            .frame(width: geometry.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(16)
        .background(Color.alefSurface)
        .cornerRadius(AlefLayout.cardRadius)
    }
}
