//
//  BannerAdView.swift
//  squibble
//
//  Google AdMob banner ad wrapper for SwiftUI
//

import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = adUnitID

        // Get the root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            bannerView.rootViewController = rootVC
        }

        bannerView.load(Request())
        return bannerView
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}

// MARK: - Banner Ad Container

struct BannerAdContainer: View {
    @EnvironmentObject var userManager: UserManager

    private var shouldShowAd: Bool {
        guard let user = userManager.currentUser else { return true }
        return !user.isPremium
    }

    var body: some View {
        if shouldShowAd {
            BannerAdView(adUnitID: Config.AdMob.bannerAdUnitID)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(Color(hex: "F5F5F5"))
        }
    }
}

#Preview {
    BannerAdContainer()
        .environmentObject(UserManager())
}
