//
//  CreateTaskView.swift
//  alef
//
//  Form to create a new task
//

import SwiftUI

struct CreateTaskView: View {
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ProjectViewModel
    
    let projectId: String?
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedPriority: TaskPriority = .none
    @State private var selectedStatus: TaskStatus = .todo
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    
    init(viewModel: ProjectViewModel, projectId: String? = nil) {
        self.viewModel = viewModel
        self.projectId = projectId
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.alefBg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AlefLayout.sectionSpacing) {
                        // Title Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Task Title")
                                .font(AlefFont.semibold(15))
                                .foregroundColor(.alefTextSecondary)
                            
                            TextField("Enter title", text: $title)
                                .font(AlefFont.regular(17))
                                .foregroundColor(.alefText)
                                .padding(16)
                                .background(Color.alefSurface)
                                .cornerRadius(12)
                        }
                        
                        // Description Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(AlefFont.semibold(15))
                                .foregroundColor(.alefTextSecondary)
                            
                            TextField("Optional", text: $description)
                                .font(AlefFont.regular(17))
                                .foregroundColor(.alefText)
                                .padding(16)
                                .background(Color.alefSurface)
                                .cornerRadius(12)
                        }
                        
                        // Status Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Status")
                                .font(AlefFont.semibold(15))
                                .foregroundColor(.alefTextSecondary)
                            
                            HStack(spacing: 8) {
                                ForEach(TaskStatus.allCases, id: \.self) { status in
                                    statusChip(status)
                                }
                            }
                        }
                        
                        // Priority Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Priority")
                                .font(AlefFont.semibold(15))
                                .foregroundColor(.alefTextSecondary)
                            
                            HStack(spacing: 8) {
                                ForEach(TaskPriority.allCases, id: \.self) { priority in
                                    priorityChip(priority)
                                }
                            }
                        }
                        
                        // Due Date
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("Set Due Date", isOn: $hasDueDate)
                                .font(AlefFont.semibold(15))
                                .foregroundColor(.alefTextSecondary)
                                .tint(.alefProjects)
                            
                            if hasDueDate {
                                DatePicker("", selection: $dueDate, displayedComponents: .date)
                                    .datePickerStyle(.graphical)
                                    .tint(.alefProjects)
                            }
                        }
                        
                        // Create Button
                        Button {
                            createTask()
                        } label: {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.alefBg)
                                    .frame(maxWidth: .infinity)
                                    .padding(16)
                                    .background(Color.alefProjects)
                                    .cornerRadius(12)
                            } else {
                                Text("Create Task")
                                    .font(AlefFont.semibold(17))
                                    .foregroundColor(.alefBg)
                                    .frame(maxWidth: .infinity)
                                    .padding(16)
                                    .background(title.isEmpty ? Color.alefTextTertiary : Color.alefProjects)
                                    .cornerRadius(12)
                            }
                        }
                        .disabled(title.isEmpty || viewModel.isLoading)
                    }
                    .padding(.horizontal, AlefLayout.horizontalPadding)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.alefTextSecondary)
                }
            }
        }
    }
    
    // MARK: - Status Chip
    
    private func statusChip(_ status: TaskStatus) -> some View {
        Button {
            Haptics.selection()
            selectedStatus = status
        } label: {
            HStack(spacing: 4) {
                Image(systemName: status.icon)
                    .font(.system(size: 12))
            }
            .foregroundColor(selectedStatus == status ? .alefBg : .alefTextSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(selectedStatus == status ? Color.alefProjects : Color.alefSurface)
            .cornerRadius(8)
        }
    }
    
    // MARK: - Priority Chip
    
    private func priorityChip(_ priority: TaskPriority) -> some View {
        Button {
            Haptics.selection()
            selectedPriority = priority
        } label: {
            HStack(spacing: 4) {
                Image(systemName: priority.icon)
                    .font(.system(size: 12))
            }
            .foregroundColor(selectedPriority == priority ? .alefBg : priority.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(selectedPriority == priority ? priority.color : Color.alefSurface)
            .cornerRadius(8)
        }
    }
    
    // MARK: - Create Task
    
    private func createTask() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dueDateStr = hasDueDate ? formatter.string(from: dueDate) : nil
        
        Task {
            await viewModel.createTask(
                title: title,
                description: description.isEmpty ? nil : description,
                projectId: projectId,
                priority: selectedPriority.rawValue,
                dueDate: dueDateStr
            )
            dismiss()
        }
    }
}
