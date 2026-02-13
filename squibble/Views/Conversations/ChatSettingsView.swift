//
//  ChatSettingsView.swift
//  squibble
//
//  Settings sheet for a conversation (mute, unfriend)
//

import SwiftUI

struct ChatSettingsView: View {
    let conversation: ConversationSummary
    var onUnfriend: (() -> Void)?  // Called when unfriending completes

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var conversationManager: ConversationManager
    @EnvironmentObject var friendManager: FriendManager
    @EnvironmentObject var authManager: AuthManager

    @State private var showUnfriendConfirmation = false
    @State private var isProcessing = false
    @State private var isMuted: Bool
    @State private var showAddFriendSuccess = false

    /// Check if the other participant is currently a friend
    private var isFriend: Bool {
        friendManager.friends.contains { $0.id == conversation.otherParticipant.id }
    }

    init(conversation: ConversationSummary, onUnfriend: (() -> Void)? = nil) {
        self.conversation = conversation
        self.onUnfriend = onUnfriend
        self._isMuted = State(initialValue: conversation.muted)
    }

    private var friendColor: Color {
        Color(hex: conversation.otherParticipant.colorHex.replacingOccurrences(of: "#", with: ""))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Avatar and name
            VStack(spacing: 12) {
                avatar

                Text(conversation.otherParticipant.displayName)
                    .font(.custom("Avenir-Heavy", size: 22))
                    .foregroundColor(AppTheme.textPrimary)
            }
            .padding(.top, 24)
            .padding(.bottom, 24)

            // Settings options
            VStack(spacing: 0) {
                // Mute toggle
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: isMuted ? "bell.slash.fill" : "bell.fill")
                            .font(.system(size: 18))
                            .foregroundColor(AppTheme.textSecondary)
                            .frame(width: 24)

                        Text("Mute Notifications")
                            .font(.custom("Avenir-Medium", size: 17))
                            .foregroundColor(AppTheme.textPrimary)
                    }

                    Spacer()

                    Toggle("", isOn: $isMuted)
                        .tint(AppTheme.secondary)
                        .labelsHidden()
                        .onChange(of: isMuted) { newValue in
                            toggleMute()
                        }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)

                Rectangle()
                    .fill(AppTheme.divider)
                    .frame(height: 1)
                    .padding(.horizontal, 24)

                // Friend action button (Unfriend or Add Friend)
                if isFriend {
                    Button(action: { showUnfriendConfirmation = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "person.badge.minus")
                                .font(.system(size: 18))
                                .foregroundColor(AppTheme.primaryStart)
                                .frame(width: 24)

                            Text("Unfriend")
                                .font(.custom("Avenir-Medium", size: 17))
                                .foregroundColor(AppTheme.primaryStart)

                            Spacer()

                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryStart))
                                    .scaleEffect(0.8)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }
                    .disabled(isProcessing)
                } else {
                    Button(action: { addFriend() }) {
                        HStack(spacing: 12) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 18))
                                .foregroundColor(AppTheme.secondary)
                                .frame(width: 24)

                            Text("Add Friend")
                                .font(.custom("Avenir-Medium", size: 17))
                                .foregroundColor(AppTheme.secondary)

                            Spacer()

                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.secondary))
                                    .scaleEffect(0.8)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }
                    .disabled(isProcessing)
                }
            }

            Spacer()
        }
        .alert("Unfriend?", isPresented: $showUnfriendConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Unfriend", role: .destructive) {
                unfriend()
            }
        } message: {
            Text("You will no longer be able to send doodles to each other.")
        }
        .alert("Friend Request Sent", isPresented: $showAddFriendSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your friend request has been sent to \(conversation.otherParticipant.displayName).")
        }
    }

    @ViewBuilder
    private var avatar: some View {
        let user = conversation.otherParticipant
        if let profileURL = user.profileImageURL {
            CachedAsyncImage(urlString: profileURL)
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(friendColor, lineWidth: 3)
                )
        } else {
            ZStack {
                Circle()
                    .fill(AppTheme.glassBackgroundStrong)
                    .frame(width: 80, height: 80)

                Text(user.initials)
                    .font(.custom("Avenir-Heavy", size: 28))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .overlay(
                Circle()
                    .stroke(friendColor, lineWidth: 3)
            )
        }
    }

    private func toggleMute() {
        guard let userID = authManager.currentUserID else { return }
        Task {
            await conversationManager.toggleMute(
                conversationID: conversation.id,
                userID: userID
            )
        }
    }

    private func unfriend() {
        guard let userID = authManager.currentUserID else { return }
        isProcessing = true

        Task {
            do {
                try await friendManager.removeFriend(
                    conversation.otherParticipant,
                    currentUserID: userID
                )
                dismiss()
                // Call callback to dismiss parent thread view
                onUnfriend?()
            } catch {
                print("Error unfriending: \(error)")
                isProcessing = false
            }
        }
    }

    private func addFriend() {
        guard let userID = authManager.currentUserID else { return }
        isProcessing = true

        Task {
            do {
                // Fetch full user data to get their invite code
                // (conversation summary doesn't include invite_code)
                guard let fullUser = try await SupabaseService.shared.getUser(id: conversation.otherParticipant.id) else {
                    print("Error: Could not fetch user data")
                    isProcessing = false
                    return
                }

                _ = try await friendManager.sendFriendRequest(
                    from: userID,
                    toInviteCode: fullUser.inviteCode
                )
                isProcessing = false
                showAddFriendSuccess = true
            } catch {
                print("Error sending friend request: \(error)")
                isProcessing = false
            }
        }
    }
}

#Preview {
    let mockUser = User(
        id: UUID(),
        displayName: "Alex",
        profileImageURL: nil,
        colorHex: "#007AFF",
        isPremium: false,
        streak: 5,
        totalDoodlesSent: 10,
        deviceToken: nil,
        inviteCode: "ABC123",
        createdAt: Date()
    )

    let mockConversation = ConversationSummary(
        id: UUID(),
        type: .direct,
        updatedAt: Date(),
        otherParticipant: mockUser,
        lastItem: nil,
        lastDoodle: nil,
        unreadCount: 0,
        muted: false
    )

    return ChatSettingsView(conversation: mockConversation)
        .environmentObject(ConversationManager.shared)
        .environmentObject(FriendManager())
        .environmentObject(AuthManager())
        .presentationBackground(AppTheme.modalGradient)
}
