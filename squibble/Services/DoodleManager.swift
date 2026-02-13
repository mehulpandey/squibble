//
//  DoodleManager.swift
//  squibble
//
//  Manages doodle operations (create, fetch, delete)
//

import Foundation
import Combine
import WidgetKit
import UIKit

@MainActor
final class DoodleManager: ObservableObject {
    @Published var sentDoodles: [Doodle] = []
    @Published var receivedDoodles: [Doodle] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false

    // Pagination state
    @Published private(set) var hasMoreSent = true
    @Published private(set) var hasMoreReceived = true
    private let pageSize = 50

    private let supabase = SupabaseService.shared
    private var lastWidgetUpdateTime: Date?  // For debouncing widget updates

    var hasMore: Bool { hasMoreSent || hasMoreReceived }

    func loadDoodles(for userID: UUID, showLoading: Bool = true) async {
        if showLoading {
            isLoading = true
        }

        // Reset pagination state
        hasMoreSent = true
        hasMoreReceived = true

        // Fetch first page of sent and received doodles in parallel
        async let sentTask: [Doodle]? = {
            do { return try await supabase.getDoodlesSent(by: userID, limit: self.pageSize, offset: 0) }
            catch { print("Error loading sent doodles: \(error)"); return nil }
        }()
        async let receivedTask: [Doodle]? = {
            do { return try await supabase.getDoodlesReceived(by: userID, limit: self.pageSize, offset: 0) }
            catch { print("Error loading received doodles: \(error)"); return nil }
        }()

        let (newSent, newReceived) = await (sentTask, receivedTask)
        if let newSent {
            sentDoodles = newSent
            hasMoreSent = newSent.count >= pageSize
        }
        if let newReceived {
            receivedDoodles = newReceived
            hasMoreReceived = newReceived.count >= pageSize
        }

        if showLoading {
            isLoading = false
        }
    }

    /// Refresh doodles without showing loading indicator (for pull-to-refresh)
    func refreshDoodles(for userID: UUID) async {
        await loadDoodles(for: userID, showLoading: false)
    }

    /// Load more doodles (pagination)
    func loadMoreDoodles(for userID: UUID) async {
        guard !isLoadingMore && hasMore else { return }

        isLoadingMore = true

        // Load more sent doodles if available
        if hasMoreSent {
            do {
                let moreSent = try await supabase.getDoodlesSent(
                    by: userID,
                    limit: pageSize,
                    offset: sentDoodles.count
                )
                sentDoodles.append(contentsOf: moreSent)
                hasMoreSent = moreSent.count >= pageSize
            } catch {
                print("Error loading more sent doodles: \(error)")
            }
        }

        // Load more received doodles if available
        if hasMoreReceived {
            do {
                let moreReceived = try await supabase.getDoodlesReceived(
                    by: userID,
                    limit: pageSize,
                    offset: receivedDoodles.count
                )
                receivedDoodles.append(contentsOf: moreReceived)
                hasMoreReceived = moreReceived.count >= pageSize
            } catch {
                print("Error loading more received doodles: \(error)")
            }
        }

        isLoadingMore = false
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

        // Create conversations and thread items for each recipient
        for recipientID in recipientIDs {
            do {
                print("DEBUG: Creating conversation between \(senderID) and \(recipientID)")
                // Get or create conversation with this recipient
                let conversationID = try await supabase.getOrCreateDirectConversation(
                    userA: senderID,
                    userB: recipientID
                )
                print("DEBUG: Got conversation ID: \(conversationID)")
                // Create thread item linking doodle to conversation
                let threadItemID = try await supabase.createThreadItemForDoodle(
                    conversationID: conversationID,
                    senderID: senderID,
                    doodleID: doodle.id
                )
                print("DEBUG: Created thread item: \(threadItemID)")
            } catch {
                // Log but don't fail the whole send if conversation creation fails
                print("ERROR: Failed to create conversation/thread_item for recipient \(recipientID): \(error)")
                print("ERROR: Full error: \(String(describing: error))")
            }
        }

        // Update local state
        sentDoodles.insert(doodle, at: 0)
    }

