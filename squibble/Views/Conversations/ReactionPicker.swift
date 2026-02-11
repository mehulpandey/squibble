//
//  ReactionPicker.swift
//  squibble
//
//  Horizontal emoji picker for reactions
//

import SwiftUI

struct ReactionPicker: View {
    let currentEmoji: String?  // Currently selected emoji (if any)
    let onSelect: (String) -> Void
    let onDismiss: () -> Void

    private let emojis = ReactionEmoji.allCases.map { $0.rawValue }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(emojis, id: \.self) { emoji in
                Button(action: {
                    onSelect(emoji)
                }) {
                    Text(emoji)
                        .font(.system(size: 28))
                        .padding(8)
                        .background(
                            Circle()
                                .fill(emoji == currentEmoji ? Color.white.opacity(0.2) : Color.clear)
                        )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Reaction Display

/// Shows reactions below a thread item
struct ReactionDisplay: View {
    let reactions: [Reaction]
    let isGroupChat: Bool

    var body: some View {
        if reactions.isEmpty {
            EmptyView()
        } else if isGroupChat {
            // Group chat: show aggregated counts
            groupReactionDisplay
        } else {
            // 1:1 chat: just show emojis
            directReactionDisplay
        }
    }

    private var directReactionDisplay: some View {
        HStack(spacing: 3) {
            ForEach(uniqueEmojis, id: \.self) { emoji in
                Text(emoji)
                    .font(.system(size: 16))
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .opacity(0.8)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                    )
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
        }
    }

    private var groupReactionDisplay: some View {
        HStack(spacing: 3) {
            ForEach(emojiCounts, id: \.emoji) { item in
                ZStack {
                    Text(item.emoji)
                        .font(.system(size: 16))

                    // Count badge for multiple reactions
                    if item.count > 1 {
                        VStack {
                            HStack {
                                Spacer()
                                Text("\(item.count)")
                                    .font(.custom("Avenir-Heavy", size: 9))
                                    .foregroundColor(.white)
                                    .frame(width: 14, height: 14)
                                    .background(Circle().fill(Color.black.opacity(0.5)))
                                    .offset(x: 6, y: -6)
                            }
                            Spacer()
                        }
                    }
                }
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.8)
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                )
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
        }
    }

    private var uniqueEmojis: [String] {
        Array(Set(reactions.map { $0.emoji }))
    }

    private var emojiCounts: [(emoji: String, count: Int)] {
        var counts: [String: Int] = [:]
        for reaction in reactions {
            counts[reaction.emoji, default: 0] += 1
        }
        return counts.map { (emoji: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 30) {
            ReactionPicker(
                currentEmoji: nil,
                onSelect: { _ in },
                onDismiss: {}
            )

            ReactionPicker(
                currentEmoji: "❤️",
                onSelect: { _ in },
                onDismiss: {}
            )

            // Direct chat reactions
            ReactionDisplay(
                reactions: [
                    Reaction(id: UUID(), threadItemID: UUID(), userID: UUID(), emoji: "❤️", createdAt: Date())
                ],
                isGroupChat: false
            )

            // Group chat reactions
            ReactionDisplay(
                reactions: [
                    Reaction(id: UUID(), threadItemID: UUID(), userID: UUID(), emoji: "❤️", createdAt: Date()),
                    Reaction(id: UUID(), threadItemID: UUID(), userID: UUID(), emoji: "❤️", createdAt: Date()),
                    Reaction(id: UUID(), threadItemID: UUID(), userID: UUID(), emoji: "😂", createdAt: Date())
                ],
                isGroupChat: true
            )
        }
    }
}
