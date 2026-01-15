//
//  OnboardingView.swift
//  squibble
//
//  Onboarding flow for first-time users
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var currentPage = 0
    @State private var notificationStatus: NotificationStatus = .notDetermined
    @State private var selectedColorHex: String = "#FF6B54" // Default coral

    let onComplete: () -> Void

    enum NotificationStatus {
        case notDetermined, granted, denied
    }

    var body: some View {
        ZStack {
            // Dark ambient background
            AmbientBackground()

            VStack(spacing: 0) {
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<5) { index in
                        Capsule()
                            .fill(index == currentPage ? AppTheme.primaryStart : AppTheme.textTertiary)
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 20)

                // Content
                TabView(selection: $currentPage) {
                    OnboardingWelcomePage()
                        .tag(0)

                    OnboardingColorPage(selectedColorHex: $selectedColorHex)
                        .tag(1)

                    OnboardingNotificationPage(status: $notificationStatus)
                        .tag(2)

                    OnboardingWidgetPage()
                        .tag(3)

                    OnboardingInviteFriendsPage()
                        .environmentObject(userManager)
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Bottom buttons
                VStack(spacing: 16) {
                    // Primary button
                    Button(action: handlePrimaryAction) {
                        Text(primaryButtonText)
                            .font(.custom("Avenir-Heavy", size: 17))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(AppTheme.primaryGradient)
                            .cornerRadius(16)
                            .shadow(color: AppTheme.primaryGlow, radius: 10, x: 0, y: 4)
                    }

                    // Skip button (not on last page, and not on color page)
                    if currentPage < 4 && currentPage != 1 {
                        Button(action: handleSkip) {
                            Text("Skip")
                                .font(.custom("Avenir-Medium", size: 16))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }

    private var primaryButtonText: String {
        switch currentPage {
        case 0: return "Get Started"
        case 1: return "Continue"
        case 2:
            switch notificationStatus {
            case .notDetermined: return "Enable Notifications"
            case .granted, .denied: return "Continue"
            }
        case 3: return "Continue"
        case 4: return "Start Doodling"
        default: return "Continue"
        }
    }

    private func handlePrimaryAction() {
        switch currentPage {
        case 0:
            withAnimation(.easeInOut(duration: 0.3)) {
                currentPage = 1
            }
        case 1:
            // Save selected color to user profile
            Task {
                try? await userManager.updateColor(selectedColorHex)
            }
            withAnimation(.easeInOut(duration: 0.3)) {
                currentPage = 2
            }
        case 2:
            if notificationStatus == .notDetermined {
                requestNotifications()
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPage = 3
                }
            }
        case 3:
            withAnimation(.easeInOut(duration: 0.3)) {
                currentPage = 4
            }
        case 4:
            completeOnboarding()
        default:
            break
        }
    }

    private func handleSkip() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPage += 1
        }
    }

    private func requestNotifications() {
        Task {
            let granted = await NotificationManager.shared.requestPermission()
            await MainActor.run {
                notificationStatus = granted ? .granted : .denied
                // Don't auto-advance - user must tap Continue
            }
        }
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        onComplete()
    }
}

// MARK: - Color Page

private struct OnboardingColorPage: View {
    @Binding var selectedColorHex: String
    @State private var iconScale: CGFloat = 0.8
    @State private var iconOpacity: Double = 0
    @State private var contentOpacity: Double = 0

    // Color palette - vibrant colors that work well on dark backgrounds
    let colorOptions: [(hex: String, name: String)] = [
        ("#FF6B54", "Coral"),
        ("#FF9F43", "Orange"),
        ("#FECA57", "Golden"),
        ("#4ADE80", "Green"),
        ("#2DD4BF", "Teal"),
        ("#22D3EE", "Cyan"),
        ("#38BDF8", "Sky"),
        ("#3B82F6", "Blue"),
        ("#8B5CF6", "Purple"),
        ("#A78BFA", "Lavender"),
        ("#FB7185", "Pink"),
        ("#EF4444", "Red"),
    ]

    let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 4)

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Palette icon
            ZStack {
                Circle()
                    .fill(Color(hex: selectedColorHex.replacingOccurrences(of: "#", with: "")).opacity(0.2))
                    .frame(width: 140, height: 140)

                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 56, weight: .medium))
                    .foregroundColor(Color(hex: selectedColorHex.replacingOccurrences(of: "#", with: "")))
            }
            .scaleEffect(iconScale)
            .opacity(iconOpacity)

            VStack(spacing: 16) {
                Text("Pick Your Color")
                    .font(.custom("Avenir-Black", size: 28))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("This color will represent you\nto your friends.")
                    .font(.custom("Avenir-Medium", size: 17))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .opacity(contentOpacity)

            // Color grid
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(colorOptions, id: \.hex) { option in
                    OnboardingColorOption(
                        hex: option.hex,
                        isSelected: selectedColorHex == option.hex,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedColorHex = option.hex
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .opacity(contentOpacity)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                contentOpacity = 1.0
            }
        }
    }
}

