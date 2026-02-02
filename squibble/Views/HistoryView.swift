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

struct HistoryView: View {
    @EnvironmentObject var doodleManager: DoodleManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var friendManager: FriendManager
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var navigationManager: NavigationManager

    @State private var selectedFilter: DoodleFilter = .all
    @State private var showPersonFilter = false
    @State private var selectedPersonID: UUID?
    @State private var selectedDoodle: Doodle?
    @State private var hasRetriedPendingDoodle = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerBar

            // Filter bar
            filterBar
                .padding(.top, 16)
                .padding(.bottom, 12)

            // Content
            if doodleManager.isLoading {
                loadingView
            } else if filteredDoodles.isEmpty {
                emptyStateView
            } else {
                doodleGrid
            }

            // Banner ad for free users
            BannerAdContainer()
                .padding(.top, 8)

            // Space for tab bar
            Spacer().frame(height: 100)
        }
        .sheet(isPresented: $showPersonFilter) {
            PersonFilterSheet(
                selectedPersonID: $selectedPersonID,
                friends: friendManager.friends
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(AppTheme.modalGradient)
        }
        .fullScreenCover(item: $selectedDoodle) { doodle in
            DoodleDetailView(doodle: doodle, allDoodles: filteredDoodles)
        }
        .task {
            await loadDoodles()
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
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            Text("History")
                .font(.custom("Avenir-Heavy", size: 32))
                .foregroundColor(AppTheme.textPrimary)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 0)
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
                            AppTheme.primaryGradient
                        } else {
                            AppTheme.buttonInactiveBackground
                        }
                    }
                )
                .overlay(
                    Capsule()
                        .stroke(selectedPersonID != nil ? Color.clear : AppTheme.buttonInactiveBorder, lineWidth: 1)
                )
                .clipShape(Capsule())
                .shadow(color: selectedPersonID != nil ? AppTheme.primaryGlow : .clear, radius: 8, x: 0, y: 2)
            }
            .buttonStyle(ScaleButtonStyle())

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Doodle Grid

    private var doodleGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
                spacing: 8
            ) {
                ForEach(filteredDoodles) { doodle in
                    DoodleGridItem(
                        doodle: doodle,
                        sender: getSender(for: doodle),
                        isSentByMe: doodle.senderID == authManager.currentUserID
                    )
                    .onTapGesture {
                        selectedDoodle = doodle
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
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
    }

    private func tryOpenPendingDoodle() {
        guard let pendingDoodleID = navigationManager.pendingDoodleID else { return }

        // Only try if we have doodles loaded
        guard !doodleManager.allDoodles.isEmpty else { return }

        // Find and open the doodle
        if let doodle = doodleManager.allDoodles.first(where: { $0.id == pendingDoodleID }) {
            selectedDoodle = doodle
            navigationManager.clearPendingDoodle()
        } else if !hasRetriedPendingDoodle {
            // Doodle not in local list yet — refresh from Supabase and retry once
            hasRetriedPendingDoodle = true
            Task {
                await loadDoodles()
            }
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
                            AppTheme.primaryGradient
                        } else {
                            AppTheme.buttonInactiveBackground
                        }
                    }
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : AppTheme.buttonInactiveBorder, lineWidth: 1)
                )
                .clipShape(Capsule())
                .shadow(color: isSelected ? AppTheme.primaryGlow : .clear, radius: 8, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Doodle Grid Item

struct DoodleGridItem: View {
    let doodle: Doodle
    let sender: User?
    let isSentByMe: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                // Doodle image - use .fit to maintain proper alignment
                AsyncImage(url: URL(string: doodle.imageURL)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(AppTheme.canvasTop)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.textTertiary))
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:
                        Rectangle()
                            .fill(AppTheme.canvasTop)
                            .overlay(
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(AppTheme.textTertiary)
                            )
                    @unknown default:
                        Rectangle()
                            .fill(AppTheme.canvasTop)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.width)

                // Sender badge - match widget style
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
            }
            .frame(width: geometry.size.width, height: geometry.size.width)
            .background(AppTheme.canvasTop)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.glassBorder, lineWidth: 1)
            )
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
        if let profileURL = friend.profileImageURL,
           let url = URL(string: profileURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(friendColor, lineWidth: 2.5)
                        )
                default:
                    defaultAvatar
                }
            }
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

#Preview {
    HistoryView()
        .environmentObject(DoodleManager())
        .environmentObject(AuthManager())
        .environmentObject(FriendManager())
        .environmentObject(UserManager())
        .environmentObject(NavigationManager())
}
