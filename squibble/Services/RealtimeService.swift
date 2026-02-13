//
//  RealtimeService.swift
//  squibble
//
//  Manages Supabase Realtime subscriptions for live updates
//

import Foundation
import Combine
import Supabase

@MainActor
final class RealtimeService: ObservableObject {
    static let shared = RealtimeService()

    @Published private(set) var isConnected = false

    private let supabase = SupabaseService.shared.client
    private var doodleChannel: RealtimeChannelV2?
    private var friendshipChannel: RealtimeChannelV2?
    private var currentUserID: UUID?

    // Multi-conversation thread item subscriptions
    // Limit to 30 most recent conversations to avoid overloading
    private let maxConversationSubscriptions = 30
    private var threadItemChannels: [UUID: RealtimeChannelV2] = [:]
    private var threadItemListenerTasks: [UUID: Task<Void, Never>] = [:]
    private var subscribedConversationIDs: Set<UUID> = []

    // Store tasks to prevent them from being deallocated
    private var doodleListenerTask: Task<Void, Never>?
    private var friendshipInsertTask: Task<Void, Never>?
    private var friendshipUpdateTask: Task<Void, Never>?

    // Callbacks for handling realtime events
    var onNewDoodleReceived: ((DoodleRecipient) -> Void)?
    var onFriendRequestReceived: ((Friendship) -> Void)?
    var onFriendRequestAccepted: ((Friendship) -> Void)?
    var onNewThreadItem: ((ThreadItem) -> Void)?

    private init() {}

    // MARK: - Public Methods

    func connect(userID: UUID) async {
        // Disconnect any existing subscriptions first
        if isConnected {
            await disconnect()
        }

        currentUserID = userID
        await subscribeToDoodles(for: userID)
        await subscribeToFriendships(for: userID)
        isConnected = true
        print("Realtime: Connected for user \(userID)")
    }

    func disconnect() async {
        // Cancel listener tasks first
        doodleListenerTask?.cancel()
        friendshipInsertTask?.cancel()
        friendshipUpdateTask?.cancel()
        doodleListenerTask = nil
        friendshipInsertTask = nil
        friendshipUpdateTask = nil

        // Cancel all thread item listener tasks
        for (_, task) in threadItemListenerTasks {
            task.cancel()
        }
        threadItemListenerTasks.removeAll()

        if let channel = doodleChannel {
            await supabase.realtimeV2.removeChannel(channel)
        }
        if let channel = friendshipChannel {
            await supabase.realtimeV2.removeChannel(channel)
        }

        // Remove all thread item channels
        for (_, channel) in threadItemChannels {
            await supabase.realtimeV2.removeChannel(channel)
        }
        threadItemChannels.removeAll()
        subscribedConversationIDs.removeAll()

        doodleChannel = nil
        friendshipChannel = nil
        currentUserID = nil
        isConnected = false
        print("Realtime: Disconnected")
    }

    // MARK: - Thread Item Subscriptions (multi-conversation)

    /// Subscribe to thread_items for multiple conversations at once.
    /// Called after loading conversations list. Limited to maxConversationSubscriptions.
    func subscribeToConversations(_ conversationIDs: [UUID]) async {
        // Take only the first N conversations (most recent, assuming they're sorted)
        let idsToSubscribe = Array(conversationIDs.prefix(maxConversationSubscriptions))

        // Find which ones we need to add
        let currentIDs = subscribedConversationIDs
        let newIDs = Set(idsToSubscribe).subtracting(currentIDs)

        // Subscribe to new conversations
        for conversationID in newIDs {
            await addConversationSubscription(conversationID)
        }

        print("Realtime: Subscribed to \(subscribedConversationIDs.count) conversations (added \(newIDs.count) new)")
    }

    /// Add a subscription for a single conversation (e.g., when a new conversation is created)
    func addConversationSubscription(_ conversationID: UUID) async {
        // Skip if already subscribed
        guard !subscribedConversationIDs.contains(conversationID) else { return }

        // Check if we're at the limit
        if subscribedConversationIDs.count >= maxConversationSubscriptions {
            print("Realtime: At subscription limit (\(maxConversationSubscriptions)), skipping \(conversationID)")
            return
        }

        let channel = supabase.realtimeV2.channel("thread_items_\(conversationID.uuidString)")

        let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "thread_items",
            filter: "conversation_id=eq.\(conversationID.uuidString)"
        )

        await channel.subscribe()

