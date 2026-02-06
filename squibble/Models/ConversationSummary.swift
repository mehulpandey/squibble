//
//  ConversationSummary.swift
//  squibble
//
//  View model for displaying conversation in the conversation list
//  Combines conversation, participant info, and latest item data
//

import Foundation

struct ConversationSummary: Identifiable, Equatable {
    let id: UUID
    let type: ConversationType
    let updatedAt: Date
    let otherParticipant: User        // The other user in a direct conversation
    let lastItem: ThreadItem?         // Most recent thread item
    let lastDoodle: Doodle?           // Resolved doodle (if last item is a doodle)
    let unreadCount: Int
    let muted: Bool

    /// Preview text for the conversation list
    var previewText: String {
        guard let lastItem = lastItem else {
            return "Start a conversation"
        }

        switch lastItem.type {
        case .doodle:
            if lastItem.senderID == otherParticipant.id {
                return "Sent you a doodle"
            } else {
                return "You sent a doodle"
            }
        case .text:
            if let text = lastItem.textContent {
                // Truncate long text
                let maxLength = 40
                if text.count > maxLength {
                    return String(text.prefix(maxLength)) + "..."
                }
                return text
            }
            return "Sent a message"
        }
    }

    /// Formatted relative time for display
    var relativeTime: String {
        let now = Date()
        let interval = now.timeIntervalSince(updatedAt)

        if interval < 60 {
            return "now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days)d"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: updatedAt)
        }
    }
}
