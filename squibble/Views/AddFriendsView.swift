//
//  AddFriendsView.swift
//  squibble
//
//  Add friends screen with invite link, friend requests, and friends list
//

import SwiftUI

struct AddFriendsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var friendManager: FriendManager

    @State private var showCopiedFeedback = false
    @State private var friendToRemove: User?
    @State private var showRemoveConfirmation = false
    @State private var addByCodeText = ""
    @State private var showAddByCode = false
    @State private var isAddingFriend = false
    @State private var addFriendError: String?
    @State private var showAddSuccess = false
    @State private var showUpgradeView = false

    private let maxFreeFreiends = 30

    private var user: User? {
        userManager.currentUser
    }

    private var inviteCode: String {
        user?.inviteCode ?? ""
    }

    private var isAtFriendLimit: Bool {
        guard let user = user else { return false }
        return !user.isPremium && friendManager.friendCount >= maxFreeFreiends
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Dark ambient background
                AmbientBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // Invite section
                        inviteSection

                        // Add by code section
                        addByCodeSection

                        // Friend requests section (if any)
                        if !friendManager.pendingRequests.isEmpty {
                            friendRequestsSection
                        }

                        // Friends list
                        friendsListSection

                        Spacer().frame(height: 40)
                    }
                    .padding(.top, 16)
                }
                .refreshable {
                    await refreshFriends()
                }
            }
            .safeAreaInset(edge: .top) {
                headerBar
            }
            .navigationBarHidden(true)
            .alert("Remove Friend", isPresented: $showRemoveConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Remove", role: .destructive) {
                    if let friend = friendToRemove {
                        removeFriend(friend)
                    }
                }
            } message: {
                if let friend = friendToRemove {
                    Text("Remove \(friend.displayName) from your friends?")
                }
            }
            .onAppear {
                loadFriends()
            }
            .fullScreenCover(isPresented: $showUpgradeView) {
                UpgradeView()
            }
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.glassBackgroundStrong)
                    .overlay(
                        Circle()
                            .stroke(AppTheme.glassBorder, lineWidth: 1)
                    )
                    .clipShape(Circle())
            }

            Spacer()

            Text("Friends")
                .font(.custom("Avenir-Heavy", size: 20))
                .foregroundColor(AppTheme.textPrimary)

            Spacer()

            // Invisible spacer for centering
            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(AppTheme.backgroundTop.opacity(0.8))
    }

    // MARK: - Invite Section

    private var inviteSection: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "person.badge.key")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.primaryStart)

                Text("Your Invite Code")
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()
            }

            Text("Share your code so friends can add you on Squibble")
                .font(.custom("Avenir-Medium", size: 13))
                .foregroundColor(AppTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Code display
            HStack(spacing: 12) {
                Text(inviteCode)
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(AppTheme.textPrimary)
                    .kerning(2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()

                // Copy button
                Button(action: copyCode) {
                    HStack(spacing: 4) {
                        Image(systemName: showCopiedFeedback ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 12, weight: .semibold))
                        Text(showCopiedFeedback ? "Copied!" : "Copy")
                            .font(.custom("Avenir-Heavy", size: 12))
                    }
                    .foregroundColor(.white)
                    .frame(width: 80)
                    .padding(.vertical, 8)
                    .background(
                        showCopiedFeedback
                            ? LinearGradient(colors: [AppTheme.secondary, AppTheme.secondary.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : AppTheme.primaryGradient
                    )
                    .cornerRadius(8)
                }

                // Share button
                ShareLink(item: "Add me on Squibble! My invite code is: \(inviteCode)\n\nDownload: https://apps.apple.com/app/squibble") {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.primaryStart)
                        .frame(width: 36, height: 36)
                        .background(AppTheme.primaryStart.opacity(0.15))
                        .cornerRadius(8)
                }
            }
            .padding(12)
            .background(AppTheme.glassBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.glassBorder, lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .padding(16)
        .glassContainer(cornerRadius: 16)
        .padding(.horizontal, 20)
    }

    // MARK: - Add by Code Section

    private var addByCodeSection: some View {
        VStack(spacing: 12) {
            // Header with toggle
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    showAddByCode.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.secondary)

                    Text("Add by Invite Code")
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(AppTheme.textPrimary)

                    Spacer()

                    Image(systemName: showAddByCode ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            if showAddByCode {
                VStack(spacing: 12) {
                    Text("Enter a friend's invite code to send them a request")
                        .font(.custom("Avenir-Medium", size: 13))
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 12) {
                        TextField("Enter code", text: $addByCodeText)
                            .font(.custom("Avenir-Medium", size: 14))
                            .foregroundColor(AppTheme.textPrimary)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .padding(12)
                            .background(AppTheme.glassBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AppTheme.glassBorder, lineWidth: 1)
                            )
                            .cornerRadius(10)

                        Button(action: addFriendByCode) {
                            if isAddingFriend {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(width: 80, height: 44)
                            } else {
                                Text("Add")
                                    .font(.custom("Avenir-Heavy", size: 14))
                                    .foregroundColor(.white)
                                    .frame(width: 80, height: 44)
                            }
                        }
                        .background(
                            LinearGradient(
                                colors: [AppTheme.secondary, AppTheme.secondary.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(10)
                        .shadow(color: AppTheme.secondaryGlow, radius: 8, x: 0, y: 2)
                        .disabled(addByCodeText.isEmpty || isAddingFriend || isAtFriendLimit)
                        .opacity(addByCodeText.isEmpty || isAtFriendLimit ? 0.5 : 1)
                    }

                    if let error = addFriendError {
                        Text(error)
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(Color(hex: "FF4444"))
                    }

                    if showAddSuccess {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppTheme.secondary)
                            Text("Friend request sent!")
                                .font(.custom("Avenir-Medium", size: 12))
                                .foregroundColor(AppTheme.secondary)
                        }
                    }

                    if isAtFriendLimit {
                        friendLimitWarning
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .glassContainer(cornerRadius: 16)
        .padding(.horizontal, 20)
    }

    // MARK: - Friend Requests Section

    private var friendRequestsSection: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "person.wave.2")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.primaryEnd)

                Text("Friend Requests")
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(AppTheme.textPrimary)

                // Badge
                Text("\(friendManager.pendingRequestCount)")
                    .font(.custom("Avenir-Heavy", size: 11))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.primaryEnd)
                    .cornerRadius(10)

                Spacer()
            }

            // Requests list
            VStack(spacing: 0) {
                ForEach(friendManager.pendingRequests) { request in
                    FriendRequestRow(
                        friendship: request,
                        onAccept: { acceptRequest(request) },
                        onDecline: { declineRequest(request) },
                        isAtLimit: isAtFriendLimit
                    )

                    if request.id != friendManager.pendingRequests.last?.id {
                        Divider()
                            .background(AppTheme.divider)
                            .padding(.horizontal, 12)
                    }
                }
            }
            .background(AppTheme.glassBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.glassBorder, lineWidth: 1)
            )
            .cornerRadius(12)

            if isAtFriendLimit {
                friendLimitWarning
            }
        }
        .padding(16)
        .glassContainer(cornerRadius: 16)
        .padding(.horizontal, 20)
    }

    // MARK: - Friends List Section

    private var friendsListSection: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.secondary)

                Text("Your Friends")
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                // Count
                if let user = user {
                    if user.isPremium {
                        Text("\(friendManager.friendCount)")
                            .font(.custom("Avenir-Heavy", size: 14))
                            .foregroundColor(AppTheme.textSecondary)
                    } else {
                        Text("\(friendManager.friendCount) of \(maxFreeFreiends)")
                            .font(.custom("Avenir-Heavy", size: 14))
                            .foregroundColor(friendManager.friendCount >= maxFreeFreiends
                                ? AppTheme.primaryEnd
                                : AppTheme.textSecondary)
                    }
                }
            }

            if friendManager.friends.isEmpty {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(AppTheme.textTertiary)

                    Text("No friends yet")
                        .font(.custom("Avenir-Heavy", size: 15))
                        .foregroundColor(AppTheme.textSecondary)

                    Text("Share your link to connect!")
                        .font(.custom("Avenir-Medium", size: 13))
                        .foregroundColor(AppTheme.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(AppTheme.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.glassBorder, lineWidth: 1)
                )
                .cornerRadius(12)
            } else {
                // Friends list
                VStack(spacing: 0) {
                    ForEach(friendManager.friends) { friend in
                        FriendRow(
                            friend: friend,
                            onRemove: {
                                friendToRemove = friend
                                showRemoveConfirmation = true
                            }
                        )

                        if friend.id != friendManager.friends.last?.id {
                            Divider()
                                .background(AppTheme.divider)
                                .padding(.horizontal, 12)
                        }
                    }
                }
                .background(AppTheme.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.glassBorder, lineWidth: 1)
                )
                .cornerRadius(12)
            }
        }
        .padding(16)
        .glassContainer(cornerRadius: 16)
        .padding(.horizontal, 20)
    }

    // MARK: - Friend Limit Warning

    private var friendLimitWarning: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(AppTheme.primaryEnd)

            Text("You've reached the free limit of \(maxFreeFreiends) friends.")
                .font(.custom("Avenir-Medium", size: 12))
                .foregroundColor(AppTheme.textSecondary)

            Spacer()

            Button(action: {
                showUpgradeView = true
            }) {
                Text("Upgrade")
                    .font(.custom("Avenir-Heavy", size: 12))
                    .foregroundColor(AppTheme.primaryStart)
            }
        }
        .padding(12)
        .background(AppTheme.primaryEnd.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppTheme.primaryEnd.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(10)
    }

    // MARK: - Actions

    private func loadFriends() {
        guard let userID = authManager.currentUserID else { return }
        Task {
            await friendManager.loadFriends(for: userID)
        }
    }

    private func refreshFriends() async {
        guard let userID = authManager.currentUserID else { return }
        await friendManager.loadFriends(for: userID)
    }

    private func copyCode() {
        HapticManager.mediumTap()
        UIPasteboard.general.string = inviteCode
        withAnimation {
            showCopiedFeedback = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedFeedback = false
            }
        }
    }

    private func addFriendByCode() {
        guard let userID = authManager.currentUserID else { return }
        let code = addByCodeText.trimmingCharacters(in: .whitespaces).uppercased()
        guard !code.isEmpty else { return }

        isAddingFriend = true
        addFriendError = nil
        showAddSuccess = false

        Task {
            do {
                let success = try await friendManager.sendFriendRequest(from: userID, toInviteCode: code)
                if success {
                    HapticManager.success()
                    addByCodeText = ""
                    showAddSuccess = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showAddSuccess = false
                    }
                } else {
                    HapticManager.error()
                    addFriendError = "No user found with that code"
                }
            } catch {
                HapticManager.error()
                addFriendError = "Failed to send request"
            }
            isAddingFriend = false
        }
    }

    private func acceptRequest(_ friendship: Friendship) {
        HapticManager.success()
        guard let userID = authManager.currentUserID else { return }
        Task {
            try? await friendManager.acceptFriendRequest(friendship, currentUserID: userID)
        }
    }

    private func declineRequest(_ friendship: Friendship) {
        Task {
            try? await friendManager.declineFriendRequest(friendship)
        }
    }

    private func removeFriend(_ friend: User) {
        guard let userID = authManager.currentUserID else { return }
        Task {
            try? await friendManager.removeFriend(friend, currentUserID: userID)
        }
    }
}

