//
//  AggregatedReaction.swift
//  squibble
//
//  Model for aggregated reactions across all thread_items for a doodle
//  Used when displaying reactions for doodles sent to multiple recipients
//

import Foundation

/// Represents a single reaction with user info, from the aggregated reactions RPC
struct AggregatedReaction: Codable, Equatable, Identifiable {
    var id: UUID { userID }  // Use userID as identifier since one reaction per user per doodle

    let doodleID: UUID
    let userID: UUID
    let displayName: String
    let profileImageURL: String?
    let colorHex: String
    let emoji: String

    enum CodingKeys: String, CodingKey {
        case doodleID = "doodle_id"
        case userID = "user_id"
        case displayName = "display_name"
        case profileImageURL = "profile_image_url"
        case colorHex = "color_hex"
        case emoji
    }
}

/// Summary of reactions for a doodle, used for badge display
struct ReactionSummary: Equatable {
    /// Top emojis sorted by frequency (up to 3)
    let topEmojis: [String]
    /// Total number of reactions
    let totalCount: Int
    /// Full list of reactions for the popup
    let reactions: [AggregatedReaction]

    var isEmpty: Bool { reactions.isEmpty }

    static let empty = ReactionSummary(topEmojis: [], totalCount: 0, reactions: [])
}
