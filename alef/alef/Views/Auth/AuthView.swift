//
//  AuthView.swift
//  alef
//
//  Sign up and sign in screen.
//  Toggle between modes with the segmented control at the top.
//
//  On successful auth, the backend returns a JWT token which is
//  stored in @AppStorage("authToken") for subsequent API calls.
//
//  The base URL points to the Alef API (Bun + Hono).
//  In development this is a local IP; in production it's the
//  user's self-hosted server or our managed hosting endpoint.
//
//  TODO: Implement Sign in with Apple (ASAuthorizationAppleIDProvider)
//

import SwiftUI

// MARK: - Auth Mode

enum AuthMode {
    case signIn
    case signUp
}

// MARK: - Auth View

struct AuthView: View {
    @State private var mode: AuthMode = .signUp
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showPassword = false

    /// Called with the JWT token on successful authentication
    var onAuth: (String) -> Void

    var body: some View {
        ZStack {
            Color.alefBg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 60)

                    // ── Logo ─────────────────────────────────────────
                    Image("LogoIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)

                    Image("Wordmark")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 20)
                        .padding(.top, 4)

                    Spacer().frame(height: 48)

                    // ── Mode toggle (Sign Up / Sign In) ──────────────
                    HStack(spacing: 0) {
                        modeTab("Sign Up", mode: .signUp)
                        modeTab("Sign In", mode: .signIn)
                    }
                    .background(Color.alefSurface)
                    .cornerRadius(12)
                    .padding(.horizontal, AlefLayout.horizontalPadding)

                    Spacer().frame(height: 32)

                    // ── Form fields ──────────────────────────────────
                    VStack(spacing: 16) {
                        // Name field (sign up only)
                        if mode == .signUp {
                            inputField(
                                icon: "person.fill",
                                placeholder: "Your name",
                                text: $name,
                                isSecure: false
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Email
                        inputField(
                            icon: "envelope.fill",
                            placeholder: "Email",
                            text: $email,
                            isSecure: false,
                            keyboard: .emailAddress
                        )

                        // Password with visibility toggle
                        ZStack(alignment: .trailing) {
                            inputField(
                                icon: "lock.fill",
                                placeholder: "Password",
                                text: $password,
                                isSecure: !showPassword
                            )

                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .font(.system(size: 15))
                                    .foregroundColor(.alefTextTertiary)
                            }
                            .padding(.trailing, 16)
                        }

                        // Error message
                        if let error = errorMessage {
                            Text(error)
                                .font(AlefFont.regular(13))
                                .foregroundColor(.alefError)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal, AlefLayout.horizontalPadding)

                    Spacer().frame(height: 32)

                    // ── Submit button ─────────────────────────────────
                    Button {
                        Task { await submit() }
                    } label: {
                        if isLoading {
                            ProgressView()
                                .tint(Color.alefBg)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.alefGold)
                                .cornerRadius(AlefLayout.cardRadius)
                        } else {
                            Text(mode == .signUp ? "Create Account" : "Sign In")
                                .font(AlefFont.semibold(17))
                                .foregroundColor(.alefBg)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(isFormValid ? Color.alefGold : Color.alefSurfaceSecondary)
                                .cornerRadius(AlefLayout.cardRadius)
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                    .padding(.horizontal, AlefLayout.horizontalPadding)

                    Spacer().frame(height: 24)

                    // ── Divider ──────────────────────────────────────
                    HStack {
                        Rectangle().fill(Color.alefBorder).frame(height: 1)
                        Text("or")
                            .font(AlefFont.regular(13))
                            .foregroundColor(.alefTextTertiary)
                        Rectangle().fill(Color.alefBorder).frame(height: 1)
                    }
                    .padding(.horizontal, AlefLayout.horizontalPadding)

                    Spacer().frame(height: 24)

                    // ── Sign in with Apple (placeholder) ─────────────
                    Button {
                        // TODO: Implement Apple Sign In
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 18))
                            Text("Continue with Apple")
                                .font(AlefFont.semibold(16))
                        }
                        .foregroundColor(.alefText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.alefSurface)
                        .cornerRadius(AlefLayout.cardRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: AlefLayout.cardRadius)
                                .stroke(Color.alefBorder, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, AlefLayout.horizontalPadding)

                    Spacer().frame(height: 60)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: mode)
    }

    // MARK: - Components

    /// Segmented control tab for switching between Sign Up and Sign In
    private func modeTab(_ title: String, mode: AuthMode) -> some View {
        Button {
            self.mode = mode
            errorMessage = nil
        } label: {
            Text(title)
                .font(AlefFont.semibold(15))
                .foregroundColor(self.mode == mode ? .alefText : .alefTextTertiary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(self.mode == mode ? Color.alefSurfaceSecondary : Color.clear)
                .cornerRadius(10)
        }
        .padding(3)
    }

    /// Reusable input field with icon, placeholder, and optional secure mode
    private func inputField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(.alefTextTertiary)
                .frame(width: 20)

            if isSecure {
                SecureField("", text: text, prompt: Text(placeholder).foregroundColor(.alefTextTertiary))
                    .font(AlefFont.regular(16))
                    .foregroundColor(.alefText)
                    .autocorrectionDisabled()
            } else {
                TextField("", text: text, prompt: Text(placeholder).foregroundColor(.alefTextTertiary))
                    .font(AlefFont.regular(16))
                    .foregroundColor(.alefText)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                    .autocorrectionDisabled()
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(Color.alefSurface)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.alefBorder, lineWidth: 1)
        )
    }

    // MARK: - Validation

    /// Form is valid when email looks real, password >= 6 chars,
    /// and name is filled (for sign up only).
    private var isFormValid: Bool {
        let emailValid = email.contains("@") && email.contains(".")
        let passValid = password.count >= 6
        if mode == .signUp {
            return !name.isEmpty && emailValid && passValid
        }
        return emailValid && passValid
    }

    // MARK: - API Call

    /// Sends sign up or sign in request to the Alef API.
    /// On success, calls `onAuth` with the JWT token.
    private func submit() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // Base URL — points to the Alef backend.
        // In production, this would be configurable per user's server.
        let baseURL = "http://192.168.1.114:3002/api/auth"
        let endpoint = mode == .signUp ? "\(baseURL)/sign-up" : "\(baseURL)/sign-in"

        // Build request body
        var body: [String: String] = [
            "email": email.lowercased().trimmingCharacters(in: .whitespaces),
            "password": password,
        ]
        if mode == .signUp {
            body["name"] = name.trimmingCharacters(in: .whitespaces)
            body["timezone"] = TimeZone.current.identifier
        }

        guard let url = URL(string: endpoint) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            if http.statusCode >= 200, http.statusCode < 300,
               let token = json?["token"] as? String {
                onAuth(token)
            } else {
                errorMessage = (json?["error"] as? String) ?? "Something went wrong"
            }
        } catch {
            errorMessage = "Network error — is the server running?"
        }
    }
}
