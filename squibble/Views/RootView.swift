//
//  RootView.swift
//  squibble
//
//  Root view that switches between Login and Main app based on auth state
//

import SwiftUI
import WidgetKit

struct RootView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var doodleManager: DoodleManager
    @EnvironmentObject var friendManager: FriendManager
    @EnvironmentObject var navigationManager: NavigationManager

    @State private var showOnboarding: Bool? = nil  // nil = not yet determined
    @State private var isLoadingUserData = true

    var body: some View {
        Group {
            if authManager.isLoading || (authManager.isAuthenticated && isLoadingUserData) {
                SplashView()
            } else if authManager.isAuthenticated {
                authenticatedView
            } else {
                LoginView()
                    .task {
                        // Disconnect realtime when logged out
                        await RealtimeService.shared.disconnect()
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
        .sheet(isPresented: $navigationManager.showPasswordReset) {
            SetNewPasswordView()
                .environmentObject(authManager)
                .environmentObject(navigationManager)
        }
        .task(id: authManager.isAuthenticated) {
            // Load user data when authenticated
            if authManager.isAuthenticated && !authManager.isLoading {
                await loadUserDataAndCheckOnboarding()
            } else if !authManager.isAuthenticated {
                // Reset state when logged out
                isLoadingUserData = true
                showOnboarding = nil
            }
        }
    }

    @ViewBuilder
    private var authenticatedView: some View {
        Group {
            if showOnboarding == true {
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showOnboarding = false
                    }
                }
                .environmentObject(userManager)
            } else {
                MainTabView()
            }
        }
    }

    private func loadUserDataAndCheckOnboarding() async {
        guard let userID = authManager.currentUserID else { return }

        // PROGRESSIVE STARTUP: Only block on user data (needed for onboarding check)
        await userManager.loadUser(id: userID)

        // Check if user needs onboarding BEFORE showing authenticated view
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

        await MainActor.run {
            showOnboarding = !hasCompletedOnboarding
            isLoadingUserData = false
        }

        // Load friends and doodles in background (non-blocking)
        // UI will show immediately and update as data loads
        Task.detached(priority: .userInitiated) {
            // Load friends and doodles in parallel
            async let friendsTask: () = self.friendManager.loadFriends(for: userID)
            async let doodlesTask: () = self.doodleManager.loadDoodles(for: userID)
            _ = await (friendsTask, doodlesTask)
        }

        // Delay non-critical background work to let UI settle first
        Task.detached(priority: .utility) {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

            // Set up and connect realtime subscriptions
            await self.setupRealtimeCallbacks(userID: userID)
            await RealtimeService.shared.connect(userID: userID)

            // Update widget with latest received doodle
            await self.doodleManager.updateWidgetWithLatestDoodle(friends: self.friendManager.friends)
        }
    }

    // MARK: - Realtime Callbacks

    private func setupRealtimeCallbacks(userID: UUID) async {
        let realtime = RealtimeService.shared

        // Handle new doodle received
        realtime.onNewDoodleReceived = { [weak doodleManager, weak friendManager] recipient in
            print("Realtime callback: New doodle received - doodleID: \(recipient.doodleID)")
            Task { @MainActor in
                guard let doodleManager = doodleManager,
                      let friendManager = friendManager else {
                    print("Realtime callback: doodleManager or friendManager is nil")
                    return
                }

                // OPTIMIZATION: Append just the new doodle instead of reloading all
                let didAppend = await doodleManager.appendReceivedDoodle(doodleID: recipient.doodleID)
                print("Realtime callback: Append result = \(didAppend), receivedDoodles count = \(doodleManager.receivedDoodles.count)")

                // Update widget with latest doodle
                if didAppend {
                    print("Realtime callback: Updating widget...")
                    await doodleManager.updateWidgetWithLatestDoodle(friends: friendManager.friends)
                    print("Realtime callback: Widget update complete")
                }
            }
        }

        // Handle new friend request received
        realtime.onFriendRequestReceived = { [weak friendManager] friendship in
            Task { @MainActor in
                guard let friendManager = friendManager else { return }
                // Add to pending requests if not already there
                if !friendManager.pendingRequests.contains(where: { $0.id == friendship.id }) {
                    friendManager.pendingRequests.append(friendship)
                }
            }
        }

        // Handle friend request accepted (someone accepted our request)
        realtime.onFriendRequestAccepted = { [weak friendManager] friendship in
            Task { @MainActor in
                guard let friendManager = friendManager else { return }
                // Reload friends to get the new friend
                await friendManager.loadFriends(for: userID)
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AuthManager())
        .environmentObject(UserManager.shared)
        .environmentObject(DoodleManager())
        .environmentObject(FriendManager())
        .environmentObject(NavigationManager.shared)
}
