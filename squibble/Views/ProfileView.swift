//
//  ProfileView.swift
//  squibble
//
//  User profile screen with stats and activity
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var friendManager: FriendManager
    @EnvironmentObject var doodleManager: DoodleManager
    @EnvironmentObject var navigationManager: NavigationManager

    @State private var showSettings = false
    @State private var showAddFriends = false
    @State private var showNameEditor = false
    @State private var editedName = ""
    @State private var showPhotoPicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isUploadingPhoto = false

    private var user: User? {
        userManager.currentUser
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerBar

            ScrollView {
                VStack(spacing: 0) {
                    // Profile header
                    profileHeader
                        .padding(.top, 16)

                    // Stats row
                    statsRow
                        .padding(.top, 16)

                    // Activity calendar
                    activitySection
                        .padding(.top, 20)

                    // Friends list
                    friendsSection
                        .padding(.top, 20)

                    Spacer().frame(height: 100)  // Allow content to scroll behind tab bar
                }
            }
            .scrollContentBackground(.hidden)

            // Banner ad for free users
            BannerAdContainer()
                .padding(.top, 8)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showAddFriends) {
            AddFriendsView()
        }
        .alert("Edit Name", isPresented: $showNameEditor) {
            TextField("Display Name", text: $editedName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                saveName()
            }
        } message: {
            Text("Enter your display name")
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto, matching: .images)
        .onChange(of: selectedPhoto) { newValue in
            if let newValue {
                loadAndUploadPhoto(from: newValue)
            }
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            Text("Profile")
                .font(.custom("Avenir-Heavy", size: 32))
                .foregroundColor(AppTheme.textPrimary)

            Spacer()

            // Settings button
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
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
        .padding(.top, (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 0) + 12)  // Extra padding for breathing room
    }

    // MARK: - Profile Header

    private var userColor: Color {
        Color(hex: user?.colorHex.replacingOccurrences(of: "#", with: "") ?? "FF6B54")
    }

    private var profileHeader: some View {
        VStack(spacing: 12) {
            // Avatar
            Button(action: { showPhotoPicker = true }) {
                ZStack {
                    if let profileURL = user?.profileImageURL {
                        CachedAsyncImage(urlString: profileURL)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 88, height: 88)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(userColor, lineWidth: 4)
                            )
                    } else {
                        defaultAvatar
                    }
                }
                .frame(width: 88, height: 88)
                .shadow(color: userColor.opacity(0.4), radius: 12, x: 0, y: 4)
                .overlay(
                    // Camera badge
                    ZStack {
                        Circle()
                            .fill(AppTheme.primaryGradient)
                            .frame(width: 28, height: 28)
                            .shadow(color: AppTheme.primaryGlow, radius: 8, x: 0, y: 2)

                        if isUploadingPhoto {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.6)
                        } else {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .offset(x: 32, y: 32)
                )
            }
            .disabled(isUploadingPhoto)

            // Name only
            Button(action: {
                editedName = user?.displayName ?? ""
                showNameEditor = true
            }) {
                HStack(spacing: 6) {
                    Text(user?.displayName ?? "Your Name")
                        .font(.custom("Avenir-Heavy", size: 22))
                        .foregroundColor(AppTheme.textPrimary)

                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
        }
    }

    private var defaultAvatar: some View {
        ZStack {
            Circle()
                .fill(AppTheme.glassBackgroundStrong)

            Text(user?.initials ?? "?")
                .font(.custom("Avenir-Heavy", size: 32))
                .foregroundColor(AppTheme.textSecondary)
        }
        .overlay(
            Circle()
                .stroke(userColor, lineWidth: 4)
        )
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            // Doodles sent - tappable to navigate to History with Sent filter
            Button(action: {
                navigationManager.navigateToHistory(filter: .sent)
            }) {
                statItemContent(
                    value: "\(user?.totalDoodlesSent ?? 0)",
                    label: "Doodles Sent",
                    isStreak: false
                )
            }
            .buttonStyle(PlainButtonStyle())

            // Divider
            Rectangle()
                .fill(AppTheme.divider)
                .frame(width: 1, height: 40)

            // Streak - not tappable
            statItemContent(
                value: "\(user?.streak ?? 0)",
                label: "Day Streak",
                isStreak: true
            )

            // Divider
            Rectangle()
                .fill(AppTheme.divider)
                .frame(width: 1, height: 40)

            // Friends - tappable to show Add Friends popup
            Button(action: {
                showAddFriends = true
            }) {
                statItemContent(
                    value: "\(friendManager.friendCount)",
                    label: "Friends",
                    isStreak: false
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 16)
        .glassContainer(cornerRadius: 16)
        .padding(.horizontal, 20)
    }

    private func statItemContent(value: String, label: String, isStreak: Bool) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                if isStreak && (user?.streak ?? 0) > 0 {
                    Text("🔥")
                        .font(.system(size: 18))
                }
                Text(value)
                    .font(.custom("Avenir-Heavy", size: 24))
                    .foregroundColor(AppTheme.textPrimary)
            }

            Text(label)
                .font(.custom("Avenir-Medium", size: 11))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Activity Section

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity")
                .font(.custom("Avenir-Heavy", size: 18))
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal, 20)

            ActivityCalendarView(
                sentDoodles: doodleManager.sentDoodles,
                receivedDoodles: doodleManager.receivedDoodles
            )
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Friends Section

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Friends")
                    .font(.custom("Avenir-Heavy", size: 18))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                Button(action: { showAddFriends = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Add")
                            .font(.custom("Avenir-Heavy", size: 13))
                    }
                    .foregroundColor(AppTheme.primaryStart)
                }
            }
            .padding(.horizontal, 20)

            if friendManager.friends.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(AppTheme.textTertiary)

                    Text("No friends yet")
                        .font(.custom("Avenir-Medium", size: 13))
                        .foregroundColor(AppTheme.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .glassContainer(cornerRadius: 16)
                .padding(.horizontal, 20)
            } else {
                VStack(spacing: 0) {
                    ForEach(friendManager.friends) { friend in
                        ProfileFriendRow(friend: friend)

                        if friend.id != friendManager.friends.last?.id {
                            Divider()
                                .background(AppTheme.divider)
                                .padding(.horizontal, 12)
                        }
                    }
                }
                .glassContainer(cornerRadius: 16)
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Actions

    private func saveName() {
        guard !editedName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        Task {
            try? await userManager.updateDisplayName(editedName.trimmingCharacters(in: .whitespaces))
        }
    }

    private func loadAndUploadPhoto(from item: PhotosPickerItem) {
        isUploadingPhoto = true

        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    isUploadingPhoto = false
                    return
                }

                // Resize and compress image
                guard let uiImage = UIImage(data: data),
                      let compressedData = uiImage.resizedToMaxDimension(400)?.jpegData(compressionQuality: 0.7) else {
                    isUploadingPhoto = false
                    return
                }

                // Upload to Supabase
                guard let userID = authManager.currentUserID else {
                    isUploadingPhoto = false
                    return
                }

                let url = try await SupabaseService.shared.uploadProfileImage(
                    userID: userID,
                    imageData: compressedData
                )

                try await userManager.updateProfileImage(url: url)

            } catch {
                print("Failed to upload profile image: \(error)")
            }

            isUploadingPhoto = false
            selectedPhoto = nil
        }
    }
}

