//
//  ConversationListView.swift
//  squibble
//
//  Shows list of conversations (chats) for the History tab
//

import SwiftUI

struct ConversationListView: View {
    @EnvironmentObject var conversationManager: ConversationManager
    @EnvironmentObject var authManager: AuthManager

    @State private var selectedConversation: ConversationSummary?

    var body: some View {
        Group {
            if conversationManager.isLoading {
                loadingView
            } else if conversationManager.conversations.isEmpty {
                emptyStateView
            } else {
                conversationList
            }
        }
        .task {
            guard let userID = authManager.currentUserID else { return }
            await conversationManager.loadConversations(for: userID)
        }
        .fullScreenCover(item: $selectedConversation) { conversation in
            ConversationThreadView(conversation: conversation)
        }
    }

    // MARK: - Conversation List

    private var conversationList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(conversationManager.conversations) { conversation in
                    ConversationRow(conversation: conversation)
                        .onTapGesture {
                            selectedConversation = conversation
                        }

                    Rectangle()
                        .fill(AppTheme.divider)
                        .frame(height: 1)
                        .padding(.leading, 76)
                }
            }
            .padding(.horizontal, 20)
        }
        .refreshable {
            guard let userID = authManager.currentUserID else { return }
            await conversationManager.loadConversations(for: userID)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppTheme.glassBackgroundStrong)
                    .frame(width: 100, height: 100)

                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 40))
                    .foregroundColor(AppTheme.primaryStart)
            }

            VStack(spacing: 8) {
                Text("No Conversations")
                    .font(.custom("Avenir-Heavy", size: 20))
                    .foregroundColor(AppTheme.textPrimary)

                Text("Send a doodle to start\na conversation!")
                    .font(.custom("Avenir-Regular", size: 16))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryStart))
                .scaleEffect(1.2)
            Spacer()
        }
    }
}

// MARK: - Conversation Row

struct ConversationRow: View {
    let conversation: ConversationSummary

    private var friendColor: Color {
        Color(hex: conversation.otherParticipant.colorHex.replacingOccurrences(of: "#", with: ""))
    }

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            avatar

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.otherParticipant.displayName)
                        .font(.custom(
                            conversation.unreadCount > 0 ? "Avenir-Heavy" : "Avenir-Medium",
                            size: 17
                        ))
                        .foregroundColor(AppTheme.textPrimary)

                    Spacer()

                    Text(conversation.relativeTime)
                        .font(.custom("Avenir-Regular", size: 14))
                        .foregroundColor(AppTheme.textSecondary)
                }

                HStack {
                    Text(conversation.previewText)
                        .font(.custom("Avenir-Regular", size: 15))
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(1)

                    Spacer()

                    // Unread indicator
                    if conversation.unreadCount > 0 {
                        Circle()
                            .fill(AppTheme.primaryStart)
                            .frame(width: 10, height: 10)
                    }
                }
            }
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var avatar: some View {
        let user = conversation.otherParticipant
        if let profileURL = user.profileImageURL {
            CachedAsyncImage(urlString: profileURL)
                .aspectRatio(contentMode: .fill)
                .frame(width: 52, height: 52)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(friendColor, lineWidth: 2.5)
                )
        } else {
            ZStack {
                Circle()
                    .fill(AppTheme.glassBackgroundStrong)
                    .frame(width: 52, height: 52)

                Text(user.initials)
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .overlay(
                Circle()
                    .stroke(friendColor, lineWidth: 2.5)
            )
        }
    }
}

#Preview {
    ConversationListView()
        .environmentObject(ConversationManager.shared)
        .environmentObject(AuthManager())
}
