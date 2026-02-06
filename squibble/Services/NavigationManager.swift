//
//  NavigationManager.swift
//  squibble
//
//  Manages navigation state and deep link handling
//

import Foundation
import SwiftUI
import Combine
import Supabase

@MainActor
final class NavigationManager: ObservableObject {
    static let shared = NavigationManager()

    @Published var selectedTab: Tab = .home
    @Published var pendingDoodleID: UUID?
    @Published var pendingInviteCode: String?
    @Published var pendingReplyRecipientID: UUID?
    @Published var pendingConversationID: UUID?
    @Published var showAddFriends = false
    @Published var pendingHistoryFilter: DoodleFilter?
    @Published var showPasswordReset = false

    // Grid overlay state (shown at MainTabView level to cover tab bar)
    @Published var gridOverlayDoodle: Doodle?
    @Published var gridOverlayReactionEmoji: String?
    var gridOverlayOnReaction: ((String) -> Void)?
    var gridOverlayOnDismiss: (() -> Void)?

    func showGridOverlay(doodle: Doodle, currentEmoji: String?, onReaction: @escaping (String) -> Void, onDismiss: @escaping () -> Void) {
        gridOverlayDoodle = doodle
        gridOverlayReactionEmoji = currentEmoji
        gridOverlayOnReaction = onReaction
        gridOverlayOnDismiss = onDismiss
    }

    func dismissGridOverlay() {
        gridOverlayDoodle = nil
        gridOverlayReactionEmoji = nil
        gridOverlayOnReaction = nil
        gridOverlayOnDismiss = nil
    }

    // Handle deep links
    func handleDeepLink(_ url: URL) {
        let urlString = url.absoluteString

        // Check for Supabase auth callbacks (tokens in URL fragment after #)
        // Supabase sends: squibble://reset-password#access_token=...&type=recovery
        if urlString.contains("access_token") || urlString.contains("type=recovery") || urlString.contains("type=signup") {
            Task {
                do {
                    // Supabase Swift client's session(from:) handles fragment parsing
                    _ = try await SupabaseService.shared.client.auth.session(from: url)

                    // Check if this was a password reset (type=recovery in fragment)
                    if urlString.contains("type=recovery") {
                        showPasswordReset = true
                    }
                } catch {
                    print("Failed to handle auth callback: \(error)")
                }
            }
            return
        }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return
        }

        // Handle squibble:// scheme
        if components.scheme == "squibble" {
            switch components.host {
            case "doodle":
                // squibble://doodle/{id} - Open specific doodle
                if let doodleIDString = components.path.dropFirst().description.split(separator: "/").first,
                   let doodleID = UUID(uuidString: String(doodleIDString)) {
                    pendingDoodleID = doodleID
                    selectedTab = .history
                }

            case "invite":
                // squibble://invite/{code} - Handle friend invite
                if let code = components.queryItems?.first(where: { $0.name == "code" })?.value {
                    pendingInviteCode = code
                    selectedTab = .profile
                }

            case "draw":
                // squibble://draw - Open drawing canvas
                selectedTab = .home

            case "conversation":
                // squibble://conversation/{id} - Open specific conversation
                if let conversationIDString = components.path.dropFirst().description.split(separator: "/").first,
                   let conversationID = UUID(uuidString: String(conversationIDString)) {
                    pendingConversationID = conversationID
                    selectedTab = .history
                }

            case "reset-password":
                // squibble://reset-password#access_token=...&type=recovery
                // This is handled above, but if we get here without tokens, just show the reset form
                // (user might be manually navigating)
                if let fragment = components.fragment, fragment.contains("access_token") {
                    Task {
                        do {
                            _ = try await SupabaseService.shared.client.auth.session(from: url)
                            showPasswordReset = true
                        } catch {
                            print("Failed to handle password reset callback: \(error)")
                        }
                    }
                }

            default:
                break
            }
        }
    }

    // Navigate to specific tab
    func navigateTo(_ tab: Tab) {
        selectedTab = tab
    }

    // Navigate to history with a specific filter
    func navigateToHistory(filter: DoodleFilter) {
        pendingHistoryFilter = filter
        selectedTab = .history
    }

    func clearPendingHistoryFilter() {
        pendingHistoryFilter = nil
    }

    // Navigate to doodle detail
    func openDoodle(_ doodleID: UUID) {
        pendingDoodleID = doodleID
        selectedTab = .history
    }

    // Clear pending navigation
    func clearPendingDoodle() {
        pendingDoodleID = nil
    }

    func clearPendingInvite() {
        pendingInviteCode = nil
    }

    func clearPendingReplyRecipient() {
        pendingReplyRecipientID = nil
    }

    func clearPendingConversation() {
        pendingConversationID = nil
    }

    // MARK: - Notification Actions

    func handleNotificationAction(_ action: NotificationAction) {
        switch action {
        case .openDoodle(let doodleID):
            pendingDoodleID = doodleID
            selectedTab = .history

        case .openHistory:
            selectedTab = .history

        case .openAddFriends:
            showAddFriends = true
            selectedTab = .home

        case .openHome:
            selectedTab = .home
        }
    }
}