// MARK: - Activity Calendar View

struct ActivityCalendarView: View {
    let sentDoodles: [Doodle]
    let receivedDoodles: [Doodle]

    @State private var currentMonth = Date()

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    // Wrapper for calendar day cells with unique IDs
    private struct CalendarCell: Identifiable {
        let id: Int  // Position index (0-41 for 6 weeks max)
        let date: Date?
    }

    var body: some View {
        VStack(spacing: 10) {
            // Month header
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(width: 28, height: 28)
                }

                Spacer()

                Text(monthYearString)
                    .font(.custom("Avenir-Heavy", size: 15))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(canGoForward ? AppTheme.textSecondary : AppTheme.textInactive)
                        .frame(width: 28, height: 28)
                }
                .disabled(!canGoForward)
            }

            // Weekday headers - use indices for unique IDs
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(0..<7, id: \.self) { index in
                    Text(weekdayLabels[index])
                        .font(.custom("Avenir-Medium", size: 11))
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(height: 20)
                }
            }

            // Calendar grid - use CalendarCell for unique IDs
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(calendarCells) { cell in
                    if let date = cell.date {
                        calendarDay(date: date)
                    } else {
                        Color.clear
                            .frame(height: 32)
                    }
                }
            }
        }
        .padding(12)
        .glassContainer(cornerRadius: 16)
    }

    private func calendarDay(date: Date) -> some View {
        let activity = activityType(for: date)
        let isToday = Calendar.current.isDateInToday(date)

        return ZStack {
            // Today indicator ring
            if isToday {
                Circle()
                    .stroke(AppTheme.primaryStart, lineWidth: 2)
            }

            // Activity icon or day number
            if activity != .none {
                // Show icon for activity days
                Image(systemName: activity == .sent ? "paperplane.fill" : "envelope.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(activity == .sent ? AppTheme.primaryStart : AppTheme.secondary)
            } else {
                // Show day number for inactive days
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.custom("Avenir-Medium", size: 13))
                    .foregroundColor(AppTheme.textTertiary)
            }
        }
        .frame(height: 32)
    }

    // MARK: - Helpers

    private enum ActivityType {
        case none
        case sent
        case received
    }

    private func activityType(for date: Date) -> ActivityType {
        let calendar = Calendar.current
        let hasSent = sentDoodles.contains { calendar.isDate($0.createdAt, inSameDayAs: date) }
        let hasReceived = receivedDoodles.contains { calendar.isDate($0.createdAt, inSameDayAs: date) }

        // Sent overrides received if both happened same day
        if hasSent {
            return .sent
        } else if hasReceived {
            return .received
        }
        return .none
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    private var canGoForward: Bool {
        let calendar = Calendar.current
        let now = Date()
        return calendar.compare(currentMonth, to: now, toGranularity: .month) == .orderedAscending
    }

    private var calendarCells: [CalendarCell] {
        let calendar = Calendar.current

        guard let range = calendar.range(of: .day, in: .month, for: currentMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: firstDay) - 1

        var cells: [CalendarCell] = []

        // Empty cells for days before the first of the month
        for i in 0..<firstWeekday {
            cells.append(CalendarCell(id: i, date: nil))
        }

        // Days of the month
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                cells.append(CalendarCell(id: firstWeekday + day - 1, date: date))
            }
        }

        return cells
    }

    private func previousMonth() {
        withAnimation {
            currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }

    private func nextMonth() {
        withAnimation {
            currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
    }
}

// MARK: - Profile Friend Row

struct ProfileFriendRow: View {
    let friend: User

    private var friendColor: Color {
        Color(hex: friend.colorHex.replacingOccurrences(of: "#", with: ""))
    }

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            if let profileURL = friend.profileImageURL {
                CachedAsyncImage(urlString: profileURL)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(friendColor, lineWidth: 2)
                    )
            } else {
                ZStack {
                    Circle()
                        .fill(AppTheme.glassBackgroundStrong)

                    Text(friend.initials)
                        .font(.custom("Avenir-Heavy", size: 13))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(width: 36, height: 36)
                .overlay(
                    Circle()
                        .stroke(friendColor, lineWidth: 2)
                )
            }

            // Name
            Text(friend.displayName)
                .font(.custom("Avenir-Heavy", size: 14))
                .foregroundColor(AppTheme.textPrimary)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
        .environmentObject(UserManager())
        .environmentObject(FriendManager())
        .environmentObject(DoodleManager())
        .environmentObject(NavigationManager())
}
