//
//  NotificationManager.swift
//  squibble
//
//  Handles push notification permissions, registration, and handling
//

import Foundation
import UserNotifications
import UIKit
import Combine

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    /// Stores device token until user is loaded and it can be saved
    var pendingDeviceToken: String?

    private init() {}

    // MARK: - Permission Request

    /// Requests notification permissions from the user
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            isAuthorized = granted

            if granted {
                await registerForRemoteNotifications()
            }

            return granted
        } catch {
            print("Error requesting notification permission: \(error)")
            return false
        }
    }

    /// Checks current authorization status and re-registers if already authorized
    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized

        // Re-register for remote notifications if already authorized
        // This ensures we get a fresh device token on each app launch
        if isAuthorized {
            await registerForRemoteNotifications()
        }
    }

    /// Registers for remote notifications (must be called on main thread)
    func registerForRemoteNotifications() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    // MARK: - Device Token

    /// Converts device token data to string format for storage
    static func tokenString(from deviceToken: Data) -> String {
        deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    }

    // MARK: - Notification Handling

    /// Parses notification payload and returns navigation action
    func parseNotification(userInfo: [AnyHashable: Any]) -> NotificationAction? {
        // Expected payload structure:
        // {
        //   "type": "new_doodle" | "friend_request" | "friend_accepted" | "new_text_message" | "new_reaction",
        //   "doodle_id": "uuid" (for new_doodle),
        //   "sender_id": "uuid",
        //   "sender_name": "Name",
        //   "conversation_id": "uuid" (for new_text_message, new_reaction),
        //   "emoji": "👍" (for new_reaction)
        // }

        guard let type = userInfo["type"] as? String else { return nil }

        switch type {
        case "new_doodle":
            if let doodleIDString = userInfo["doodle_id"] as? String,
               let doodleID = UUID(uuidString: doodleIDString) {
                return .openDoodle(doodleID)
            }
            return .openHistory

        case "friend_request":
            return .openAddFriends

        case "friend_accepted":
            return .openHome

        case "new_text_message", "new_reaction":
            if let conversationIDString = userInfo["conversation_id"] as? String,
               let conversationID = UUID(uuidString: conversationIDString) {
                return .openConversation(conversationID)
            }
            return .openHistory

        default:
            return nil
        }
    }
}

// MARK: - Notification Action

enum NotificationAction {
    case openDoodle(UUID)
    case openHistory
    case openAddFriends
    case openHome
    case openConversation(UUID)
}
