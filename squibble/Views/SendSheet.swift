//
//  SendSheet.swift
//  squibble
//
//  Send doodle sheet with friend selection
//

import SwiftUI

struct SendSheet: View {
    @ObservedObject var drawingState: DrawingState
    @Binding var isPresented: Bool
    var onAddFriends: (() -> Void)? = nil

    @EnvironmentObject var friendManager: FriendManager
    @EnvironmentObject var doodleManager: DoodleManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var userManager: UserManager

    @State private var selectedFriendIDs: Set<UUID> = []
    @State private var isSending = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false

    private var canvasSize: CGSize {
        CGSize(width: 300, height: 300)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if friendManager.friends.isEmpty {
                    // Empty state
                    emptyFriendsView
                } else {
                    // Friend list
                    friendListView
                }

                Spacer(minLength: 0)

                // Send button
                sendButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
            .navigationTitle("Send to...")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(AppTheme.primaryStart)
                }
            }
        }
        .overlay(
            Group {
                if showSuccess {
                    successOverlay
                }
            }
        )
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // Pre-select reply recipient if coming from Reply action
            if let replyRecipientID = navigationManager.pendingReplyRecipientID {
                selectedFriendIDs.insert(replyRecipientID)
                navigationManager.clearPendingReplyRecipient()
            }
        }
    }

    // MARK: - Empty Friends View

    private var emptyFriendsView: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppTheme.glassBackgroundStrong)
                    .frame(width: 100, height: 100)

                Image(systemName: "person.2.fill")
                    .font(.system(size: 40))
                    .foregroundColor(AppTheme.primaryStart)
            }

            VStack(spacing: 8) {
                Text("No Friends Yet")
                    .font(.custom("Avenir-Heavy", size: 20))
                    .foregroundColor(AppTheme.textPrimary)

                Text("Add friends to send them\nyour doodles!")
                    .font(.custom("Avenir-Regular", size: 16))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                onAddFriends?()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Add Friends")
                        .font(.custom("Avenir-Heavy", size: 16))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(AppTheme.primaryGradient)
                .clipShape(Capsule())
                .shadow(color: AppTheme.primaryGlow, radius: 12, x: 0, y: 4)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Friend List View

    private var friendListView: some View {
        List {
            // Select All row
            Button(action: toggleSelectAll) {
                HStack {
                    Text("Select All")
                        .font(.custom("Avenir-Medium", size: 17))
                        .foregroundColor(AppTheme.textPrimary)

                    Spacer()

                    Image(systemName: allSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(allSelected ? AppTheme.secondary : AppTheme.textTertiary)
                }
            }
            .listRowBackground(Color.clear)

            // Friend list
            ForEach(friendManager.friends) { friend in
                Button(action: { toggleFriend(friend) }) {
                    HStack(spacing: 12) {
                        // Avatar
                        friendAvatar(for: friend)

                        // Name
                        Text(friend.displayName)
                            .font(.custom("Avenir-Medium", size: 17))
                            .foregroundColor(AppTheme.textPrimary)

                        Spacer()

                        // Checkbox on the right
                        Image(systemName: selectedFriendIDs.contains(friend.id) ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 24))
                            .foregroundColor(selectedFriendIDs.contains(friend.id) ? AppTheme.secondary : AppTheme.textTertiary)
                    }
                }
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
    }

    @ViewBuilder
    private func friendAvatar(for friend: User) -> some View {
        let friendColor = Color(hex: friend.colorHex.replacingOccurrences(of: "#", with: ""))

        if let profileURL = friend.profileImageURL {
            CachedAsyncImage(urlString: profileURL)
                .aspectRatio(contentMode: .fill)
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(friendColor, lineWidth: 2)
                )
        } else {
            ZStack {
                Circle()
                    .fill(friendColor)
                    .frame(width: 44, height: 44)
                Text(friend.initials)
                    .font(.custom("Avenir-Heavy", size: 14))
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Send Button

    private var sendButton: some View {
        Button(action: sendDoodle) {
            ZStack {
                if isSending {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18, weight: .semibold))

                        Text(sendButtonText)
                            .font(.custom("Avenir-Heavy", size: 18))
                    }
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Group {
                    if selectedFriendIDs.isEmpty || isSending {
                        AppTheme.buttonInactiveBackground
                    } else {
                        // Use secondary (mustard yellow) for Send confirmation
                        LinearGradient(
                            colors: [AppTheme.secondary, AppTheme.secondary.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                }
            )
            .overlay(
                Capsule()
                    .stroke(selectedFriendIDs.isEmpty ? AppTheme.buttonInactiveBorder : Color.clear, lineWidth: 1)
            )
            .clipShape(Capsule())
            .shadow(
                color: selectedFriendIDs.isEmpty ? .clear : AppTheme.secondaryGlow,
                radius: 16,
                x: 0,
                y: 4
            )
        }
        .disabled(selectedFriendIDs.isEmpty || isSending)
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.secondary, AppTheme.secondary.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: AppTheme.secondaryGlow, radius: 20, x: 0, y: 4)

                    Image(systemName: "checkmark")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(showSuccess ? 1 : 0.5)
                .opacity(showSuccess ? 1 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showSuccess)

                Text("Sent!")
                    .font(.custom("Avenir-Heavy", size: 28))
                    .foregroundColor(AppTheme.textPrimary)
                    .opacity(showSuccess ? 1 : 0)
                    .animation(.easeOut.delay(0.2), value: showSuccess)
            }
        }
        .transition(.opacity)
    }

    // MARK: - Helpers

    private var allSelected: Bool {
        !friendManager.friends.isEmpty &&
        selectedFriendIDs.count == friendManager.friends.count
    }

    private var sendButtonText: String {
        if selectedFriendIDs.isEmpty {
            return "Select friends to send"
        } else if selectedFriendIDs.count == 1 {
            return "Send to 1 friend"
        } else {
            return "Send to \(selectedFriendIDs.count) friends"
        }
    }

    private func toggleSelectAll() {
        if allSelected {
            selectedFriendIDs.removeAll()
        } else {
            selectedFriendIDs = Set(friendManager.friends.map { $0.id })
        }
    }

    private func toggleFriend(_ friend: User) {
        HapticManager.selectionChanged()
        if selectedFriendIDs.contains(friend.id) {
            selectedFriendIDs.remove(friend.id)
        } else {
            selectedFriendIDs.insert(friend.id)
        }
    }

    private func sendDoodle() {
        guard let userID = authManager.currentUserID else { return }
        guard !selectedFriendIDs.isEmpty else { return }

        isSending = true

        Task {
            do {
                // Export drawing to JPEG with proper scaling from original canvas size
                let originalSize = drawingState.currentCanvasSize.width > 0 ? drawingState.currentCanvasSize : nil
                guard let imageData = drawingState.exportToJPEG(size: canvasSize, originalCanvasSize: originalSize) else {
                    throw SendError.exportFailed
                }

                // Get the last sent date before sending (for streak calculation)
                let lastSentDate = doodleManager.sentDoodles.first?.createdAt

                // Send doodle via DoodleManager
                try await doodleManager.sendDoodle(
                    senderID: userID,
                    imageData: imageData,
                    recipientIDs: Array(selectedFriendIDs)
                )

                // Update user stats (doodles sent count and streak)
                do {
                    try await userManager.recordDoodleSent(lastSentDate: lastSentDate)
                } catch {
                    print("Failed to update user stats: \(error)")
                    // Don't fail the whole send if stats update fails
                }

                // Show success with haptic feedback
                HapticManager.success()
                withAnimation {
                    showSuccess = true
                }

                // Clear canvas and dismiss after delay
                try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds

                drawingState.clearAll()
                isPresented = false

            } catch {
                HapticManager.error()
                isSending = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

enum SendError: LocalizedError {
    case exportFailed

    var errorDescription: String? {
        switch self {
        case .exportFailed:
            return "Failed to export your doodle. Please try again."
        }
    }
}

#Preview {
    SendSheet(
        drawingState: DrawingState(),
        isPresented: .constant(true)
    )
    .environmentObject(FriendManager())
    .environmentObject(DoodleManager())
    .environmentObject(AuthManager())
    .environmentObject(NavigationManager())
    .environmentObject(UserManager())
}
