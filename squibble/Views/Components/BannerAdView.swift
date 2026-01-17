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

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = adUnitID
        bannerView.delegate = context.coordinator
        context.coordinator.bannerView = bannerView
        return bannerView
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        // Only load if not already loaded
        if !context.coordinator.hasLoaded {
            context.coordinator.hasLoaded = true

            // Get the root view controller
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                uiView.rootViewController = rootVC
            }

            // Load ad asynchronously to avoid blocking UI
            DispatchQueue.main.async {
                uiView.load(Request())
            }
        }
    }

    class Coordinator: NSObject, BannerViewDelegate {
        var bannerView: BannerView?
        var hasLoaded = false

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            // Ad loaded successfully
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("Banner ad failed to load: \(error.localizedDescription)")
        }
    }
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
