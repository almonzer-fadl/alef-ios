//
//  MediaSearchView.swift
//  alef
//
//  TMDB search interface with debounced queries.
//  Shows results as poster cards with add-to-collection action.
//

import SwiftUI
import Combine

struct MediaSearchView: View {
    
    @Environment(\.dismiss) private var dismiss
    @AppStorage("authToken") private var authToken = ""
    
    let mediaType: MediaType
    
    @State private var searchQuery = ""
    @State private var searchResults: [TMDBSearchResult] = []
    @State private var isSearching = false
    @State private var selectedStatus: MediaStatus = .watchlist
    @State private var showingStatusPicker = false
    @State private var selectedResult: TMDBSearchResult?
    
    private let service = MediaService.shared
    private let searchDebounce = PassthroughSubject<String, Never>()
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.alefBg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    searchBar
                    
                    // Results
                    if isSearching {
                        loadingState
                    } else if searchResults.isEmpty && !searchQuery.isEmpty {
                        emptyResults
                    } else if !searchResults.isEmpty {
                        resultsList
                    } else {
                        promptState
                    }
                }
            }
            .navigationTitle("Search \(mediaType.label)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.alefTextSecondary)
                }
            }
            .sheet(isPresented: $showingStatusPicker) {
                if let result = selectedResult {
                    StatusPickerSheet(
                        result: result,
                        mediaType: mediaType,
                        onAdd: { status in
                            Task {
                                await addToCollection(result: result, status: status)
                            }
                        }
                    )
                }
            }
            .onAppear {
                setupSearchDebounce()
            }
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.alefTextTertiary)
            
            TextField(
                "Search \(mediaType == .movie ? "movies" : "TV shows")...",
                text: $searchQuery
            )
            .font(AlefFont.regular(16))
            .foregroundColor(.alefText)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .onChange(of: searchQuery) { newValue in
                searchDebounce.send(newValue)
            }
            
            if !searchQuery.isEmpty {
                Button {
                    searchQuery = ""
                    searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.alefTextTertiary)
                }
            }
        }
        .padding(12)
        .background(Color.alefSurface)
        .cornerRadius(12)
        .padding(.horizontal, AlefLayout.horizontalPadding)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }
    
    // MARK: - Results List
    
    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(searchResults) { result in
                    SearchResultCard(result: result)
                        .onTapGesture {
                            Haptics.medium()
                            selectedResult = result
                            showingStatusPicker = true
                        }
                }
            }
            .padding(.horizontal, AlefLayout.horizontalPadding)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - States
    
    private var loadingState: some View {
        VStack {
            ProgressView()
                .tint(.alefMovies)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyResults: some View {
        VStack(spacing: 12) {
            Image(systemName: "film.slash")
                .font(.system(size: 48))
                .foregroundColor(.alefTextTertiary)
            
            Text("No results found")
                .font(AlefFont.semibold(16))
                .foregroundColor(.alefTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var promptState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.alefTextTertiary)
            
            Text("Search for \(mediaType.label.lowercased())")
                .font(AlefFont.semibold(16))
                .foregroundColor(.alefTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Search Logic
    
    private func setupSearchDebounce() {
        searchDebounce
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { query in
                Task {
                    await performSearch(query: query)
                }
            }
            .store(in: &cancellables)
    }
    
    private func performSearch(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        do {
            searchResults = try await service.search(
                query: query,
                type: mediaType,
                token: authToken
            )
        } catch {
            print("Search error:", error)
        }
        
        isSearching = false
    }
    
    // MARK: - Add to Collection
    
    private func addToCollection(result: TMDBSearchResult, status: MediaStatus) async {
        do {
            _ = try await service.createMedia(
                type: mediaType,
                status: status,
                title: result.title,
                externalId: String(result.tmdbId),
                posterUrl: result.posterUrl,
                token: authToken
            )
            
            Haptics.success()
            dismiss()
        } catch {
            print("Add error:", error)
        }
    }
}

// MARK: - Search Result Card

struct SearchResultCard: View {
    let result: TMDBSearchResult
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Poster
            if let posterUrl = result.posterUrl, let url = URL(string: posterUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(2/3, contentMode: .fill)
                } placeholder: {
                    posterPlaceholder
                }
                .frame(width: 80, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                posterPlaceholder
                    .frame(width: 80, height: 120)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(result.title)
                    .font(AlefFont.semibold(16))
                    .foregroundColor(.alefText)
                    .lineLimit(2)
                
                if let year = result.year {
                    Text(year)
                        .font(AlefFont.medium(13))
                        .foregroundColor(.alefTextSecondary)
                }
                
                if let overview = result.overview, !overview.isEmpty {
                    Text(overview)
                        .font(AlefFont.regular(13))
                        .foregroundColor(.alefTextTertiary)
                        .lineLimit(3)
                        .padding(.top, 4)
                }
                
                Spacer()
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.alefSurface)
        .cornerRadius(AlefLayout.cardRadius)
    }
    
    private var posterPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.alefSurfaceSecondary.opacity(0.3))
            .overlay(
                Image(systemName: "film")
                    .font(.system(size: 24))
                    .foregroundColor(.alefTextTertiary)
            )
    }
}

// MARK: - Status Picker Sheet

struct StatusPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let result: TMDBSearchResult
    let mediaType: MediaType
    let onAdd: (MediaStatus) -> Void
    
    @State private var selectedStatus: MediaStatus = .watchlist
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.alefBg.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Preview
                    VStack(spacing: 8) {
                        Text(result.title)
                            .font(AlefFont.semibold(18))
                            .foregroundColor(.alefText)
                            .multilineTextAlignment(.center)
                        
                        if let year = result.year {
                            Text(year)
                                .font(AlefFont.medium(14))
                                .foregroundColor(.alefTextSecondary)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Status Picker
                    VStack(spacing: 12) {
                        ForEach(MediaStatus.allCases, id: \.self) { status in
                            Button {
                                Haptics.selection()
                                selectedStatus = status
                            } label: {
                                HStack {
                                    Image(systemName: status.icon)
                                        .font(.system(size: 18))
                                        .foregroundColor(
                                            selectedStatus == status ? .alefMovies : .alefTextSecondary
                                        )
                                        .frame(width: 24)
                                    
                                    Text(status.label)
                                        .font(AlefFont.semibold(16))
                                        .foregroundColor(
                                            selectedStatus == status ? .alefText : .alefTextSecondary
                                        )
                                    
                                    Spacer()
                                    
                                    if selectedStatus == status {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.alefMovies)
                                    }
                                }
                                .padding(16)
                                .background(
                                    selectedStatus == status
                                        ? Color.alefMovies.opacity(0.1)
                                        : Color.alefSurface
                                )
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, AlefLayout.horizontalPadding)
                    
                    Spacer()
                    
                    // Add Button
                    Button {
                        Haptics.success()
                        onAdd(selectedStatus)
                        dismiss()
                    } label: {
                        Text("Add to \(selectedStatus.label)")
                            .font(AlefFont.semibold(17))
                            .foregroundColor(.alefText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.alefMovies)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, AlefLayout.horizontalPadding)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Add to Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.alefTextSecondary)
                }
            }
        }
    }
}