// MARK: - Friend Request Row

struct FriendRequestRow: View {
    let friendship: Friendship
    let onAccept: () -> Void
    let onDecline: () -> Void
    let isAtLimit: Bool

    @State private var requesterUser: User?

    private var requesterColor: Color {
        Color(hex: requesterUser?.colorHex.replacingOccurrences(of: "#", with: "") ?? "555555")
    }

    var body: some View {
        HStack(spacing: 12) {
            // Avatar with profile picture or initials
            requesterAvatar

            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(requesterUser?.displayName ?? "Loading...")
                    .font(.custom("Avenir-Heavy", size: 14))
                    .foregroundColor(AppTheme.textPrimary)

                Text("Wants to be friends")
                    .font(.custom("Avenir-Medium", size: 11))
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            // Actions
            HStack(spacing: 8) {
                Button(action: onDecline) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(AppTheme.glassBackgroundStrong)
                        .clipShape(Circle())
                }

                Button(action: onAccept) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            LinearGradient(
                                colors: [AppTheme.secondary, AppTheme.secondary.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: AppTheme.secondaryGlow, radius: 4, x: 0, y: 0)
                }
                .disabled(isAtLimit)
                .opacity(isAtLimit ? 0.5 : 1)
            }
        }
        .padding(12)
        .task {
            requesterUser = try? await SupabaseService.shared.getUser(id: friendship.requesterID)
        }
    }

    @ViewBuilder
    private var requesterAvatar: some View {
        if let user = requesterUser,
           let profileURL = user.profileImageURL,
           let url = URL(string: profileURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(requesterColor, lineWidth: 2)
                        )
                default:
                    defaultRequesterAvatar
                }
            }
        } else {
            defaultRequesterAvatar
        }
    }

    private var defaultRequesterAvatar: some View {
        ZStack {
            Circle()
                .fill(AppTheme.glassBackgroundStrong)

            Text(requesterUser?.initials ?? "?")
                .font(.custom("Avenir-Heavy", size: 14))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(width: 40, height: 40)
        .overlay(
            Circle()
                .stroke(requesterColor, lineWidth: 2)
        )
    }
}

