//
//  ChatSettingsView.swift
//  squibble
//
//  Settings sheet for a conversation (mute, unfriend)
//

import SwiftUI

struct ChatSettingsView: View {
    let conversation: ConversationSummary

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var conversationManager: ConversationManager
    @EnvironmentObject var friendManager: FriendManager
    @EnvironmentObject var authManager: AuthManager

    @State private var showUnfriendConfirmation = false
    @State private var isUnfriending = false
    @State private var isMuted: Bool

    init(conversation: ConversationSummary) {
        self.conversation = conversation
        self._isMuted = State(initialValue: conversation.muted)
    }

    private var friendColor: Color {
        Color(hex: conversation.otherParticipant.colorHex.replacingOccurrences(of: "#", with: ""))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(AppTheme.textTertiary.opacity(0.5))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)

            // Avatar and name
            VStack(spacing: 12) {
                avatar

                Text(conversation.otherParticipant.displayName)
                    .font(.custom("Avenir-Heavy", size: 22))
                    .foregroundColor(AppTheme.textPrimary)
            }
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

                // Unfriend button
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

                        if isUnfriending {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryStart))
                                .scaleEffect(0.8)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
                .disabled(isUnfriending)
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
        isUnfriending = true

        Task {
            do {
                try await friendManager.removeFriend(
                    conversation.otherParticipant,
                    currentUserID: userID
                )
                dismiss()
            } catch {
                print("Error unfriending: \(error)")
                isUnfriending = false
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
