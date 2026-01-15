//
//  squibbleApp.swift
//  squibble
//
//  Created by Mehul Pandey on 12/26/25.
//

import SwiftUI
import WidgetKit

@main
struct squibbleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var authManager = AuthManager()
    @StateObject private var userManager = UserManager.shared
    @StateObject private var doodleManager = DoodleManager()
    @StateObject private var friendManager = FriendManager()
    @StateObject private var navigationManager = NavigationManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .environmentObject(userManager)
                .environmentObject(doodleManager)
                .environmentObject(friendManager)
                .environmentObject(navigationManager)
                .onOpenURL { url in
                    // Handle deep links (squibble:// URLs)
                    navigationManager.handleDeepLink(url)
                }
                .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                // Refresh widget when app becomes active
                WidgetCenter.shared.reloadTimelines(ofKind: AppGroupStorage.widgetKind)
            }
        }
    }
}
