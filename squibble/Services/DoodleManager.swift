//
//  DoodleManager.swift
//  squibble
//
//  Manages doodle operations (create, fetch, delete)
//

import Foundation
import Combine
import WidgetKit

@MainActor
final class DoodleManager: ObservableObject {
    @Published var sentDoodles: [Doodle] = []
    @Published var receivedDoodles: [Doodle] = []
    @Published var isLoading = false

    private let supabase = SupabaseService.shared

    func loadDoodles(for userID: UUID, showLoading: Bool = true) async {
        if showLoading {
            isLoading = true
        }

        // Fetch sent and received doodles in parallel
        async let sentTask: [Doodle]? = {
            do { return try await supabase.getDoodlesSent(by: userID) }
            catch { print("Error loading sent doodles: \(error)"); return nil }
        }()
        async let receivedTask: [Doodle]? = {
            do { return try await supabase.getDoodlesReceived(by: userID) }
            catch { print("Error loading received doodles: \(error)"); return nil }
        }()

        let (newSent, newReceived) = await (sentTask, receivedTask)
        if let newSent { sentDoodles = newSent }
        if let newReceived { receivedDoodles = newReceived }

        if showLoading {
            isLoading = false
        }
    }

    /// Refresh doodles without showing loading indicator (for pull-to-refresh)
    func refreshDoodles(for userID: UUID) async {
        await loadDoodles(for: userID, showLoading: false)
    }

    func sendDoodle(senderID: UUID, imageData: Data, recipientIDs: [UUID]) async throws {
        let doodleID = UUID()

        // Upload image to storage
        let imageURL = try await supabase.uploadDoodleImage(
            userID: senderID,
            doodleID: doodleID,
            imageData: imageData
        )

        // Create doodle record
        let doodle = try await supabase.createDoodle(senderID: senderID, imageURL: imageURL)

        // Add recipients
        try await supabase.addDoodleRecipients(doodleID: doodle.id, recipientIDs: recipientIDs)

        // Update local state
        sentDoodles.insert(doodle, at: 0)
    }

    func deleteSentDoodle(_ doodle: Doodle, userID: UUID) async throws {
        // Delete from storage
        try await supabase.deleteDoodleImage(userID: userID, doodleID: doodle.id)

        // Delete from database (cascades to recipients)
        try await supabase.deleteDoodle(id: doodle.id)

        // Update local state
        sentDoodles.removeAll { $0.id == doodle.id }
    }

    func removeReceivedDoodle(_ doodle: Doodle, recipientID: UUID) async throws {
        // Remove recipient entry (doesn't delete the doodle itself)
        try await supabase.deleteDoodleRecipient(doodleID: doodle.id, recipientID: recipientID)

        // Update local state
        receivedDoodles.removeAll { $0.id == doodle.id }
    }

    var allDoodles: [Doodle] {
        (sentDoodles + receivedDoodles).sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Widget Updates

    /// Updates the widget with the most recent received doodle
    /// Pass friends list to look up sender info, or nil to clear widget if no doodles
    func updateWidgetWithLatestDoodle(friends: [User]) async {
        print("Widget: updateWidgetWithLatestDoodle called")
        print("Widget: receivedDoodles count = \(receivedDoodles.count)")
        print("Widget: friends count = \(friends.count)")

        guard let latestDoodle = receivedDoodles.first else {
            // No received doodles - clear the widget
            print("Widget: No received doodles, clearing widget")
            AppGroupStorage.clearLatestDoodle()
            WidgetCenter.shared.reloadAllTimelines()
            return
        }

        print("Widget: Latest doodle ID = \(latestDoodle.id)")
        print("Widget: Latest doodle senderID = \(latestDoodle.senderID)")
        for friend in friends {
            print("Widget: Friend - id=\(friend.id), name=\(friend.displayName), initials=\(friend.initials)")
        }

        // Download the doodle image first (can do in parallel with sender lookup if needed)
        guard let imageData = await downloadDoodleImage(from: latestDoodle.imageURL) else {
            print("Widget: Failed to download image")
            return
        }

        // Try to find sender in friends list first
        var sender = friends.first(where: { $0.id == latestDoodle.senderID })

        // If not found in friends, try to fetch from database
        if sender == nil {
            print("Widget: Sender not found in friends list, fetching from database")
            sender = try? await supabase.getUser(id: latestDoodle.senderID)
        }

        // Use sender info if found, otherwise use placeholder
        let senderName = sender?.displayName ?? "Friend"
        let senderInitials = sender?.initials ?? "?"
        let senderColor = sender?.colorHex ?? "#FF6B54"

        print("Widget: Using sender - name=\(senderName), initials=\(senderInitials)")

        // Save to App Group storage
        AppGroupStorage.saveLatestDoodle(
            imageData: imageData,
            doodleID: latestDoodle.id,
            senderName: senderName,
            senderInitials: senderInitials,
            senderColor: senderColor,
            date: latestDoodle.createdAt
        )

        // Trigger widget refresh using specific widget kind
        print("Widget: Data saved at \(Date()). Requesting timeline reload...")
        WidgetCenter.shared.reloadTimelines(ofKind: AppGroupStorage.widgetKind)
        print("Widget: Timeline reload requested")
    }

    /// Downloads image data from a URL
    private func downloadDoodleImage(from urlString: String) async -> Data? {
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        } catch {
            print("Error downloading doodle image: \(error)")
            return nil
        }
    }

    /// Refreshes widget timeline
    func refreshWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: AppGroupStorage.widgetKind)
    }
}
