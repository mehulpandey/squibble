//
//  DoodleReactionOverlay.swift
//  squibble
//
//  Unified fullscreen overlay for viewing doodles
//  Shows enlarged doodle with reactions, actions (save, share, delete, reply)
//

import SwiftUI

struct DoodleReactionOverlay: View {
    let doodle: Doodle
    let threadItemID: UUID?  // nil if viewing from grid (not in a conversation context)
    let currentUserID: UUID
    let currentEmoji: String?
    let onReactionSelected: (String) -> Void
    let onDismiss: () -> Void

    @EnvironmentObject var doodleManager: DoodleManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var friendManager: FriendManager
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var navigationManager: NavigationManager

    @State private var isAnimatingIn = false
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    @State private var selectedEmoji: String?  // For immediate visual feedback

    private var isSentByMe: Bool {
        doodle.senderID == currentUserID
    }

    private var sender: User? {
        if doodle.senderID == currentUserID {
            return userManager.currentUser
        }
        return friendManager.friends.first { $0.id == doodle.senderID }
    }

    var body: some View {
        ZStack {
            // Blurred and darkened background
            VisualEffectBlur(blurStyle: .dark)
                .opacity(0.95)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithAnimation()
                }

            // Content - centered in full screen
            VStack(spacing: 16) {
                Spacer()

                // Sender info
                senderInfo
                    .scaleEffect(isAnimatingIn ? 1.0 : 0.9)
                    .opacity(isAnimatingIn ? 1.0 : 0)

                // Reaction picker
                ReactionPicker(
                    currentEmoji: selectedEmoji ?? currentEmoji,
                    onSelect: { emoji in
                        // Immediate visual feedback
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedEmoji = emoji
                        }
                        // Haptic feedback
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        // Send reaction
                        onReactionSelected(emoji)
                        // Auto-dismiss quickly
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            dismissWithAnimation()
                        }
                    },
                    onDismiss: {
                        dismissWithAnimation()
                    }
                )
                .scaleEffect(isAnimatingIn ? 1.0 : 0.8)
                .opacity(isAnimatingIn ? 1.0 : 0)

                // Enlarged doodle
                CachedAsyncImage(urlString: doodle.imageURL)
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: UIScreen.main.bounds.width - 48)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                    .scaleEffect(isAnimatingIn ? 1.0 : 0.7)
                    .opacity(isAnimatingIn ? 1.0 : 0)

                // Action buttons (Delete / Reply)
                actionButtons
                    .scaleEffect(isAnimatingIn ? 1.0 : 0.9)
                    .opacity(isAnimatingIn ? 1.0 : 0)

                Spacer()
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .onAppear {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isAnimatingIn = true
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(items: [image])
            }
        }
    }

    // MARK: - Sender Info

    private var senderInfo: some View {
        HStack(spacing: 8) {
            if let sender = sender {
                Text(isSentByMe ? "You" : sender.displayName)
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(AppTheme.textPrimary)

                if isSentByMe {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.primaryStart)
                }

                Text("•")
                    .font(.custom("Avenir-Regular", size: 16))
                    .foregroundColor(AppTheme.textTertiary)

                Text(formatDate(doodle.createdAt))
                    .font(.custom("Avenir-Regular", size: 16))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Share button
            Button(action: shareDoodle) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                    Text("Share")
                        .font(.custom("Avenir-Heavy", size: 15))
                }
                .foregroundColor(AppTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
            }
            .buttonStyle(ScaleButtonStyle())

            // Reply button
            Button(action: replyToDoodle) {
                HStack(spacing: 8) {
                    Image(systemName: "arrowshape.turn.up.left.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text("Reply")
                        .font(.custom("Avenir-Heavy", size: 15))
                }
                .foregroundColor(isSentByMe ? AppTheme.textTertiary : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    Group {
                        if isSentByMe {
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                        } else {
                            Capsule()
                                .fill(AppTheme.primaryGradient)
                        }
                    }
                )
                .overlay(
                    Capsule()
                        .stroke(isSentByMe ? Color.white.opacity(0.15) : Color.clear, lineWidth: 1)
                )
                .shadow(color: isSentByMe ? .clear : AppTheme.primaryGlow.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .disabled(isSentByMe)
            .buttonStyle(ScaleButtonStyle())
        }
    }

    // MARK: - Helpers

    private func dismissWithAnimation() {
        withAnimation(.easeOut(duration: 0.2)) {
            isAnimatingIn = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func shareDoodle() {
        guard let url = URL(string: doodle.imageURL) else { return }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        shareImage = image
                        showShareSheet = true
                    }
                }
            } catch {
                print("Failed to download image for sharing: \(error)")
            }
        }
    }

    private func replyToDoodle() {
        // Store the sender ID to pre-select when sending
        if let senderID = sender?.id {
            navigationManager.pendingReplyRecipientID = senderID
        }
        // Dismiss first, then switch tab smoothly
        dismissWithAnimation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeInOut(duration: 0.3)) {
                navigationManager.selectedTab = .home
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        DoodleReactionOverlay(
            doodle: Doodle(
                id: UUID(),
                senderID: UUID(),
                imageURL: "https://example.com/doodle.png",
                createdAt: Date()
            ),
            threadItemID: UUID(),
            currentUserID: UUID(),
            currentEmoji: nil,
            onReactionSelected: { _ in },
            onDismiss: {}
        )
        .environmentObject(DoodleManager())
        .environmentObject(AuthManager())
        .environmentObject(FriendManager())
        .environmentObject(UserManager())
        .environmentObject(NavigationManager())
    }
}
