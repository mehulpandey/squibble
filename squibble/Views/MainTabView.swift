//
//  MainTabView.swift
//  squibble
//
//  Main tab bar with History, Home, and Profile tabs
//

import SwiftUI

enum Tab: Int, CaseIterable {
    case history = 0
    case home = 1
    case profile = 2

    var title: String {
        switch self {
        case .history: return "History"
        case .home: return "Home"
        case .profile: return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .history: return "clock.fill"
        case .home: return "house.fill"
        case .profile: return "person.fill"
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var doodleManager: DoodleManager
    @EnvironmentObject var friendManager: FriendManager
    @EnvironmentObject var navigationManager: NavigationManager

    @StateObject private var drawingState = DrawingState()
    @State private var tabBarVisible = true

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background that extends to all edges
            AmbientBackground()

            // Tab content - using standard TabView instead of page style to avoid black backgrounds
            Group {
                switch navigationManager.selectedTab {
                case .history:
                    HistoryView()
                case .home:
                    HomeView(drawingState: drawingState)
                case .profile:
                    ProfileView()
                }
            }

            // Custom tab bar
            if tabBarVisible {
                CustomTabBar(selectedTab: $navigationManager.selectedTab)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Grid overlay (shown above tab bar to cover it)
            if let doodle = navigationManager.gridOverlayDoodle,
               let userID = authManager.currentUserID {
                DoodleReactionOverlay(
                    doodle: doodle,
                    threadItemID: nil,
                    currentUserID: userID,
                    currentEmoji: navigationManager.gridOverlayReactionEmoji,
                    onReactionSelected: { emoji in
                        navigationManager.gridOverlayOnReaction?(emoji)
                    },
                    onDismiss: {
                        navigationManager.gridOverlayOnDismiss?()
                        navigationManager.dismissGridOverlay()
                    }
                )
                .ignoresSafeArea()
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    @Namespace private var animation

    var body: some View {
        // Floating tab bar with no background
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.rawValue) { tab in
                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    namespace: animation
                ) {
                    // Light haptic on tab switch
                    if selectedTab != tab {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background(
            ZStack {
                // Solid dark base for opacity
                Capsule()
                    .fill(Color.black.opacity(0.3))
                // Blur on top
                VisualEffectBlur(blurStyle: .regular)
                    .clipShape(Capsule())
            }
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal, 100)
        .padding(.bottom, 8)
    }
}

struct TabBarButton: View {
    let tab: Tab
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isSelected {
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .matchedGeometryEffect(id: "tabBackground", in: namespace)
                }

                Image(systemName: tab.icon)
                    .font(.system(size: isSelected ? 20 : 18, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? AppTheme.textPrimary : AppTheme.textTertiary)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
            }
            .frame(height: 54)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(TabButtonStyle())
    }
}

struct TabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}


// MARK: - Preview

#Preview {
    MainTabView()
        .environmentObject(AuthManager())
        .environmentObject(UserManager())
        .environmentObject(DoodleManager())
        .environmentObject(FriendManager())
        .environmentObject(NavigationManager())
}
