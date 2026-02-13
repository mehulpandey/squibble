//
//  SettingsView.swift
//  squibble
//
//  Full settings screen with account, preferences, and support options
//

import SwiftUI
import PhotosUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var userManager: UserManager

    @State private var showNameEditor = false
    @State private var editedName = ""
    @State private var showPhotoPicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isUploadingPhoto = false
    @State private var showColorPicker = false
    @State private var showSignOutConfirmation = false
    @State private var showDeleteAccountConfirmation = false
    @State private var isSigningOut = false
    @State private var isDeletingAccount = false
    @State private var showUpgradeView = false
    @State private var showEmailUnavailable = false
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""

    private var user: User? {
        userManager.currentUser
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Dark ambient background
                AmbientBackground()

                ScrollView {
                    VStack(spacing: 24) {
                        // Account Section
                        settingsSection(title: "ACCOUNT") {
                            // Edit Name
                            settingsRow(
                                icon: "person.fill",
                                iconColor: AppTheme.primaryStart,
                                title: "Display Name",
                                subtitle: user?.displayName ?? "Not set"
                            ) {
                                editedName = user?.displayName ?? ""
                                showNameEditor = true
                            }

                            Divider()
                                .background(AppTheme.divider)
                                .padding(.leading, 52)

                            // Edit Profile Picture
                            settingsRow(
                                icon: "camera.fill",
                                iconColor: AppTheme.primaryEnd,
                                title: "Profile Picture",
                                subtitle: user?.profileImageURL != nil ? "Change photo" : "Add photo"
                            ) {
                                showPhotoPicker = true
                            }

                            Divider()
                                .background(AppTheme.divider)
                                .padding(.leading, 52)

                            // Change Color
                            settingsRowWithColorPreview(
                                icon: "paintpalette.fill",
                                iconColor: AppTheme.primaryStart,
                                title: "Signature Color",
                                color: Color(hex: user?.colorHex.replacingOccurrences(of: "#", with: "") ?? "FF6B54")
                            ) {
                                showColorPicker = true
                            }
                        }

                        // Preferences Section
                        settingsSection(title: "PREFERENCES") {
                            settingsRow(
                                icon: "bell.fill",
                                iconColor: AppTheme.secondary,
                                title: "Notifications",
                                subtitle: "Manage in Settings"
                            ) {
                                openNotificationSettings()
                            }
                        }

                        // Membership Section
                        settingsSection(title: "MEMBERSHIP") {
                            settingsRowWithBadge(
                                icon: "sparkles",
                                iconColor: AppTheme.primaryStart,
                                title: (user?.isPremium ?? false) ? "Premium" : "Free",
                                isPremium: user?.isPremium ?? false
                            ) {
                                showUpgradeView = true
                            }
                        }

                        // Support Section
                        settingsSection(title: "SUPPORT") {
                            settingsRow(
                                icon: "envelope.fill",
                                iconColor: AppTheme.secondary,
                                title: "Contact Us",
                                subtitle: nil
                            ) {
                                openContactEmail()
                            }
                        }

                        // Destructive Actions Section
                        VStack(spacing: 0) {
                            // Sign Out
                            Button(action: { showSignOutConfirmation = true }) {
                                HStack {
                                    Text("Sign Out")
                                        .font(.custom("Avenir-Medium", size: 16))
                                        .foregroundColor(AppTheme.primaryStart)

                                    Spacer()

                                    if isSigningOut {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryStart))
                                            .scaleEffect(0.8)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                            }
                            .disabled(isSigningOut)

                            Divider()
                                .background(AppTheme.divider)

                            // Delete Account
                            Button(action: { showDeleteAccountConfirmation = true }) {
                                HStack {
                                    Text("Delete Account")
                                        .font(.custom("Avenir-Medium", size: 16))
                                        .foregroundColor(Color(hex: "FF4444"))

                                    Spacer()

                                    if isDeletingAccount {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "FF4444")))
                                            .scaleEffect(0.8)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                            }
                            .disabled(isDeletingAccount)
                        }
                        .background(AppTheme.glassBackgroundStrong)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppTheme.glassBorder, lineWidth: 1)
                        )
                        .cornerRadius(16)
                        .padding(.horizontal, 20)

                        // App Version
                        Text("Squibble v1.0.0")
                            .font(.custom("Avenir-Regular", size: 12))
                            .foregroundColor(AppTheme.textTertiary)
                            .padding(.top, 8)

                        Spacer().frame(height: 40)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                }
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
            .alert("Sign Out?", isPresented: $showSignOutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account?", isPresented: $showDeleteAccountConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text("This will permanently delete your account and all your data. This action cannot be undone.")
            }
            .alert("Email Copied", isPresented: $showEmailUnavailable) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("mpan.apps@gmail.com has been copied to your clipboard.")
            }
            .alert("Delete Failed", isPresented: $showDeleteError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(deleteErrorMessage)
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto, matching: .images)
            .onChange(of: selectedPhoto) { newValue in
                if let newValue {
                    loadAndUploadPhoto(from: newValue)
                }
            }
            .sheet(isPresented: $showColorPicker) {
                ColorPickerSettingsView()
            }
            .fullScreenCover(isPresented: $showUpgradeView) {
                UpgradeView()
            }
        }
    }

    // MARK: - Section Builder

    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.custom("Avenir-Heavy", size: 12))
                .foregroundColor(AppTheme.textSecondary)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                content()
            }
            .background(AppTheme.glassBackgroundStrong)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.glassBorder, lineWidth: 1)
            )
            .cornerRadius(16)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Row Builders

    private func settingsRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                // Title and subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.custom("Avenir-Medium", size: 16))
                        .foregroundColor(AppTheme.textPrimary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.custom("Avenir-Regular", size: 13))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func settingsRowWithColorPreview(
        icon: String,
        iconColor: Color,
        title: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                // Title
                Text(title)
                    .font(.custom("Avenir-Medium", size: 16))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                // Color preview
                Circle()
                    .fill(color)
                    .frame(width: 24, height: 24)
                    .shadow(color: color.opacity(0.4), radius: 4, x: 0, y: 0)

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func settingsRowWithBadge(
        icon: String,
        iconColor: Color,
        title: String,
        isPremium: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                // Title
                Text(title)
                    .font(.custom("Avenir-Medium", size: 16))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                // Badge
                if isPremium {
                    Text("Active")
                        .font(.custom("Avenir-Heavy", size: 12))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppTheme.primaryGradient)
                        .clipShape(Capsule())
                } else {
                    Text("Upgrade")
                        .font(.custom("Avenir-Heavy", size: 12))
                        .foregroundColor(AppTheme.primaryStart)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppTheme.primaryStart.opacity(0.15))
                        .clipShape(Capsule())
                }

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
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

                guard let uiImage = UIImage(data: data),
                      let compressedData = uiImage.resizedToMaxDimension(400)?.jpegData(compressionQuality: 0.7) else {
                    isUploadingPhoto = false
                    return
                }

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

    private func openNotificationSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func openContactEmail() {
        let email = "mpan.apps@gmail.com"
        if let url = URL(string: "mailto:\(email)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // Copy email to clipboard and show alert
            UIPasteboard.general.string = email
            showEmailUnavailable = true
        }
    }

    private func signOut() {
        isSigningOut = true
        Task {
            do {
                try await authManager.signOut()
                userManager.clearUser()
                dismiss()
            } catch {
                print("Failed to sign out: \(error)")
            }
            isSigningOut = false
        }
    }

    private func deleteAccount() {
        isDeletingAccount = true
        Task {
            do {
                // Delete all user data via Edge Function (includes auth.users)
                try await SupabaseService.shared.deleteUserAccount()

                // Clear local state
                userManager.clearUser()

                // Clear onboarding flag so new accounts get onboarding
                UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")

                // Sign out locally (user is already deleted from auth)
                try? await authManager.signOut()

                dismiss()
            } catch {
                print("Failed to delete account: \(error)")
                deleteErrorMessage = error.localizedDescription
                showDeleteError = true
            }
            isDeletingAccount = false
        }
    }
}

