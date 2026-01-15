//
//  User.swift
//  squibble
//
//  User model matching Supabase public.users table
//

import Foundation

struct User: Codable, Identifiable, Equatable {
    let id: UUID
    var displayName: String
    var profileImageURL: String?
    var colorHex: String
    var isPremium: Bool
    var streak: Int
    var totalDoodlesSent: Int
    var deviceToken: String?
    var inviteCode: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case profileImageURL = "profile_image_url"
        case colorHex = "color_hex"
        case isPremium = "is_premium"
        case streak
        case totalDoodlesSent = "total_doodles_sent"
        case deviceToken = "device_token"
        case inviteCode = "invite_code"
        case createdAt = "created_at"
    }

    var initials: String {
        let components = displayName.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(displayName.prefix(2)).uppercased()
    }
}