private struct OnboardingColorOption: View {
    let hex: String
    let isSelected: Bool
    let action: () -> Void

    private var color: Color {
        Color(hex: hex.replacingOccurrences(of: "#", with: ""))
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 52, height: 52)
                    .shadow(color: color.opacity(isSelected ? 0.6 : 0.3), radius: isSelected ? 10 : 4, x: 0, y: 0)

                if isSelected {
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 62, height: 62)

                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 64, height: 64)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Welcome Page

private struct OnboardingWelcomePage: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var contentOpacity: Double = 0

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Logo
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .shadow(color: AppTheme.primaryGlow, radius: 25, x: 0, y: 12)
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

            VStack(spacing: 16) {
                Text("Welcome to Squibble!")
                    .font(.custom("Avenir-Black", size: 32))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Send doodles to friends.")
                    .font(.custom("Avenir-Medium", size: 18))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .opacity(contentOpacity)

            // Feature highlights
            VStack(spacing: 16) {
                OnboardingFeatureRow(icon: "pencil.tip", text: "Draw anything you want")
                OnboardingFeatureRow(icon: "paperplane.fill", text: "Send to friends instantly")
                OnboardingFeatureRow(icon: "sparkles", text: "They see doodles on their widget")
            }
            .opacity(contentOpacity)
            .padding(.top, 20)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                contentOpacity = 1.0
            }
        }
    }
}

private struct OnboardingFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.primaryStart)
                .frame(width: 32)

            Text(text)
                .font(.custom("Avenir-Medium", size: 16))
                .foregroundColor(AppTheme.textPrimary)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(AppTheme.glassBackgroundStrong)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.glassBorder, lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

// MARK: - Notification Page

private struct OnboardingNotificationPage: View {
    @Binding var status: OnboardingView.NotificationStatus
    @State private var bellScale: CGFloat = 0.8
    @State private var bellOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var bellWiggle = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Bell icon
            ZStack {
                Circle()
                    .fill(AppTheme.secondary.opacity(0.15))
                    .frame(width: 140, height: 140)

                Image(systemName: status == .granted ? "bell.badge.fill" : "bell.fill")
                    .font(.system(size: 56, weight: .medium))
                    .foregroundColor(AppTheme.secondary)
                    .rotationEffect(.degrees(bellWiggle ? 15 : -15))
            }
            .scaleEffect(bellScale)
            .opacity(bellOpacity)

            VStack(spacing: 16) {
                Text(statusTitle)
                    .font(.custom("Avenir-Black", size: 28))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(statusSubtitle)
                    .font(.custom("Avenir-Medium", size: 17))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .opacity(contentOpacity)

            // Benefits list
            if status == .notDetermined {
                VStack(spacing: 12) {
                    OnboardingNotificationBenefit(text: "Know when friends send you doodles")
                    OnboardingNotificationBenefit(text: "Get friend request alerts")
                    OnboardingNotificationBenefit(text: "Never miss a Squibble")
                }
                .opacity(contentOpacity)
                .padding(.top, 8)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                bellScale = 1.0
                bellOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                contentOpacity = 1.0
            }
            // Bell wiggle animation
            withAnimation(.easeInOut(duration: 0.15).repeatCount(6, autoreverses: true).delay(0.5)) {
                bellWiggle = true
            }
        }
    }

    private var statusTitle: String {
        switch status {
        case .notDetermined: return "Stay in the Loop"
        case .granted: return "You're All Set!"
        case .denied: return "No Worries"
        }
    }

    private var statusSubtitle: String {
        switch status {
        case .notDetermined:
            return "Enable notifications so you never\nmiss a doodle from friends."
        case .granted:
            return "You'll be notified when friends\nsend you doodles."
        case .denied:
            return "You can enable notifications\nlater in Settings."
        }
    }
}

private struct OnboardingNotificationBenefit: View {
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(AppTheme.secondary)

            Text(text)
                .font(.custom("Avenir-Medium", size: 15))
                .foregroundColor(AppTheme.textPrimary)

            Spacer()
        }
    }
}

// MARK: - Widget Page

