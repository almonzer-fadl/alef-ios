//
//  TaskDetailView.swift
//  alef
//
//  Detail/edit view for a single task
//

import SwiftUI

struct TaskDetailView: View {
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ProjectViewModel
    
    let projectId: String?
    
    @State private var task: ProjectTask
    @State private var showDeleteConfirmation = false
    
    private var priority: TaskPriority {
        TaskPriority(rawValue: task.priority) ?? .none
    }
    
    private var status: TaskStatus {
        TaskStatus(rawValue: task.status) ?? .todo
    }
    
    init(task: ProjectTask, viewModel: ProjectViewModel, projectId: String? = nil) {
        self._task = State(initialValue: task)
        self.viewModel = viewModel
        self.projectId = projectId
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.alefBg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AlefLayout.sectionSpacing) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(AlefFont.semibold(15))
                                .foregroundColor(.alefTextSecondary)
                            
                            TextField("Task title", text: $task.title)
                                .font(AlefFont.regular(17))
                                .foregroundColor(.alefText)
                                .padding(16)
                                .background(Color.alefSurface)
                                .cornerRadius(12)
                                .onChange(of: task.title) { _, _ in
                                    updateTask()
                                }
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(AlefFont.semibold(15))
                                .foregroundColor(.alefTextSecondary)
                            
                            TextField("Optional", text: Binding(
                                get: { task.description ?? "" },
                                set: { task.description = $0.isEmpty ? nil : $0 }
                            ))
                            .font(AlefFont.regular(17))
                            .foregroundColor(.alefText)
                            .padding(16)
                            .background(Color.alefSurface)
                            .cornerRadius(12)
                            .onChange(of: task.description) { _, _ in
                                updateTask()
                            }
                        }
                        
                        // Status
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Status")
                                .font(AlefFont.semibold(15))
                                .foregroundColor(.alefTextSecondary)
                            
                            HStack(spacing: 8) {
                                ForEach(TaskStatus.allCases, id: \.self) { s in
                                    statusButton(s)
                                }
                            }
                        }
                        
                        // Priority
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Priority")
                                .font(AlefFont.semibold(15))
                                .foregroundColor(.alefTextSecondary)
                            
                            HStack(spacing: 8) {
                                ForEach(TaskPriority.allCases, id: \.self) { p in
                                    priorityButton(p)
                                }
                            }
                        }
                        
                        // Due Date
                        if let dueDateStr = task.dueDate {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Due Date")
                                    .font(AlefFont.semibold(15))
                                    .foregroundColor(.alefTextSecondary)
                                
                                HStack {
                                    Image(systemName: "calendar")
                                    Text(formatDate(dueDateStr))
                                        .font(AlefFont.regular(15))
                                }
                                .foregroundColor(.alefText)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.alefSurface)
                                .cornerRadius(12)
                            }
                        }
                        
                        // Delete Button
                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            Text("Delete Task")
                                .font(AlefFont.semibold(17))
                                .foregroundColor(.alefError)
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(Color.alefSurface)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, AlefLayout.horizontalPadding)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.alefProjects)
                }
            }
            .alert("Delete Task", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteTask()
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Status Button
    
    private func statusButton(_ s: TaskStatus) -> some View {
        Button {
            Haptics.selection()
            task.status = s.rawValue
            updateTask()
        } label: {
            Image(systemName: s.icon)
                .font(.system(size: 14))
                .foregroundColor(status == s ? .alefBg : .alefTextSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(status == s ? Color.alefProjects : Color.alefSurface)
                .cornerRadius(8)
        }
    }
    
    // MARK: - Priority Button
    
    private func priorityButton(_ p: TaskPriority) -> some View {
        Button {
            Haptics.selection()
            task.priority = p.rawValue
            updateTask()
        } label: {
            Image(systemName: p.icon)
                .font(.system(size: 14))
                .foregroundColor(priority == p ? .alefBg : p.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(priority == p ? p.color : Color.alefSurface)
                .cornerRadius(8)
        }
    }
    
    // MARK: - Update Task
    
    private func updateTask() {
        Task {
            await viewModel.updateTask(
                id: task.id,
                title: task.title,
                description: task.description,
                status: task.status,
                priority: task.priority,
                projectId: projectId
            )
        }
    }
    
    // MARK: - Delete Task
    
    private func deleteTask() {
        Task {
            await viewModel.deleteTask(id: task.id, projectId: projectId)
            dismiss()
        }
    }
    
    // MARK: - Format Date
    
    private func formatDate(_ dateStr: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else { return dateStr }
        
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}
