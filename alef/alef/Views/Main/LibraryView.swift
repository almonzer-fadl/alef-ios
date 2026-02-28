//
//  LibraryView.swift
//  alef
//
//  The Library tab — shows all enabled modules as a browsable grid.
//
//  Each module card shows its icon, name, accent colour, and a brief
//  description. Tapping a card navigates to that module's main screen
//  (or a "coming soon" placeholder for unbuilt modules).
//
//  This is the discovery point for all life-tracking features.
//  Users manage which modules appear here from Settings.
//

import SwiftUI
import Combine

struct LibraryView: View {
    @AppStorage("authToken") private var authToken = ""
    @State private var modules: [ModuleItem] = []
    @State private var isLoading = true

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        ZStack {
            Color.alefBg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // ── Enabled modules ──────────────────────────
                    let enabled = modules.filter(\.enabled)
                    if !enabled.isEmpty {
                        sectionHeader("Enabled")

                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(enabled) { module in
                                moduleCard(module, isEnabled: true)
                            }
                        }
                    }

                    // ── Available modules ─────────────────────────
                    let disabled = modules.filter { !$0.enabled }
                    if !disabled.isEmpty {
                        sectionHeader("Available")

                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(disabled) { module in
                                moduleCard(module, isEnabled: false)
                            }
                        }
                    }

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, AlefLayout.horizontalPadding)
                .padding(.top, 16)
            }
        }
        .navigationTitle("Library")
        .task { await loadModules() }
        .refreshable { await loadModules() }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AlefFont.medium(13))
            .foregroundColor(.alefTextSecondary)
            .textCase(.uppercase)
            .tracking(0.8)
    }

    // MARK: - Module Card

    private func moduleCard(_ module: ModuleItem, isEnabled: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon with accent background
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(module.swiftUIColor.opacity(isEnabled ? 0.15 : 0.08))
                    .frame(width: 44, height: 44)

                Image(systemName: module.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isEnabled ? module.swiftUIColor : module.swiftUIColor.opacity(0.4))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(module.label)
                    .font(AlefFont.semibold(15))
                    .foregroundColor(isEnabled ? .alefText : .alefTextSecondary)

                Text(module.description)
                    .font(AlefFont.regular(12))
                    .foregroundColor(.alefTextTertiary)
                    .lineLimit(2)
            }

            // Status badge
            if isEnabled {
                Text("Active")
                    .font(AlefFont.medium(11))
                    .foregroundColor(module.swiftUIColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(module.swiftUIColor.opacity(0.1))
                    .clipShape(Capsule())
            } else {
                Text("Tap to enable")
                    .font(AlefFont.medium(11))
                    .foregroundColor(.alefTextTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.alefSurfaceSecondary.opacity(0.3))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: AlefLayout.cardRadius)
                .fill(Color.alefSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AlefLayout.cardRadius)
                .stroke(
                    isEnabled ? module.swiftUIColor.opacity(0.15) : Color.alefBorder,
                    lineWidth: 1
                )
        )
        .opacity(isEnabled ? 1.0 : 0.7)
        .onTapGesture {
            if !isEnabled {
                Task { await toggleModule(key: module.key, enabled: true) }
            }
        }
    }

    // MARK: - Data

    private func loadModules() async {
        guard !authToken.isEmpty else { isLoading = false; return }
        do {
            let response: ModulesResponse = try await APIClient.shared.request(
                "GET", "/modules", token: authToken
            )
            modules = response.modules
        } catch {}
        isLoading = false
    }

    private func toggleModule(key: String, enabled: Bool) async {
        // Optimistic update
        if let idx = modules.firstIndex(where: { $0.key == key }) {
            withAnimation(.spring(response: 0.3)) {
                modules[idx].enabled = enabled
            }
        }

        guard let url = URL(string: "\(APIClient.shared.baseURL)/modules/\(key)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["enabled": enabled])
        _ = try? await URLSession.shared.data(for: request)
    }
}
