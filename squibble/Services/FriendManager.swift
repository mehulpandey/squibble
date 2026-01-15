//
//  FriendManager.swift
//  squibble
//
//  Manages friend operations (requests, accept, remove)
//

import Foundation
import Combine

@MainActor
final class FriendManager: ObservableObject {
    @Published var friends: [User] = []
    @Published var pendingRequests: [Friendship] = []
    @Published var isLoading = false

    private let supabase = SupabaseService.shared

    func loadFriends(for userID: UUID) async {
        isLoading = true
        do {
            // Get accepted friendships
            let friendships = try await supabase.getAcceptedFriends(for: userID)

            // Get friend user IDs
            let friendIDs = friendships.compactMap { friendship -> UUID? in
                if friendship.requesterID == userID {
                    return friendship.addresseeID
                } else {
                    return friendship.requesterID
                }
            }

            // Fetch friend user objects
            var friendUsers: [User] = []
            for friendID in friendIDs {
                if let user = try await supabase.getUser(id: friendID) {
                    friendUsers.append(user)
                }
            }
            friends = friendUsers

            // Get pending requests (where user is addressee)
            pendingRequests = try await supabase.getPendingFriendRequests(for: userID)
        } catch {
            print("Error loading friends: \(error)")
        }
        isLoading = false
    }

    func sendFriendRequest(from requesterID: UUID, toInviteCode code: String) async throws -> Bool {
        // Find user by invite code
        guard let addressee = try await supabase.getUserByInviteCode(code) else {
            return false
        }

        // Don't allow self-friending
        guard addressee.id != requesterID else {
            return false
        }

        // Create friend request
        try await supabase.createFriendRequest(requesterID: requesterID, addresseeID: addressee.id)
        return true
    }

    func acceptFriendRequest(_ friendship: Friendship, currentUserID: UUID) async throws {
        try await supabase.acceptFriendRequest(friendshipID: friendship.id)

        // Move from pending to friends
        pendingRequests.removeAll { $0.id == friendship.id }

        // Fetch the requester's user object
        if let user = try await supabase.getUser(id: friendship.requesterID) {
            friends.append(user)
        }
    }

    func declineFriendRequest(_ friendship: Friendship) async throws {
        try await supabase.deleteFriendship(id: friendship.id)
        pendingRequests.removeAll { $0.id == friendship.id }
    }

    func removeFriend(_ friend: User, currentUserID: UUID) async throws {
        // Find the friendship
        let friendships = try await supabase.getFriendships(for: currentUserID)
        guard let friendship = friendships.first(where: {
            ($0.requesterID == friend.id || $0.addresseeID == friend.id)
        }) else {
            return
        }

        try await supabase.deleteFriendship(id: friendship.id)
        friends.removeAll { $0.id == friend.id }
    }

    var friendCount: Int {
        friends.count
    }

    var pendingRequestCount: Int {
        pendingRequests.count
    }
}
