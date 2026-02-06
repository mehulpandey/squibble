//
//  ThreadItem.swift
//  squibble
//
//  ThreadItem model matching Supabase public.thread_items table
//  Represents a single item in a conversation thread (doodle or text)
//

import Foundation

struct ThreadItem: Codable, Identifiable, Equatable {
    let id: UUID
    let conversationID: UUID
    let senderID: UUID
    let type: ThreadItemType
    let doodleID: UUID?
    let textContent: String?
    let replyToItemID: UUID?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case conversationID = "conversation_id"
        case senderID = "sender_id"
        case type
        case doodleID = "doodle_id"
        case textContent = "text_content"
        case replyToItemID = "reply_to_item_id"
        case createdAt = "created_at"
    }
}

enum ThreadItemType: String, Codable {
    case doodle
    case text
}
