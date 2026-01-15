//
//  DoodleRecipient.swift
//  squibble
//
//  DoodleRecipient model matching Supabase public.doodle_recipients table
//

import Foundation

struct DoodleRecipient: Codable, Identifiable, Equatable {
    let id: UUID
    let doodleID: UUID
    let recipientID: UUID
    var viewedAt: Date?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case doodleID = "doodle_id"
        case recipientID = "recipient_id"
        case viewedAt = "viewed_at"
        case createdAt = "created_at"
    }
}