    /// Send a doodle within a conversation context
    /// Creates the doodle and thread_item in one flow
    func sendDoodleToConversation(senderID: UUID, imageData: Data, conversationID: UUID) async throws -> (doodle: Doodle, threadItemID: UUID) {
        let doodleID = UUID()

        // Upload image to storage
        let imageURL = try await supabase.uploadDoodleImage(
            userID: senderID,
            doodleID: doodleID,
            imageData: imageData
        )

        // Create doodle record
        let doodle = try await supabase.createDoodle(senderID: senderID, imageURL: imageURL)

        // Create thread item linking doodle to conversation
        let threadItemID = try await supabase.createThreadItemForDoodle(
            conversationID: conversationID,
            senderID: senderID,
            doodleID: doodle.id
        )

        // Update local state
        sentDoodles.insert(doodle, at: 0)

        return (doodle, threadItemID)
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

    // MARK: - Realtime Append (Optimization)

    /// Appends a single received doodle without reloading all doodles
    /// Returns true if the doodle was appended, false if it already exists
    @discardableResult
    func appendReceivedDoodle(doodleID: UUID) async -> Bool {
        // Check if we already have this doodle
        guard !receivedDoodles.contains(where: { $0.id == doodleID }) else {
            print("DoodleManager: Doodle \(doodleID) already in receivedDoodles, skipping")
            return false
        }

        // Fetch just this one doodle
        do {
            let doodles = try await supabase.getDoodles(ids: [doodleID])
            guard let doodle = doodles.first else {
                print("DoodleManager: Could not fetch doodle \(doodleID)")
                return false
            }

            // Insert at the beginning (most recent)
            receivedDoodles.insert(doodle, at: 0)
            print("DoodleManager: Appended new doodle \(doodleID), total received: \(receivedDoodles.count)")
            return true
        } catch {
            print("DoodleManager: Error fetching doodle \(doodleID): \(error)")
            return false
        }
    }

    // MARK: - Widget Updates

    /// Updates the widget with the most recent received doodle
    /// Pass friends list to look up sender info, or nil to clear widget if no doodles
    /// Debounced to max once per 5 seconds to prevent rapid successive calls
    func updateWidgetWithLatestDoodle(friends: [User]) async {
        // Debounce: skip if updated within last 5 seconds
        if let lastUpdate = lastWidgetUpdateTime {
            let elapsed = Date().timeIntervalSince(lastUpdate)
            if elapsed < 5 {
                print("Widget: Skipping update (debounce, \(Int(elapsed))s since last update)")
                return
            }
        }
        lastWidgetUpdateTime = Date()

        print("Widget: updateWidgetWithLatestDoodle called")

        guard let latestDoodle = receivedDoodles.first else {
            // No received doodles - clear the widget
            print("Widget: No received doodles, clearing widget")
            AppGroupStorage.clearLatestDoodle()
            WidgetCenter.shared.reloadAllTimelines()
            return
        }

        // OPTIMIZATION: Check if widget already has this exact doodle cached
        if AppGroupStorage.hasValidCache(doodleID: latestDoodle.id, imageURL: latestDoodle.imageURL) {
            print("Widget: Doodle \(latestDoodle.id) already cached, skipping download")
            // Still refresh timeline in case metadata needs update, but no network call
            WidgetCenter.shared.reloadTimelines(ofKind: AppGroupStorage.widgetKind)
            return
        }

        print("Widget: Need to fetch doodle \(latestDoodle.id)")

        // Use ImageCache for efficient downloading (memory + disk cache)
        guard let imageData = await fetchDoodleImageData(from: latestDoodle.imageURL) else {
            print("Widget: Failed to get image data")
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

        // Save to App Group storage (includes imageURL for cache validation)
        AppGroupStorage.saveLatestDoodle(
            imageData: imageData,
            imageURL: latestDoodle.imageURL,
            doodleID: latestDoodle.id,
            senderName: senderName,
            senderInitials: senderInitials,
            senderColor: senderColor,
            date: latestDoodle.createdAt
        )

        // Trigger widget refresh
        print("Widget: Data saved. Requesting timeline reload...")
        WidgetCenter.shared.reloadTimelines(ofKind: AppGroupStorage.widgetKind)
    }

    /// Fetches doodle image data using ImageCache (memory + disk cache)
    /// Returns raw Data for saving to App Group storage
    private func fetchDoodleImageData(from urlString: String) async -> Data? {
        // First try to get from ImageCache (memory + disk)
        if let cachedImage = await ImageCache.shared.image(for: urlString) {
            // Convert UIImage back to Data for App Group storage
            return cachedImage.pngData()
        }

        // ImageCache will have downloaded and cached it if available
        // If we get here, the download failed
        print("Widget: Image not available from cache or network")
        return nil
    }

    /// Refreshes widget timeline
    func refreshWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: AppGroupStorage.widgetKind)
    }
}
