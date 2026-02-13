//
//  ConversationManager.swift
//  squibble
//
//  Manages conversation data and operations for the chat feature
//

import Foundation
import Combine

@MainActor
final class ConversationManager: ObservableObject {
    static let shared = ConversationManager()

    // MARK: - Published Properties

    @Published var conversations: [ConversationSummary] = []
    @Published var isLoading = false
    @Published var isLoadingThread = false
    @Published var isLoadingMoreThreadItems = false
    @Published var hasMoreThreadItems = true  // Assume there's more until proven otherwise

    // For thread view
    @Published var currentConversationID: UUID?
    @Published var currentConversationItems: [ThreadItem] = []
    @Published var currentConversationDoodles: [UUID: Doodle] = [:]
    @Published var currentConversationReactions: [UUID: [Reaction]] = [:]  // keyed by thread item ID

    // MARK: - Private Properties

    private let supabase = SupabaseService.shared

    // Cache for thread data by conversation ID
    private var threadCache: [UUID: ThreadCache] = [:]

    private struct ThreadCache {
        var items: [ThreadItem]
        var doodles: [UUID: Doodle]
        var reactions: [UUID: [Reaction]]
        var loadedAt: Date
    }

    // Cache for doodle recipients (keyed by doodle ID)
    private var recipientsCache: [UUID: [User]] = [:]

    // MARK: - Initialization

    private init() {
        setupRealtimeCallbacks()
    }

    private func setupRealtimeCallbacks() {
        RealtimeService.shared.onNewThreadItem = { [weak self] threadItem in
            print("ConversationManager: CALLBACK RECEIVED for thread item \(threadItem.id)")
            guard let self = self else {
                print("ConversationManager: CALLBACK - self is nil!")
                return
            }
            // Handle directly on main actor (we're already on it via @MainActor class)
            Task { @MainActor in
                self.handleRealtimeThreadItemSync(threadItem)
                // Load doodle async if needed
                await self.loadDoodleForRealtimeItem(threadItem)
            }
        }
    }

    /// Handle incoming thread item from realtime subscription (SYNCHRONOUS part)
    private func handleRealtimeThreadItemSync(_ item: ThreadItem) {
        print("ConversationManager: Processing realtime thread item \(item.id) for conversation \(item.conversationID)")

        // 1. Update conversation list preview
        updateConversationPreview(with: item)
        print("ConversationManager: Updated preview for conversation \(item.conversationID)")

        // 2. Update cache
        updateCacheWithThreadItemSync(item)

        // 3. Update thread view UI if this is the current conversation
        guard currentConversationID == item.conversationID else {
            print("ConversationManager: Item is for different conversation (current: \(String(describing: currentConversationID))), skipping UI update")
            return
        }

        // Check if item already exists in UI (was added optimistically)
        guard !currentConversationItems.contains(where: { $0.id == item.id }) else {
            print("ConversationManager: Item already exists in UI, skipping")
            return
        }

        print("ConversationManager: Adding realtime thread item \(item.id) to current UI")

        // Add to beginning of list (most recent first)
        currentConversationItems.insert(item, at: 0)
    }

    /// Load doodle for a realtime item (ASYNC part, called after sync processing)
    private func loadDoodleForRealtimeItem(_ item: ThreadItem) async {
        guard let doodleID = item.doodleID else { return }
        guard currentConversationID == item.conversationID else { return }
        guard currentConversationDoodles[doodleID] == nil else { return }

        do {
            let doodles = try await supabase.getDoodles(ids: [doodleID])
            if let doodle = doodles.first {
                currentConversationDoodles[doodleID] = doodle
                // Also update cache
                if var cached = threadCache[item.conversationID] {
                    cached.doodles[doodleID] = doodle
                    threadCache[item.conversationID] = cached
                }
            }
        } catch {
            print("Error loading doodle for realtime item: \(error)")
        }
    }

