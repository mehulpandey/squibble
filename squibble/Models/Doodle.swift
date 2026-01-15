//
//  Doodle.swift
//  squibble
//
//  Doodle model matching Supabase public.doodles table
//

import Foundation

struct Doodle: Codable, Identifiable, Equatable {
    let id: UUID
    let senderID: UUID
    let imageURL: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case senderID = "sender_id"
        case imageURL = "image_url"
        case createdAt = "created_at"
    }
}

enum DoodleType {
    case sent
    case received
}