// MARK: - Friend Row

struct FriendRow: View {
    let friend: User
    let onRemove: () -> Void

    private var friendColor: Color {
        Color(hex: friend.colorHex.replacingOccurrences(of: "#", with: ""))
    }

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            if let profileURL = friend.profileImageURL,
               let url = URL(string: profileURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(friendColor, lineWidth: 2)
                            )
                    default:
                        defaultFriendAvatar
                    }
                }
            } else {
                defaultFriendAvatar
            }

            // Name
            Text(friend.displayName)
                .font(.custom("Avenir-Heavy", size: 14))
                .foregroundColor(AppTheme.textPrimary)

            Spacer()

            // Remove button
            Button(action: onRemove) {
                Image(systemName: "minus.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppTheme.textTertiary)
            }
        }
        .padding(12)
    }

    private var defaultFriendAvatar: some View {
        ZStack {
            Circle()
                .fill(AppTheme.glassBackgroundStrong)

            Text(friend.initials)
                .font(.custom("Avenir-Heavy", size: 14))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(width: 40, height: 40)
        .overlay(
            Circle()
                .stroke(friendColor, lineWidth: 2)
        )
    }
}

#Preview {
    AddFriendsView()
        .environmentObject(AuthManager())
        .environmentObject(UserManager())
        .environmentObject(FriendManager())
}
