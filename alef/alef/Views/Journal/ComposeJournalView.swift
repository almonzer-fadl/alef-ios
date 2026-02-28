//
//  ComposeJournalView.swift
//  alef
//
//  Compose a new journal entry.
//
//  Layout:
//  1. Date (defaults to today)
//  2. Mood picker — horizontal row of mood icons
//  3. Energy slider (1-5)
//  4. Content text area — the main writing space
//  5. Tags — comma-separated, shown as chips
//
//  Inspired by Bevel's journal: mood picker at top, clean text area,
//  quick daily check-in feel.
//

import SwiftUI

struct ComposeJournalView: View {
    @ObservedObject var vm: JournalViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var content = ""
    @State private var selectedMood: Mood?
    @State private var energyLevel: Double = 3
    @State private var tagInput = ""
    @State private var tags: [String] = []
    @State private var isSaving = false

    @FocusState private var isContentFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.alefBg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // ── Date ─────────────────────────────────
                        Text(todayFormatted)
                            .font(AlefFont.medium(14))
                            .foregroundColor(.alefTextSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 8)

                        // ── Mood picker ──────────────────────────
                        VStack(alignment: .leading, spacing: 10) {
                            Text("HOW ARE YOU FEELING?")
                                .font(AlefFont.medium(11))
                                .foregroundColor(.alefTextTertiary)
                                .tracking(1)

                            HStack(spacing: 12) {
                                ForEach(Mood.allCases, id: \.self) { mood in
                                    Button {
                                        Haptics.selection()
                                        withAnimation(.spring(response: 0.25)) {
                                            selectedMood = selectedMood == mood ? nil : mood
                                        }
                                    } label: {
                                        VStack(spacing: 6) {
                                            Image(systemName: mood.icon)
                                                .font(.system(size: 24))
                                                .foregroundColor(
                                                    selectedMood == mood ? mood.color : .alefTextTertiary
                                                )

                                            Text(mood.label)
                                                .font(AlefFont.regular(10))
                                                .foregroundColor(
                                                    selectedMood == mood ? mood.color : .alefTextTertiary
                                                )
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(selectedMood == mood
                                                    ? mood.color.opacity(0.1)
                                                    : Color.alefSurface
                                                )
                                        )
                                    }
                                }
                            }
                        }

                        // ── Energy level ─────────────────────────
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("ENERGY LEVEL")
                                    .font(AlefFont.medium(11))
                                    .foregroundColor(.alefTextTertiary)
                                    .tracking(1)
                                Spacer()
                                Text("\(Int(energyLevel))/5")
                                    .font(AlefFont.Rounded.semibold(13))
                                    .foregroundColor(.alefDiet)
                            }

                            // Energy bar — tap to set
                            HStack(spacing: 6) {
                                ForEach(1...5, id: \.self) { level in
                                    Button {
                                        Haptics.light()
                                        withAnimation(.spring(response: 0.2)) {
                                            energyLevel = Double(level)
                                        }
                                    } label: {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Double(level) <= energyLevel ? Color.alefDiet : Color.alefSurfaceSecondary.opacity(0.3))
                                            .frame(height: 8)
                                    }
                                }
                            }
                        }

                        // ── Content ──────────────────────────────
                        VStack(alignment: .leading, spacing: 8) {
                            Text("WHAT'S ON YOUR MIND?")
                                .font(AlefFont.medium(11))
                                .foregroundColor(.alefTextTertiary)
                                .tracking(1)

                            TextEditor(text: $content)
                                .font(AlefFont.regular(16))
                                .foregroundColor(.alefText)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 200)
                                .padding(12)
                                .background(Color.alefSurface)
                                .cornerRadius(14)
                                .focused($isContentFocused)
                        }

                        // ── Tags ─────────────────────────────────
                        VStack(alignment: .leading, spacing: 10) {
                            Text("TAGS")
                                .font(AlefFont.medium(11))
                                .foregroundColor(.alefTextTertiary)
                                .tracking(1)

                            // Tag chips
                            if !tags.isEmpty {
                                FlowLayout(spacing: 6) {
                                    ForEach(tags, id: \.self) { tag in
                                        HStack(spacing: 4) {
                                            Text("#\(tag)")
                                                .font(AlefFont.regular(13))
                                                .foregroundColor(.alefJournal)
                                            Button {
                                                tags.removeAll { $0 == tag }
                                            } label: {
                                                Image(systemName: "xmark")
                                                    .font(.system(size: 9, weight: .bold))
                                                    .foregroundColor(.alefTextTertiary)
                                            }
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.alefJournal.opacity(0.1))
                                        .clipShape(Capsule())
                                    }
                                }
                            }

                            // Tag input
                            HStack {
                                TextField("", text: $tagInput, prompt: Text("Add tag...").foregroundColor(.alefTextTertiary))
                                    .font(AlefFont.regular(14))
                                    .foregroundColor(.alefText)
                                    .onSubmit { addTag() }

                                if !tagInput.isEmpty {
                                    Button { addTag() } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.alefJournal)
                                    }
                                }
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 44)
                            .background(Color.alefSurface)
                            .cornerRadius(10)
                        }

                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, AlefLayout.horizontalPadding)
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.alefTextSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView().tint(.alefJournal)
                        } else {
                            Text("Save")
                                .foregroundColor(content.isEmpty ? .alefTextTertiary : .alefJournal)
                        }
                    }
                    .disabled(content.isEmpty || isSaving)
                }
            }
            .toolbarBackground(Color.alefBg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear { isContentFocused = true }
        }
    }

    // MARK: - Helpers

    private var todayFormatted: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d, yyyy"
        return f.string(from: Date())
    }

    private var todayDateString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    private func addTag() {
        let tag = tagInput.trimmingCharacters(in: .whitespaces).lowercased()
        guard !tag.isEmpty, !tags.contains(tag) else { return }
        tags.append(tag)
        tagInput = ""
        Haptics.light()
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        await vm.create(
            date: todayDateString,
            content: content,
            mood: selectedMood,
            energy: Int(energyLevel),
            tags: tags
        )
        dismiss()
    }
}

// MARK: - Flow Layout

/// Simple horizontal flow layout for tag chips.
/// Wraps to the next line when content exceeds available width.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}
