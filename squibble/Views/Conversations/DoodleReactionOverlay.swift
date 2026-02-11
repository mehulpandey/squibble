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
    let preloadedReactionSummary: ReactionSummary?  // Pre-loaded from grid cache
    let preloadedRecipients: [User]?  // Pre-loaded from cache
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
    @State private var recipients: [User] = []
    @State private var isLoadingRecipients = false
    @State private var showRecipientsList = false
    @State private var showForwardSheet = false
    @State private var reactionSummary: ReactionSummary = .empty
    @State private var showReactorsSheet = false

    // Convenience init with default nil for pre-loaded data
    init(
        doodle: Doodle,
        threadItemID: UUID?,
        currentUserID: UUID,
        currentEmoji: String?,
        preloadedReactionSummary: ReactionSummary? = nil,
        preloadedRecipients: [User]? = nil,
        onReactionSelected: @escaping (String) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.doodle = doodle
        self.threadItemID = threadItemID
        self.currentUserID = currentUserID
        self.currentEmoji = currentEmoji
        self.preloadedReactionSummary = preloadedReactionSummary
        self.preloadedRecipients = preloadedRecipients
        self.onReactionSelected = onReactionSelected
        self.onDismiss = onDismiss
    }

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

                // Sender/recipient info
                headerInfo
                    .scaleEffect(isAnimatingIn ? 1.0 : 0.9)
                    .opacity(isAnimatingIn ? 1.0 : 0)

                // Reaction picker - only show for received doodles
                if !isSentByMe {
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
                }

                // Enlarged doodle with overlaid reactions badge
                ZStack(alignment: .bottomTrailing) {
                    CachedAsyncImage(urlString: doodle.imageURL)
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: UIScreen.main.bounds.width - 48)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)

                    // Aggregated reactions badge (for sent doodles) - overlaid on bottom-right
                    if isSentByMe && !reactionSummary.isEmpty {
                        aggregatedReactionsBadge
                            .offset(x: -12, y: -12)
                    }
                }
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

            // Use pre-loaded data if available, otherwise fetch
            if isSentByMe {
                // Use cached data immediately if available
                if let cached = preloadedReactionSummary {
                    reactionSummary = cached
                }
                if let cached = preloadedRecipients {
                    recipients = cached
                }

                // Only fetch what we don't have
                Task {
                    if preloadedRecipients == nil {
                        await loadRecipients()
                    }
                    if preloadedReactionSummary == nil {
                        await loadAggregatedReactions()
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(items: [image])
            }
        }
        .sheet(isPresented: $showRecipientsList) {
            RecipientListSheet(recipients: recipients)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showForwardSheet) {
            ForwardDoodleSheet(doodle: doodle, onDismiss: {
                showForwardSheet = false
            })
        }
        .sheet(isPresented: $showReactorsSheet) {
            ReactorsListSheet(reactions: reactionSummary.reactions)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header Info

    private var headerInfo: some View {
        HStack(spacing: 8) {
            if isSentByMe {
                // Show recipients for sent doodles
                sentToInfo
            } else if let sender = sender {
                // Show sender for received doodles
                Text(sender.displayName)
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(AppTheme.textPrimary)
            }

            Text("•")
                .font(.custom("Avenir-Regular", size: 16))
                .foregroundColor(AppTheme.textTertiary)

            Text(formatDate(doodle.createdAt))
                .font(.custom("Avenir-Regular", size: 16))
                .foregroundColor(AppTheme.textSecondary)
        }
    }

    @ViewBuilder
    private var sentToInfo: some View {
        if isLoadingRecipients {
            Text("Sent to...")
                .font(.custom("Avenir-Heavy", size: 16))
                .foregroundColor(AppTheme.textPrimary)
        } else if recipients.count == 1, let recipient = recipients.first {
            HStack(spacing: 4) {
                Text("Sent to")
                    .font(.custom("Avenir-Regular", size: 16))
                    .foregroundColor(AppTheme.textSecondary)
                Text(recipient.displayName)
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(AppTheme.textPrimary)
            }
        } else if recipients.count > 1 {
            HStack(spacing: 4) {
                Text("Sent to")
                    .font(.custom("Avenir-Regular", size: 16))
                    .foregroundColor(AppTheme.textSecondary)
                Button(action: {
                    showRecipientsList = true
                }) {
                    Text("\(recipients.count) people")
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(AppTheme.primaryStart)
                }
            }
        } else {
            Text("Sent")
                .font(.custom("Avenir-Heavy", size: 16))
                .foregroundColor(AppTheme.textPrimary)
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

            if isSentByMe {
                // Forward button for sent doodles
                Button(action: { showForwardSheet = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrowshape.turn.up.forward.fill")
                            .font(.system(size: 16, weight: .medium))
                        Text("Forward")
                            .font(.custom("Avenir-Heavy", size: 15))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        Capsule()
                            .fill(AppTheme.primaryGradient)
                    )
                    .shadow(color: AppTheme.primaryGlow.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
            } else {
                // Reply button for received doodles
                Button(action: replyToDoodle) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrowshape.turn.up.left.fill")
                            .font(.system(size: 16, weight: .medium))
                        Text("Reply")
                            .font(.custom("Avenir-Heavy", size: 15))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        Capsule()
                            .fill(AppTheme.primaryGradient)
                    )
                    .shadow(color: AppTheme.primaryGlow.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
            }
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

    private func loadRecipients() async {
        isLoadingRecipients = true
        recipients = await ConversationManager.shared.loadRecipients(doodleID: doodle.id)
        isLoadingRecipients = false
    }

    private func loadAggregatedReactions() async {
        reactionSummary = await ConversationManager.shared.loadAggregatedReactions(doodleID: doodle.id)
    }

    /// Tappable aggregated reactions badge for sent doodles
    private var aggregatedReactionsBadge: some View {
        Button(action: { showReactorsSheet = true }) {
            HStack(spacing: 2) {
                // Top emojis (up to 3)
                ForEach(reactionSummary.topEmojis.prefix(3), id: \.self) { emoji in
                    Text(emoji)
                        .font(.system(size: 18))
                }

                // Count
                if reactionSummary.totalCount > 1 {
                    Text("\(reactionSummary.totalCount)")
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.leading, 2)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .opacity(0.8)
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Recipient List Sheet

struct RecipientListSheet: View {
    let recipients: [User]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List(recipients) { recipient in
                HStack(spacing: 12) {
                    // Avatar
                    if let profileURL = recipient.profileImageURL {
                        CachedAsyncImage(urlString: profileURL)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color(hex: recipient.colorHex), lineWidth: 2)
                            )
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color(hex: recipient.colorHex))
                                .frame(width: 44, height: 44)
                            Text(recipient.initials)
                                .font(.custom("Avenir-Heavy", size: 14))
                                .foregroundColor(.white)
                        }
                    }

                    Text(recipient.displayName)
                        .font(.custom("Avenir-Medium", size: 17))
                        .foregroundColor(AppTheme.textPrimary)

                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .navigationTitle("Sent to")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.primaryStart)
                }
            }
        }
    }
}

// MARK: - Reactors List Sheet

struct ReactorsListSheet: View {
    let reactions: [AggregatedReaction]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List(reactions) { reaction in
                HStack(spacing: 12) {
                    // Avatar
                    if let profileURL = reaction.profileImageURL {
                        CachedAsyncImage(urlString: profileURL)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color(hex: reaction.colorHex), lineWidth: 2)
                            )
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color(hex: reaction.colorHex))
                                .frame(width: 44, height: 44)
                            Text(String(reaction.displayName.prefix(2)).uppercased())
                                .font(.custom("Avenir-Heavy", size: 14))
                                .foregroundColor(.white)
                        }
                    }

                    // Name
                    Text(reaction.displayName)
                        .font(.custom("Avenir-Medium", size: 17))
                        .foregroundColor(AppTheme.textPrimary)

                    Spacer()

                    // Emoji reaction
                    Text(reaction.emoji)
                        .font(.system(size: 24))
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .navigationTitle("Reactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.primaryStart)
                }
            }
        }
    }
}

