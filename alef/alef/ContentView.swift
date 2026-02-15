import SwiftUI

enum AppState {
    case splash
    case onboarding
    case auth
    case main
}

struct ContentView: View {
    @State private var appState: AppState = .splash
    @AppStorage("authToken") private var authToken: String = ""
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    
    var body: some View {
        ZStack {
            Color.alefBg.ignoresSafeArea()
            
            switch appState {
            case .splash:
                SplashView {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        if !authToken.isEmpty {
                            appState = .main
                        } else if hasOnboarded {
                            appState = .auth
                        } else {
                            appState = .onboarding
                        }
                    }
                }
                .transition(.opacity)
                
            case .onboarding:
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        hasOnboarded = true
                        appState = .auth
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                
            case .auth:
                AuthView { token in
                    authToken = token
                    withAnimation(.easeInOut(duration: 0.4)) {
                        appState = .main
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                
            case .main:
                MainTabView()
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
