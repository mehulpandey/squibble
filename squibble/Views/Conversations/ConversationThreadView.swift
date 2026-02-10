//
//  ConversationThreadView.swift
//  squibble
//
//  Shows the conversation thread between the current user and another user
//

import SwiftUI

struct ConversationThreadView: View {
    let conversation: ConversationSummary

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var conversationManager: ConversationManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var navigationManager: NavigationManager

    @State private var showSettings = false
    @State private var messageText = ""
    @State private var isSendingMessage = false
    @FocusState private var isTextFieldFocused: Bool

    // Doodle action overlay state
    @State private var selectedDoodle: Doodle?
    @State private var selectedDoodleItemID: UUID?
    @State private var hasScrolledToBottom = false

    // Time gap threshold for showing timestamps (1 hour)
    private let timestampGapThreshold: TimeInterval = 3600

    private var safeAreaTop: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 0
    }

    var body: some View {
        ZStack {
            AmbientBackground()

            // Thread content (full screen, scrolls behind header and action bar)
            threadContent

            // Floating header at top
            VStack {
                floatingHeader
                Spacer()
            }

            // Floating action bar at bottom
            VStack {
                Spacer()
                floatingActionBar
            }

            // Unified doodle action overlay
            if let doodle = selectedDoodle, let userID = authManager.currentUserID {
                DoodleReactionOverlay(
                    doodle: doodle,
                    threadItemID: selectedDoodleItemID,
                    currentUserID: userID,
                    currentEmoji: currentUserReactionEmoji,
                    onReactionSelected: { emoji in
                        handleReactionSelection(emoji)
                    },
                    onDismiss: {
                        selectedDoodle = nil
                        selectedDoodleItemID = nil
                    }
                )
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarHidden(true)
        .task {
            await conversationManager.loadThread(conversationID: conversation.id)
            if let userID = authManager.currentUserID {
                await conversationManager.markAsRead(
                    conversationID: conversation.id,
                    userID: userID
                )
            }
        }
        .onDisappear {
            conversationManager.clearCurrentThread()
        }
        .sheet(isPresented: $showSettings) {
            ChatSettingsView(conversation: conversation)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(AppTheme.modalGradient)
        }
    }

    // MARK: - Floating Header

    private var floatingHeader: some View {
        ZStack(alignment: .top) {
            // Semi-transparent background
            AppTheme.backgroundTop.opacity(0.95)

            // Content layer
            HStack {
                // Back button
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())

                Spacer()

                // Centered avatar + name
                HStack(spacing: 10) {
                    avatarView(for: conversation.otherParticipant, size: 32)

                    Text(conversation.otherParticipant.displayName)
                        .font(.custom("Avenir-Heavy", size: 17))
                        .foregroundColor(AppTheme.textPrimary)
                }

                Spacer()

                // Settings button
                Button(action: { showSettings = true }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .padding(.top, safeAreaTop + 8)
        }
        .frame(height: safeAreaTop + 60)
    }

    // MARK: - Thread Content

    private var threadContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    // Top padding for floating header
                    Color.clear.frame(height: safeAreaTop + 60)

                    let items = conversationManager.currentConversationItems.reversed()
                    let itemsArray = Array(items)

                    ForEach(Array(itemsArray.enumerated()), id: \.element.id) { index, item in
                        VStack(spacing: 8) {
                            // Show timestamp if needed (first item or time gap)
                            if shouldShowTimestamp(for: index, in: itemsArray) {
                                timestampView(for: item.createdAt)
                                    .padding(.top, index == 0 ? 0 : 16)
                                    .padding(.bottom, 8)
                            }

                            ThreadItemBubble(
                                item: item,
                                doodle: item.doodleID.flatMap { conversationManager.currentConversationDoodles[$0] },
                                isFromMe: item.senderID == authManager.currentUserID,
                                otherUser: conversation.otherParticipant,
                                showAvatar: shouldShowAvatar(for: index, in: itemsArray),
                                reactions: conversationManager.currentConversationReactions[item.id] ?? [],
                                isGroupChat: conversation.type == .group,
                                onTapDoodle: { doodle in
                                    selectedDoodle = doodle
                                    selectedDoodleItemID = item.id
                                }
                            )
                        }
                        .id(item.id)
                    }

                    // Bottom padding for floating action bar + keyboard space
                    Color.clear
                        .frame(height: 80)
                        .id("bottomAnchor")
                }
                .padding(.horizontal, 16)
            }
            .scrollDismissesKeyboard(.interactively)
            // Fade content behind send bar
            // Send bar: 12px bottom padding + ~52px bar = ~64px from bottom
            // Midpoint of bar: ~38px from bottom
            // Fade should be subtle and only cover the send bar area
            .mask(
                VStack(spacing: 0) {
                    Color.black // Fully visible content
                    LinearGradient(
                        colors: [Color.black, Color.black.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 30) // Short fade zone
                    Color.clear
                        .frame(height: 25) // Hidden zone (below send bar midpoint)
                }
            )
            .onChange(of: isTextFieldFocused) { focused in
                if focused {
                    // Scroll to bottom when keyboard appears
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo("bottomAnchor", anchor: .bottom)
                    }
                }
            }
            .onChange(of: conversationManager.currentConversationItems.count) { newCount in
                // Scroll to bottom when new messages arrive
                if hasScrolledToBottom && newCount > 0 {
                    // Animate scroll for new messages after initial load
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("bottomAnchor", anchor: .bottom)
                    }
                }
            }
            .onAppear {
                // Scroll to bottom on appear - using multiple attempts to ensure it works
                scrollToBottomWithRetry(proxy: proxy)
            }
        }
    }

    private func shouldShowTimestamp(for index: Int, in items: [ThreadItem]) -> Bool {
        if index == 0 { return true }

        let currentItem = items[index]
        let previousItem = items[index - 1]

        let gap = currentItem.createdAt.timeIntervalSince(previousItem.createdAt)
        return gap >= timestampGapThreshold
    }

    private func shouldShowAvatar(for index: Int, in items: [ThreadItem]) -> Bool {
        let currentItem = items[index]

        // Don't show avatar for sent messages
        if currentItem.senderID == authManager.currentUserID { return false }

        // If this is the last item, show avatar
        if index == items.count - 1 { return true }

        let nextItem = items[index + 1]

        // Show avatar if next message is from a different sender
        if nextItem.senderID != currentItem.senderID { return true }

        // Show avatar if there's a time gap before next message
        let gap = nextItem.createdAt.timeIntervalSince(currentItem.createdAt)
        if gap >= timestampGapThreshold { return true }

        return false
    }

    private func timestampView(for date: Date) -> some View {
        Text(formatTimestamp(date))
            .font(.custom("Avenir-Medium", size: 13))
            .foregroundColor(AppTheme.textTertiary)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "h:mm a"
            return "Yesterday, \(formatter.string(from: date))"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE, h:mm a"
            return formatter.string(from: date)
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
            return formatter.string(from: date)
        }
    }

    private func scrollToBottomWithRetry(proxy: ScrollViewProxy) {
        // Multiple attempts with increasing delays to ensure scroll works
        // This handles the case where items are loaded but not yet laid out
        let delays: [Double] = [0.05, 0.15, 0.3, 0.5]

        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if !hasScrolledToBottom && !conversationManager.currentConversationItems.isEmpty {
                    proxy.scrollTo("bottomAnchor", anchor: .bottom)
                    if delay == delays.last {
                        hasScrolledToBottom = true
                    }
                } else if !hasScrolledToBottom && delay == delays.last {
                    // Still mark as scrolled even if no items (prevents future issues)
                    hasScrolledToBottom = true
                }
            }
        }

        // Final attempt - mark as scrolled
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            hasScrolledToBottom = true
        }
    }

    @ViewBuilder
    private func avatarView(for user: User, size: CGFloat) -> some View {
        let color = Color(hex: user.colorHex.replacingOccurrences(of: "#", with: ""))

        if let profileURL = user.profileImageURL {
            CachedAsyncImage(urlString: profileURL)
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(Circle().stroke(color.opacity(0.5), lineWidth: 2))
        } else {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: size, height: size)

                Text(user.initials)
                    .font(.custom("Avenir-Heavy", size: size * 0.4))
                    .foregroundColor(color)
            }
            .overlay(Circle().stroke(color.opacity(0.3), lineWidth: 1.5))
        }
    }

    // MARK: - Floating Action Bar

    private var floatingActionBar: some View {
        HStack(spacing: 12) {
            // Text input field
            HStack(spacing: 8) {
                TextField("Send message...", text: $messageText)
                    .font(.custom("Avenir-Regular", size: 16))
                    .foregroundColor(AppTheme.textPrimary)
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        sendTextMessage()
                    }

                // Send button (always present to maintain consistent height)
                Button(action: sendTextMessage) {
                    Image(systemName: isSendingMessage ? "hourglass" : "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(AppTheme.primaryStart)
                }
                .disabled(isSendingMessage || messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0 : 1)
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(minHeight: 48)
            .background(
                VisualEffectBlur(blurStyle: .dark)
                    .clipShape(Capsule())
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private func sendTextMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let userID = authManager.currentUserID else { return }

        isSendingMessage = true
        messageText = ""
        isTextFieldFocused = false

        Task {
            do {
                _ = try await conversationManager.sendTextMessage(
                    conversationID: conversation.id,
                    senderID: userID,
                    text: text
                )
            } catch {
                print("Error sending text message: \(error)")
                messageText = text
            }
            isSendingMessage = false
        }
    }

    // MARK: - Reaction Helpers

    private var currentUserReactionEmoji: String? {
        guard let targetID = selectedDoodleItemID,
              let userID = authManager.currentUserID else { return nil }
        return conversationManager.myReaction(for: targetID, userID: userID)?.emoji
    }

    private func handleReactionSelection(_ emoji: String) {
        guard let targetID = selectedDoodleItemID,
              let userID = authManager.currentUserID else { return }

        Task {
            await conversationManager.toggleReaction(
                threadItemID: targetID,
                userID: userID,
                emoji: emoji
            )
        }
    }
}

// MARK: - Visual Effect Blur

struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}

// MARK: - Thread Item Bubble

struct ThreadItemBubble: View {
    let item: ThreadItem
    let doodle: Doodle?
    let isFromMe: Bool
    let otherUser: User
    let showAvatar: Bool
    let reactions: [Reaction]
    let isGroupChat: Bool
    let onTapDoodle: (Doodle) -> Void

    @State private var didLongPress = false
    @State private var isHolding = false

    private var otherUserColor: Color {
        Color(hex: otherUser.colorHex.replacingOccurrences(of: "#", with: ""))
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Avatar for received messages (only show on last in group)
            if !isFromMe {
                if showAvatar {
                    avatarView
                } else {
                    // Invisible spacer to maintain alignment
                    Color.clear.frame(width: 28, height: 28)
                }
            } else {
                Spacer(minLength: 50)
            }

            // Content
            VStack(alignment: isFromMe ? .trailing : .leading, spacing: 0) {
                if let doodle = doodle {
                    doodleBubble(doodle: doodle)
                }

                if let text = item.textContent, item.type == .text {
                    textBubble(text: text)
                }
            }

            if !isFromMe {
                Spacer(minLength: 50)
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var avatarView: some View {
        if let profileURL = otherUser.profileImageURL {
            CachedAsyncImage(urlString: profileURL)
                .aspectRatio(contentMode: .fill)
                .frame(width: 28, height: 28)
                .clipShape(Circle())
        } else {
            ZStack {
                Circle()
                    .fill(otherUserColor.opacity(0.2))
                    .frame(width: 28, height: 28)

                Text(otherUser.initials)
                    .font(.custom("Avenir-Heavy", size: 11))
                    .foregroundColor(otherUserColor)
            }
        }
    }

    @ViewBuilder
    private func doodleBubble(doodle: Doodle) -> some View {
        ZStack(alignment: .bottomTrailing) {
            CachedAsyncImage(urlString: doodle.imageURL)
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 220)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            // Reaction overlay inside doodle, bottom-right with equal margins
            if !reactions.isEmpty {
                ReactionDisplay(reactions: reactions, isGroupChat: isGroupChat)
                    .padding(8)
            }
        }
        .scaleEffect(isHolding ? 1.05 : 1.0)
        .shadow(color: Color.black.opacity(isHolding ? 0.25 : 0.15), radius: isHolding ? 16 : 8, x: 0, y: isHolding ? 8 : 4)
        .animation(.easeOut(duration: 0.35), value: isHolding)
        .contentShape(Rectangle())
        .onTapGesture {
            onTapDoodle(doodle)
        }
        .onLongPressGesture(minimumDuration: 0.25, pressing: { isPressing in
            if isPressing {
                didLongPress = false
                withAnimation(.easeOut(duration: 0.35)) {
                    isHolding = true
                }
            } else {
                withAnimation(.easeOut(duration: 0.2)) {
                    isHolding = false
                }
                if didLongPress {
                    didLongPress = false
                }
            }
        }) {
            didLongPress = true
            onTapDoodle(doodle)
        }
    }

    @ViewBuilder
    private func textBubble(text: String) -> some View {
        Text(text)
            .font(.custom("Avenir-Regular", size: 17))
            .foregroundColor(isFromMe ? .white : AppTheme.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isFromMe {
                        LinearGradient(
                            colors: [
                                Color(hex: "FF8A65"),
                                Color(hex: "FF6B54")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color(white: 0.22)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        // No long press on text - reactions are only for doodles
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

    return ConversationThreadView(conversation: mockConversation)
        .environmentObject(ConversationManager.shared)
        .environmentObject(AuthManager())
        .environmentObject(UserManager.shared)
        .environmentObject(NavigationManager.shared)
}
