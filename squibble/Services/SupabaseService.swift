//
//  SupabaseService.swift
//  squibble
//
//  Singleton service for Supabase client and database operations
//

import Foundation
import Supabase

final class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: Config.Supabase.url)!,
            supabaseKey: Config.Supabase.anonKey
        )
    }

    // MARK: - User Operations

    func createUser(_ user: User) async throws {
        try await client
            .from("users")
            .insert(user)
            .execute()
    }

    func getUser(id: UUID) async throws -> User? {
        let response: [User] = try await client
            .from("users")
            .select()
            .eq("id", value: id.uuidString)
            .execute()
            .value
        return response.first
    }

    func getUsers(ids: [UUID]) async throws -> [User] {
        guard !ids.isEmpty else { return [] }
        return try await client
            .from("users")
            .select()
            .in("id", values: ids.map { $0.uuidString })
            .execute()
            .value
    }

    func getUserByInviteCode(_ code: String) async throws -> User? {
        let response: [User] = try await client
            .from("users")
            .select()
            .eq("invite_code", value: code)
            .execute()
            .value
        return response.first
    }

    func updateUser(_ user: User) async throws {
        try await client
            .from("users")
            .update(user)
            .eq("id", value: user.id.uuidString)
            .execute()
    }

    // MARK: - Doodle Operations

    func createDoodle(senderID: UUID, imageURL: String) async throws -> Doodle {
        let doodle: [Doodle] = try await client
            .from("doodles")
            .insert(["sender_id": senderID.uuidString, "image_url": imageURL])
            .select()
            .execute()
            .value
        return doodle.first!
    }

    func getDoodlesSent(by userID: UUID, limit: Int = 50, offset: Int = 0) async throws -> [Doodle] {
        try await client
            .from("doodles")
            .select()
            .eq("sender_id", value: userID.uuidString)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
    }

    func getDoodlesReceived(by userID: UUID, limit: Int = 50, offset: Int = 0) async throws -> [Doodle] {
        // OPTIMIZATION: Only select doodle_id (reduces payload ~60%)
        let recipients: [DoodleRecipientID] = try await client
            .from("doodle_recipients")
            .select("doodle_id")
            .eq("recipient_id", value: userID.uuidString)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value

        let doodleIDs = recipients.map { $0.doodleID.uuidString }
        guard !doodleIDs.isEmpty else { return [] }

        return try await client
            .from("doodles")
            .select()
            .in("id", values: doodleIDs)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func deleteDoodle(id: UUID) async throws {
        try await client
            .from("doodles")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Doodle Recipient Operations

    func addDoodleRecipients(doodleID: UUID, recipientIDs: [UUID]) async throws {
        // Use RPC function to bypass RLS INSERT policy issues
        let params: [String: AnyJSON] = [
            "p_doodle_id": AnyJSON.string(doodleID.uuidString),
            "p_recipient_ids": AnyJSON.array(recipientIDs.map { AnyJSON.string($0.uuidString) })
        ]
        try await client
            .rpc("add_doodle_recipients", params: params)
            .execute()
    }

    func deleteDoodleRecipient(doodleID: UUID, recipientID: UUID) async throws {
        try await client
            .from("doodle_recipients")
            .delete()
            .eq("doodle_id", value: doodleID.uuidString)
            .eq("recipient_id", value: recipientID.uuidString)
            .execute()
    }

    func getDoodleRecipients(doodleID: UUID) async throws -> [User] {
        // Fetch recipients with user info joined
        let response: [DoodleRecipientWithUser] = try await client
            .from("doodle_recipients")
            .select("recipient_id, users!doodle_recipients_recipient_id_fkey(*)")
            .eq("doodle_id", value: doodleID.uuidString)
            .execute()
            .value

        return response.compactMap { $0.user }
    }

    // MARK: - Friendship Operations

    func createFriendRequest(requesterID: UUID, addresseeID: UUID) async throws {
        try await client
            .from("friendships")
            .insert(["requester_id": requesterID.uuidString, "addressee_id": addresseeID.uuidString])
            .execute()
    }

    func acceptFriendRequest(friendshipID: UUID) async throws {
        try await client
            .from("friendships")
            .update(["status": "accepted"])
            .eq("id", value: friendshipID.uuidString)
            .execute()
    }

    func deleteFriendship(id: UUID) async throws {
        try await client
            .from("friendships")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    func getFriendships(for userID: UUID) async throws -> [Friendship] {
        try await client
            .from("friendships")
            .select()
            .or("requester_id.eq.\(userID.uuidString),addressee_id.eq.\(userID.uuidString)")
            .execute()
            .value
    }

    func getAcceptedFriends(for userID: UUID) async throws -> [Friendship] {
        try await client
            .from("friendships")
            .select()
            .or("requester_id.eq.\(userID.uuidString),addressee_id.eq.\(userID.uuidString)")
            .eq("status", value: "accepted")
            .execute()
            .value
    }

    func getPendingFriendRequests(for userID: UUID) async throws -> [Friendship] {
        try await client
            .from("friendships")
            .select()
            .eq("addressee_id", value: userID.uuidString)
            .eq("status", value: "pending")
            .execute()
            .value
    }

    func getOutgoingFriendRequests(for userID: UUID) async throws -> [Friendship] {
        try await client
            .from("friendships")
            .select()
            .eq("requester_id", value: userID.uuidString)
            .eq("status", value: "pending")
            .execute()
            .value
    }

    // MARK: - Storage Operations

    func uploadDoodleImage(userID: UUID, doodleID: UUID, imageData: Data) async throws -> String {
        let path = "\(userID.uuidString)/\(doodleID.uuidString).jpg"
        try await client.storage
            .from("doodles")
            .upload(path, data: imageData, options: .init(cacheControl: "31536000", contentType: "image/jpeg"))
        return try client.storage.from("doodles").getPublicURL(path: path).absoluteString
    }

    func deleteDoodleImage(userID: UUID, doodleID: UUID) async throws {
        let path = "\(userID.uuidString)/\(doodleID.uuidString).jpg"
        try await client.storage
            .from("doodles")
            .remove(paths: [path])
    }

    func uploadProfileImage(userID: UUID, imageData: Data) async throws -> String {
        let path = "\(userID.uuidString).jpg"
        try await client.storage
            .from("profiles")
            .upload(path, data: imageData, options: .init(cacheControl: "3600", contentType: "image/jpeg", upsert: true))
        return try client.storage.from("profiles").getPublicURL(path: path).absoluteString
    }

    // MARK: - Account Deletion

    /// Deletes all user data via Edge Function (includes auth.users deletion)
    /// Falls back to client-side deletion if Edge Function is not deployed
    func deleteUserAccount() async throws {
        let session = try await client.auth.session
        let accessToken = session.accessToken
        let userID = session.user.id

        // Try Edge Function first (includes auth.users deletion)
        if let edgeFunctionResult = try? await callDeleteAccountEdgeFunction(accessToken: accessToken) {
            if edgeFunctionResult {
                return // Success via Edge Function
            }
        }

        // Fallback: client-side deletion (doesn't delete from auth.users)
        // This is used when Edge Function is not deployed yet
        print("Edge Function not available, falling back to client-side deletion")
        try await deleteUserAccountFallback(userID: userID)
    }

    private func callDeleteAccountEdgeFunction(accessToken: String) async throws -> Bool {
        guard let url = URL(string: "\(Config.Supabase.url)/functions/v1/delete-account") else {
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            return false
        }

        // 404 means function not deployed - use fallback
        if httpResponse.statusCode == 404 {
            return false
        }

        if httpResponse.statusCode == 200 {
            return true
        }

        // Other errors - throw them
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let errorMessage = json["error"] as? String {
            throw NSError(domain: "SupabaseService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        throw NSError(domain: "SupabaseService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to delete account"])
    }

    /// Fallback deletion method (doesn't delete from auth.users)
    private func deleteUserAccountFallback(userID: UUID) async throws {
        // 1. Get all doodles sent by user to delete their images
        let sentDoodles: [Doodle] = (try? await client
            .from("doodles")
            .select()
            .eq("sender_id", value: userID.uuidString)
            .execute()
            .value) ?? []

        // 2. Delete doodle images from storage
        for doodle in sentDoodles {
            try? await deleteDoodleImage(userID: userID, doodleID: doodle.id)
        }

        // 3. Delete doodle_recipients where user is recipient
        _ = try? await client
            .from("doodle_recipients")
            .delete()
            .eq("recipient_id", value: userID.uuidString)
            .execute()

        // 4. Delete doodles sent by user
        _ = try? await client
            .from("doodles")
            .delete()
            .eq("sender_id", value: userID.uuidString)
            .execute()

        // 5. Delete friendships
        _ = try? await client
            .from("friendships")
            .delete()
            .or("requester_id.eq.\(userID.uuidString),addressee_id.eq.\(userID.uuidString)")
            .execute()

        // 6. Delete profile image
        _ = try? await client.storage
            .from("profiles")
            .remove(paths: ["\(userID.uuidString).jpg"])

        // 7. Delete user record
        try await client
            .from("users")
            .delete()
            .eq("id", value: userID.uuidString)
            .execute()
    }

    // MARK: - Conversation Operations

    /// Get or create a direct conversation between two users
    func getOrCreateDirectConversation(userA: UUID, userB: UUID) async throws -> UUID {
        let result: String = try await client
            .rpc("get_or_create_direct_conversation", params: [
                "user_a": userA.uuidString,
                "user_b": userB.uuidString
            ])
            .execute()
            .value
        guard let uuid = UUID(uuidString: result) else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid UUID returned"])
        }
        return uuid
    }

    /// Get user's conversation participations
    func getConversationParticipations(for userID: UUID) async throws -> [ConversationParticipant] {
        try await client
            .from("conversation_participants")
            .select()
            .eq("user_id", value: userID.uuidString)
            .execute()
            .value
    }

    /// Get conversations by IDs
    func getConversations(ids: [UUID]) async throws -> [Conversation] {
        guard !ids.isEmpty else { return [] }
        return try await client
            .from("conversations")
            .select()
            .in("id", values: ids.map { $0.uuidString })
            .order("updated_at", ascending: false)
            .execute()
            .value
    }

    /// Get all participants for given conversations (uses RPC to avoid RLS recursion)
    func getAllParticipants(conversationIDs: [UUID]) async throws -> [ConversationParticipant] {
        guard !conversationIDs.isEmpty else { return [] }
        return try await client
            .rpc("get_conversation_participants", params: [
                "p_conversation_ids": conversationIDs.map { $0.uuidString }
            ])
            .execute()
            .value
    }

    /// Get latest thread item for a conversation
    func getLatestThreadItem(conversationID: UUID) async throws -> ThreadItem? {
        let items: [ThreadItem] = try await client
            .from("thread_items")
            .select()
            .eq("conversation_id", value: conversationID.uuidString)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value
        return items.first
    }

    /// Get thread items for a conversation with pagination
    func getThreadItems(conversationID: UUID, limit: Int = 50, before: Date? = nil) async throws -> [ThreadItem] {
        var query = client
            .from("thread_items")
            .select()
            .eq("conversation_id", value: conversationID.uuidString)

        if let beforeDate = before {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            query = query.lt("created_at", value: formatter.string(from: beforeDate))
        }

        return try await query
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    /// Get doodles by IDs
    func getDoodles(ids: [UUID]) async throws -> [Doodle] {
        guard !ids.isEmpty else { return [] }
        return try await client
            .from("doodles")
            .select()
            .in("id", values: ids.map { $0.uuidString })
            .execute()
            .value
    }

    /// Update last_read_at for a conversation participant
    func updateLastReadAt(conversationID: UUID, userID: UUID) async throws {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try await client
            .from("conversation_participants")
            .update(["last_read_at": formatter.string(from: Date())])
            .eq("conversation_id", value: conversationID.uuidString)
            .eq("user_id", value: userID.uuidString)
            .execute()
    }

    /// Update muted status for a conversation participant
    func updateMuted(conversationID: UUID, userID: UUID, muted: Bool) async throws {
        try await client
            .from("conversation_participants")
            .update(["muted": muted])
            .eq("conversation_id", value: conversationID.uuidString)
            .eq("user_id", value: userID.uuidString)
            .execute()
    }

    /// Create a thread item for a doodle using RPC function
    func createThreadItemForDoodle(conversationID: UUID, senderID: UUID, doodleID: UUID) async throws -> UUID {
        let result: String = try await client
            .rpc("create_thread_item_for_doodle", params: [
                "p_conversation_id": conversationID.uuidString,
                "p_sender_id": senderID.uuidString,
                "p_doodle_id": doodleID.uuidString
            ])
            .execute()
            .value
        guard let uuid = UUID(uuidString: result) else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid UUID returned"])
        }
        return uuid
    }

    /// Create a text message thread item using RPC function
    func createTextThreadItem(conversationID: UUID, senderID: UUID, textContent: String) async throws -> UUID {
        let result: String = try await client
            .rpc("create_text_thread_item", params: [
                "p_conversation_id": conversationID.uuidString,
                "p_sender_id": senderID.uuidString,
                "p_text_content": textContent
            ])
            .execute()
            .value
        guard let uuid = UUID(uuidString: result) else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid UUID returned"])
        }
        return uuid
    }

    /// Count unread items in a conversation for a user
    func countUnreadItems(conversationID: UUID, userID: UUID, lastReadAt: Date) async throws -> Int {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let items: [ThreadItem] = try await client
            .from("thread_items")
            .select()
            .eq("conversation_id", value: conversationID.uuidString)
            .neq("sender_id", value: userID.uuidString)
            .gt("created_at", value: formatter.string(from: lastReadAt))
            .execute()
            .value
        return items.count
    }

    /// Get thread item by doodle ID (for reacting to doodles from grid view)
    func getThreadItem(byDoodleID doodleID: UUID) async throws -> ThreadItem? {
        let items: [ThreadItem] = try await client
            .from("thread_items")
            .select()
            .eq("doodle_id", value: doodleID.uuidString)
            .limit(1)
            .execute()
            .value
        return items.first
    }

    // MARK: - Reaction Operations

    /// Add or update a reaction to a thread item
    /// Uses upsert to handle both new reactions and changing existing ones
    func addReaction(threadItemID: UUID, userID: UUID, emoji: String) async throws -> Reaction {
        let reactions: [Reaction] = try await client
            .from("reactions")
            .upsert([
                "thread_item_id": threadItemID.uuidString,
                "user_id": userID.uuidString,
                "emoji": emoji
            ], onConflict: "thread_item_id,user_id")
            .select()
            .execute()
            .value
        guard let reaction = reactions.first else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to add reaction"])
        }
        return reaction
    }

    /// Remove a reaction from a thread item
    func removeReaction(threadItemID: UUID, userID: UUID) async throws {
        try await client
            .from("reactions")
            .delete()
            .eq("thread_item_id", value: threadItemID.uuidString)
            .eq("user_id", value: userID.uuidString)
            .execute()
    }

    /// Get all reactions for a set of thread items
    func getReactions(threadItemIDs: [UUID]) async throws -> [Reaction] {
        guard !threadItemIDs.isEmpty else { return [] }
        return try await client
            .from("reactions")
            .select()
            .in("thread_item_id", values: threadItemIDs.map { $0.uuidString })
            .execute()
            .value
    }

    /// Get reactions for a single thread item
    func getReactions(threadItemID: UUID) async throws -> [Reaction] {
        try await client
            .from("reactions")
            .select()
            .eq("thread_item_id", value: threadItemID.uuidString)
            .execute()
            .value
    }

    // MARK: - Aggregated Reactions

    /// Get all reactions for a doodle across all thread_items (for detail view)
    func getAggregatedReactions(doodleID: UUID) async throws -> [AggregatedReaction] {
        try await client
            .rpc("get_aggregated_reactions_for_doodle", params: ["p_doodle_id": doodleID.uuidString])
            .execute()
            .value
    }

    /// Get aggregated reactions for multiple doodles (for grid view efficiency)
    func getAggregatedReactions(doodleIDs: [UUID]) async throws -> [AggregatedReaction] {
        guard !doodleIDs.isEmpty else { return [] }
        return try await client
            .rpc("get_aggregated_reactions_for_doodles", params: ["p_doodle_ids": doodleIDs.map { $0.uuidString }])
            .execute()
            .value
    }

    // MARK: - Batch Conversation Query

    /// Get all conversations with metadata in a single query (eliminates N+1)
    func getConversationsWithMetadata(userID: UUID) async throws -> [ConversationWithMetadata] {
        return try await client
            .rpc("get_conversations_with_metadata", params: ["p_user_id": userID.uuidString])
            .execute()
            .value
    }
}

// MARK: - Batch Query Response Models

/// Response from get_conversations_with_metadata RPC
struct ConversationWithMetadata: Codable {
    let conversationID: UUID
    let conversationType: String
    let conversationUpdatedAt: Date
    let otherUserID: UUID
    let otherUserDisplayName: String
    let otherUserColorHex: String
    let otherUserProfileImageURL: String?
    let myLastReadAt: Date?
    let myMuted: Bool
    let latestItemID: UUID?
    let latestItemType: String?
    let latestItemSenderID: UUID?
    let latestItemDoodleID: UUID?
    let latestItemTextContent: String?
    let latestItemCreatedAt: Date?
    let unreadCount: Int

    enum CodingKeys: String, CodingKey {
        case conversationID = "conversation_id"
        case conversationType = "conversation_type"
        case conversationUpdatedAt = "conversation_updated_at"
        case otherUserID = "other_user_id"
        case otherUserDisplayName = "other_user_display_name"
        case otherUserColorHex = "other_user_color_hex"
        case otherUserProfileImageURL = "other_user_profile_image_url"
        case myLastReadAt = "my_last_read_at"
        case myMuted = "my_muted"
        case latestItemID = "latest_item_id"
        case latestItemType = "latest_item_type"
        case latestItemSenderID = "latest_item_sender_id"
        case latestItemDoodleID = "latest_item_doodle_id"
        case latestItemTextContent = "latest_item_text_content"
        case latestItemCreatedAt = "latest_item_created_at"
        case unreadCount = "unread_count"
    }
}

// MARK: - Helper Structs for Joined Queries

/// Minimal struct for fetching just doodle_id from doodle_recipients (reduces payload ~60%)
private struct DoodleRecipientID: Codable {
    let doodleID: UUID

    enum CodingKeys: String, CodingKey {
        case doodleID = "doodle_id"
    }
}

/// Helper struct for decoding doodle recipients with joined user data
private struct DoodleRecipientWithUser: Codable {
    let recipientID: UUID
    let user: User?

    enum CodingKeys: String, CodingKey {
        case recipientID = "recipient_id"
        case user = "users"
    }
}
