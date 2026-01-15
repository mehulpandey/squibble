//
//  UserManager.swift
//  squibble
//
//  Manages current user state and profile operations
//

import Foundation
import Combine

@MainActor
final class UserManager: ObservableObject {
    static let shared = UserManager()

    @Published var currentUser: User?
    @Published var isLoading = false

    private let supabase = SupabaseService.shared

    func loadUser(id: UUID) async {
        isLoading = true
        do {
            currentUser = try await supabase.getUser(id: id)

            // Save any pending device token that arrived before user loaded
            if let pendingToken = NotificationManager.shared.pendingDeviceToken {
                NotificationManager.shared.pendingDeviceToken = nil
                try await updateDeviceToken(pendingToken)
                print("Pending device token saved to Supabase")
            }
        } catch {
            print("Error loading user: \(error)")
            currentUser = nil
        }
        isLoading = false
    }

    func createUserProfile(id: UUID, displayName: String) async throws {
        let inviteCode = generateInviteCode()
        let user = User(
            id: id,
            displayName: displayName,
            profileImageURL: nil,
            colorHex: randomColor(),
            isPremium: false,
            streak: 0,
            totalDoodlesSent: 0,
            deviceToken: nil,
            inviteCode: inviteCode,
            createdAt: Date()
        )
        try await supabase.createUser(user)
        currentUser = user
    }

    func updateDisplayName(_ name: String) async throws {
        guard var user = currentUser else { return }
        user.displayName = name
        try await supabase.updateUser(user)
        currentUser = user
    }

    func updateColor(_ colorHex: String) async throws {
        guard var user = currentUser else { return }
        user.colorHex = colorHex
        try await supabase.updateUser(user)
        currentUser = user
    }

    func updateProfileImage(url: String) async throws {
        guard var user = currentUser else { return }
        user.profileImageURL = url
        try await supabase.updateUser(user)
        currentUser = user
    }

    /// Updates user stats after sending a doodle (increments count and updates streak)
    /// Call this after successfully sending a doodle
    func recordDoodleSent(lastSentDate: Date?) async throws {
        guard var user = currentUser else {
            print("[UserManager] recordDoodleSent: No current user")
            return
        }

        let oldCount = user.totalDoodlesSent
        let oldStreak = user.streak

        // Increment doodles sent count
        user.totalDoodlesSent += 1

        // Update streak
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastDate = lastSentDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            print("[UserManager] lastSentDate: \(lastDate), daysDiff: \(daysDiff)")

            if daysDiff == 1 {
                // Consecutive day - increment streak
                user.streak += 1
            } else if daysDiff > 1 {
                // Gap in days - reset streak to 1
                user.streak = 1
            }
            // daysDiff == 0 means already sent today, keep streak as is
        } else {
            // First doodle ever - start streak at 1
            print("[UserManager] First doodle ever, setting streak to 1")
            user.streak = 1
        }

        print("[UserManager] Updating: doodlesSent \(oldCount) -> \(user.totalDoodlesSent), streak \(oldStreak) -> \(user.streak)")

        try await supabase.updateUser(user)
        currentUser = user

        print("[UserManager] Update complete, currentUser.streak = \(currentUser?.streak ?? -1)")
    }

    func updatePremiumStatus(isPremium: Bool) async throws {
        guard var user = currentUser else { return }
        user.isPremium = isPremium
        try await supabase.updateUser(user)
        currentUser = user
    }

    func updateDeviceToken(_ token: String) async throws {
        guard var user = currentUser else { return }
        user.deviceToken = token
        try await supabase.updateUser(user)
        currentUser = user
    }

    func clearUser() {
        currentUser = nil
    }

    // MARK: - Private Helpers

    private func generateInviteCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<8).map { _ in chars.randomElement()! })
    }

    private func randomColor() -> String {
        let colors = ["#007AFF", "#FF3B30", "#FF9500", "#FFCC00", "#34C759", "#5856D6", "#AF52DE", "#FF2D55", "#A2845E"]
        return colors.randomElement() ?? "#007AFF"
    }
}
