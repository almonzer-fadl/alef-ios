//
//  NoteEditorView.swift
//  alef
//
//  Created by Alef on 2026-03-07.
//  Full-screen note editor with auto-save.
//

import SwiftUI

struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: NotesViewModel
    
    let note: Note?
    
    @State private var title: String
    @State private var content: String
    @State private var isPinned: Bool
    @State private var selectedFolderId: String?
    @State private var showingFolderPicker = false
    @State private var hasChanges = false
    @State private var saveWorkItem: DispatchWorkItem?
    
    init(note: Note?, viewModel: NotesViewModel) {
        self.note = note
        self.viewModel = viewModel
        
        _title = State(initialValue: note?.title ?? "")
        _content = State(initialValue: note?.content ?? "")
        _isPinned = State(initialValue: note?.isPinned ?? false)
        _selectedFolderId = State(initialValue: note?.folderId)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.alefBg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Title Field
                    TextField("Title", text: $title)
                        .font(AlefFont.bold(24))
                        .foregroundColor(.alefText)
                        .padding(.horizontal, AlefLayout.horizontalPadding)
                        .padding(.top, 20)
                        .onChange(of: title) { _ in
                            markChanged()
                        }
                    
                    Divider()
                        .padding(.horizontal, AlefLayout.horizontalPadding)
                        .padding(.vertical, 12)
                    
                    // Content Field
                    TextEditor(text: $content)
                        .font(AlefFont.regular(16))
                        .foregroundColor(.alefText)
                        .padding(.horizontal, AlefLayout.horizontalPadding)
                        .scrollContentBackground(.hidden)
                        .background(Color.alefBg)
                        .onChange(of: content) { _ in
                            markChanged()
                        }
                    
                    // Toolbar
                    toolbar
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        saveAndDismiss()
                    }
                    .foregroundColor(.alefNotes)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingFolderPicker = true }) {
                            Label("Move to Folder", systemImage: "folder")
                        }
                        
                        Button(action: togglePin) {
                            Label(isPinned ? "Unpin" : "Pin", systemImage: "pin")
                        }
                        
                        if note != nil {
                            Divider()
                            
                            Button(role: .destructive, action: deleteNote) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.alefText)
                    }
                }
            }
            .sheet(isPresented: $showingFolderPicker) {
                folderPicker
            }
        }
    }
    
    // MARK: - Toolbar
    
    private var toolbar: some View {
        HStack {
            // Folder indicator
            if let folderId = selectedFolderId,
               let folder = viewModel.folders.first(where: { $0.id == folderId }) {
                HStack(spacing: 6) {
                    Image(systemName: folder.icon ?? "folder.fill")
                        .font(.system(size: 12))
                    Text(folder.name)
                        .font(AlefFont.medium(13))
                }
                .foregroundColor(.alefTextSecondary)
            } else {
                Text("No Folder")
                    .font(AlefFont.medium(13))
                    .foregroundColor(.alefTextTertiary)
            }
            
            Spacer()
            
            // Pin indicator
            if isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.alefNotes)
            }
            
            // Character count
            Text("\(content.count) characters")
                .font(AlefFont.regular(13))
                .foregroundColor(.alefTextTertiary)
        }
        .padding(.horizontal, AlefLayout.horizontalPadding)
        .padding(.vertical, 12)
        .background(Color.alefSurface)
    }
    
    // MARK: - Folder Picker
    
    private var folderPicker: some View {
        NavigationView {
            List {
                Button(action: {
                    selectedFolderId = nil
                    showingFolderPicker = false
                    markChanged()
                }) {
                    HStack {
                        Image(systemName: "tray")
                        Text("No Folder")
                        Spacer()
                        if selectedFolderId == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.alefNotes)
                        }
                    }
                }
                
                ForEach(viewModel.folders) { folder in
                    Button(action: {
                        selectedFolderId = folder.id
                        showingFolderPicker = false
                        markChanged()
                    }) {
                        HStack {
                            Image(systemName: folder.icon ?? "folder.fill")
                                .foregroundColor(Color(hex: folder.color ?? "#FCD34D"))
                            Text(folder.name)
                            Spacer()
                            if selectedFolderId == folder.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.alefNotes)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Move to Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showingFolderPicker = false
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func markChanged() {
        hasChanges = true
        
        // Debounced auto-save
        saveWorkItem?.cancel()
        let workItem = DispatchWorkItem { [self] in
            Task {
                await save()
            }
        }
        saveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
    }
    
    private func togglePin() {
        isPinned.toggle()
        markChanged()
        Haptics.light()
    }
    
    private func save() async {
        guard !title.isEmpty else { return }
        
        if let note = note {
            // Update existing note
            await viewModel.updateNote(
                id: note.id,
                title: title,
                content: content,
                isPinned: isPinned
            )
        } else {
            // Create new note
            await viewModel.createNote(
                title: title,
                content: content
            ) { _ in
                // Note created
            }
        }
        
        hasChanges = false
        Haptics.success()
    }
    
    private func saveAndDismiss() {
        if hasChanges {
            Task {
                await save()
                dismiss()
            }
        } else {
            dismiss()
        }
    }
    
    private func deleteNote() {
        guard let note = note else { return }
        Task {
            await viewModel.deleteNote(id: note.id)
            Haptics.success()
            dismiss()
        }
    }
}

struct NoteEditorView_Previews: PreviewProvider {
    static var previews: some View {
        NoteEditorView(note: nil, viewModel: NotesViewModel())
    }
}