        let task = Task { [weak self] in
            print("Realtime: Listener task STARTED for conversation \(conversationID)")
            var eventCount = 0
            for await insertion in insertions {
                eventCount += 1
                print("Realtime: Event #\(eventCount) received for conversation \(conversationID)")
                await self?.handleThreadItemInsertion(insertion.record)
            }
            print("Realtime: Listener task ENDED for conversation \(conversationID) after \(eventCount) events")
        }

        threadItemChannels[conversationID] = channel
        threadItemListenerTasks[conversationID] = task
        subscribedConversationIDs.insert(conversationID)

        print("Realtime: Added subscription for conversation \(conversationID) - total subscriptions: \(subscribedConversationIDs.count)")
    }

    /// Remove subscription for a specific conversation (rarely needed)
    func removeConversationSubscription(_ conversationID: UUID) async {
        threadItemListenerTasks[conversationID]?.cancel()
        threadItemListenerTasks.removeValue(forKey: conversationID)

        if let channel = threadItemChannels[conversationID] {
            await supabase.realtimeV2.removeChannel(channel)
        }
        threadItemChannels.removeValue(forKey: conversationID)
        subscribedConversationIDs.remove(conversationID)

        print("Realtime: Removed subscription for conversation \(conversationID)")
    }

    /// Unsubscribe from all thread_items (called on disconnect)
    private func unsubscribeFromAllThreadItems() async {
        for (_, task) in threadItemListenerTasks {
            task.cancel()
        }
        threadItemListenerTasks.removeAll()

        for (_, channel) in threadItemChannels {
            await supabase.realtimeV2.removeChannel(channel)
        }
        threadItemChannels.removeAll()
        subscribedConversationIDs.removeAll()

        print("Realtime: Unsubscribed from all thread_items")
    }

    // MARK: - Private Subscriptions

    private func subscribeToDoodles(for userID: UUID) async {
        let channel = supabase.realtimeV2.channel("doodle_recipients_\(userID.uuidString)")

        let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "doodle_recipients",
            filter: "recipient_id=eq.\(userID.uuidString)"
        )

        await channel.subscribe()
        print("Realtime: Subscribed to doodle_recipients for user \(userID)")

        // Store the task to prevent it from being deallocated
        doodleListenerTask = Task { [weak self] in
            print("Realtime: Doodle listener task started")
            var eventCount = 0
            for await insertion in insertions {
                eventCount += 1
                print("Realtime: Doodle insertion event #\(eventCount) received")
                await self?.handleDoodleInsertion(insertion.record)
            }
            print("Realtime: Doodle listener task ended after \(eventCount) events")

            // If the loop ended unexpectedly (WebSocket dropped), attempt to reconnect
            if let self = self, let userID = self.currentUserID, !Task.isCancelled {
                print("Realtime: Connection dropped, attempting to reconnect in 2 seconds...")
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay
                if !Task.isCancelled {
                    await self.reconnect()
                }
            }
        }

        doodleChannel = channel
    }

    /// Reconnects to realtime channels (called automatically when connection drops)
    private func reconnect() async {
        guard let userID = currentUserID else { return }
        print("Realtime: Reconnecting for user \(userID)...")

        // Store current conversation subscriptions to restore
        let conversationsToResubscribe = Array(subscribedConversationIDs)

        // Clean up old channels
        if let channel = doodleChannel {
            await supabase.realtimeV2.removeChannel(channel)
        }
        if let channel = friendshipChannel {
            await supabase.realtimeV2.removeChannel(channel)
        }
        await unsubscribeFromAllThreadItems()

        doodleChannel = nil
        friendshipChannel = nil

        // Resubscribe to user-level channels
        await subscribeToDoodles(for: userID)
        await subscribeToFriendships(for: userID)

        // Resubscribe to conversation channels
        await subscribeToConversations(conversationsToResubscribe)

        print("Realtime: Reconnected for user \(userID)")
    }

    private func subscribeToFriendships(for userID: UUID) async {
        let channel = supabase.realtimeV2.channel("friendships_\(userID.uuidString)")

        // Listen for new friend requests (where user is the addressee)
        let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "friendships",
            filter: "addressee_id=eq.\(userID.uuidString)"
        )

        // Listen for accepted friend requests (where user is the requester)
        let updates = channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "friendships",
            filter: "requester_id=eq.\(userID.uuidString)"
        )

        await channel.subscribe()
        print("Realtime: Subscribed to friendships for user \(userID)")

        // Handle new friend requests - store task to prevent deallocation
        friendshipInsertTask = Task { [weak self] in
            for await insertion in insertions {
                await self?.handleFriendshipInsertion(insertion.record)
            }
        }

        // Handle friend request acceptances - store task to prevent deallocation
        friendshipUpdateTask = Task { [weak self] in
            for await update in updates {
                await self?.handleFriendshipUpdate(update.record)
            }
        }

        friendshipChannel = channel
    }

    // MARK: - Event Handlers

    private func handleDoodleInsertion(_ record: [String: AnyJSON]) async {
        do {
            // Convert AnyJSON to standard types for JSONSerialization
            let convertedRecord = convertAnyJSONRecord(record)
            let data = try JSONSerialization.data(withJSONObject: convertedRecord)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                // Try ISO8601 with fractional seconds first
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = formatter.date(from: dateString) {
                    return date
                }
                // Fallback to without fractional seconds
                formatter.formatOptions = [.withInternetDateTime]
                if let date = formatter.date(from: dateString) {
                    return date
                }
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(dateString)")
            }
            let recipient = try decoder.decode(DoodleRecipient.self, from: data)
            print("Realtime: New doodle received - \(recipient.doodleID)")
            onNewDoodleReceived?(recipient)
        } catch {
            print("Realtime: Failed to decode doodle recipient - \(error)")
        }
    }

    private func handleFriendshipInsertion(_ record: [String: AnyJSON]) async {
        do {
            let convertedRecord = convertAnyJSONRecord(record)
            let data = try JSONSerialization.data(withJSONObject: convertedRecord)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = formatter.date(from: dateString) {
                    return date
                }
                formatter.formatOptions = [.withInternetDateTime]
                if let date = formatter.date(from: dateString) {
                    return date
                }
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(dateString)")
            }
            let friendship = try decoder.decode(Friendship.self, from: data)
            // Only notify for pending requests (new friend requests)
            if friendship.status == .pending {
                print("Realtime: New friend request from \(friendship.requesterID)")
                onFriendRequestReceived?(friendship)
            }
        } catch {
            print("Realtime: Failed to decode friendship insertion - \(error)")
        }
    }

    private func handleFriendshipUpdate(_ record: [String: AnyJSON]) async {
        do {
            let convertedRecord = convertAnyJSONRecord(record)
            let data = try JSONSerialization.data(withJSONObject: convertedRecord)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = formatter.date(from: dateString) {
                    return date
                }
                formatter.formatOptions = [.withInternetDateTime]
                if let date = formatter.date(from: dateString) {
                    return date
                }
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(dateString)")
            }
            let friendship = try decoder.decode(Friendship.self, from: data)
            // Notify when a request we sent was accepted
            if friendship.status == .accepted {
                print("Realtime: Friend request accepted by \(friendship.addresseeID)")
                onFriendRequestAccepted?(friendship)
            }
        } catch {
            print("Realtime: Failed to decode friendship update - \(error)")
        }
    }

    private func handleThreadItemInsertion(_ record: [String: AnyJSON]) async {
        print("Realtime: RAW thread_item record received: \(record.keys.joined(separator: ", "))")
        do {
            let convertedRecord = convertAnyJSONRecord(record)
            let data = try JSONSerialization.data(withJSONObject: convertedRecord)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = formatter.date(from: dateString) {
                    return date
                }
                formatter.formatOptions = [.withInternetDateTime]
                if let date = formatter.date(from: dateString) {
                    return date
                }
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(dateString)")
            }
            let threadItem = try decoder.decode(ThreadItem.self, from: data)
            print("Realtime: Decoded thread item - id: \(threadItem.id), conversation: \(threadItem.conversationID)")
            if onNewThreadItem != nil {
                print("Realtime: Invoking onNewThreadItem callback...")
                onNewThreadItem?(threadItem)
                print("Realtime: Callback invoked successfully")
            } else {
                print("Realtime: WARNING - onNewThreadItem callback is nil!")
            }
        } catch {
            print("Realtime: Failed to decode thread item - \(error)")
        }
    }

    // MARK: - Helpers

    /// Converts AnyJSON dictionary to a standard [String: Any] for JSONSerialization
    private func convertAnyJSONRecord(_ record: [String: AnyJSON]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in record {
            result[key] = convertAnyJSON(value)
        }
        return result
    }

    private func convertAnyJSON(_ value: AnyJSON) -> Any {
        switch value {
        case .null:
            return NSNull()
        case .bool(let b):
            return b
        case .integer(let i):
            return i
        case .double(let d):
            return d
        case .string(let s):
            return s
        case .array(let arr):
            return arr.map { convertAnyJSON($0) }
        case .object(let obj):
            var result: [String: Any] = [:]
            for (k, v) in obj {
                result[k] = convertAnyJSON(v)
            }
            return result
        }
    }
}
