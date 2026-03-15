//
//  FolderListView.swift
//  alef
//
//  Created by Alef on 2026-03-07.
//  Folder sidebar for organizing notes.
//

import SwiftUI

struct FolderListView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: NotesViewModel
    
    @State private var showingCreateFolder = false
    @State private var newFolderName = ""
    @State private var selectedIcon = "folder.fill"
    @State private var selectedColor = "#FCD34D"
    
    var body: some View {
        NavigationView {
            List {
                // All Notes (default view)
                Button(action: {
                    viewModel.selectedFolderId = nil
                    Task {
                        await viewModel.loadNotes()
                    }
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "tray.fill")
                            .foregroundColor(.alefNotes)
                        Text("All Notes")
                            .font(AlefFont.medium(16))
                            .foregroundColor(.alefText)
                        Spacer()
                        if viewModel.selectedFolderId == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.alefNotes)
                        }
                    }
                }
                
                // User Folders
                Section(header: Text("Folders").font(AlefFont.semibold(13))) {
                    ForEach(viewModel.folders) { folder in
                        Button(action: {
                            selectFolder(folder)
                        }) {
                            HStack {
                                Image(systemName: folder.icon ?? "folder.fill")
                                    .foregroundColor(Color(hex: folder.color ?? "#FCD34D"))
                                
                                Text(folder.name)
                                    .font(AlefFont.medium(16))
                                    .foregroundColor(.alefText)
                                
                                Spacer()
                                
                                if let count = folder.noteCount, count > 0 {
                                    Text("\(count)")
                                        .font(AlefFont.regular(13))
                                        .foregroundColor(.alefTextSecondary)
                                }
                                
                                if viewModel.selectedFolderId == folder.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.alefNotes)
                                }
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteFolder(folder)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                
                // Create Folder Button
                Button(action: { showingCreateFolder = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.alefNotes)
                        Text("New Folder")
                            .font(AlefFont.medium(16))
                            .foregroundColor(.alefNotes)
                    }
                }
            }
            .navigationTitle("Folders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.alefNotes)
                }
            }
            .sheet(isPresented: $showingCreateFolder) {
                createFolderSheet
            }
        }
    }
    
    // MARK: - Create Folder Sheet
    
    private var createFolderSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Folder Details")) {
                    TextField("Name", text: $newFolderName)
                        .font(AlefFont.regular(16))
                    
                    Picker("Icon", selection: $selectedIcon) {
                        ForEach(folderIcons, id: \.self) { icon in
                            HStack {
                                Image(systemName: icon)
                                Text(icon)
                            }
                            .tag(icon)
                        }
                    }
                    
                    Picker("Color", selection: $selectedColor) {
                        ForEach(folderColors, id: \.hex) { color in
                            HStack {
                                Circle()
                                    .fill(Color(hex: color.hex))
                                    .frame(width: 20, height: 20)
                                Text(color.name)
                            }
                            .tag(color.hex)
                        }
                    }
                }
            }
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingCreateFolder = false
                        resetForm()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createFolder()
                    }
                    .disabled(newFolderName.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func selectFolder(_ folder: NoteFolder) {
        viewModel.selectedFolderId = folder.id
        Task {
            await viewModel.loadNotes()
        }
        Haptics.light()
        dismiss()
    }
    
    private func createFolder() {
        Task {
            await viewModel.createFolder(
                name: newFolderName,
                icon: selectedIcon,
                color: selectedColor
            )
            Haptics.success()
            showingCreateFolder = false
            resetForm()
        }
    }
    
    private func deleteFolder(_ folder: NoteFolder) {
        Task {
            await viewModel.deleteFolder(id: folder.id)
            Haptics.success()
        }
    }
    
    private func resetForm() {
        newFolderName = ""
        selectedIcon = "folder.fill"
        selectedColor = "#FCD34D"
    }
    
    // MARK: - Data
    
    private let folderIcons = [
        "folder.fill",
        "folder",
        "tray.fill",
        "archivebox.fill",
        "star.fill",
        "heart.fill",
        "briefcase.fill",
        "house.fill",
        "lightbulb.fill",
        "book.fill"
    ]
    
    private let folderColors = [
        FolderColor(name: "Amber", hex: "#FCD34D"),
        FolderColor(name: "Red", hex: "#EF4444"),
        FolderColor(name: "Orange", hex: "#F97316"),
        FolderColor(name: "Green", hex: "#10B981"),
        FolderColor(name: "Blue", hex: "#3B82F6"),
        FolderColor(name: "Purple", hex: "#A78BFA"),
        FolderColor(name: "Pink", hex: "#EC4899"),
        FolderColor(name: "Cyan", hex: "#22D3EE"),
    ]
}

struct FolderColor {
    let name: String
    let hex: String
}

struct FolderListView_Previews: PreviewProvider {
    static var previews: some View {
        FolderListView(viewModel: NotesViewModel())
    }
}
