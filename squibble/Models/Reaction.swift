//
//  Reaction.swift
//  squibble
//
//  Reaction model matching Supabase public.reactions table
//  Represents an emoji reaction to a thread item
//

import Foundation

struct Reaction: Codable, Identifiable, Equatable {
    let id: UUID
    let threadItemID: UUID
    let userID: UUID
    let emoji: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case threadItemID = "thread_item_id"
        case userID = "user_id"
        case emoji
        case createdAt = "created_at"
    }
}

// Available reaction emojis
enum ReactionEmoji: String, CaseIterable {
    case heart = "❤️"
    case laugh = "😂"
    case wow = "😮"
    case sad = "😢"
    case fire = "🔥"
    case thumbsUp = "👍"
}
