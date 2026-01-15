//
//  AppDelegate.swift
//  squibble
//
//  Handles push notification callbacks
//

import UIKit
import UserNotifications
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self

        // Configure Google Sign-In
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: Config.Google.clientID)

        // Check notification authorization and re-register if already authorized
        Task {
            await NotificationManager.shared.checkAuthorizationStatus()
        }

        return true
    }

    // MARK: - URL Handling for Google Sign-In

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }

    // MARK: - Remote Notification Registration

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenString = NotificationManager.tokenString(from: deviceToken)
        print("Device token: \(tokenString)")

        // Store token in Supabase (or save as pending if user not loaded yet)
        Task { @MainActor in
            if UserManager.shared.currentUser != nil {
                do {
                    try await UserManager.shared.updateDeviceToken(tokenString)
                    print("Device token saved to Supabase")
                } catch {
                    print("Error saving device token: \(error)")
                }
            } else {
                // User not loaded yet, store token for later
                NotificationManager.shared.pendingDeviceToken = tokenString
                print("Device token stored as pending (user not loaded yet)")
            }
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error)")
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Called when notification is received while app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner and play sound even when app is open
        completionHandler([.banner, .sound, .badge])
    }

    /// Called when user taps on notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        Task { @MainActor in
            if let action = NotificationManager.shared.parseNotification(userInfo: userInfo) {
                NavigationManager.shared.handleNotificationAction(action)
            }
        }

        completionHandler()
    }
}
