//
//  BookSearchView.swift
//  alef
//
//  Open Library book search — search and add books to collection.
//
//  Features:
//  - Debounced search (waits 500ms after typing stops)
//  - Cover thumbnails from Open Library
//  - Tap to add to collection
//

import SwiftUI

struct BookSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = BookViewModel()
    @AppStorage("authToken") private var authToken = ""
    
    @State private var query = ""
    @State private var debounceTask: Task<Void, Never>?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.alefBg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    searchBar
                        .padding(.horizontal, AlefLayout.horizontalPadding)
                        .padding(.vertical, 12)
                    
                    if viewModel.isSearching {
                        loadingView
                    } else if viewModel.searchResults.isEmpty && !query.isEmpty {
                        emptyState
                    } else if viewModel.searchResults.isEmpty {
                        placeholderState
                    } else {
                        resultsList
                    }
                }
            }
            .navigationTitle("Search Books")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.alefTextSecondary)
                }
            }
        }
        .task {
            viewModel.token = authToken
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.alefTextTertiary)
            
            TextField("Search books...", text: $query)
                .font(AlefFont.regular(16))
                .foregroundColor(.alefText)
                .onChange(of: query) { oldValue, newValue in
                    debouncedSearch(newValue)
                }
            
            if !query.isEmpty {
                Button {
                    query = ""
                    viewModel.searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.alefTextTertiary)
                }
            }
        }
        .padding(12)
        .background(Color.alefSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Results List
    
    private var resultsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: AlefLayout.itemSpacing) {
                ForEach(viewModel.searchResults) { result in
                    SearchResultCard(result: result) {
                        Task {
                            await addBook(result)
                        }
                    }
                }
            }
            .padding(.horizontal, AlefLayout.horizontalPadding)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Search Result Card
    
    private struct SearchResultCard: View {
        let result: BookSearchResult
        let onAdd: () -> Void
        
        @State private var isAdding = false
        
        var body: some View {
            HStack(spacing: 12) {
                // Cover
                Group {
                    if let coverUrl = result.coverUrl, let url = URL(string: coverUrl) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(2/3, contentMode: .fill)
                            } else {
                                placeholderCover
                            }
                        }
                    } else {
                        placeholderCover
                    }
                }
                .frame(width: 60, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 6) {
                    // Title
                    Text(result.title)
                        .font(AlefFont.semibold(16))
                        .foregroundColor(.alefText)
                        .lineLimit(2)
                    
                    // Author
                    if let author = result.author {
                        Text(author)
                            .font(AlefFont.regular(14))
                            .foregroundColor(.alefTextSecondary)
                            .lineLimit(1)
                    }
                    
                    // Year
                    if let year = result.year {
                        Text("\(year)")
                            .font(AlefFont.medium(12))
                            .foregroundColor(.alefTextTertiary)
                    }
                }
                
                Spacer()
                
                // Add button
                Button {
                    Haptics.selection()
                    onAdd()
                } label: {
                    if isAdding {
                        ProgressView()
                            .tint(.alefBooks)
                    } else {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.alefBooks)
                    }
                }
                .disabled(isAdding)
            }
            .padding(12)
            .background(Color.alefSurface)
            .clipShape(RoundedRectangle(cornerRadius: AlefLayout.cardRadius))
        }
        
        private var placeholderCover: some View {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.alefSurfaceSecondary)
                .overlay(
                    Image(systemName: "book")
                        .font(.system(size: 24))
                        .foregroundColor(.alefTextTertiary)
                )
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.alefBooks)
            Text("Searching...")
                .font(AlefFont.medium(14))
                .foregroundColor(.alefTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.alefBooks.opacity(0.3))
            
            Text("No results found")
                .font(AlefFont.semibold(16))
                .foregroundColor(.alefText)
            
            Text("Try a different search")
                .font(AlefFont.regular(14))
                .foregroundColor(.alefTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Placeholder State
    
    private var placeholderState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.alefBooks.opacity(0.3))
            
            Text("Search for books")
                .font(AlefFont.semibold(16))
                .foregroundColor(.alefText)
            
            Text("Try 'Atomic Habits' or 'Dune'")
                .font(AlefFont.regular(14))
                .foregroundColor(.alefTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    private func debouncedSearch(_ query: String) {
        // Cancel previous task
        debounceTask?.cancel()
        
        guard !query.isEmpty else {
            viewModel.searchResults = []
            return
        }
        
        // Create new debounced task
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
            
            guard !Task.isCancelled else { return }
            
            await viewModel.search(query: query)
        }
    }
    
    private func addBook(_ result: BookSearchResult) async {
        let success = await viewModel.addBook(result)
        if success {
            Haptics.success()
            dismiss()
        }
    }
}