    /// Update cache with a new thread item (SYNCHRONOUS - no await)
    /// Called for ALL realtime items, regardless of which conversation is currently viewed
    /// Doodles are NOT loaded here - they'll be loaded when the conversation is opened
    private func updateCacheWithThreadItemSync(_ item: ThreadItem) {
        // If no cache exists for this conversation, that's fine
        // The cache will be populated when user opens the conversation
        guard var cached = threadCache[item.conversationID] else {
            print("ConversationManager: No cache exists for conversation \(item.conversationID), skipping cache update")
            return
        }

        // Check if item already exists in cache (e.g., added optimistically)
        guard !cached.items.contains(where: { $0.id == item.id }) else {
            print("ConversationManager: Item already in cache, skipping")
            return
        }

        // Add item to cache (doodles will be loaded when thread is viewed)
        cached.items.insert(item, at: 0)
        cached.loadedAt = Date()  // Mark cache as fresh
        threadCache[item.conversationID] = cached
        print("ConversationManager: Updated cache for conversation \(item.conversationID) (now has \(cached.items.count) items)")
    }

    /// Load any doodles that are referenced in cached items but not yet loaded
    /// This handles doodles from realtime items that were cached without loading the doodle
    private func loadMissingDoodlesFromCache(conversationID: UUID, cached: ThreadCache) async {
        // Find doodle IDs that are in items but not in doodles dict
        let missingDoodleIDs = cached.items.compactMap { item -> UUID? in
            guard let doodleID = item.doodleID, cached.doodles[doodleID] == nil else {
                return nil
            }
            return doodleID
        }

        guard !missingDoodleIDs.isEmpty else { return }

        print("DEBUG loadThread: Loading \(missingDoodleIDs.count) missing doodles from cache")

        do {
            let doodles = try await supabase.getDoodles(ids: missingDoodleIDs)
            for doodle in doodles {
                currentConversationDoodles[doodle.id] = doodle
            }

            // Update cache with the loaded doodles
            if var updatedCache = threadCache[conversationID] {
                for doodle in doodles {
                    updatedCache.doodles[doodle.id] = doodle
                }
                threadCache[conversationID] = updatedCache
            }
        } catch {
            print("Error loading missing doodles: \(error)")
        }
    }

    /// Update conversation list preview when a new thread item arrives
    private func updateConversationPreview(with item: ThreadItem) {
        guard let index = conversations.firstIndex(where: { $0.id == item.conversationID }) else {
            return
        }

        let conv = conversations[index]
        let updatedConversation = ConversationSummary(
            id: conv.id,
            type: conv.type,
            updatedAt: item.createdAt,  // Update timestamp to new message time
            otherParticipant: conv.otherParticipant,
            lastItem: item,  // Update last item to show new preview
            lastDoodle: nil,  // Will be loaded if needed, but preview text handles doodles
            unreadCount: conv.unreadCount + 1,  // Increment unread (will be reset when opened)
            muted: conv.muted
        )

        conversations[index] = updatedConversation

        // Re-sort conversations by most recent
        conversations.sort { $0.updatedAt > $1.updatedAt }

        print("ConversationManager: Updated conversation preview for \(item.conversationID)")
    }

    // MARK: - Load Conversations List

