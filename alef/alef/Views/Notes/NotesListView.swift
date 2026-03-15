//
//  NotesListView.swift
//  alef
//
//  Created by Alef on 2026-03-07.
//  Main notes list — inspired by Apple Notes.
//

import SwiftUI

struct NotesListView: View {
    @StateObject private var viewModel = NotesViewModel()
    @AppStorage("authToken") private var authToken = ""
    
    @State private var showingEditor = false
    @State private var selectedNote: Note?
    @State private var showingFolderList = false
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                mainContent
                
                // FAB — Create Note
                Button(action: createNewNote) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.alefNotes)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                .padding(.trailing, AlefLayout.horizontalPadding)
                .padding(.bottom, 20)
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingFolderList.toggle() }) {
                        Image(systemName: "folder")
                            .foregroundColor(.alefText)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refresh) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.alefText)
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                if let note = selectedNote {
                    NoteEditorView(note: note, viewModel: viewModel)
                } else {
                    NoteEditorView(note: nil, viewModel: viewModel)
                }
            }
            .sheet(isPresented: $showingFolderList) {
                FolderListView(viewModel: viewModel)
            }
        }
        .task {
            viewModel.token = authToken
            await loadData()
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, 40)
                } else if viewModel.notes.isEmpty {
                    emptyState
                } else {
                    notesContent
                }
            }
        }
        .background(Color.alefBg)
        .refreshable {
            await refresh()
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.alefTextSecondary)
            
            TextField("Search notes", text: $viewModel.searchQuery)
                .font(AlefFont.regular(15))
                .foregroundColor(.alefText)
                .onChange(of: viewModel.searchQuery) { _ in
                    Task {
                        await viewModel.searchNotes()
                    }
                }
            
            if !viewModel.searchQuery.isEmpty {
                Button(action: { viewModel.searchQuery = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.alefTextSecondary)
                }
            }
        }
        .padding(12)
        .background(Color.alefSurface)
        .cornerRadius(10)
        .padding(.horizontal, AlefLayout.horizontalPadding)
        .padding(.vertical, 12)
    }
    
    // MARK: - Notes Content
    
    private var notesContent: some View {
        VStack(spacing: 20) {
            // Pinned Notes Section
            if !viewModel.pinnedNotes.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pinned")
                        .font(AlefFont.bold(20))
                        .foregroundColor(.alefText)
                        .padding(.horizontal, AlefLayout.horizontalPadding)
                    
                    ForEach(viewModel.pinnedNotes) { note in
                        noteRow(note)
                    }
                }
            }
            
            // Date-Grouped Notes
            ForEach(viewModel.sectionHeaders, id: \.self) { header in
                if let notes = viewModel.groupedNotes[header], !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(header)
                            .font(AlefFont.bold(20))
                            .foregroundColor(.alefText)
                            .padding(.horizontal, AlefLayout.horizontalPadding)
                        
                        ForEach(notes) { note in
                            noteRow(note)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Note Row
    
    private func noteRow(_ note: Note) -> some View {
        Button(action: { openNote(note) }) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    // Pin indicator
                    if note.isPinned == true {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.alefNotes)
                    }
                    
                    // Title
                    Text(note.title)
                        .font(AlefFont.semibold(16))
                        .foregroundColor(.alefText)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Date
                    Text(note.relativeDate)
                        .font(AlefFont.regular(13))
                        .foregroundColor(.alefTextTertiary)
                }
                
                // Preview
                if !note.preview.isEmpty {
                    Text(note.preview)
                        .font(AlefFont.regular(14))
                        .foregroundColor(.alefTextSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(16)
            .background(Color.alefSurface)
            .cornerRadius(AlefLayout.cardRadius)
            .padding(.horizontal, AlefLayout.horizontalPadding)
        }
        .contextMenu {
            Button(action: { 
                Task {
                    await viewModel.togglePin(note: note)
                }
            }) {
                Label(note.isPinned == true ? "Unpin" : "Pin", systemImage: "pin")
            }
            
            Button(role: .destructive, action: { deleteNote(note) }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "note.text")
                .font(.system(size: 64))
                .foregroundColor(.alefTextTertiary)
            
            Text("No Notes Yet")
                .font(AlefFont.semibold(20))
                .foregroundColor(.alefText)
            
            Text("Tap the button below to create your first note")
                .font(AlefFont.regular(15))
                .foregroundColor(.alefTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 80)
        .padding(.horizontal, 40)
    }
    
    // MARK: - Actions
    
    private var navigationTitle: String {
        if let folderId = viewModel.selectedFolderId,
           let folder = viewModel.folders.first(where: { $0.id == folderId }) {
            return folder.name
        }
        return "Notes"
    }
    
    private func loadData() async {
        await viewModel.loadNotes()
        await viewModel.loadFolders()
    }
    
    private func refresh() async {
        Haptics.light()
        await loadData()
    }
    
    private func createNewNote() {
        selectedNote = nil
        showingEditor = true
        Haptics.light()
    }
    
    private func openNote(_ note: Note) {
        selectedNote = note
        showingEditor = true
    }
    
    private func deleteNote(_ note: Note) {
        Task {
            await viewModel.deleteNote(id: note.id)
            Haptics.success()
        }
    }
}

struct NotesListView_Previews: PreviewProvider {
    static var previews: some View {
        NotesListView()
    }
}