// MARK: - Forward Doodle Sheet

struct ForwardDoodleSheet: View {
    let doodle: Doodle
    let onDismiss: () -> Void

    @EnvironmentObject var friendManager: FriendManager
    @EnvironmentObject var doodleManager: DoodleManager
    @EnvironmentObject var authManager: AuthManager

    @State private var selectedFriendIDs: Set<UUID> = []
    @State private var isSending = false
    @State private var showSuccess = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Friend list
                if friendManager.friends.isEmpty {
                    emptyState
                } else {
                    friendList
                }

                // Send button
                if !selectedFriendIDs.isEmpty {
                    sendButton
                        .padding()
                }
            }
            .navigationTitle("Forward Doodle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                        onDismiss()
                    }
                    .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .overlay {
            if showSuccess {
                successOverlay
            }
        }
    }

    private var friendList: some View {
        List(friendManager.friends) { friend in
            Button(action: {
                toggleFriend(friend.id)
            }) {
                HStack(spacing: 12) {
                    // Checkbox
                    Image(systemName: selectedFriendIDs.contains(friend.id) ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(selectedFriendIDs.contains(friend.id) ? AppTheme.primaryStart : AppTheme.textTertiary)

                    // Avatar
                    if let profileURL = friend.profileImageURL {
                        CachedAsyncImage(urlString: profileURL)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color(hex: friend.colorHex), lineWidth: 2)
                            )
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color(hex: friend.colorHex))
                                .frame(width: 44, height: 44)
                            Text(friend.initials)
                                .font(.custom("Avenir-Heavy", size: 14))
                                .foregroundColor(.white)
                        }
                    }

                    Text(friend.displayName)
                        .font(.custom("Avenir-Medium", size: 17))
                        .foregroundColor(AppTheme.textPrimary)

                    Spacer()
                }
            }
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.textTertiary)
            Text("No friends to forward to")
                .font(.custom("Avenir-Medium", size: 17))
                .foregroundColor(AppTheme.textSecondary)
            Spacer()
        }
    }

    private var sendButton: some View {
        Button(action: forwardDoodle) {
            HStack {
                if isSending {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "paperplane.fill")
                    Text("Forward to \(selectedFriendIDs.count) \(selectedFriendIDs.count == 1 ? "friend" : "friends")")
                }
            }
            .font(.custom("Avenir-Heavy", size: 17))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                Capsule()
                    .fill(AppTheme.primaryGradient)
            )
            .shadow(color: AppTheme.primaryGlow.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .disabled(isSending)
    }

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
                Text("Forwarded!")
                    .font(.custom("Avenir-Heavy", size: 20))
                    .foregroundColor(.white)
            }
        }
    }

    private func toggleFriend(_ id: UUID) {
        if selectedFriendIDs.contains(id) {
            selectedFriendIDs.remove(id)
        } else {
            selectedFriendIDs.insert(id)
        }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func forwardDoodle() {
        guard let userID = authManager.currentUserID else { return }

        isSending = true

        Task {
            do {
                // Forward doodle to selected friends (add new recipients)
                try await SupabaseService.shared.addDoodleRecipients(
                    doodleID: doodle.id,
                    recipientIDs: Array(selectedFriendIDs)
                )

                // Create conversations/thread items for each new recipient
                for recipientID in selectedFriendIDs {
                    if let conversationID = try? await SupabaseService.shared.getOrCreateDirectConversation(
                        userA: userID,
                        userB: recipientID
                    ) {
                        try? await SupabaseService.shared.createThreadItemForDoodle(
                            conversationID: conversationID,
                            senderID: userID,
                            doodleID: doodle.id
                        )
                    }
                }

                await MainActor.run {
                    showSuccess = true
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }

                // Dismiss after success
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                await MainActor.run {
                    dismiss()
                    onDismiss()
                }
            } catch {
                print("Failed to forward doodle: \(error)")
                await MainActor.run {
                    isSending = false
                }
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
