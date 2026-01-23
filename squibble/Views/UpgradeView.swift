//
//  UpgradeView.swift
//  squibble
//
//  Premium upgrade screen with subscription options
//

import SwiftUI
import StoreKit

struct UpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    @StateObject private var storeManager = StoreManager.shared

    @State private var selectedPlan: SubscriptionPlan = .annual
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var appearAnimation = false

    enum SubscriptionPlan {
        case monthly, annual
    }

    private var isPremium: Bool {
        userManager.currentUser?.isPremium ?? false
    }

    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    headerSection

                    if isPremium {
                        // Already premium view
                        alreadyPremiumSection
                    } else {
                        // Features list
                        featuresSection

                        // Pricing cards
                        pricingSection

                        // Purchase button
                        purchaseButton

                        // Restore purchases
                        restoreButton

                        // Terms
                        termsText
                    }

                    Spacer().frame(height: 100)
                }
            }
            .scrollIndicators(.hidden)

            // Close button
            VStack {
                HStack {
                    closeButton
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                Spacer()
            }

            // Success overlay
            if showSuccess {
                successOverlay
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appearAnimation = true
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            // Base gradient matching app theme
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            // Coral ambient glow (upper area) - matching app theme but stronger for premium feel
            RadialGradient(
                colors: [AppTheme.primaryStart.opacity(0.15), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 400
            )

            // Gold ambient glow (lower area) - premium gold accent
            RadialGradient(
                colors: [Color(hex: "FFD93D").opacity(0.1), .clear],
                center: .bottomLeading,
                startRadius: 0,
                endRadius: 350
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Close Button

    private var closeButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppTheme.textSecondary)
                .frame(width: 36, height: 36)
                .background(AppTheme.glassBackgroundStrong)
                .overlay(
                    Circle()
                        .stroke(AppTheme.glassBorder, lineWidth: 1)
                )
                .clipShape(Circle())
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 8) {
            Spacer().frame(height: 50)

            // Premium badge with gold accent
            HStack(spacing: 6) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 12))
                Text("PRO")
                    .font(.custom("Avenir-Heavy", size: 11))
                    .tracking(2)
            }
            .foregroundColor(Color(hex: "FFD93D"))
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color(hex: "FFD93D").opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(Color(hex: "FFD93D").opacity(0.3), lineWidth: 1)
                    )
            )
            .opacity(appearAnimation ? 1 : 0)
            .offset(y: appearAnimation ? 0 : 20)

            // Title
            Text("Unlock the Full\nExperience")
                .font(.custom("Avenir-Heavy", size: 28))
                .foregroundColor(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .opacity(appearAnimation ? 1 : 0)
                .offset(y: appearAnimation ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.1), value: appearAnimation)

            // Subtitle
            Text("Send unlimited doodles to all your friends")
                .font(.custom("Avenir-Medium", size: 14))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .opacity(appearAnimation ? 1 : 0)
                .offset(y: appearAnimation ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.2), value: appearAnimation)

            Spacer().frame(height: 16)
        }
    }

    // MARK: - Already Premium Section

    private var alreadyPremiumSection: some View {
        VStack(spacing: 24) {
            // Success checkmark
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.secondary, AppTheme.secondary.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            }
            .shadow(color: AppTheme.secondaryGlow, radius: 20, x: 0, y: 10)

            Text("You're a Premium Member!")
                .font(.custom("Avenir-Heavy", size: 22))
                .foregroundColor(AppTheme.textPrimary)

            Text("Thank you for supporting Squibble")
                .font(.custom("Avenir-Medium", size: 15))
                .foregroundColor(AppTheme.textSecondary)

            // Features unlocked
            VStack(spacing: 0) {
                ForEach(PremiumFeature.allCases, id: \.self) { feature in
                    HStack(spacing: 14) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.secondary)

                        Text(feature.title)
                            .font(.custom("Avenir-Medium", size: 15))
                            .foregroundColor(AppTheme.textPrimary)

                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 20)

                    if feature != PremiumFeature.allCases.last {
                        Divider()
                            .background(AppTheme.divider)
                    }
                }
            }
            .glassContainer(cornerRadius: 16)
            .padding(.horizontal, 20)
            .padding(.top, 8)

            // Manage Subscription button
            Button(action: openSubscriptionManagement) {
                HStack(spacing: 8) {
                    Image(systemName: "gear")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Manage Subscription")
                        .font(.custom("Avenir-Medium", size: 14))
                }
                .foregroundColor(AppTheme.textSecondary)
            }
            .padding(.top, 8)
        }
        .padding(.top, 20)
    }

    private func openSubscriptionManagement() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(PremiumFeature.allCases.enumerated()), id: \.element) { index, feature in
                featureRow(feature: feature, index: index)

                if feature != PremiumFeature.allCases.last {
                    Divider()
                        .background(AppTheme.divider)
                }
            }
        }
        .glassContainer(cornerRadius: 16)
        .padding(.horizontal, 20)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 30)
        .animation(.easeOut(duration: 0.6).delay(0.3), value: appearAnimation)
    }

    private func featureRow(feature: PremiumFeature, index: Int) -> some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(feature.color.opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: feature.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(feature.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(feature.title)
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(AppTheme.textPrimary)

                    if feature.isComingSoon {
                        Text("SOON")
                            .font(.custom("Avenir-Heavy", size: 9))
                            .foregroundColor(Color(hex: "FFD93D"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: "FFD93D").opacity(0.2))
                            .cornerRadius(4)
                    }
                }

                Text(feature.description)
                    .font(.custom("Avenir-Regular", size: 12))
                    .foregroundColor(AppTheme.textTertiary)
            }

            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
    }

    // MARK: - Pricing Section

    private var pricingSection: some View {
        VStack(spacing: 10) {
            // Annual plan
            pricingCard(
                plan: .annual,
                title: "Annual",
                price: "$2.99",
                period: "/month",
                subtitle: "Billed \(storeManager.annualProduct?.displayPrice ?? "$35.99")/year",
                badge: "BEST VALUE",
                isSelected: selectedPlan == .annual
            )

            // Monthly plan
            pricingCard(
                plan: .monthly,
                title: "Monthly",
                price: storeManager.monthlyProduct?.displayPrice ?? "$3.99",
                period: "/month",
                subtitle: "Cancel anytime",
                badge: nil,
                isSelected: selectedPlan == .monthly
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 30)
        .animation(.easeOut(duration: 0.6).delay(0.4), value: appearAnimation)
    }

    private func pricingCard(
        plan: SubscriptionPlan,
        title: String,
        price: String,
        period: String,
        subtitle: String,
        badge: String?,
        isSelected: Bool
    ) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                selectedPlan = plan
            }
        }) {
            HStack(spacing: 14) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? AppTheme.primaryStart : AppTheme.buttonInactiveBorder, lineWidth: 2)
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(AppTheme.primaryStart)
                            .frame(width: 12, height: 12)
                    }
                }

                // Plan info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.custom("Avenir-Heavy", size: 16))
                            .foregroundColor(AppTheme.textPrimary)

                        if let badge = badge {
                            Text(badge)
                                .font(.custom("Avenir-Heavy", size: 9))
                                .foregroundColor(AppTheme.backgroundBottom)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "FFD93D"), Color(hex: "FF9500")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(4)
                        }
                    }

                    Text(subtitle)
                        .font(.custom("Avenir-Regular", size: 13))
                        .foregroundColor(AppTheme.textTertiary)
                }

                Spacer()

                // Price
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(price)
                        .font(.custom("Avenir-Heavy", size: 20))
                        .foregroundColor(AppTheme.textPrimary)

                    Text(period)
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AppTheme.glassBackgroundStrong : AppTheme.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? AppTheme.primaryStart.opacity(0.5) : AppTheme.glassBorder,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .shadow(color: isSelected ? AppTheme.primaryGlowSoft : .clear, radius: 12, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        Button(action: purchase) {
            HStack(spacing: 8) {
                if isPurchasing || storeManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Continue")
                        .font(.custom("Avenir-Heavy", size: 16))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(AppTheme.primaryGradient)
            .clipShape(Capsule())
            .shadow(color: AppTheme.primaryGlow, radius: 16, x: 0, y: 4)
        }
        .disabled(isPurchasing || storeManager.isLoading)
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 30)
        .animation(.easeOut(duration: 0.6).delay(0.5), value: appearAnimation)
    }

    // MARK: - Restore Button

    private var restoreButton: some View {
        Button(action: restore) {
            Text("Restore Purchases")
                .font(.custom("Avenir-Medium", size: 14))
                .foregroundColor(AppTheme.textTertiary)
                .underline()
        }
        .padding(.top, 16)
        .opacity(appearAnimation ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.6), value: appearAnimation)
    }

    // MARK: - Terms Text

    private var termsText: some View {
        VStack(spacing: 8) {
            // Subscription details required by App Store
            Text(subscriptionDisclosureText)
                .font(.custom("Avenir-Regular", size: 11))
                .foregroundColor(AppTheme.textInactive)
                .multilineTextAlignment(.center)

            HStack(spacing: 4) {
                Button("Terms of Use (EULA)") {
                    if let url = URL(string: "https://mehulpandey.github.io/squibble-legal/terms-of-service") {
                        UIApplication.shared.open(url)
                    }
                }
                .underline()
                Text("•")
                Button("Privacy Policy") {
                    if let url = URL(string: "https://mehulpandey.github.io/squibble-legal/privacy-policy") {
                        UIApplication.shared.open(url)
                    }
                }
                .underline()
            }
            .font(.custom("Avenir-Regular", size: 11))
            .foregroundColor(AppTheme.textInactive)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .opacity(appearAnimation ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.7), value: appearAnimation)
    }

    private var subscriptionDisclosureText: String {
        let monthlyPrice = storeManager.monthlyProduct?.displayPrice ?? "$3.99"
        let annualPrice = storeManager.annualProduct?.displayPrice ?? "$35.99"

        return "Squibble Pro Monthly: \(monthlyPrice)/month. Squibble Pro Annual: \(annualPrice)/year. Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless cancelled at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period. You can manage and cancel your subscriptions in your App Store account settings."
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        ZStack {
            // Dark opaque background
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.secondary, AppTheme.secondary.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)

                    Image(systemName: "checkmark")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                }
                .shadow(color: AppTheme.secondaryGlow, radius: 20, x: 0, y: 10)

                Text("Welcome to Premium!")
                    .font(.custom("Avenir-Heavy", size: 24))
                    .foregroundColor(AppTheme.textPrimary)

                Text("You now have access to all premium features")
                    .font(.custom("Avenir-Medium", size: 15))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)

                Button(action: { dismiss() }) {
                    Text("Let's Go!")
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.white)
                        .frame(width: 160, height: 48)
                        .background(AppTheme.primaryGradient)
                        .clipShape(Capsule())
                        .shadow(color: AppTheme.primaryGlow, radius: 12, x: 0, y: 4)
                }
                .padding(.top, 8)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(AppTheme.backgroundTop)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(AppTheme.glassBorder, lineWidth: 1)
                    )
            )
        }
        .transition(.opacity)
    }

    // MARK: - Actions

    private func purchase() {
        let product: Product?
        switch selectedPlan {
        case .annual:
            product = storeManager.annualProduct
        case .monthly:
            product = storeManager.monthlyProduct
        }

        guard let product = product else {
            errorMessage = "Product not available"
            showError = true
            return
        }

        isPurchasing = true

        Task {
            do {
                let success = try await storeManager.purchase(product)
                if success {
                    // Update user's premium status in Supabase
                    try? await userManager.updatePremiumStatus(isPremium: true)

                    withAnimation {
                        showSuccess = true
                    }
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isPurchasing = false
        }
    }

    private func restore() {
        Task {
            await storeManager.restorePurchases()

            if storeManager.hasActiveSubscription {
                try? await userManager.updatePremiumStatus(isPremium: true)
                withAnimation {
                    showSuccess = true
                }
            } else if let error = storeManager.errorMessage {
                errorMessage = error
                showError = true
            }
        }
    }
}

// MARK: - Premium Feature

enum PremiumFeature: CaseIterable {
    case unlimitedFriends
    case noAds
    case uploadImage
    case aiAnimate

    var icon: String {
        switch self {
        case .unlimitedFriends: return "person.2.fill"
        case .noAds: return "hand.raised.slash.fill"
        case .uploadImage: return "photo.fill"
        case .aiAnimate: return "wand.and.stars"
        }
    }

    var title: String {
        switch self {
        case .unlimitedFriends: return "Unlimited Friends"
        case .noAds: return "Remove Ads"
        case .uploadImage: return "Upload Image"
        case .aiAnimate: return "AI Animation"
        }
    }

    var description: String {
        switch self {
        case .unlimitedFriends: return "No more 30 friend limit"
        case .noAds: return "Enjoy an ad-free experience"
        case .uploadImage: return "Doodle on top of your photos"
        case .aiAnimate: return "Animate doodles with AI"
        }
    }

    var color: Color {
        switch self {
        case .unlimitedFriends: return Color(hex: "5856D6")
        case .noAds: return Color(hex: "FF6B6B")
        case .uploadImage: return Color(hex: "38BDF8")
        case .aiAnimate: return Color(hex: "FFD93D")
        }
    }

    var isComingSoon: Bool {
        switch self {
        case .aiAnimate: return true
        default: return false
        }
    }
}

#Preview {
    UpgradeView()
        .environmentObject(UserManager())
}
