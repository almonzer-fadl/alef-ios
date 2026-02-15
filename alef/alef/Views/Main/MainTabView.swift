import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.alefBg.ignoresSafeArea()
            
            // Tab content
            Group {
                switch selectedTab {
                case 0:
                    PlaceholderTab(title: "Today", icon: "sun.max.fill")
                case 1:
                    PlaceholderTab(title: "Habits", icon: "checkmark.circle.fill")
                case 2:
                    PlaceholderTab(title: "Journal", icon: "book.fill")
                case 3:
                    PlaceholderTab(title: "Profile", icon: "person.fill")
                default:
                    EmptyView()
                }
            }
            .padding(.bottom, 80)
            
            // Custom tab bar
            customTabBar
        }
    }
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabItem(icon: "sun.max.fill", label: "Today", index: 0)
            tabItem(icon: "checkmark.circle.fill", label: "Habits", index: 1)
            tabItem(icon: "book.fill", label: "Journal", index: 2)
            tabItem(icon: "person.fill", label: "Profile", index: 3)
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            Color.alefSurface
                .overlay(
                    Rectangle()
                        .fill(Color.alefBorder)
                        .frame(height: 0.5),
                    alignment: .top
                )
        )
    }
    
    private func tabItem(icon: String, label: String, index: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.25)) {
                selectedTab = index
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(selectedTab == index ? .alefAccent : .alefTextTertiary)
                    .scaleEffect(selectedTab == index ? 1.1 : 1.0)
                
                Text(label)
                    .font(AlefFont.medium(11))
                    .foregroundColor(selectedTab == index ? .alefAccent : .alefTextTertiary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// Placeholder for tabs we haven't built yet
struct PlaceholderTab: View {
    let title: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.alefAccent.opacity(0.3))
            
            Text(title)
                .font(AlefFont.bold(24))
                .foregroundColor(.alefText)
            
            Text("Coming soon")
                .font(AlefFont.regular(15))
                .foregroundColor(.alefTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.alefBg)
    }
}
