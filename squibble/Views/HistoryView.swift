//
//  HistoryView.swift
//  squibble
//
//  Shows history of sent and received doodles
//

import SwiftUI

enum DoodleFilter: String, CaseIterable {
    case all = "All"
    case sent = "Sent"
    case received = "Received"
}

enum HistoryViewMode: String, CaseIterable {
    case grid = "Grid"
    case chats = "Chats"
}

struct HistoryView: View {
    @EnvironmentObject var doodleManager: DoodleManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var friendManager: FriendManager
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var conversationManager: ConversationManager

    @State private var viewMode: HistoryViewMode = .grid
    @State private var selectedFilter: DoodleFilter = .all
    @State private var showPersonFilter = false
    @State private var selectedPersonID: UUID?
    @State private var hasRetriedPendingDoodle = false
    @State private var doodleReactions: [UUID: String] = [:]  // Cache of reactions by doodle ID

    private var safeAreaTop: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 0
    }

    // Header height: safeAreaTop + title row + optional filter bar
    private var headerContentHeight: CGFloat {
        viewMode == .grid ? 56 + 56 : 56  // title row + filter bar in grid mode
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Content based on view mode
            if viewMode == .grid {
                if doodleManager.isLoading {
                    loadingView
                } else if filteredDoodles.isEmpty {
                    emptyStateView
                } else {
                    doodleGrid
                }
            } else {
                // Chats mode - conversation list
                ConversationListView(topPadding: 1.6 * safeAreaTop + headerContentHeight + 16)
            }

            // Floating header at top
            floatingHeader
        }
        .ignoresSafeArea(edges: .top)
        .sheet(isPresented: $showPersonFilter) {
            PersonFilterSheet(
                selectedPersonID: $selectedPersonID,
                friends: friendManager.friends
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(AppTheme.modalGradient)
        }
        .task {
            await loadDoodles()
            await loadReactions()
        }
        .onAppear {
            // Check for pending filter from navigation
            if let pendingFilter = navigationManager.pendingHistoryFilter {
                selectedFilter = pendingFilter
                navigationManager.clearPendingHistoryFilter()
            }

            // Try to open pending doodle from widget/deep link
            tryOpenPendingDoodle()
        }
        .onChange(of: navigationManager.pendingDoodleID) { _ in
            // Handle deep link when view is already visible
            hasRetriedPendingDoodle = false
            tryOpenPendingDoodle()
        }
        .onChange(of: doodleManager.allDoodles) { _ in
            // Retry opening pending doodle after doodles load
            tryOpenPendingDoodle()
            // Reload reactions when doodles change
            Task {
                await loadReactions()
            }
        }
        .onChange(of: viewMode) { newMode in
            // Reload reactions when switching to grid view (ensures sync after chat interactions)
            if newMode == .grid {
                Task {
                    await loadReactions()
                }
            }
        }
    }

    // MARK: - Floating Header

    private var floatingHeader: some View {
        ZStack(alignment: .top) {
            // Semi-transparent background
            AppTheme.backgroundTop.opacity(0.95)

            // Content layer
            VStack(spacing: 0) {
                headerBar

                if viewMode == .grid {
                    filterBar
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                }
            }
            .padding(.top, 1.6 * safeAreaTop)
        }
        .frame(height: 1.6 * safeAreaTop + headerContentHeight)
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            Text("History")
                .font(.custom("Avenir-Heavy", size: 32))
                .foregroundColor(AppTheme.textPrimary)

            Spacer()

            // Compact icon toggle
            viewModeToggle
        }
        .padding(.horizontal, 20)
    }

    // MARK: - View Mode Toggle

    private var viewModeToggle: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(.easeInOut(duration: 0.2)) {
                viewMode = viewMode == .grid ? .chats : .grid
            }
        }) {
            // Show filled icon for the view you'll switch TO
            Image(systemName: viewMode == .grid ? "bubble.left.and.bubble.right.fill" : "square.grid.2x2.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(ViewModeToggleButtonStyle())
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack(spacing: 8) {
            ForEach(DoodleFilter.allCases, id: \.self) { filter in
                FilterPill(
                    title: filter.rawValue,
                    isSelected: selectedFilter == filter && (filter != .all || selectedPersonID == nil),
                    action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = filter
                            // Reset person filter when clicking "All"
                            if filter == .all {
                                selectedPersonID = nil
                            }
                        }
                    }
                )
            }

            // Person filter button (inline with other filters)
            Button(action: { showPersonFilter = true }) {
                HStack(spacing: 6) {
                    Image(systemName: selectedPersonID != nil ? "person.fill" : "person")
                        .font(.system(size: 14, weight: .semibold))

                    if selectedPersonID != nil {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                    }
                }
                .foregroundColor(selectedPersonID != nil ? .white : AppTheme.textSecondary)
                .padding(.horizontal, selectedPersonID != nil ? 14 : 12)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if selectedPersonID != nil {
                            Capsule()
                                .fill(AppTheme.primaryGradient)
                        } else {
                            Capsule()
                                .fill(AppTheme.buttonInactiveBackground)
                        }
                    }
                )
                .overlay(
                    Capsule()
                        .stroke(selectedPersonID != nil ? Color.clear : AppTheme.buttonInactiveBorder, lineWidth: 1)
                )
            }
            .buttonStyle(ScaleButtonStyle())

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Doodle Grid

    /// Calculates positions where inline ads should appear (after 9 items, then every 12)
    private func inlineAdPositions(totalItems: Int) -> Set<Int> {
        guard totalItems >= 9 else { return [] }
        var positions: Set<Int> = [9]  // First ad after 9 items
        var nextPosition = 21  // Then 21, 33, 45, etc.
        while nextPosition <= totalItems {
            positions.insert(nextPosition)
            nextPosition += 12
        }
        return positions
    }

    private var doodleGrid: some View {
        let adPositions = inlineAdPositions(totalItems: filteredDoodles.count)

        return ScrollView {
            LazyVStack(spacing: 4) {
                // Group doodles into rows of 3
                let rows = stride(from: 0, to: filteredDoodles.count, by: 3).map { startIndex in
                    Array(filteredDoodles[startIndex..<min(startIndex + 3, filteredDoodles.count)])
                }

                ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, rowDoodles in
                    // Doodle row
                    HStack(spacing: 4) {
                        ForEach(rowDoodles) { doodle in
                            DoodleGridItem(
                                doodle: doodle,
                                sender: getSender(for: doodle),
                                isSentByMe: doodle.senderID == authManager.currentUserID,
                                reactionEmoji: doodleReactions[doodle.id],
                                onTap: {
                                    navigationManager.showGridOverlay(
                                        doodle: doodle,
                                        currentEmoji: doodleReactions[doodle.id],
                                        onReaction: { emoji in
                                            handleGridReaction(doodle: doodle, emoji: emoji)
                                        },
                                        onDismiss: {
                                            Task { await loadReactions() }
                                        }
                                    )
                                }
                            )
                        }
                        // Fill empty slots in incomplete rows
                        if rowDoodles.count < 3 {
                            ForEach(0..<(3 - rowDoodles.count), id: \.self) { _ in
                                Color.clear
                                    .aspectRatio(1, contentMode: .fit)
                            }
                        }
                    }

                    // Insert inline ad after this row if position matches
                    let itemsAfterThisRow = (rowIndex + 1) * 3
                    if adPositions.contains(itemsAfterThisRow) {
                        InlineBannerAdContainer()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 1.6 * safeAreaTop + headerContentHeight + 16)
            .padding(.bottom, 100)
        }
        .refreshable {
            await refreshDoodles()
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

                Image(systemName: emptyStateIcon)
                    .font(.system(size: 40))
                    .foregroundColor(AppTheme.primaryStart)
            }

            VStack(spacing: 8) {
                Text(emptyStateTitle)
                    .font(.custom("Avenir-Heavy", size: 20))
                    .foregroundColor(AppTheme.textPrimary)

                Text(emptyStateMessage)
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

    // MARK: - Computed Properties

    private var filteredDoodles: [Doodle] {
        var doodles: [Doodle]

        switch selectedFilter {
        case .all:
            doodles = doodleManager.allDoodles
        case .sent:
            doodles = doodleManager.sentDoodles
        case .received:
            doodles = doodleManager.receivedDoodles
        }

        // Apply person filter
        if let personID = selectedPersonID {
            doodles = doodles.filter { doodle in
                doodle.senderID == personID ||
                (selectedFilter == .sent && doodle.senderID == authManager.currentUserID)
                // Note: For sent doodles, we'd need recipient info to filter properly
                // This is a simplified implementation
            }
        }

        return doodles
    }

    private var emptyStateIcon: String {
        if selectedPersonID != nil || selectedFilter != .all {
            return "magnifyingglass"
        }
        return "clock.fill"
    }

    private var emptyStateTitle: String {
        if selectedPersonID != nil || selectedFilter != .all {
            return "No Matches"
        }
        return "No Doodles Yet"
    }

    private var emptyStateMessage: String {
        if selectedPersonID != nil || selectedFilter != .all {
            return "No doodles match this filter.\nTry adjusting your filters."
        }
        return "Your sent and received\ndoodles will appear here."
    }

    // MARK: - Helpers

    private func getSender(for doodle: Doodle) -> User? {
        if doodle.senderID == authManager.currentUserID {
            return userManager.currentUser
        }
        return friendManager.friends.first { $0.id == doodle.senderID }
    }

    private func loadDoodles() async {
        guard let userID = authManager.currentUserID else { return }
        await doodleManager.loadDoodles(for: userID)
    }

    private func refreshDoodles() async {
        guard let userID = authManager.currentUserID else { return }
        await doodleManager.refreshDoodles(for: userID)
        await loadReactions()
    }

    private func loadReactions() async {
        guard let userID = authManager.currentUserID else { return }
        let doodleIDs = doodleManager.allDoodles.map { $0.id }
        guard !doodleIDs.isEmpty else { return }

        let reactions = await conversationManager.loadReactionsForDoodles(doodleIDs: doodleIDs, userID: userID)
        doodleReactions = reactions
    }

    private func tryOpenPendingDoodle() {
        guard let pendingDoodleID = navigationManager.pendingDoodleID else { return }

        // Only try if we have doodles loaded
        guard !doodleManager.allDoodles.isEmpty else { return }

        // Find and open the doodle
        if let doodle = doodleManager.allDoodles.first(where: { $0.id == pendingDoodleID }) {
            navigationManager.showGridOverlay(
                doodle: doodle,
                currentEmoji: doodleReactions[doodle.id],
                onReaction: { emoji in
                    handleGridReaction(doodle: doodle, emoji: emoji)
                },
                onDismiss: {
                    Task { await loadReactions() }
                }
            )
            navigationManager.clearPendingDoodle()
        } else if !hasRetriedPendingDoodle {
            // Doodle not in local list yet — refresh from Supabase and retry once
            hasRetriedPendingDoodle = true
            Task {
                await loadDoodles()
            }
        }
    }

    private func handleGridReaction(doodle: Doodle, emoji: String) {
        guard let userID = authManager.currentUserID else { return }

        // Update local cache immediately for responsive UI
        let existingEmoji = doodleReactions[doodle.id]
        if existingEmoji == emoji {
            // Toggle off - remove reaction
            doodleReactions.removeValue(forKey: doodle.id)
        } else {
            // Set new reaction
            doodleReactions[doodle.id] = emoji
        }

        // Persist to server
        Task {
            await conversationManager.toggleReactionOnDoodle(
                doodleID: doodle.id,
                userID: userID,
                emoji: emoji
            )
        }
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Avenir-Heavy", size: 14))
                .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if isSelected {
                            Capsule()
                                .fill(AppTheme.primaryGradient)
                        } else {
                            Capsule()
                                .fill(AppTheme.buttonInactiveBackground)
                        }
                    }
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : AppTheme.buttonInactiveBorder, lineWidth: 1)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Doodle Grid Item

struct DoodleGridItem: View {
    let doodle: Doodle
    let sender: User?
    let isSentByMe: Bool
    let reactionEmoji: String?  // User's reaction on this doodle
    let onTap: () -> Void

    @State private var didLongPress = false
    @State private var isHolding = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Doodle image - use .fit to maintain proper alignment
                CachedAsyncImage(urlString: doodle.imageURL)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width, height: geometry.size.width)

                // Sender badge - bottom left
                VStack {
                    Spacer()
                    HStack {
                        if let sender = sender {
                            Text(sender.initials)
                                .font(.custom("Avenir-Heavy", size: 8))
                                .foregroundColor(.white)
                                .frame(width: 20, height: 20)
                                .background(Color(hex: sender.colorHex))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                .padding(6)
                        }
                        Spacer()
                    }
                }

                // Reaction badge - bottom right (matches initials badge size/shadow)
                if let emoji = reactionEmoji {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(emoji)
                                .font(.system(size: 12))
                                .frame(width: 20, height: 20)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.65))
                                )
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                .padding(6)
                        }
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.width)
            .background(AppTheme.canvasTop)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.glassBorder, lineWidth: 1)
            )
            .scaleEffect(isHolding ? 1.05 : 1.0)
            .shadow(color: Color.black.opacity(isHolding ? 0.25 : 0), radius: isHolding ? 12 : 0, x: 0, y: isHolding ? 6 : 0)
            .animation(.easeOut(duration: 0.35), value: isHolding)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
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
                // Triggers immediately when duration reached, while still holding
                didLongPress = true
                onTap()
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Person Filter Sheet

