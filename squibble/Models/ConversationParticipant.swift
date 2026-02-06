//
//  ConversationParticipant.swift
//  squibble
//
//  ConversationParticipant model matching Supabase public.conversation_participants table
//

import Foundation

struct ConversationParticipant: Codable, Equatable {
    let conversationID: UUID
    let userID: UUID
    var lastReadAt: Date
    var muted: Bool
    let joinedAt: Date

    enum CodingKeys: String, CodingKey {
        case conversationID = "conversation_id"
        case userID = "user_id"
        case lastReadAt = "last_read_at"
        case muted
        case joinedAt = "joined_at"
    }
}

extension ConversationParticipant: Identifiable {
    // Composite key for Identifiable conformance
    var id: String { "\(conversationID.uuidString)-\(userID.uuidString)" }
}
