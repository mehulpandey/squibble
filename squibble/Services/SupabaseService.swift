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

    func getDoodlesSent(by userID: UUID) async throws -> [Doodle] {
        try await client
            .from("doodles")
            .select()
            .eq("sender_id", value: userID.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func getDoodlesReceived(by userID: UUID) async throws -> [Doodle] {
        let recipients: [DoodleRecipient] = try await client
            .from("doodle_recipients")
            .select()
            .eq("recipient_id", value: userID.uuidString)
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
}