struct PersonFilterSheet: View {
    @Binding var selectedPersonID: UUID?
    let friends: [User]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Filter by Person")
                    .font(.custom("Avenir-Heavy", size: 20))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)

            if friends.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "person.2")
                        .font(.system(size: 40))
                        .foregroundColor(AppTheme.textTertiary)
                    Text("No friends yet")
                        .font(.custom("Avenir-Regular", size: 16))
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                }
            } else {
                // Clear filter option
                if selectedPersonID != nil {
                    Button(action: {
                        selectedPersonID = nil
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 20))
                                .foregroundColor(AppTheme.primaryStart)

                            Text("Clear Filter")
                                .font(.custom("Avenir-Medium", size: 16))
                                .foregroundColor(AppTheme.primaryStart)

                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                    }

                    Rectangle()
                        .fill(AppTheme.divider)
                        .frame(height: 1)
                        .padding(.horizontal, 24)
                }

                // Friend list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(friends) { friend in
                            PersonFilterRow(
                                friend: friend,
                                isSelected: selectedPersonID == friend.id,
                                action: {
                                    selectedPersonID = friend.id
                                    dismiss()
                                }
                            )
                        }
                    }
                }
            }
        }
    }
}

struct PersonFilterRow: View {
    let friend: User
    let isSelected: Bool
    let action: () -> Void

