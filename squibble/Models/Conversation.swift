//
//  Conversation.swift
//  squibble
//
//  Conversation model matching Supabase public.conversations table
//

import Foundation

struct Conversation: Codable, Identifiable, Equatable {
    let id: UUID
    let type: ConversationType
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum ConversationType: String, Codable {
    case direct
    case group
}
