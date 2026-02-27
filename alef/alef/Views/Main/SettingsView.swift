//
//  SettingsView.swift
//  alef
//
//  App settings — profile, module management, server config, sign out.
//
//  Sections:
//  1. Profile card — name, email, member since
//  2. Modules — enable/disable with toggles
//  3. Server — base URL configuration
//  4. About — version, links
//  5. Sign out
//

import SwiftUI
import Combine

// MARK: - User Profile

struct UserProfile: Codable {
    let id: String
    let email: String
    let name: String
    let timezone: String?
    let createdAt: String
}

struct UserProfileResponse: Codable {
    let user: UserProfile
}

// MARK: - Module Item

struct ModuleItem: Codable, Identifiable {
    let key: String
    let label: String
    let icon: String
    let color: String
    let description: String
    var enabled: Bool
    let sortOrder: Int

    var id: String { key }

    var swiftUIColor: Color {
        Color(hex: color.replacingOccurrences(of: "#", with: ""))
    }
}

struct ModulesResponse: Codable {
    let modules: [ModuleItem]
}

// MARK: - Settings View

struct SettingsView: View {
    @AppStorage("authToken") private var authToken = ""
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("hasPickedModules") private var hasPickedModules = false

    @State private var profile: UserProfile?
    @State private var modules: [ModuleItem] = []
    @State private var serverURL = APIClient.shared.baseURL
        .replacingOccurrences(of: "/api", with: "")
    @State private var showSignOutAlert = false
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Color.alefBg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AlefLayout.sectionSpacing) {

                    // ── Profile card ─────────────────────────────
                    profileCard
                        .padding(.top, 16)

                    // ── Modules ──────────────────────────────────
                    modulesSection

                    // ── Server ───────────────────────────────────
                    serverSection

                    // ── About ────────────────────────────────────
                    aboutSection

                    // ── Sign out ─────────────────────────────────
                    Button {
                        showSignOutAlert = true
                    } label: {
                        Text("Sign Out")
                            .font(AlefFont.medium(16))
                            .foregroundColor(.alefError)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.alefError.opacity(0.08))
                            .cornerRadius(AlefLayout.cardRadius)
                    }

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, AlefLayout.horizontalPadding)
            }
        }
        .navigationTitle("Settings")
        .task { await loadData() }
        .alert("Sign out?", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) { signOut() }
        } message: {
            Text("You'll need to sign in again to use Alef.")
        }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        VStack(spacing: 12) {
            // Avatar circle with initial
            ZStack {
                Circle()
                    .fill(Color.alefHabits.opacity(0.15))
                    .frame(width: 64, height: 64)

                Text(String((profile?.name.first ?? "?")).uppercased())
                    .font(AlefFont.bold(24))
                    .foregroundColor(.alefHabits)
            }

            if let profile {
                Text(profile.name)
                    .font(AlefFont.semibold(18))
                    .foregroundColor(.alefText)

                Text(profile.email)
                    .font(AlefFont.regular(14))
                    .foregroundColor(.alefTextSecondary)

                Text("Member since \(formatDate(profile.createdAt))")
                    .font(AlefFont.regular(12))
                    .foregroundColor(.alefTextTertiary)
            } else if isLoading {
                ProgressView().tint(.alefTextSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: AlefLayout.cardRadiusLarge)
                .fill(Color.alefSurface)
        )
    }

    // MARK: - Modules Section

    private var modulesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MODULES")
                .font(AlefFont.medium(12))
                .foregroundColor(.alefTextTertiary)
                .tracking(1)

            VStack(spacing: 1) {
                ForEach(modules) { module in
                    HStack(spacing: 14) {
                        Image(systemName: module.icon)
                            .font(.system(size: 18))
                            .foregroundColor(module.swiftUIColor)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(module.label)
                                .font(AlefFont.medium(15))
                                .foregroundColor(.alefText)
                            Text(module.description)
                                .font(AlefFont.regular(12))
                                .foregroundColor(.alefTextTertiary)
                        }

                        Spacer()

                        Toggle("", isOn: Binding(
                            get: { module.enabled },
                            set: { newValue in
                                Task { await toggleModule(key: module.key, enabled: newValue) }
                            }
                        ))
                        .tint(module.swiftUIColor)
                        .labelsHidden()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .background(Color.alefSurface)
            .cornerRadius(AlefLayout.cardRadius)
        }
    }

    // MARK: - Server Section

    private var serverSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SERVER")
                .font(AlefFont.medium(12))
                .foregroundColor(.alefTextTertiary)
                .tracking(1)

            VStack(alignment: .leading, spacing: 8) {
                Text("API URL")
                    .font(AlefFont.regular(13))
                    .foregroundColor(.alefTextSecondary)

                HStack {
                    TextField("", text: $serverURL, prompt: Text("http://localhost:3002").foregroundColor(.alefTextTertiary))
                        .font(AlefFont.regular(14))
                        .foregroundColor(.alefText)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    Button {
                        // Update the API client base URL
                        let url = serverURL.hasSuffix("/api") ? serverURL : "\(serverURL)/api"
                        APIClient.shared.baseURL = url
                    } label: {
                        Text("Save")
                            .font(AlefFont.medium(13))
                            .foregroundColor(.alefHabits)
                    }
                }
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(Color.alefSurface)
                .cornerRadius(10)

                Text("Your self-hosted Alef backend address")
                    .font(AlefFont.regular(12))
                    .foregroundColor(.alefTextTertiary)
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ABOUT")
                .font(AlefFont.medium(12))
                .foregroundColor(.alefTextTertiary)
                .tracking(1)

            VStack(spacing: 1) {
                aboutRow(label: "Version", value: "0.1.0")
                aboutRow(label: "Build", value: "1")
                aboutRow(label: "License", value: "MIT")
            }
            .background(Color.alefSurface)
            .cornerRadius(AlefLayout.cardRadius)
        }
    }

    private func aboutRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AlefFont.regular(15))
                .foregroundColor(.alefText)
            Spacer()
            Text(value)
                .font(AlefFont.regular(15))
                .foregroundColor(.alefTextSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Data

    private func loadData() async {
        guard !authToken.isEmpty else { isLoading = false; return }

        // Fetch profile
        do {
            let response: UserProfileResponse = try await APIClient.shared.request(
                "GET", "/auth/me", token: authToken
            )
            profile = response.user
        } catch {}

        // Fetch modules
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
            modules[idx].enabled = enabled
        }

        // API call
        guard let url = URL(string: "\(APIClient.shared.baseURL)/modules/\(key)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["enabled": enabled])
        _ = try? await URLSession.shared.data(for: request)
    }

    private func signOut() {
        authToken = ""
        hasOnboarded = true // don't re-show onboarding
        hasPickedModules = false
    }

    private func formatDate(_ isoString: String) -> String {
        let iso = ISO8601DateFormatter()
        guard let date = iso.date(from: isoString) else { return "" }
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return f.string(from: date)
    }
}