private struct OnboardingWidgetPage: View {
    @State private var iconScale: CGFloat = 0.8
    @State private var iconOpacity: Double = 0
    @State private var contentOpacity: Double = 0

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Widget icon
            ZStack {
                Circle()
                    .fill(AppTheme.primaryStart.opacity(0.15))
                    .frame(width: 140, height: 140)

                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 56, weight: .medium))
                    .foregroundColor(AppTheme.primaryStart)
            }
            .scaleEffect(iconScale)
            .opacity(iconOpacity)

            VStack(spacing: 16) {
                Text("Add the Widget")
                    .font(.custom("Avenir-Black", size: 28))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("See doodles right on your\nhome screen!")
                    .font(.custom("Avenir-Medium", size: 17))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .opacity(contentOpacity)

            // Steps
            VStack(spacing: 12) {
                OnboardingWidgetStep(number: "1", text: "Long press your home screen")
                OnboardingWidgetStep(number: "2", text: "Tap the + in the top corner")
                OnboardingWidgetStep(number: "3", text: "Search for \"Squibble\"")
                OnboardingWidgetStep(number: "4", text: "Add the widget")
            }
            .opacity(contentOpacity)
            .padding(.top, 8)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                contentOpacity = 1.0
            }
        }
    }
}

private struct OnboardingWidgetStep: View {
    let number: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Text(number)
                .font(.custom("Avenir-Heavy", size: 14))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(AppTheme.primaryGradient)
                .clipShape(Circle())

            Text(text)
                .font(.custom("Avenir-Medium", size: 15))
                .foregroundColor(AppTheme.textPrimary)

            Spacer()
        }
    }
}

// MARK: - Invite Friends Page

private struct OnboardingInviteFriendsPage: View {
    @EnvironmentObject var userManager: UserManager
    @State private var iconScale: CGFloat = 0.8
    @State private var iconOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var copied = false

    private var inviteCode: String {
        userManager.currentUser?.inviteCode ?? "------"
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Friends icon
            ZStack {
                Circle()
                    .fill(AppTheme.secondary.opacity(0.15))
                    .frame(width: 140, height: 140)

                Image(systemName: "person.2.fill")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(AppTheme.secondary)
            }
            .scaleEffect(iconScale)
            .opacity(iconOpacity)

            VStack(spacing: 16) {
                Text("Invite Your Friends")
                    .font(.custom("Avenir-Black", size: 28))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Squibble is more fun with friends!\nShare your code to connect.")
                    .font(.custom("Avenir-Medium", size: 17))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .opacity(contentOpacity)

            // Invite code card
            VStack(spacing: 16) {
                Text("Your invite code")
                    .font(.custom("Avenir-Medium", size: 14))
                    .foregroundColor(AppTheme.textSecondary)

                Text(inviteCode)
                    .font(.custom("Avenir-Black", size: 32))
                    .foregroundColor(AppTheme.textPrimary)
                    .kerning(4)

                HStack(spacing: 12) {
                    // Copy button
                    Button(action: copyCode) {
                        HStack(spacing: 6) {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 14, weight: .semibold))
                            Text(copied ? "Copied!" : "Copy")
                                .font(.custom("Avenir-Heavy", size: 14))
                        }
                        .foregroundColor(copied ? .white : AppTheme.primaryStart)
                        .frame(width: 100, height: 40)
                        .background(
                            copied
                                ? LinearGradient(colors: [AppTheme.secondary, AppTheme.secondary.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [AppTheme.primaryStart.opacity(0.15), AppTheme.primaryStart.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .cornerRadius(10)
                    }

                    // Share button
                    ShareLink(
                        item: "Join me on Squibble! Use my invite code: \(inviteCode)\n\nDownload: https://apps.apple.com/app/squibble"
                    ) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Share")
                                .font(.custom("Avenir-Heavy", size: 14))
                        }
                        .foregroundColor(AppTheme.primaryStart)
                        .frame(width: 100, height: 40)
                        .background(AppTheme.primaryStart.opacity(0.15))
                        .cornerRadius(10)
                    }
                }
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
            .background(AppTheme.glassBackgroundStrong)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(AppTheme.glassBorder, lineWidth: 1)
            )
            .cornerRadius(20)
            .opacity(contentOpacity)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                contentOpacity = 1.0
            }
        }
    }

    private func copyCode() {
        UIPasteboard.general.string = inviteCode
        withAnimation(.easeInOut(duration: 0.2)) {
            copied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: 0.2)) {
                copied = false
            }
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
        .environmentObject(UserManager())
}
