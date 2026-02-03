//
//  DoodleDetailView.swift
//  squibble
//
//  Full-screen doodle detail view with actions
//

import SwiftUI

struct DoodleDetailView: View {
    let doodle: Doodle
    let allDoodles: [Doodle]

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var doodleManager: DoodleManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var friendManager: FriendManager
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var navigationManager: NavigationManager

    @State private var currentIndex: Int = 0
    @State private var showDeleteConfirmation = false
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    @State private var isDeleting = false
    @State private var dragOffset: CGFloat = 0

    private var currentDoodle: Doodle {
        allDoodles.indices.contains(currentIndex) ? allDoodles[currentIndex] : doodle
    }

    private var isSentByMe: Bool {
        currentDoodle.senderID == authManager.currentUserID
    }

    private func getSender(for doodle: Doodle) -> User? {
        if doodle.senderID == authManager.currentUserID {
            return userManager.currentUser
        }
        return friendManager.friends.first { $0.id == doodle.senderID }
    }

    private var sender: User? {
        getSender(for: currentDoodle)
    }

    var body: some View {
        GeometryReader { geometry in
            let imageSize = min(geometry.size.width - 48, geometry.size.height * 0.5)

            ZStack {
                // Dark ambient background
                AmbientBackground()

                VStack(spacing: 0) {
                    // Top bar
                    topBar
                        .padding(.top, geometry.safeAreaInsets.top > 0 ? 0 : 8)

                    Spacer()

                    // Doodle carousel with sender info sliding together
                    doodleCarousel(imageSize: imageSize)

                    Spacer()

                    // Action buttons
                    actionButtons
                        .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 16 : 32)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Find initial index
            if let index = allDoodles.firstIndex(where: { $0.id == doodle.id }) {
                currentIndex = index
            }
        }
        .alert("Delete Doodle?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteDoodle()
            }
        } message: {
            Text(isSentByMe
                 ? "This will permanently delete this doodle for everyone."
                 : "This will remove this doodle from your history.")
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(items: [image])
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Close button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(AppTheme.glassBackgroundStrong)
                    .overlay(
                        Circle()
                            .stroke(AppTheme.glassBorder, lineWidth: 1)
                    )
                    .clipShape(Circle())
            }

            Spacer()

            // Page indicator
            if allDoodles.count > 1 {
                Text("\(currentIndex + 1) of \(allDoodles.count)")
                    .font(.custom("Avenir-Medium", size: 14))
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            // Share button
            Button(action: shareDoodle) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(AppTheme.glassBackgroundStrong)
                    .overlay(
                        Circle()
                            .stroke(AppTheme.glassBorder, lineWidth: 1)
                    )
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Doodle Carousel

    private func doodleCarousel(imageSize: CGFloat) -> some View {
        let spacing: CGFloat = 40 // Gap between doodles
        let totalItemWidth = imageSize + spacing

        return VStack(spacing: 24) {
            // Doodles in a horizontal stack that slides
            GeometryReader { geo in
                HStack(spacing: spacing) {
                    ForEach(Array(allDoodles.enumerated()), id: \.element.id) { index, doodle in
                        doodleCard(doodle: doodle, imageSize: imageSize)
                    }
                }
                .offset(x: -CGFloat(currentIndex) * totalItemWidth + dragOffset + (geo.size.width - imageSize) / 2)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation.width
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 50
                            let velocity = value.predictedEndTranslation.width - value.translation.width

                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                if (value.translation.width > threshold || velocity > 100) && currentIndex > 0 {
                                    currentIndex -= 1
                                } else if (value.translation.width < -threshold || velocity < -100) && currentIndex < allDoodles.count - 1 {
                                    currentIndex += 1
                                }
                                dragOffset = 0
                            }
                        }
                )
            }
            .frame(height: imageSize + 60) // Extra space for sender info
        }
    }

    private func doodleCard(doodle: Doodle, imageSize: CGFloat) -> some View {
        let cardSender = getSender(for: doodle)
        let isCardSentByMe = doodle.senderID == authManager.currentUserID

        return VStack(spacing: 16) {
            // Doodle image
            CachedAsyncImage(urlString: doodle.imageURL)
                .aspectRatio(contentMode: .fit)
                .frame(width: imageSize, height: imageSize)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: AppTheme.primaryGlow.opacity(0.3), radius: 24, x: 0, y: 12)

            // Sender info for this doodle
            HStack(spacing: 8) {
                if let sender = cardSender {
                    Text(isCardSentByMe ? "You" : sender.displayName)
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(AppTheme.textPrimary)

                    if isCardSentByMe {
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
        .frame(width: imageSize)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Delete button
            Button(action: { showDeleteConfirmation = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Delete")
                        .font(.custom("Avenir-Heavy", size: 16))
                }
                .foregroundColor(AppTheme.primaryStart)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(AppTheme.primaryStart.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(AppTheme.primaryStart.opacity(0.3), lineWidth: 1)
                )
                .clipShape(Capsule())
            }
            .disabled(isDeleting)

            // Reply button (always shown, but disabled for sent doodles)
            Button(action: replyToDoodle) {
                HStack(spacing: 8) {
                    Image(systemName: "arrowshape.turn.up.left.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Reply")
                        .font(.custom("Avenir-Heavy", size: 16))
                }
                .foregroundColor(isSentByMe ? AppTheme.textTertiary : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    Group {
                        if isSentByMe {
                            AppTheme.buttonInactiveBackground
                        } else {
                            AppTheme.primaryGradient
                        }
                    }
                )
                .overlay(
                    Capsule()
                        .stroke(isSentByMe ? AppTheme.buttonInactiveBorder : Color.clear, lineWidth: 1)
                )
                .clipShape(Capsule())
                .shadow(color: isSentByMe ? .clear : AppTheme.primaryGlow, radius: 12, x: 0, y: 6)
            }
            .disabled(isSentByMe)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Helpers

    private func shareDoodle() {
        // Download image and show share sheet
        guard let url = URL(string: currentDoodle.imageURL) else { return }

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

    private func deleteDoodle() {
        guard let userID = authManager.currentUserID else { return }

        isDeleting = true

        Task {
            do {
                if isSentByMe {
                    // Delete entire doodle (sender)
                    try await doodleManager.deleteSentDoodle(currentDoodle, userID: userID)
                } else {
                    // Remove from received (recipient)
                    try await doodleManager.removeReceivedDoodle(currentDoodle, recipientID: userID)

                    // Update widget with next most recent doodle (or clear if none)
                    await doodleManager.updateWidgetWithLatestDoodle(friends: friendManager.friends)
                }
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Failed to delete doodle: \(error)")
                isDeleting = false
            }
        }
    }

    private func replyToDoodle() {
        // Store the sender ID to pre-select when sending
        if let senderID = sender?.id {
            navigationManager.pendingReplyRecipientID = senderID
        }
        // Switch to Home tab
        navigationManager.selectedTab = .home
        dismiss()
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
    DoodleDetailView(
        doodle: Doodle(
            id: UUID(),
            senderID: UUID(),
            imageURL: "https://example.com/doodle.png",
            createdAt: Date()
        ),
        allDoodles: []
    )
    .environmentObject(DoodleManager())
    .environmentObject(AuthManager())
    .environmentObject(FriendManager())
    .environmentObject(UserManager())
    .environmentObject(NavigationManager())
}
