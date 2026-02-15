import SwiftUI

struct SplashView: View {
    @State private var showLogo = false
    @State private var showTagline = false
    @State private var showGlow = false
    @State private var navigateAway = false
    
    var onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            Color.alefBg.ignoresSafeArea()
            
            // Subtle radial glow behind logo
            if showGlow {
                RadialGradient(
                    colors: [Color.alefAccent.opacity(0.12), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 200
                )
                .ignoresSafeArea()
                .transition(.opacity)
            }
            
            VStack(spacing: 24) {
                Spacer()
                
                // Arabic letter أ — the logo
                Text("أ")
                    .font(.system(size: 120, weight: .ultraLight))
                    .foregroundColor(.alefAccent)
                    .opacity(showLogo ? 1 : 0)
                    .scaleEffect(showLogo ? 1 : 0.6)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: showLogo)
                
                // App name
                Text("alef")
                    .font(AlefFont.heavy(32))
                    .foregroundColor(.alefText)
                    .tracking(6)
                    .opacity(showLogo ? 1 : 0)
                    .offset(y: showLogo ? 0 : 10)
                    .animation(.easeOut(duration: 0.6).delay(0.3), value: showLogo)
                
                // Tagline
                Text("a life entirely filed")
                    .font(AlefFont.regular(14))
                    .foregroundColor(.alefTextSecondary)
                    .tracking(2)
                    .opacity(showTagline ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.6), value: showTagline)
                
                Spacer()
                Spacer()
            }
        }
        .onAppear {
            withAnimation { showGlow = true }
            showLogo = true
            showTagline = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                onComplete()
            }
        }
    }
}
