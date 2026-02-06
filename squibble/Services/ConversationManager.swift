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

    // MARK: - Initialization

    private init() {}

    // MARK: - Load Conversations List

    /// Load all conversations for the current user
    func loadConversations(for userID: UUID) async {
        isLoading = true
        defer { isLoading = false }

        do {
            print("DEBUG ConversationManager: Loading conversations for user \(userID)")
            // 1. Get user's participations
            let participations = try await supabase.getConversationParticipations(for: userID)
            print("DEBUG ConversationManager: Found \(participations.count) participations")
            guard !participations.isEmpty else {
                print("DEBUG ConversationManager: No participations found, returning empty")
                conversations = []
                return
            }

            let conversationIDs = participations.map { $0.conversationID }

            // 2. Get conversations
            let convos = try await supabase.getConversations(ids: conversationIDs)

            // 3. Get all participants for these conversations
            let allParticipants = try await supabase.getAllParticipants(conversationIDs: conversationIDs)

            // 4. Get latest thread item for each conversation
            var latestItems: [UUID: ThreadItem] = [:]
            for convID in conversationIDs {
                if let item = try? await supabase.getLatestThreadItem(conversationID: convID) {
                    latestItems[convID] = item
                }
            }

            // 5. Get doodles for latest items
            let doodleIDs = latestItems.values.compactMap { $0.doodleID }
            let doodles = try await supabase.getDoodles(ids: doodleIDs)
            let doodleMap = Dictionary(uniqueKeysWithValues: doodles.map { ($0.id, $0) })

            // 6. Get other participants' user info
            let otherUserIDs = allParticipants
                .filter { $0.userID != userID }
                .map { $0.userID }
            let uniqueOtherUserIDs = Array(Set(otherUserIDs))
            let otherUsers = try await supabase.getUsers(ids: uniqueOtherUserIDs)
            let userMap = Dictionary(uniqueKeysWithValues: otherUsers.map { ($0.id, $0) })

            // 7. Build summaries
            var summaries: [ConversationSummary] = []
            for conv in convos {
                guard let myParticipation = participations.first(where: { $0.conversationID == conv.id }) else {
                    continue
                }

                let otherParticipantID = allParticipants
                    .first { $0.conversationID == conv.id && $0.userID != userID }?
                    .userID

                guard let otherID = otherParticipantID,
                      let otherUser = userMap[otherID] else {
                    continue
                }

                let lastItem = latestItems[conv.id]
                let lastDoodle = lastItem?.doodleID.flatMap { doodleMap[$0] }

                // Calculate unread count
                let unreadCount = try await supabase.countUnreadItems(
                    conversationID: conv.id,
                    userID: userID,
                    lastReadAt: myParticipation.lastReadAt
                )

                let summary = ConversationSummary(
                    id: conv.id,
                    type: conv.type,
                    updatedAt: conv.updatedAt,
                    otherParticipant: otherUser,
                    lastItem: lastItem,
                    lastDoodle: lastDoodle,
                    unreadCount: unreadCount,
                    muted: myParticipation.muted
                )
                summaries.append(summary)
            }

            // Sort by most recent activity
            conversations = summaries.sorted { $0.updatedAt > $1.updatedAt }

        } catch {
            print("Error loading conversations: \(error)")
            conversations = []
        }
    }

    // MARK: - Load Thread Items

    /// Load thread items for a specific conversation
    /// Uses caching to avoid re-fetching recent data
    func loadThread(conversationID: UUID, limit: Int = 50, forceRefresh: Bool = false) async {
        currentConversationID = conversationID

        // Check cache first (unless force refresh)
        if !forceRefresh, let cached = threadCache[conversationID] {
            // Use cached data immediately
            currentConversationItems = cached.items
            currentConversationDoodles = cached.doodles
            currentConversationReactions = cached.reactions

            // If cache is recent (< 30 seconds), don't refetch
            if Date().timeIntervalSince(cached.loadedAt) < 30 {
                return
            }
        }

        // Fetch from server
        isLoadingThread = threadCache[conversationID] == nil  // Only show loading if no cache
        defer { isLoadingThread = false }

        do {
            let items = try await supabase.getThreadItems(conversationID: conversationID, limit: limit)

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
                currentConversationItems = items
                currentConversationDoodles = doodlesDict
                currentConversationReactions = reactionsDict
            }
        } catch {
            print("Error loading thread: \(error)")
            // Only clear if no cache exists
            if threadCache[conversationID] == nil {
                currentConversationItems = []
                currentConversationDoodles = [:]
                currentConversationReactions = [:]
            }
        }
    }

    /// Load more (older) thread items
    func loadMoreThreadItems(conversationID: UUID, limit: Int = 30) async {
        guard let oldestItem = currentConversationItems.min(by: { $0.createdAt < $1.createdAt }) else {
            return
        }

        do {
            let olderItems = try await supabase.getThreadItems(
                conversationID: conversationID,
                limit: limit,
                before: oldestItem.createdAt
            )

            // Append older items
            currentConversationItems.append(contentsOf: olderItems)

            // Load associated doodles
            let newDoodleIDs = olderItems.compactMap { $0.doodleID }.filter { currentConversationDoodles[$0] == nil }
            if !newDoodleIDs.isEmpty {
                let newDoodles = try await supabase.getDoodles(ids: newDoodleIDs)
                for doodle in newDoodles {
                    currentConversationDoodles[doodle.id] = doodle
                }
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
            return try await supabase.getOrCreateDirectConversation(userA: currentUserID, userB: friendID)
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
}
