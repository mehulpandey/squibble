//
//  Friendship.swift
//  squibble
//
//  Friendship model matching Supabase public.friendships table
//

import Foundation

struct Friendship: Codable, Identifiable, Equatable {
    let id: UUID
    let requesterID: UUID
    let addresseeID: UUID
    var status: FriendshipStatus
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case requesterID = "requester_id"
        case addresseeID = "addressee_id"
        case status
        case createdAt = "created_at"
    }
}

enum FriendshipStatus: String, Codable {
    case pending
    case accepted
}
