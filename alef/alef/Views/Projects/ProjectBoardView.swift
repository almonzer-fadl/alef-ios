//
//  ProjectBoardView.swift
//  alef
//
//  Kanban board for a single project — 4 columns (To Do, In Progress, Review, Done)
//

import SwiftUI

struct ProjectBoardView: View {
    
    let projectId: String
    let projectName: String
    @ObservedObject var viewModel: ProjectViewModel
    
    @State private var showCreateTask = false
    @State private var selectedTask: ProjectTask?
    
    private var tasksByStatus: [TaskStatus: [ProjectTask]] {
        Dictionary(grouping: viewModel.tasks, by: { TaskStatus(rawValue: $0.status) ?? .todo })
    }
    
    var body: some View {
        ZStack {
            Color.alefBg.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Kanban Columns
                ScrollView {
                    HStack(alignment: .top, spacing: 16) {
                        ForEach([TaskStatus.todo, .inProgress, .review, .done], id: \.self) { status in
                            boardColumn(status: status)
                        }
                    }
                    .padding(.horizontal, AlefLayout.horizontalPadding)
                    .padding(.top, 20)
                    .padding(.bottom, 100) // Space for FAB
                }
            }
            
            // FAB
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        Haptics.selection()
                        showCreateTask = true
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
        .navigationTitle(projectName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCreateTask) {
            CreateTaskView(viewModel: viewModel, projectId: projectId)
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailView(task: task, viewModel: viewModel, projectId: projectId)
        }
        .task {
            await viewModel.loadProjectTasks(projectId: projectId)
        }
    }
    
    // MARK: - Board Column
    
    private func boardColumn(status: TaskStatus) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Column Header
            HStack {
                Text(status.label)
                    .font(AlefFont.semibold(15))
                    .foregroundColor(.alefText)
                
                Spacer()
                
                // Task count
                Text("\(tasksByStatus[status]?.count ?? 0)")
                    .font(AlefFont.Rounded.bold(14))
                    .foregroundColor(.alefTextTertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.alefSurface)
            .cornerRadius(8)
            
            // Tasks
            ForEach(tasksByStatus[status] ?? []) { task in
                TaskCardView(task: task)
                    .onTapGesture {
                        Haptics.selection()
                        selectedTask = task
                    }
            }
        }
        .frame(width: 200)
    }
}

// MARK: - Task Card View

struct TaskCardView: View {
    let task: ProjectTask
    
    private var priority: TaskPriority {
        TaskPriority(rawValue: task.priority) ?? .none
    }
    
    private var dueDateText: String? {
        guard let dueDateStr = task.dueDate else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dueDateStr) else { return nil }
        
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Priority Badge
            if priority != .none {
                HStack(spacing: 4) {
                    Image(systemName: priority.icon)
                        .font(.system(size: 10))
                    Text(priority.label)
                        .font(AlefFont.semibold(11))
                }
                .foregroundColor(priority.color)
            }
            
            // Title
            Text(task.title)
                .font(AlefFont.medium(15))
                .foregroundColor(.alefText)
                .lineLimit(2)
            
            // Due Date
            if let dueText = dueDateText {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                    Text(dueText)
                        .font(AlefFont.regular(12))
                }
                .foregroundColor(.alefTextSecondary)
            }
        }
        .padding(12)
        .frame(width: 200)
        .background(Color.alefSurface)
        .cornerRadius(12)
    }
}