    private var friendColor: Color {
        Color(hex: friend.colorHex.replacingOccurrences(of: "#", with: ""))
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Avatar with profile picture or initials
                friendAvatar

                // Name
                Text(friend.displayName)
                    .font(.custom("Avenir-Medium", size: 17))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private var friendAvatar: some View {
        if let profileURL = friend.profileImageURL {
            CachedAsyncImage(urlString: profileURL)
                .aspectRatio(contentMode: .fill)
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(friendColor, lineWidth: 2.5)
                )
        } else {
            defaultAvatar
        }
    }

    private var defaultAvatar: some View {
        ZStack {
            Circle()
                .fill(AppTheme.glassBackgroundStrong)
                .frame(width: 44, height: 44)

            Text(friend.initials)
                .font(.custom("Avenir-Heavy", size: 14))
                .foregroundColor(AppTheme.textSecondary)
        }
        .overlay(
            Circle()
                .stroke(friendColor, lineWidth: 2.5)
        )
    }
}

// MARK: - View Mode Toggle Button Style

struct ViewModeToggleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    HistoryView()
        .environmentObject(DoodleManager())
        .environmentObject(AuthManager())
        .environmentObject(FriendManager())
        .environmentObject(UserManager())
        .environmentObject(NavigationManager())
        .environmentObject(ConversationManager.shared)
}