    /// Load all conversations for the current user
    /// Uses batch RPC query to eliminate N+1 queries
    func loadConversations(for userID: UUID) async {
        isLoading = true
        defer { isLoading = false }

        do {
            print("DEBUG ConversationManager: Loading conversations (batch query) for user \(userID)")

            // Single RPC call gets everything we need
            let metadata = try await supabase.getConversationsWithMetadata(userID: userID)
            print("DEBUG ConversationManager: Batch query returned \(metadata.count) conversations")

            guard !metadata.isEmpty else {
                print("DEBUG ConversationManager: No conversations found")
                conversations = []
                return
            }

            // Fetch doodles for latest items that are doodles (still need this for image URLs)
            let doodleIDs = metadata.compactMap { $0.latestItemDoodleID }
            var doodleMap: [UUID: Doodle] = [:]
            if !doodleIDs.isEmpty {
                let doodles = try await supabase.getDoodles(ids: doodleIDs)
                doodleMap = Dictionary(uniqueKeysWithValues: doodles.map { ($0.id, $0) })
            }

            // Convert to ConversationSummary
            var summaries: [ConversationSummary] = []
            for item in metadata {
                // Build User from metadata (only display-relevant fields matter)
                let otherUser = User(
                    id: item.otherUserID,
                    displayName: item.otherUserDisplayName,
                    profileImageURL: item.otherUserProfileImageURL,
                    colorHex: item.otherUserColorHex,
                    isPremium: false,
                    streak: 0,
                    totalDoodlesSent: 0,
                    deviceToken: nil,
                    inviteCode: "",
                    createdAt: Date()
                )

                // Build ThreadItem if exists
                var lastItem: ThreadItem?
                if let itemID = item.latestItemID,
                   let itemType = item.latestItemType,
                   let senderID = item.latestItemSenderID,
                   let createdAt = item.latestItemCreatedAt {
                    lastItem = ThreadItem(
                        id: itemID,
                        conversationID: item.conversationID,
                        senderID: senderID,
                        type: ThreadItemType(rawValue: itemType) ?? .text,
                        doodleID: item.latestItemDoodleID,
                        textContent: item.latestItemTextContent,
                        replyToItemID: nil,
                        createdAt: createdAt
                    )
                }

                let lastDoodle = item.latestItemDoodleID.flatMap { doodleMap[$0] }

                let summary = ConversationSummary(
                    id: item.conversationID,
                    type: ConversationType(rawValue: item.conversationType) ?? .direct,
                    updatedAt: item.conversationUpdatedAt,
                    otherParticipant: otherUser,
                    lastItem: lastItem,
                    lastDoodle: lastDoodle,
                    unreadCount: item.unreadCount,
                    muted: item.myMuted
                )
                summaries.append(summary)
            }

            // Already sorted by RPC, but ensure order
            conversations = summaries

            // Subscribe to realtime updates for all conversations
            let conversationIDs = summaries.map { $0.id }
            await RealtimeService.shared.subscribeToConversations(conversationIDs)

        } catch {
            print("ERROR ConversationManager: Failed to load conversations")
            print("ERROR: \(error)")
            print("ERROR localizedDescription: \(error.localizedDescription)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("ERROR: Missing key '\(key.stringValue)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                case .typeMismatch(let type, let context):
                    print("ERROR: Type mismatch for '\(type)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                case .valueNotFound(let type, let context):
                    print("ERROR: Value not found for '\(type)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                case .dataCorrupted(let context):
                    print("ERROR: Data corrupted at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                @unknown default:
                    print("ERROR: Unknown decoding error")
                }
            }
            // Don't clear conversations on error - preserve existing data
            // conversations = []
        }
    }

    // MARK: - Load Thread Items

    /// Load thread items for a specific conversation
    /// Always fetches from server, but uses cache for instant display
    func loadThread(conversationID: UUID, limit: Int = 50, forceRefresh: Bool = false) async {
        print("DEBUG loadThread: Starting for conversation \(conversationID), forceRefresh=\(forceRefresh)")
        currentConversationID = conversationID
        hasMoreThreadItems = true  // Reset pagination state

        // Use cache for INSTANT display (don't wait for server)
        // This provides immediate UI feedback while we fetch fresh data
        if let cached = threadCache[conversationID] {
            currentConversationItems = cached.items
            currentConversationDoodles = cached.doodles
            currentConversationReactions = cached.reactions
            print("DEBUG loadThread: Showing cached data immediately (\(cached.items.count) items)")
        }

        // For forceRefresh, we keep showing existing data while fetching fresh
        // Don't clear cache - let the new data replace it when it arrives

        // ALWAYS fetch from server to ensure we have latest data
        // (realtime updates may have been missed)

        // Only show loading spinner if we have no data to display
        isLoadingThread = currentConversationItems.isEmpty
        defer { isLoadingThread = false }

        do {
            print("DEBUG loadThread: Fetching from server...")
            let items = try await supabase.getThreadItems(conversationID: conversationID, limit: limit)
            print("DEBUG loadThread: Fetched \(items.count) items from server")

            // Load associated doodles
            var doodlesDict: [UUID: Doodle] = [:]
            let doodleIDs = items.compactMap { $0.doodleID }
            if !doodleIDs.isEmpty {
                let doodles = try await supabase.getDoodles(ids: doodleIDs)
                doodlesDict = Dictionary(uniqueKeysWithValues: doodles.map { ($0.id, $0) })
            }

            // Load reactions for all items
            var reactionsDict: [UUID: [Reaction]] = [:]
            let itemIDs = items.map { $0.id }
            if !itemIDs.isEmpty {
                let reactions = try await supabase.getReactions(threadItemIDs: itemIDs)
                reactionsDict = Dictionary(grouping: reactions) { $0.threadItemID }
            }

            // Update cache
            threadCache[conversationID] = ThreadCache(
                items: items,
                doodles: doodlesDict,
                reactions: reactionsDict,
                loadedAt: Date()
            )

            // Update published properties (only if still viewing this conversation)
            if currentConversationID == conversationID {
                print("DEBUG loadThread: Updating UI with \(items.count) items")
                currentConversationItems = items
                currentConversationDoodles = doodlesDict
                currentConversationReactions = reactionsDict
            } else {
                print("DEBUG loadThread: Conversation changed, skipping UI update (current: \(String(describing: currentConversationID)), loaded: \(conversationID))")
            }
        } catch {
            print("DEBUG loadThread: Error - \(error)")
            // Only clear if no cache exists
            if threadCache[conversationID] == nil {
                currentConversationItems = []
                currentConversationDoodles = [:]
                currentConversationReactions = [:]
            }
        }
    }

    /// Load more (older) thread items for pagination
    func loadMoreThreadItems(conversationID: UUID, limit: Int = 30) async {
        // Don't load if already loading or no more items
        guard !isLoadingMoreThreadItems, hasMoreThreadItems else { return }

        guard let oldestItem = currentConversationItems.min(by: { $0.createdAt < $1.createdAt }) else {
            return
        }

        isLoadingMoreThreadItems = true
        defer { isLoadingMoreThreadItems = false }

        do {
            let olderItems = try await supabase.getThreadItems(
                conversationID: conversationID,
                limit: limit,
                before: oldestItem.createdAt
            )

            // If we got fewer items than requested, there are no more
            if olderItems.count < limit {
                hasMoreThreadItems = false
            }

            // Append older items (they go at the end since newest are first)
            currentConversationItems.append(contentsOf: olderItems)

            // Load associated doodles
            let newDoodleIDs = olderItems.compactMap { $0.doodleID }.filter { currentConversationDoodles[$0] == nil }
            if !newDoodleIDs.isEmpty {
                let newDoodles = try await supabase.getDoodles(ids: newDoodleIDs)
                for doodle in newDoodles {
                    currentConversationDoodles[doodle.id] = doodle
                }
            }

            // Load reactions for the new items
            let newItemIDs = olderItems.map { $0.id }
            if !newItemIDs.isEmpty {
                let reactions = try await supabase.getReactions(threadItemIDs: newItemIDs)
                let grouped = Dictionary(grouping: reactions) { $0.threadItemID }
                for (itemID, itemReactions) in grouped {
                    currentConversationReactions[itemID] = itemReactions
                }
            }

            // Update cache
            if var cached = threadCache[conversationID] {
                cached.items = currentConversationItems
                cached.doodles = currentConversationDoodles
                cached.reactions = currentConversationReactions
                threadCache[conversationID] = cached
            }
        } catch {
            print("Error loading more thread items: \(error)")
        }
    }

    // MARK: - Mark as Read

    /// Mark a conversation as read
    func markAsRead(conversationID: UUID, userID: UUID) async {
        do {
            try await supabase.updateLastReadAt(conversationID: conversationID, userID: userID)

            // Update local unread count
            if let index = conversations.firstIndex(where: { $0.id == conversationID }) {
                let conv = conversations[index]
                conversations[index] = ConversationSummary(
                    id: conv.id,
                    type: conv.type,
                    updatedAt: conv.updatedAt,
                    otherParticipant: conv.otherParticipant,
                    lastItem: conv.lastItem,
                    lastDoodle: conv.lastDoodle,
                    unreadCount: 0,
                    muted: conv.muted
                )
            }
        } catch {
            print("Error marking as read: \(error)")
        }
    }

    // MARK: - Toggle Mute

    /// Toggle mute status for a conversation
    func toggleMute(conversationID: UUID, userID: UUID) async {
        guard let index = conversations.firstIndex(where: { $0.id == conversationID }) else { return }
        let newMuted = !conversations[index].muted

        do {
            try await supabase.updateMuted(conversationID: conversationID, userID: userID, muted: newMuted)

            // Update local state
            let conv = conversations[index]
            conversations[index] = ConversationSummary(
                id: conv.id,
                type: conv.type,
                updatedAt: conv.updatedAt,
                otherParticipant: conv.otherParticipant,
                lastItem: conv.lastItem,
                lastDoodle: conv.lastDoodle,
                unreadCount: conv.unreadCount,
                muted: newMuted
            )
        } catch {
            print("Error toggling mute: \(error)")
        }
    }

    // MARK: - Get or Create Conversation

    /// Get or create a direct conversation with a friend
    func getOrCreateConversation(with friendID: UUID, currentUserID: UUID) async -> UUID? {
        do {
            let conversationID = try await supabase.getOrCreateDirectConversation(userA: currentUserID, userB: friendID)

            // Subscribe to realtime updates for this conversation
            await RealtimeService.shared.addConversationSubscription(conversationID)

            return conversationID
        } catch {
            print("Error getting/creating conversation: \(error)")
            return nil
        }
    }

    // MARK: - Clear Thread

    /// Clear current thread reference (called when leaving thread view)
    /// Data is kept in cache for fast re-access
    func clearCurrentThread() {
        // Save current data to cache before clearing
        if let convID = currentConversationID, !currentConversationItems.isEmpty {
            threadCache[convID] = ThreadCache(
                items: currentConversationItems,
                doodles: currentConversationDoodles,
                reactions: currentConversationReactions,
                loadedAt: Date()
            )
        }
        currentConversationID = nil
    }

    // MARK: - Add Thread Item Locally

    /// Add a new thread item to the current conversation (for optimistic updates)
    func addThreadItemLocally(_ item: ThreadItem, doodle: Doodle?) {
        currentConversationItems.insert(item, at: 0)
        if let doodle = doodle {
            currentConversationDoodles[doodle.id] = doodle
        }

        // Also update cache
        if let convID = currentConversationID, var cached = threadCache[convID] {
            cached.items.insert(item, at: 0)
            if let doodle = doodle {
                cached.doodles[doodle.id] = doodle
            }
            cached.loadedAt = Date()
            threadCache[convID] = cached
        }
    }

    // MARK: - Refresh Single Conversation

    /// Refresh a single conversation in the list
    func refreshConversation(_ conversationID: UUID, for userID: UUID) async {
        guard let index = conversations.firstIndex(where: { $0.id == conversationID }) else { return }

        do {
            // Get updated conversation
            let convos = try await supabase.getConversations(ids: [conversationID])
            guard let conv = convos.first else { return }

            // Get latest item
            let lastItem = try await supabase.getLatestThreadItem(conversationID: conversationID)

            // Get doodle if needed
            var lastDoodle: Doodle?
            if let doodleID = lastItem?.doodleID {
                let doodles = try await supabase.getDoodles(ids: [doodleID])
                lastDoodle = doodles.first
            }

            // Get participation
            let participations = try await supabase.getConversationParticipations(for: userID)
            guard let myParticipation = participations.first(where: { $0.conversationID == conversationID }) else { return }

            // Get unread count
            let unreadCount = try await supabase.countUnreadItems(
                conversationID: conversationID,
                userID: userID,
                lastReadAt: myParticipation.lastReadAt
            )

            // Update existing summary
            let existingConv = conversations[index]
            conversations[index] = ConversationSummary(
                id: conv.id,
                type: conv.type,
                updatedAt: conv.updatedAt,
                otherParticipant: existingConv.otherParticipant,
                lastItem: lastItem,
                lastDoodle: lastDoodle,
                unreadCount: unreadCount,
                muted: myParticipation.muted
            )

            // Re-sort by most recent activity
            conversations.sort { $0.updatedAt > $1.updatedAt }

        } catch {
            print("Error refreshing conversation: \(error)")
        }
    }

    // MARK: - Send Text Message

    /// Send a text message in a conversation
    func sendTextMessage(conversationID: UUID, senderID: UUID, text: String) async throws -> ThreadItem {
        // Create thread item on server
        let itemID = try await supabase.createTextThreadItem(
            conversationID: conversationID,
            senderID: senderID,
            textContent: text
        )

        // Create local ThreadItem for optimistic UI update
        let newItem = ThreadItem(
            id: itemID,
            conversationID: conversationID,
            senderID: senderID,
            type: .text,
            doodleID: nil,
            textContent: text,
            replyToItemID: nil,
            createdAt: Date()
        )

        // Add to current thread
        addThreadItemLocally(newItem, doodle: nil)

        return newItem
    }

    // MARK: - Reactions

    /// Add or update a reaction to a thread item
    func addReaction(threadItemID: UUID, userID: UUID, emoji: String) async {
        do {
            let reaction = try await supabase.addReaction(
                threadItemID: threadItemID,
                userID: userID,
                emoji: emoji
            )

            // Update local state
            var reactions = currentConversationReactions[threadItemID] ?? []
            // Remove existing reaction from this user if any
            reactions.removeAll { $0.userID == userID }
            // Add new reaction
            reactions.append(reaction)
            currentConversationReactions[threadItemID] = reactions
        } catch {
            print("Error adding reaction: \(error)")
        }
    }

    /// Remove a reaction from a thread item
    func removeReaction(threadItemID: UUID, userID: UUID) async {
        do {
            try await supabase.removeReaction(threadItemID: threadItemID, userID: userID)

            // Update local state
            if var reactions = currentConversationReactions[threadItemID] {
                reactions.removeAll { $0.userID == userID }
                currentConversationReactions[threadItemID] = reactions.isEmpty ? nil : reactions
            }
        } catch {
            print("Error removing reaction: \(error)")
        }
    }

    /// Toggle a reaction (add if not present, remove if same emoji, change if different emoji)
    func toggleReaction(threadItemID: UUID, userID: UUID, emoji: String) async {
        let existingReactions = currentConversationReactions[threadItemID] ?? []
        let myReaction = existingReactions.first { $0.userID == userID }

        if let existing = myReaction {
            if existing.emoji == emoji {
                // Same emoji - remove reaction
                await removeReaction(threadItemID: threadItemID, userID: userID)
            } else {
                // Different emoji - update reaction
                await addReaction(threadItemID: threadItemID, userID: userID, emoji: emoji)
            }
        } else {
            // No existing reaction - add new
            await addReaction(threadItemID: threadItemID, userID: userID, emoji: emoji)
        }
    }

    /// Get the current user's reaction for a thread item (if any)
    func myReaction(for threadItemID: UUID, userID: UUID) -> Reaction? {
        currentConversationReactions[threadItemID]?.first { $0.userID == userID }
    }

    // MARK: - Grid View Reactions

    /// React to a doodle from the grid view (looks up the thread item first)
    func reactToDoodle(doodleID: UUID, userID: UUID, emoji: String) async {
        do {
            // Find the thread item for this doodle
            guard let threadItem = try await supabase.getThreadItem(byDoodleID: doodleID) else {
                print("No thread item found for doodle \(doodleID)")
                return
            }

            // Add the reaction
            _ = try await supabase.addReaction(
                threadItemID: threadItem.id,
                userID: userID,
                emoji: emoji
            )
        } catch {
            print("Error reacting to doodle: \(error)")
        }
    }

    /// Get current reaction for a doodle (from grid view)
    func getReactionForDoodle(doodleID: UUID, userID: UUID) async -> String? {
        do {
            guard let threadItem = try await supabase.getThreadItem(byDoodleID: doodleID) else {
                return nil
            }
            let reactions = try await supabase.getReactions(threadItemID: threadItem.id)
            return reactions.first { $0.userID == userID }?.emoji
        } catch {
            print("Error getting reaction for doodle: \(error)")
            return nil
        }
    }

    /// Toggle reaction on a doodle (from grid view)
    func toggleReactionOnDoodle(doodleID: UUID, userID: UUID, emoji: String) async {
        do {
            guard let threadItem = try await supabase.getThreadItem(byDoodleID: doodleID) else {
                print("No thread item found for doodle \(doodleID)")
                return
            }

            let reactions = try await supabase.getReactions(threadItemID: threadItem.id)
            let myReaction = reactions.first { $0.userID == userID }

            if let existing = myReaction {
                if existing.emoji == emoji {
                    // Same emoji - remove reaction
                    try await supabase.removeReaction(threadItemID: threadItem.id, userID: userID)
                    // Update cache
                    updateCachedReaction(conversationID: threadItem.conversationID, threadItemID: threadItem.id, userID: userID, emoji: nil)
                } else {
                    // Different emoji - update reaction
                    let newReaction = try await supabase.addReaction(threadItemID: threadItem.id, userID: userID, emoji: emoji)
                    // Update cache
                    updateCachedReaction(conversationID: threadItem.conversationID, threadItemID: threadItem.id, userID: userID, emoji: emoji, reaction: newReaction)
                }
            } else {
                // No existing reaction - add new
                let newReaction = try await supabase.addReaction(threadItemID: threadItem.id, userID: userID, emoji: emoji)
                // Update cache
                updateCachedReaction(conversationID: threadItem.conversationID, threadItemID: threadItem.id, userID: userID, emoji: emoji, reaction: newReaction)
            }
        } catch {
            print("Error toggling reaction on doodle: \(error)")
        }
    }

    /// Update cached reaction (called after grid view reaction)
    private func updateCachedReaction(conversationID: UUID, threadItemID: UUID, userID: UUID, emoji: String?, reaction: Reaction? = nil) {
        // Update thread cache if exists
        if var cached = threadCache[conversationID] {
            var reactions = cached.reactions[threadItemID] ?? []
            // Remove existing reaction from this user
            reactions.removeAll { $0.userID == userID }
            // Add new reaction if provided
            if let newReaction = reaction {
                reactions.append(newReaction)
            }
            cached.reactions[threadItemID] = reactions.isEmpty ? nil : reactions
            threadCache[conversationID] = cached
        }

        // Update current conversation if viewing
        if currentConversationID == conversationID {
            var reactions = currentConversationReactions[threadItemID] ?? []
            // Remove existing reaction from this user
            reactions.removeAll { $0.userID == userID }
            // Add new reaction if provided
            if let newReaction = reaction {
                reactions.append(newReaction)
            }
            currentConversationReactions[threadItemID] = reactions.isEmpty ? nil : reactions
        }
    }

    /// Load reactions for multiple doodles (for grid view)
    func loadReactionsForDoodles(doodleIDs: [UUID], userID: UUID) async -> [UUID: String] {
        var result: [UUID: String] = [:]

        for doodleID in doodleIDs {
            if let emoji = await getReactionForDoodle(doodleID: doodleID, userID: userID) {
                result[doodleID] = emoji
            }
        }

        return result
    }

    // MARK: - Aggregated Reactions

    /// Load aggregated reactions for multiple doodles (for grid view)
    /// Returns a dictionary of doodleID -> ReactionSummary, or nil on error
    func loadAggregatedReactionsForDoodles(doodleIDs: [UUID]) async -> [UUID: ReactionSummary]? {
        guard !doodleIDs.isEmpty else { return [:] }

        do {
            let reactions = try await SupabaseService.shared.getAggregatedReactions(doodleIDs: doodleIDs)
            return buildReactionSummaries(from: reactions)
        } catch {
            print("Error loading aggregated reactions: \(error)")
            return nil  // Return nil on error to preserve existing cache
        }
    }

    /// Load aggregated reactions for a single doodle (for detail view)
    func loadAggregatedReactions(doodleID: UUID) async -> ReactionSummary {
        do {
            let reactions = try await SupabaseService.shared.getAggregatedReactions(doodleID: doodleID)
            let summaries = buildReactionSummaries(from: reactions)
            return summaries[doodleID] ?? .empty
        } catch {
            print("Error loading aggregated reactions: \(error)")
            return .empty
        }
    }

    /// Build reaction summaries grouped by doodle
    private func buildReactionSummaries(from reactions: [AggregatedReaction]) -> [UUID: ReactionSummary] {
        // Group by doodle ID
        let grouped = Dictionary(grouping: reactions) { $0.doodleID }

        return grouped.mapValues { doodleReactions in
            // Count emojis
            var emojiCounts: [String: Int] = [:]
            for reaction in doodleReactions {
                emojiCounts[reaction.emoji, default: 0] += 1
            }

            // Sort by count descending, take top 3
            let sorted = emojiCounts.sorted { $0.value > $1.value }
            let topEmojis = Array(sorted.prefix(3).map { $0.key })

            return ReactionSummary(
                topEmojis: topEmojis,
                totalCount: doodleReactions.count,
                reactions: doodleReactions
            )
        }
    }

    // MARK: - Recipients Cache

    /// Get cached recipients for a doodle, or nil if not cached
    func getCachedRecipients(doodleID: UUID) -> [User]? {
        return recipientsCache[doodleID]
    }

    /// Load recipients for a doodle, using cache if available
    func loadRecipients(doodleID: UUID) async -> [User] {
        // Return cached if available
        if let cached = recipientsCache[doodleID] {
            return cached
        }

        // Fetch from server
        do {
            let recipients = try await SupabaseService.shared.getDoodleRecipients(doodleID: doodleID)
            recipientsCache[doodleID] = recipients
            return recipients
        } catch {
            print("Error loading recipients: \(error)")
            return []
        }
    }

    /// Clear recipients cache (call when doodle is forwarded to new recipients)
    func invalidateRecipientsCache(doodleID: UUID) {
        recipientsCache.removeValue(forKey: doodleID)
    }
}