// MARK: - Color Picker Settings View

struct ColorPickerSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userManager: UserManager

    @State private var selectedColor: String = ""
    @State private var isSaving = false

    // Updated colors for dark theme
    private let colors = [
        "#FF6B54", "#FF9F43", "#FECA57", "#FFE600",
        "#00FFA3", "#F3B527", "#54A0FF", "#5F27CD",
        "#A29BFE", "#FF6B81", "#FD79A8", "#FFFFFF"
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 4)

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Preview
                ZStack {
                    Circle()
                        .fill(AppTheme.glassBackgroundStrong)
                        .frame(width: 100, height: 100)

                    Text(userManager.currentUser?.initials ?? "?")
                        .font(.custom("Avenir-Heavy", size: 36))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .overlay(
                    Circle()
                        .stroke(
                            Color(hex: selectedColor.isEmpty
                                  ? (userManager.currentUser?.colorHex.replacingOccurrences(of: "#", with: "") ?? "FF6B54")
                                  : selectedColor.replacingOccurrences(of: "#", with: "")),
                            lineWidth: 4
                        )
                )
                .shadow(
                    color: Color(hex: selectedColor.isEmpty
                                 ? (userManager.currentUser?.colorHex.replacingOccurrences(of: "#", with: "") ?? "FF6B54")
                                 : selectedColor.replacingOccurrences(of: "#", with: "")).opacity(0.4),
                    radius: 12, x: 0, y: 4
                )

                // Color grid
                VStack(alignment: .leading, spacing: 16) {
                    Text("Choose your signature color")
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(AppTheme.textSecondary)

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(colors, id: \.self) { color in
                            colorButton(color: color)
                        }
                    }
                }
                .padding(20)
                .background(AppTheme.glassBackgroundStrong)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.glassBorder, lineWidth: 1)
                )
                .cornerRadius(20)
                .padding(.horizontal, 20)

                Spacer()

                // Save button
                Button(action: saveColor) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Save Color")
                                .font(.custom("Avenir-Heavy", size: 16))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(AppTheme.primaryGradient)
                    .clipShape(Capsule())
                    .shadow(color: AppTheme.primaryGlow, radius: 12, x: 0, y: 6)
                }
                .disabled(selectedColor.isEmpty || isSaving)
                .opacity(selectedColor.isEmpty ? 0.6 : 1.0)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .padding(.top, 32)
            .navigationTitle("Signature Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .onAppear {
                selectedColor = userManager.currentUser?.colorHex ?? "#FF6B54"
            }
        }
    }

    private func colorButton(color: String) -> some View {
        let isSelected = selectedColor == color
        let cleanColor = color.replacingOccurrences(of: "#", with: "")

        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedColor = color
            }
        }) {
            ZStack {
                Circle()
                    .fill(Color(hex: cleanColor))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(cleanColor == "FFFFFF" ? AppTheme.glassBorder : Color.clear, lineWidth: 1)
                    )

                if isSelected {
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 48, height: 48)

                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(cleanColor == "FFFFFF" || cleanColor == "FFE600" || cleanColor == "FECA57" ? AppTheme.backgroundTop : .white)
                }
            }
            .shadow(color: Color(hex: cleanColor).opacity(isSelected ? 0.6 : 0.4), radius: isSelected ? 8 : 4, x: 0, y: isSelected ? 4 : 2)
            .scaleEffect(isSelected ? 1.1 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func saveColor() {
        guard !selectedColor.isEmpty else { return }
        isSaving = true

        Task {
            do {
                try await userManager.updateColor(selectedColor)
                dismiss()
            } catch {
                print("Failed to save color: \(error)")
            }
            isSaving = false
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthManager())
        .environmentObject(UserManager())
}
